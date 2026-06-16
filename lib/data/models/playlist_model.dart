// lib/data/models/playlist_model.dart

class PlaylistModel {
  final String id;
  final String title;
  final String coverUrl;
  final int songCount;
  final String source;

  const PlaylistModel({
    required this.id,
    required this.title,
    this.coverUrl = '',
    this.songCount = 0,
    required this.source,
  });
}
