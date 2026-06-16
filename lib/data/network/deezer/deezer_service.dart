// lib/data/network/deezer/deezer_service.dart

import '../api_client.dart';
import 'deezer_models.dart';

/// Dart port of PixelPlayer's DeezerApiService.kt.
///
/// Uses Deezer's **public** REST API (no auth required):
///   https://api.deezer.com/
///
/// Provides: search, track details, album details, artist details,
/// chart/trending tracks, and genre-based browsing.
class DeezerService {
  static const _baseUrl = 'https://api.deezer.com';

  final ApiClient _client;

  DeezerService({ApiClient? client}) : _client = client ?? ApiClient();

  // ───────────────────── Search ─────────────────────

  /// Search tracks by query string.
  Future<List<DeezerTrack>> searchTracks(String query, {int limit = 25}) async {
    final encoded = Uri.encodeComponent(query);
    final data = await _client.get('$_baseUrl/search?q=$encoded&limit=$limit');
    final results = data['data'] as List<dynamic>? ?? [];
    return results
        .map((item) => DeezerTrack.fromJson(item as Map<String, dynamic>))
        .where((t) => t.preview.isNotEmpty)
        .toList();
  }

  // ───────────────────── Charts / Trending ─────────────────────

  /// Get current chart/trending tracks.
  Future<List<DeezerTrack>> getChartTracks({int limit = 25}) async {
    final data = await _client.get('$_baseUrl/chart/0/tracks?limit=$limit');
    final results = data['data'] as List<dynamic>? ?? [];
    return results
        .map((item) => DeezerTrack.fromJson(item as Map<String, dynamic>))
        .where((t) => t.preview.isNotEmpty)
        .toList();
  }

  // ───────────────────── Genre-based browsing ─────────────────────

  /// Get available genres.
  Future<List<Map<String, dynamic>>> getGenres() async {
    final data = await _client.get('$_baseUrl/genre');
    return (data['data'] as List<dynamic>? ?? [])
        .map((g) => g as Map<String, dynamic>)
        .toList();
  }

  /// Get top artists for a genre.
  Future<List<DeezerArtist>> getGenreArtists(int genreId) async {
    final data = await _client.get('$_baseUrl/genre/$genreId/artists');
    final results = data['data'] as List<dynamic>? ?? [];
    return results
        .map((item) => DeezerArtist.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  // ───────────────────── Track / Album / Artist details ─────────────────────

  /// Fetch a single track by its Deezer ID.
  Future<DeezerTrack> getTrack(int trackId) async {
    final data = await _client.get('$_baseUrl/track/$trackId');
    return DeezerTrack.fromJson(data);
  }

  /// Fetch album tracks.
  Future<List<DeezerTrack>> getAlbumTracks(int albumId) async {
    final data = await _client.get('$_baseUrl/album/$albumId/tracks');
    final results = data['data'] as List<dynamic>? ?? [];
    return results
        .map((item) => DeezerTrack.fromJson(item as Map<String, dynamic>))
        .where((t) => t.preview.isNotEmpty)
        .toList();
  }

  /// Fetch artist's top tracks.
  Future<List<DeezerTrack>> getArtistTopTracks(int artistId, {int limit = 25}) async {
    final data = await _client.get('$_baseUrl/artist/$artistId/top?limit=$limit');
    final results = data['data'] as List<dynamic>? ?? [];
    return results
        .map((item) => DeezerTrack.fromJson(item as Map<String, dynamic>))
        .where((t) => t.preview.isNotEmpty)
        .toList();
  }

  void dispose() => _client.dispose();
}
