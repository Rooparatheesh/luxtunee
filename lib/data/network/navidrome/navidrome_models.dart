import '../../models/track_model.dart';
import '../../models/playlist_model.dart';

class NavidromeCredentials {
  final String serverUrl;
  final String username;
  final String password;
  final String clientId;

  NavidromeCredentials({
    required this.serverUrl,
    required this.username,
    required this.password,
    this.clientId = 'PixelPlayer',
  });

  String get normalizedServerUrl {
    var url = serverUrl;
    if (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'http://$url';
    }
    return url;
  }
}

class NavidromeSong {
  final String id;
  final String title;
  final String artist;
  final String? artistId;
  final String album;
  final String? albumId;
  final String? coverArt;
  final int durationMs;
  final int trackNumber;
  final int year;

  NavidromeSong({
    required this.id,
    required this.title,
    required this.artist,
    this.artistId,
    required this.album,
    this.albumId,
    this.coverArt,
    required this.durationMs,
    required this.trackNumber,
    required this.year,
  });

  factory NavidromeSong.fromJson(Map<String, dynamic> json) {
    return NavidromeSong(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? json['name'] ?? 'Unknown Title',
      artist: json['artist'] ?? 'Unknown Artist',
      artistId: json['artistId']?.toString(),
      album: json['album'] ?? 'Unknown Album',
      albumId: json['albumId']?.toString(),
      coverArt: json['coverArt']?.toString(),
      durationMs: (json['duration'] is int) ? json['duration'] * 1000 : 0,
      trackNumber: json['track'] ?? 0,
      year: json['year'] ?? 0,
    );
  }

  TrackModel toTrackModel(
    String Function(String) getCoverArtUrl,
    String Function(String) getStreamUrl,
  ) {
    return TrackModel(
      id: id,
      title: title,
      artist: artist,
      album: album,
      albumArt: coverArt != null ? getCoverArtUrl(coverArt!) : '',
      audioUrl: getStreamUrl(id),
      duration: Duration(milliseconds: durationMs),
      source: 'navidrome',
    );
  }
}

class NavidromePlaylist {
  final String id;
  final String name;
  final int songCount;
  final String? coverArt;

  NavidromePlaylist({
    required this.id,
    required this.name,
    required this.songCount,
    this.coverArt,
  });

  factory NavidromePlaylist.fromJson(Map<String, dynamic> json) {
    return NavidromePlaylist(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? json['title'] ?? 'Unknown Playlist',
      songCount: json['songCount'] ?? json['entryCount'] ?? 0,
      coverArt: json['coverArt']?.toString(),
    );
  }

  PlaylistModel toPlaylistModel(String Function(String) getCoverArtUrl) {
    return PlaylistModel(
      id: id,
      title: name,
      coverUrl: coverArt != null ? getCoverArtUrl(coverArt!) : '',
      songCount: songCount,
      source: 'navidrome',
    );
  }
}
