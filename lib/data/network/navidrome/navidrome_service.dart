import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:uuid/uuid.dart';

import '../api_client.dart';
import 'navidrome_models.dart';

class NavidromeApiService {
  final ApiClient _apiClient;
  NavidromeCredentials? _credentials;

  static const String _apiVersion = '1.16.1';
  static const String _defaultFormat = 'json';

  NavidromeApiService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  void setCredentials(NavidromeCredentials credentials) {
    _credentials = credentials;
  }

  void clearCredentials() {
    _credentials = null;
  }

  bool hasCredentials() => _credentials != null;

  String? getServerUrl() => _credentials?.normalizedServerUrl;

  Map<String, String> _generateAuthParams(String password) {
    final salt = const Uuid().v4().substring(0, 6);
    final bytes = utf8.encode(password + salt);
    final token = md5.convert(bytes).toString();
    return {'token': token, 'salt': salt};
  }

  String _buildApiUrl(String endpoint, [Map<String, String>? extraParams]) {
    if (_credentials == null) {
      throw Exception('No credentials configured');
    }

    final creds = _credentials!;
    final authParams = _generateAuthParams(creds.password);

    final baseUrl = '${creds.normalizedServerUrl}/rest/$endpoint.view';

    final queryParams = <String, String>{
      'u': creds.username,
      't': authParams['token']!,
      's': authParams['salt']!,
      'v': _apiVersion,
      'c': creds.clientId,
      'f': _defaultFormat,
    };

    if (extraParams != null) {
      queryParams.addAll(extraParams);
    }

    final uri = Uri.parse(baseUrl).replace(queryParameters: queryParams);
    return uri.toString();
  }

  String getCoverArtUrl(String coverArtId, {int size = 500}) {
    if (_credentials == null) return '';
    return _buildApiUrl('getCoverArt', {
      'id': coverArtId,
      'size': size.toString(),
    });
  }

  String getStreamUrl(String songId, {int maxBitRate = 0, String? format}) {
    if (_credentials == null) return '';
    final params = {'id': songId};
    if (maxBitRate > 0) params['maxBitRate'] = maxBitRate.toString();
    if (format != null) params['format'] = format;
    return _buildApiUrl('stream', params);
  }

  Future<dynamic> _request(
    String endpoint, [
    Map<String, String>? params,
  ]) async {
    final url = _buildApiUrl(endpoint, params);
    try {
      final response = await _apiClient.get(url);

      if (response.containsKey('subsonic-response')) {
        final subsonicResponse = response['subsonic-response'];
        if (subsonicResponse['status'] == 'ok') {
          return subsonicResponse;
        } else {
          final error = subsonicResponse['error'] ?? {};
          throw Exception('API Error: ${error['message']}');
        }
      }
      throw Exception('Invalid response format');
    } catch (e) {
      throw Exception('Navidrome API error: $e');
    }
  }

  Future<bool> ping() async {
    try {
      await _request('ping');
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<List<NavidromePlaylist>> getPlaylists() async {
    final response = await _request('getPlaylists');
    final playlistsContainer = response['playlists'];
    if (playlistsContainer != null && playlistsContainer['playlist'] != null) {
      final playlists = List.from(playlistsContainer['playlist']);
      return playlists.map((p) => NavidromePlaylist.fromJson(p)).toList();
    }
    return [];
  }

  Future<List<NavidromeSong>> getPlaylist(String id) async {
    final response = await _request('getPlaylist', {'id': id});
    final playlist = response['playlist'];
    if (playlist != null && playlist['entry'] != null) {
      final entries = List.from(playlist['entry']);
      return entries.map((e) => NavidromeSong.fromJson(e)).toList();
    }
    return [];
  }

  Future<List<NavidromeSong>> searchSongs(
    String query, {
    int count = 30,
  }) async {
    final response = await _request('search3', {
      'query': query,
      'artistCount': '0',
      'albumCount': '0',
      'songCount': count.toString(),
    });

    final searchResult = response['searchResult3'];
    if (searchResult != null && searchResult['song'] != null) {
      final songs = List.from(searchResult['song']);
      return songs.map((s) => NavidromeSong.fromJson(s)).toList();
    }
    return [];
  }

  Future<List<NavidromeSong>> getAlbumList({
    String type = 'newest',
    int size = 50,
  }) async {
    final response = await _request('getAlbumList2', {
      'type': type,
      'size': size.toString(),
    });
    // This returns albums, we could parse them similarly
    // For now we will return NavidromeSong from albums if needed or build an album list
    return [];
  }
}
