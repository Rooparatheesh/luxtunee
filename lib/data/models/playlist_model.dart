// lib/data/models/playlist_model.dart
import 'dart:convert';
import 'track_model.dart';

class PlaylistModel {
  final String id;
  String title;
  final String coverUrl;
  final int songCount;
  final String source;
  final List<TrackModel> tracks;

  PlaylistModel({
    required this.id,
    required this.title,
    this.coverUrl = '',
    this.songCount = 0,
    this.source = 'local',
    this.tracks = const [],
  });

  PlaylistModel copyWith({
    String? id,
    String? title,
    String? coverUrl,
    int? songCount,
    String? source,
    List<TrackModel>? tracks,
  }) {
    return PlaylistModel(
      id: id ?? this.id,
      title: title ?? this.title,
      coverUrl: coverUrl ?? this.coverUrl,
      songCount: songCount ?? this.songCount,
      source: source ?? this.source,
      tracks: tracks ?? this.tracks,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'coverUrl': coverUrl,
      'songCount': songCount,
      'source': source,
      'tracks': tracks.map((x) => _trackToMap(x)).toList(),
    };
  }

  factory PlaylistModel.fromMap(Map<String, dynamic> map) {
    return PlaylistModel(
      id: map['id'] ?? '',
      title: map['title'] ?? map['name'] ?? '',
      coverUrl: map['coverUrl'] ?? '',
      songCount: map['songCount'] ?? 0,
      source: map['source'] ?? 'local',
      tracks: List<TrackModel>.from(
          (map['tracks'] as List? ?? []).map((x) => _trackFromMap(x))),
    );
  }

  String toJson() => json.encode(toMap());

  factory PlaylistModel.fromJson(String source) =>
      PlaylistModel.fromMap(json.decode(source));

  // Helper to convert TrackModel to Map since it doesn't have it built-in
  static Map<String, dynamic> _trackToMap(TrackModel track) {
    return {
      'id': track.id,
      'title': track.title,
      'artist': track.artist,
      'album': track.album,
      'duration': track.duration.inMilliseconds,
      'albumArt': track.albumArt,
      'audioUrl': track.audioUrl,
      'uri': track.uri,
      'albumId': track.albumId,
      'isFavorite': track.isFavorite,
      'lyrics': track.lyrics,
      'source': track.source,
      'syncedLyrics': track.syncedLyrics,
    };
  }

  static TrackModel _trackFromMap(Map<String, dynamic> map) {
    return TrackModel(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      artist: map['artist']?.toString() ?? '',
      album: map['album']?.toString() ?? '',
      duration: Duration(milliseconds: map['duration'] ?? 0),
      albumArt: map['albumArt']?.toString() ?? '',
      audioUrl: map['audioUrl']?.toString() ?? '',
      uri: map['uri']?.toString() ?? '',
      albumId: map['albumId'],
      isFavorite: map['isFavorite'] ?? false,
      lyrics: map['lyrics']?.toString() ?? '',
      source: map['source']?.toString() ?? 'local',
      syncedLyrics: map['syncedLyrics']?.toString() ?? '',
    );
  }
}
