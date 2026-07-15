import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:audiotags/audiotags.dart';

class DownloadService {

  /// Downloads an audio file from a URL and saves it to the device's public Music folder.
  /// Returns the path to the downloaded file, or null if it failed.
  Future<String?> downloadTrack(
    String url,
    String trackTitle,
    String trackArtist, {
    String? albumArtUrl,
    String? albumName,
    Future<Map<String, dynamic>> Function()? streamProvider,
    Function(double)? onProgress,
  }) async {
    final filename = '$trackTitle - $trackArtist';
    if (Platform.isAndroid) {
      var status = await Permission.storage.status;
      if (!status.isGranted) {
        status = await Permission.storage.request();
      }

      // For Android 13+ we need audio permissions
      var audioStatus = await Permission.audio.status;
      if (!audioStatus.isGranted) {
        await Permission.audio.request();
      }
    }

    try {
      Directory? baseDirectory;

      if (Platform.isAndroid) {
        // Try public Music directory first
        baseDirectory = Directory('/storage/emulated/0/Music');
        if (!await baseDirectory.exists()) {
          try {
            await baseDirectory.create(recursive: true);
          } catch (e) {
            // Fallback to app's external directory
            final dirs = await getExternalStorageDirectories(
              type: StorageDirectory.music,
            );
            if (dirs != null && dirs.isNotEmpty) {
              baseDirectory = dirs.first;
            } else {
              baseDirectory = await getExternalStorageDirectory();
            }
          }
        }
      } else {
        baseDirectory = await getApplicationDocumentsDirectory();
      }

      if (baseDirectory == null) return null;

      // Sanitize filename and create folder
      final safeName = filename.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_').trim();
      final songDirectory = Directory(
        '${baseDirectory.path}/LuxTune/$safeName',
      );
      if (!await songDirectory.exists()) {
        await songDirectory.create(recursive: true);
      }

      final audioPath = '${songDirectory.path}/$safeName.m4a';
      final file = File(audioPath);

      // 1. Download cover art INTO MEMORY (avoid Android permission issues with file writes)
      Uint8List? coverArtBytes;
      if (albumArtUrl != null && albumArtUrl.isNotEmpty) {
        try {
          print('🖼️ Downloading cover art from: $albumArtUrl');
          final coverResponse = await http.get(Uri.parse(albumArtUrl));
          if (coverResponse.statusCode == 200) {
            coverArtBytes = coverResponse.bodyBytes;
            print('✅ Cover art loaded into memory (${coverArtBytes.length} bytes)');

            // Save cover art PERMANENTLY to app's documents directory.
            // getApplicationDocumentsDirectory() = /data/data/com.example.luxtunee/files/
            // This is NEVER auto-deleted by Android (unlike cache/temp dirs).
            try {
              final docsDir = await getApplicationDocumentsDirectory();
              final coversDir = Directory('${docsDir.path}/luxtune_covers');
              if (!await coversDir.exists()) {
                await coversDir.create(recursive: true);
              }
              // Use safeName as the key so local_repository can look it up by audio filename
              final coverFile = File('${coversDir.path}/$safeName.jpg');
              await coverFile.writeAsBytes(coverArtBytes);
              print('✅ Cover art saved permanently at: ${coverFile.path}');
            } catch (e) {
              print('⚠️ Could not save cover art permanently: $e');
            }
          } else {
            print('❌ Cover art HTTP error: ${coverResponse.statusCode}');
          }
        } catch (e) {
          print('❌ Cover art download failed: $e');
        }
      } else {
        print('⚠️ No albumArtUrl — metadata will have no cover art!');
      }

      // 2. Download audio stream
      final sink = file.openWrite();

      if (streamProvider != null) {
        final streamData = await streamProvider();
        final Stream<List<int>> stream = streamData['stream'];
        final int totalBytes = streamData['size'] ?? 0;
        int receivedBytes = 0;

        await for (final chunk in stream) {
          receivedBytes += chunk.length;
          sink.add(chunk);
          if (totalBytes > 0 && onProgress != null) {
            onProgress(receivedBytes / totalBytes);
          }
        }
      } else {
        final client = http.Client();
        final request = http.Request('GET', Uri.parse(url));
        request.headers['User-Agent'] =
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/114.0.0.0 Safari/537.36';

        final response = await client.send(request);

        if (response.statusCode == 200) {
          final totalBytes = response.contentLength ?? 0;
          int receivedBytes = 0;

          await for (final chunk in response.stream) {
            receivedBytes += chunk.length;
            sink.add(chunk);
            if (totalBytes > 0 && onProgress != null) {
              onProgress(receivedBytes / totalBytes);
            }
          }
        } else {
          client.close();
          throw Exception('HTTP Error: ${response.statusCode} - ${response.reasonPhrase}');
        }
        client.close();
      }

      await sink.close();

      // 3. Inject Metadata using cover art bytes already in memory (no file write needed!)
      try {
        List<Picture> pictures = [];
        if (coverArtBytes != null && coverArtBytes.isNotEmpty) {
          pictures.add(Picture(
            bytes: Uint8List.fromList(coverArtBytes),
            mimeType: MimeType.jpeg,
            pictureType: PictureType.coverFront,
          ));
        }

        final tag = Tag(
          title: trackTitle,
          artist: trackArtist,
          album: albumName ?? 'LuxTune Downloads',
          pictures: pictures,
        );

        await AudioTags.write(audioPath, tag);
        print('✅ Metadata written: title=$trackTitle, artist=$trackArtist, album=${albumName ?? "LuxTune Downloads"}, hasCover=${pictures.isNotEmpty}');
      } catch (e) {
        // metadata_god may not be compiled if Rust is not installed.
        // The download still succeeds — we just won't have embedded tags.
        print('⚠️ Metadata write skipped: $e');
      }

      return audioPath;
    } catch (e, stack) {
      print('DownloadService Exception: $e\n$stack');
      throw Exception('Failed to save file: $e');
    }
  }
}
