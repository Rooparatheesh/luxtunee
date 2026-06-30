// lib/data/network/deezer/deezer_models.dart

// Lightweight data classes for Deezer API responses.
// Mirrors the Kotlin DeezerModels.kt from PixelPlayer.

class DeezerTrack {
  final int id;
  final String title;
  final String titleShort;
  final int duration; // seconds
  final String preview; // 30s MP3 preview URL
  final DeezerArtist artist;
  final DeezerAlbum album;

  const DeezerTrack({
    required this.id,
    required this.title,
    required this.titleShort,
    required this.duration,
    required this.preview,
    required this.artist,
    required this.album,
  });

  factory DeezerTrack.fromJson(Map<String, dynamic> json) {
    return DeezerTrack(
      id: json['id'] as int,
      title: (json['title'] as String?) ?? 'Unknown',
      titleShort: (json['title_short'] as String?) ?? '',
      duration: (json['duration'] as int?) ?? 0,
      preview: (json['preview'] as String?) ?? '',
      artist: DeezerArtist.fromJson(
        json['artist'] as Map<String, dynamic>? ?? {},
      ),
      album: DeezerAlbum.fromJson(json['album'] as Map<String, dynamic>? ?? {}),
    );
  }
}

class DeezerArtist {
  final int id;
  final String name;
  final String picture; // small
  final String pictureMedium;
  final String pictureBig;

  const DeezerArtist({
    required this.id,
    required this.name,
    this.picture = '',
    this.pictureMedium = '',
    this.pictureBig = '',
  });

  factory DeezerArtist.fromJson(Map<String, dynamic> json) {
    return DeezerArtist(
      id: (json['id'] as int?) ?? 0,
      name: (json['name'] as String?) ?? 'Unknown Artist',
      picture: (json['picture'] as String?) ?? '',
      pictureMedium: (json['picture_medium'] as String?) ?? '',
      pictureBig: (json['picture_big'] as String?) ?? '',
    );
  }
}

class DeezerAlbum {
  final int id;
  final String title;
  final String cover; // small
  final String coverMedium;
  final String coverBig;
  final String coverXl;

  const DeezerAlbum({
    required this.id,
    required this.title,
    this.cover = '',
    this.coverMedium = '',
    this.coverBig = '',
    this.coverXl = '',
  });

  factory DeezerAlbum.fromJson(Map<String, dynamic> json) {
    return DeezerAlbum(
      id: (json['id'] as int?) ?? 0,
      title: (json['title'] as String?) ?? 'Unknown Album',
      cover: (json['cover'] as String?) ?? '',
      coverMedium: (json['cover_medium'] as String?) ?? '',
      coverBig: (json['cover_big'] as String?) ?? '',
      coverXl: (json['cover_xl'] as String?) ?? '',
    );
  }
}
