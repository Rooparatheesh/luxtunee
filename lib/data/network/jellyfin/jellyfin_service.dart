import 'dart:convert';
import '../api_client.dart';
import 'jellyfin_models.dart';

class JellyfinApiService {
  final ApiClient _apiClient;
  JellyfinCredentials? _credentials;

  static const String _clientName = "PixelPlayer";
  static const String _clientVersion = "1.0";
  static const String _deviceName = "Flutter";
  static const String _deviceId = "PixelPlayer-Flutter";

  JellyfinApiService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  void setCredentials(JellyfinCredentials credentials) {
    _credentials = credentials;
  }

  void clearCredentials() {
    _credentials = null;
  }

  bool hasCredentials() => _credentials?.hasToken ?? false;

  String? getServerUrl() => _credentials?.normalizedServerUrl;

  String _buildAuthorizationHeader() {
    final cred = _credentials;
    final tokenPart = (cred?.accessToken != null && cred!.accessToken!.isNotEmpty) 
        ? ', Token="${cred.accessToken}"' 
        : '';
    return 'MediaBrowser Client="$_clientName", Device="$_deviceName", DeviceId="$_deviceId", Version="$_clientVersion"$tokenPart';
  }

  Future<bool> authenticateByName(String serverUrl, String username, String password) async {
    try {
      final url = '${serverUrl.replaceAll(RegExp(r'/$'), '')}/Users/AuthenticateByName';
      final body = jsonEncode({
        'Username': username,
        'Pw': password,
      });

      final authHeader = 'MediaBrowser Client="$_clientName", Device="$_deviceName", DeviceId="$_deviceId", Version="$_clientVersion"';

      final response = await _apiClient.post(
        url,
        headers: {
          'Authorization': authHeader,
          'Content-Type': 'application/json',
        },
        body: body,
      );

      final accessToken = response['AccessToken']?.toString() ?? '';
      final userId = response['User']?['Id']?.toString() ?? '';

      if (accessToken.isNotEmpty && userId.isNotEmpty) {
        if (_credentials != null) {
          _credentials!.accessToken = accessToken;
          _credentials!.userId = userId;
        } else {
          _credentials = JellyfinCredentials(
            serverUrl: serverUrl,
            username: username,
            password: password,
            accessToken: accessToken,
            userId: userId,
          );
        }
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<dynamic> _request(String path, [Map<String, String>? params]) async {
    if (_credentials == null || !_credentials!.hasToken) {
      throw Exception('No credentials configured or missing token');
    }

    final cred = _credentials!;
    final baseUrl = '${cred.normalizedServerUrl}$path';

    var uri = Uri.parse(baseUrl);
    if (params != null && params.isNotEmpty) {
      uri = uri.replace(queryParameters: params);
    }

    try {
      return await _apiClient.get(
        uri.toString(),
        headers: {
          'Authorization': _buildAuthorizationHeader(),
          'Accept': 'application/json',
        },
      );
    } catch (e) {
      throw Exception('Jellyfin API error: $e');
    }
  }

  Future<bool> ping() async {
    try {
      await _request('/System/Ping');
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<List<JellyfinSong>> getMusicItems({int startIndex = 0, int limit = 500, String? parentId}) async {
    if (_credentials == null) return [];
    
    final params = {
      'IncludeItemTypes': 'Audio',
      'Recursive': 'true',
      'Fields': 'MediaSources,Genres,Studios,Path',
      'StartIndex': startIndex.toString(),
      'Limit': limit.toString(),
      'SortBy': 'SortName',
      'SortOrder': 'Ascending',
    };
    if (parentId != null) {
      params['ParentId'] = parentId;
    }

    final response = await _request('/Users/${_credentials!.userId}/Items', params);
    if (response['Items'] != null) {
      return List.from(response['Items']).map((e) => JellyfinSong.fromJson(e)).toList();
    }
    return [];
  }

  Future<List<JellyfinPlaylist>> getPlaylists() async {
    if (_credentials == null) return [];

    final params = {
      'IncludeItemTypes': 'Playlist',
      'Recursive': 'true',
      'Fields': 'ChildCount',
      'MediaTypes': 'Audio',
    };

    final response = await _request('/Users/${_credentials!.userId}/Items', params);
    if (response['Items'] != null) {
      return List.from(response['Items']).map((e) => JellyfinPlaylist.fromJson(e)).toList();
    }
    return [];
  }

  Future<List<JellyfinSong>> getPlaylistItems(String playlistId) async {
    if (_credentials == null) return [];

    final params = {
      'Fields': 'MediaSources,Genres,Path',
      'UserId': _credentials!.userId!,
    };

    final response = await _request('/Playlists/$playlistId/Items', params);
    if (response['Items'] != null) {
      return List.from(response['Items']).map((e) => JellyfinSong.fromJson(e)).toList();
    }
    return [];
  }

  Future<List<JellyfinSong>> searchSongs(String query, {int limit = 30}) async {
    if (_credentials == null) return [];

    final params = {
      'SearchTerm': query,
      'IncludeItemTypes': 'Audio',
      'Recursive': 'true',
      'Fields': 'MediaSources,Genres,Path',
      'Limit': limit.toString(),
    };

    final response = await _request('/Users/${_credentials!.userId}/Items', params);
    if (response['Items'] != null) {
      return List.from(response['Items']).map((e) => JellyfinSong.fromJson(e)).toList();
    }
    return [];
  }

  String getStreamUrl(String itemId, {int maxBitRate = 0}) {
    if (_credentials == null || !_credentials!.hasToken) return '';
    final cred = _credentials!;

    final urlBuilder = Uri.parse('${cred.normalizedServerUrl}/Audio/$itemId/universal');
    final queryParams = {
      'UserId': cred.userId!,
      'DeviceId': _deviceId,
      'Container': 'mp3,flac,m4a,ogg,wav,aac,opus,webm',
      'AudioCodec': 'mp3,flac,aac,opus',
      'api_key': cred.accessToken!,
    };

    if (maxBitRate > 0) {
      queryParams['MaxStreamingBitrate'] = (maxBitRate * 1000).toString();
    }

    return urlBuilder.replace(queryParameters: queryParams).toString();
  }

  String getImageUrl(String itemId, {String imageType = 'Primary', int maxWidth = 500}) {
    if (_credentials == null) return '';
    return '${_credentials!.normalizedServerUrl}/Items/$itemId/Images/$imageType?maxWidth=$maxWidth&quality=90';
  }
}
