// lib/data/network/lyrics/lrclib_service.dart

import 'dart:convert';
import '../api_client.dart';
import 'lrclib_models.dart';

/// Dart port of PixelPlayer's LrcLibApiService.kt.
///
/// LrcLib is a free, open-source lyrics API:
///   https://lrclib.net/
///
/// No authentication required.
class LrcLibService {
  static const _baseUrl = 'https://lrclib.net/api';

  final ApiClient _client;

  LrcLibService({ApiClient? client}) : _client = client ?? ApiClient();

  /// Search for lyrics by track name and artist name.
  /// Returns the best match or null if nothing found.
  Future<LrcLibResponse?> getLyrics({
    required String trackName,
    required String artistName,
    String? albumName,
    int? durationSeconds,
  }) async {
    try {
      // Try the exact "get" endpoint first (fastest, most accurate)
      final params = <String, String>{
        'track_name': trackName,
        'artist_name': artistName,
      };
      if (albumName != null && albumName.isNotEmpty) {
        params['album_name'] = albumName;
      }
      if (durationSeconds != null) {
        params['duration'] = durationSeconds.toString();
      }

      final uri = Uri.parse('$_baseUrl/get').replace(queryParameters: params);
      final body = await _client.getRaw(uri.toString());
      final json = jsonDecode(body) as Map<String, dynamic>;
      return LrcLibResponse.fromJson(json);
    } catch (_) {
      // Fall back to search endpoint
      return _searchFallback(trackName, artistName);
    }
  }

  /// Fallback: search endpoint returns multiple results, pick the best one.
  Future<LrcLibResponse?> _searchFallback(
    String trackName,
    String artistName,
  ) async {
    try {
      final query = Uri.encodeComponent('$trackName $artistName');
      final body = await _client.getRaw('$_baseUrl/search?q=$query');
      final results = jsonDecode(body) as List<dynamic>;

      if (results.isEmpty) return null;

      // Pick the first result that has synced lyrics, or just the first result
      final items = results
          .map((r) => LrcLibResponse.fromJson(r as Map<String, dynamic>))
          .toList();

      return items.firstWhere(
        (item) => item.syncedLyrics?.isNotEmpty == true,
        orElse: () => items.first,
      );
    } catch (_) {
      return null;
    }
  }

  void dispose() => _client.dispose();
}
