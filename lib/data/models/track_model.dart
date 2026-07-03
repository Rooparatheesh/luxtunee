// lib/data/models/track_model.dart

class TrackModel {
  final String id;
  final String title;
  final String artist;
  final String album;
  final String
  albumArt; // kept for network/asset images (onboarding, mock data)
  final Duration duration;
  final String audioUrl; // kept for remote/mock audio
  final String uri; // local file URI from on_audio_query
  final int? albumId; // for QueryArtworkWidget
  final bool isFavorite;
  final String lyrics;
  final String source; // 'local', 'deezer', 'itunes', 'navidrome', etc.
  final String syncedLyrics; // LRC formatted synced lyrics

  const TrackModel({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    required this.duration,
    this.albumArt = '',
    this.audioUrl = '',
    this.uri = '',
    this.albumId,
    this.isFavorite = false,
    this.lyrics = '',
    this.source = 'local',
    this.syncedLyrics = '',
  });

  TrackModel copyWith({
    String? id,
    String? title,
    String? artist,
    String? album,
    String? albumArt,
    Duration? duration,
    String? audioUrl,
    String? uri,
    int? albumId,
    bool? isFavorite,
    String? lyrics,
    String? source,
    String? syncedLyrics,
  }) => TrackModel(
    id: id ?? this.id,
    title: title ?? this.title,
    artist: artist ?? this.artist,
    album: album ?? this.album,
    albumArt: albumArt ?? this.albumArt,
    duration: duration ?? this.duration,
    audioUrl: audioUrl ?? this.audioUrl,
    uri: uri ?? this.uri,
    albumId: albumId ?? this.albumId,
    isFavorite: isFavorite ?? this.isFavorite,
    lyrics: lyrics ?? this.lyrics,
    source: source ?? this.source,
    syncedLyrics: syncedLyrics ?? this.syncedLyrics,
  );

  /// Use local URI if available, fall back to remote URL
  String get playbackSource => uri.isNotEmpty ? uri : audioUrl;

  /// True if this track came from the local library
  bool get isLocal => uri.isNotEmpty;

  String get formattedDuration {
    final m = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'artist': artist,
    'album': album,
    'albumArt': albumArt,
    'durationMs': duration.inMilliseconds,
    'audioUrl': audioUrl,
    'uri': uri,
    'albumId': albumId,
    'isFavorite': isFavorite,
    'lyrics': lyrics,
    'source': source,
    'syncedLyrics': syncedLyrics,
  };

  factory TrackModel.fromJson(Map<String, dynamic> json) => TrackModel(
    id: json['id'] as String? ?? '',
    title: json['title'] as String? ?? 'Unknown',
    artist: json['artist'] as String? ?? 'Unknown Artist',
    album: json['album'] as String? ?? 'Unknown Album',
    albumArt: json['albumArt'] as String? ?? '',
    duration: Duration(milliseconds: json['durationMs'] as int? ?? 0),
    audioUrl: json['audioUrl'] as String? ?? '',
    uri: json['uri'] as String? ?? '',
    albumId: json['albumId'] as int?,
    isFavorite: json['isFavorite'] as bool? ?? false,
    lyrics: json['lyrics'] as String? ?? '',
    source: json['source'] as String? ?? 'local',
    syncedLyrics: json['syncedLyrics'] as String? ?? '',
  );
}
