// lib/data/network/lyrics/lrclib_models.dart

// Response model for the LrcLib open-source lyrics API.
// Mirrors PixelPlayer's LrcLibResponse.kt.

class LrcLibResponse {
  final int id;
  final String trackName;
  final String artistName;
  final String albumName;
  final double? duration;
  final bool instrumental;
  final String? plainLyrics;   // unsynchronised text
  final String? syncedLyrics;  // LRC-formatted synchronised lyrics

  const LrcLibResponse({
    required this.id,
    required this.trackName,
    required this.artistName,
    required this.albumName,
    this.duration,
    this.instrumental = false,
    this.plainLyrics,
    this.syncedLyrics,
  });

  factory LrcLibResponse.fromJson(Map<String, dynamic> json) {
    return LrcLibResponse(
      id: (json['id'] as int?) ?? 0,
      trackName: (json['trackName'] as String?) ?? '',
      artistName: (json['artistName'] as String?) ?? '',
      albumName: (json['albumName'] as String?) ?? '',
      duration: (json['duration'] as num?)?.toDouble(),
      instrumental: (json['instrumental'] as bool?) ?? false,
      plainLyrics: json['plainLyrics'] as String?,
      syncedLyrics: json['syncedLyrics'] as String?,
    );
  }

  /// True if we have any lyrics at all.
  bool get hasLyrics => (plainLyrics?.isNotEmpty ?? false) || (syncedLyrics?.isNotEmpty ?? false);

  /// Prefer synced lyrics, fall back to plain.
  String get bestLyrics => syncedLyrics ?? plainLyrics ?? '';
}
