import '../../models/track_model.dart';
import '../../models/playlist_model.dart';

class JellyfinCredentials {
  final String serverUrl;
  final String username;
  final String password;
  String? accessToken;
  String? userId;

  JellyfinCredentials({
    required this.serverUrl,
    required this.username,
    required this.password,
    this.accessToken,
    this.userId,
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

  bool get hasToken =>
      accessToken != null &&
      accessToken!.isNotEmpty &&
      userId != null &&
      userId!.isNotEmpty;
}

class JellyfinSong {
  final String id;
  final String name;
  final String album;
  final String? albumId;
  final List<String> artists;
  final int durationMs;
  final bool hasPrimaryImage;

  JellyfinSong({
    required this.id,
    required this.name,
    required this.album,
    this.albumId,
    required this.artists,
    required this.durationMs,
    required this.hasPrimaryImage,
  });

  factory JellyfinSong.fromJson(Map<String, dynamic> json) {
    List<String> artistsList = [];
    if (json['Artists'] != null) {
      artistsList = List<String>.from(json['Artists']);
    } else if (json['ArtistItems'] != null) {
      for (var item in json['ArtistItems']) {
        if (item['Name'] != null) {
          artistsList.add(item['Name']);
        }
      }
    }
    if (artistsList.isEmpty && json['AlbumArtist'] != null) {
      artistsList.add(json['AlbumArtist']);
    }

    int durationTicks = json['RunTimeTicks'] ?? 0;
    int durationMs = durationTicks ~/ 10000; // 1 tick = 100 ns = 0.0001 ms

    bool hasImage = false;
    if (json['ImageTags'] != null && json['ImageTags']['Primary'] != null) {
      hasImage = true;
    }

    return JellyfinSong(
      id: json['Id']?.toString() ?? '',
      name: json['Name'] ?? 'Unknown',
      album: json['Album'] ?? 'Unknown Album',
      albumId: json['AlbumId']?.toString(),
      artists: artistsList,
      durationMs: durationMs,
      hasPrimaryImage: hasImage,
    );
  }

  TrackModel toTrackModel(
    String Function(String) getCoverArtUrl,
    String Function(String) getStreamUrl,
  ) {
    return TrackModel(
      id: id,
      title: name,
      artist: artists.isNotEmpty ? artists.join(', ') : 'Unknown Artist',
      album: album,
      albumArt: hasPrimaryImage
          ? getCoverArtUrl(id)
          : (albumId != null ? getCoverArtUrl(albumId!) : ''),
      audioUrl: getStreamUrl(id),
      duration: Duration(milliseconds: durationMs),
      source: 'jellyfin',
    );
  }
}

class JellyfinPlaylist {
  final String id;
  final String name;
  final int childCount;
  final bool hasPrimaryImage;

  JellyfinPlaylist({
    required this.id,
    required this.name,
    required this.childCount,
    required this.hasPrimaryImage,
  });

  factory JellyfinPlaylist.fromJson(Map<String, dynamic> json) {
    bool hasImage = false;
    if (json['ImageTags'] != null && json['ImageTags']['Primary'] != null) {
      hasImage = true;
    }

    return JellyfinPlaylist(
      id: json['Id']?.toString() ?? '',
      name: json['Name'] ?? 'Unknown Playlist',
      childCount: json['ChildCount'] ?? 0,
      hasPrimaryImage: hasImage,
    );
  }

  PlaylistModel toPlaylistModel(String Function(String) getCoverArtUrl) {
    return PlaylistModel(
      id: id,
      title: name,
      coverUrl: hasPrimaryImage ? getCoverArtUrl(id) : '',
      songCount: childCount,
      source: 'jellyfin',
    );
  }
}
