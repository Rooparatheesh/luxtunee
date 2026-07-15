import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:metadata_god/metadata_god.dart';

class DownloadService {
  bool _metadataInitialized = false;

  /// Downloads an audio file from a URL and saves it to the device's public Music folder.
  /// Returns the path to the downloaded file, or null if it failed.
  Future<String?> downloadTrack(
    String url,
    String trackTitle,
    String trackArtist, {
    String? albumArtUrl,
    Function(double)? onProgress,
  }) async {
    final filename = '$trackTitle - $trackArtist';
    if (Platform.isAndroid) {
      var status = await Permission.storage.status;
      if (!status.isGranted) {
        status = await Permission.storage.request();
      }

      // For Android 13+ we need audio permissions or manage external storage
      var audioStatus = await Permission.audio.status;
      if (!audioStatus.isGranted) {
        await Permission.audio.request();
      }
    }

    try {
      Directory? baseDirectory;

      if (Platform.isAndroid) {
        // Try to save to the public Music directory
        baseDirectory = Directory('/storage/emulated/0/Music');
        if (!await baseDirectory.exists()) {
          try {
            await baseDirectory.create(recursive: true);
          } catch (e) {
            // Fallback to app's external directory if we can't create public directory
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

      // Sanitize filename and create a dedicated folder for the song
      final safeName = filename.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_').trim();
      final songDirectory = Directory(
        '${baseDirectory.path}/LuxTune/$safeName',
      );
      if (!await songDirectory.exists()) {
        await songDirectory.create(recursive: true);
      }

      final audioPath = '${songDirectory.path}/$safeName.m4a';
      final file = File(audioPath);

      // 1. Download cover art if available
      if (albumArtUrl != null && albumArtUrl.isNotEmpty) {
        try {
          final coverResponse = await http.get(Uri.parse(albumArtUrl));
          if (coverResponse.statusCode == 200) {
            final coverFile = File('${songDirectory.path}/cover.jpg');
            await coverFile.writeAsBytes(coverResponse.bodyBytes);
          }
        } catch (_) {
          // ignore cover art failure
        }
      }

      // 2. Download audio stream
      final client = http.Client();
      final request = http.Request('GET', Uri.parse(url));
      final response = await client.send(request);

      if (response.statusCode == 200) {
        final totalBytes = response.contentLength ?? 0;
        int receivedBytes = 0;
        final sink = file.openWrite();

        await for (final chunk in response.stream) {
          receivedBytes += chunk.length;
          sink.add(chunk);
          if (totalBytes > 0 && onProgress != null) {
            onProgress(receivedBytes / totalBytes);
          }
        }

        await sink.close();
        client.close();

        // 3. Inject Metadata (ID3 tags)
        try {
          if (!_metadataInitialized) {
            await MetadataGod.initialize();
            _metadataInitialized = true;
          }

          Picture? albumArtPicture;
          if (albumArtUrl != null && albumArtUrl.isNotEmpty) {
            final coverFile = File('${songDirectory.path}/cover.jpg');
            if (await coverFile.exists()) {
              albumArtPicture = Picture(
                data: await coverFile.readAsBytes(),
                mimeType: 'image/jpeg',
              );
            }
          }

          await MetadataGod.writeMetadata(
            file: audioPath,
            metadata: Metadata(
              title: trackTitle,
              artist: trackArtist,
              album: "LuxTune Downloads",
              picture: albumArtPicture,
            ),
          );
        } catch (e) {
          // Ignore metadata errors so we still return the downloaded path
          print("Failed to write metadata: $e");
        }

        return audioPath;
      }
      client.close();
    } catch (e) {
      // ignore
    }

    return null;
  }
}
