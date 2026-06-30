// lib/data/repositories/local_repository.dart
import 'package:on_audio_query/on_audio_query.dart';
import '../models/track_model.dart';

class LocalRepository {
  final OnAudioQuery _audioQuery = OnAudioQuery();

  Future<bool> requestPermission() async {
    return await _audioQuery.permissionsRequest();
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

    return songs
        .where((s) => s.duration != null && s.duration! > 30000) // skip <30s
        .where((s) {
          final path = s.data.toLowerCase();
          return !path.contains('whatsapp') &&
              !path.contains('voice') &&
              !path.contains('record');
        })
        .map(
          (s) => TrackModel(
            id: s.id.toString(),
            title: s.title,
            artist: s.artist ?? 'Unknown Artist',
            album: s.album ?? 'Unknown Album',
            duration: Duration(milliseconds: s.duration!),
            uri: s.uri ?? '',
            albumId: s.albumId,
            albumArt: '',
            audioUrl: '',
          ),
        )
        .toList();
  }
}
