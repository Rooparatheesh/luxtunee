// lib/data/repositories/local_repository.dart
import 'dart:io';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:path_provider/path_provider.dart';
import '../models/track_model.dart';

class LocalRepository {
  final OnAudioQuery _audioQuery = OnAudioQuery();

  /// NOTE: Do NOT call this from initState/addPostFrameCallback.
  /// Use permission_handler directly to avoid UninitializedPluginProviderException.
  Future<bool> requestPermission() async {
    try {
      return await _audioQuery.permissionsRequest();
    } catch (_) {
      return false;
    }
  }

  Future<void> scanMedia(String path) async {
    try {
      await _audioQuery.scanMedia(path);
    } catch (e) {
      // ignore
    }
  }



  Future<List<TrackModel>> fetchTracks() async {
    final songs = await _audioQuery.querySongs(
      sortType: SongSortType.TITLE,
      orderType: OrderType.ASC_OR_SMALLER,
      uriType: UriType.EXTERNAL,
      ignoreCase: true,
    );

    // Pre-load cover art paths from permanent storage (documents directory, never auto-deleted)
    final List<FileSystemEntity> savedCovers;
    try {
      final docsDir = await getApplicationDocumentsDirectory();
      final coversDir = Directory('${docsDir.path}/luxtune_covers');
      savedCovers = await coversDir.exists() ? await coversDir.list().toList() : [];
    } catch (_) {
      return _mapSongs(songs, {});
    }

    // Build a lookup map: audio basename -> cover art path
    final Map<String, String> coverMap = {};
    for (final entity in savedCovers) {
      if (entity is File && entity.path.endsWith('.jpg')) {
        final key = entity.path.split('/').last.replaceAll('.jpg', '');
        coverMap[key] = entity.path;
      }
    }

    return _mapSongs(songs, coverMap);
  }

  List<TrackModel> _mapSongs(List<SongModel> songs, Map<String, String> coverMap) {
    return songs
        .where((s) {
          final path = s.data.toLowerCase();
          // Always include our own downloaded files
          if (path.contains('luxtune')) return true;
          return s.duration != null && s.duration! > 30000;
        })
        .where((s) {
          final path = s.data.toLowerCase();
          if (path.contains('luxtune')) return true;
          return !path.contains('whatsapp') &&
              !path.contains('voice') &&
              !path.contains('record');
        })
        .map((s) {
          // Check if we have a cached cover art for this track
          final audioBasename = s.data.split('/').last
              .replaceAll('.m4a', '')
              .replaceAll('.mp3', '');
          final cachedCoverPath = coverMap[audioBasename];

          return TrackModel(
            id: s.id.toString(),
            title: s.title,
            artist: s.artist ?? 'Unknown Artist',
            album: s.album ?? 'Unknown Album',
            duration: Duration(milliseconds: s.duration ?? 0),
            uri: s.uri ?? s.data,
            albumId: s.albumId,
            // Use cached cover art path if available (for LuxTune downloads)
            albumArt: cachedCoverPath ?? '',
            audioUrl: '',
          );
        })
        .toList();
  }
}
