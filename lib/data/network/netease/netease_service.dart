import 'dart:convert';
import 'package:http/http.dart' as http;
import 'netease_encryption.dart';
import '../../models/track_model.dart';
import '../../models/playlist_model.dart';

class NeteaseApiService {
  final Map<String, String> _persistedCookies = {};

  bool hasLogin() => _persistedCookies.containsKey('MUSIC_U') && _persistedCookies['MUSIC_U']!.isNotEmpty;

  void setPersistedCookies(Map<String, String> cookies) {
    _persistedCookies.addAll(cookies);
    _persistedCookies.putIfAbsent('os', () => 'pc');
    _persistedCookies.putIfAbsent('appver', () => '8.10.35');
  }

  void logout() {
    _persistedCookies.clear();
  }

  String _buildCookieHeader() {
    final map = Map<String, String>.from(_persistedCookies);
    map.putIfAbsent('os', () => 'pc');
    map.putIfAbsent('appver', () => '8.10.35');
    if (map.isEmpty) return '';
    return map.entries.map((e) => '${e.key}=${e.value}').join('; ');
  }

  Future<dynamic> request(
    String url,
    Map<String, dynamic> params, {
    CryptoMode mode = CryptoMode.weapi,
    String method = 'POST',
    bool usePersistedCookies = true,
  }) async {
    final requestUrl = Uri.parse(url);
    Map<String, String> bodyParams;

    switch (mode) {
      case CryptoMode.weapi:
        bodyParams = NeteaseEncryption.weApiEncrypt(params);
        break;
      case CryptoMode.eapi:
        bodyParams = NeteaseEncryption.eApiEncrypt(requestUrl.path, params);
        break;
      case CryptoMode.linux:
        bodyParams = NeteaseEncryption.linuxApiEncrypt(params);
        break;
      case CryptoMode.api:
        bodyParams = params.map((key, value) => MapEntry(key, value.toString()));
        break;
    }

    var reqUrl = requestUrl;
    if (mode == CryptoMode.weapi) {
      final csrf = _persistedCookies['__csrf'] ?? '';
      reqUrl = reqUrl.replace(queryParameters: {'csrf_token': csrf});
    }

    final headers = {
      'Accept': '*/*',
      'Accept-Language': 'zh-CN,zh-Hans;q=0.9',
      'Connection': 'keep-alive',
      'Referer': 'https://music.163.com',
      'Host': requestUrl.host,
      'User-Agent': 'Mozilla/5.0 (Linux; Android 14; PixelPlayer) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Mobile Safari/537.36',
    };

    if (usePersistedCookies) {
      final cookieHeader = _buildCookieHeader();
      if (cookieHeader.isNotEmpty) {
        headers['Cookie'] = cookieHeader;
      }
    }

    http.Response response;
    try {
      if (method.toUpperCase() == 'POST') {
        response = await http.post(reqUrl, headers: headers, body: bodyParams);
      } else {
        final getUrl = reqUrl.replace(queryParameters: {
          ...reqUrl.queryParameters,
          ...bodyParams,
        });
        response = await http.get(getUrl, headers: headers);
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(response.body);
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.reasonPhrase}');
      }
    } catch (e) {
      throw Exception('Netease API error: $e');
    }
  }

  Future<dynamic> callWeApi(String path, Map<String, dynamic> params, {bool usePersistedCookies = true}) {
    final p = path.startsWith('/') ? path : '/$path';
    return request('https://music.163.com/weapi$p', params, mode: CryptoMode.weapi, method: 'POST', usePersistedCookies: usePersistedCookies);
  }

  Future<dynamic> callEApi(String path, Map<String, dynamic> params, {bool usePersistedCookies = true}) {
    final p = path.startsWith('/') ? path : '/$path';
    return request('https://interface.music.163.com/eapi$p', params, mode: CryptoMode.eapi, method: 'POST', usePersistedCookies: usePersistedCookies);
  }

  Future<List<TrackModel>> searchSongs(String keyword, {int limit = 30, int offset = 0}) async {
    final params = {
      's': keyword,
      'type': '1',
      'limit': limit,
      'offset': offset,
      'total': 'true'
    };
    
    final response = await request('https://music.163.com/weapi/cloudsearch/get/web', params, mode: CryptoMode.weapi);
    if (response['code'] == 200 && response['result'] != null && response['result']['songs'] != null) {
      final songs = List.from(response['result']['songs']);
      return songs.map((s) {
        final al = s['al'] ?? {};
        final ar = s['ar'] != null ? List.from(s['ar']) : [];
        final artistNames = ar.map((a) => a['name']).join(', ');
        
        return TrackModel(
          id: s['id'].toString(),
          title: s['name'] ?? 'Unknown',
          artist: artistNames,
          album: al['name'] ?? 'Unknown Album',
          albumArt: al['picUrl'] ?? '',
          audioUrl: '', // Needs separate call to get download URL
          duration: Duration(milliseconds: s['dt'] ?? 0),
          source: 'netease',
        );
      }).toList();
    }
    return [];
  }

  Future<String> getSongDownloadUrl(String songId, {String level = 'exhigh'}) async {
    final encodeType = (level == 'lossless' || level == 'jyeffect') ? 'flac' : 'mp3';
    final params = {
      'ids': '[$songId]',
      'level': level,
      'encodeType': encodeType
    };
    
    final response = await callEApi('/song/enhance/player/url/v1', params);
    if (response['code'] == 200 && response['data'] != null && response['data'].isNotEmpty) {
      return response['data'][0]['url'] ?? '';
    }
    return '';
  }

  Future<List<PlaylistModel>> getUserPlaylists(String userId, {int offset = 0, int limit = 50}) async {
    final params = {
      'uid': userId,
      'offset': offset,
      'limit': limit,
      'includeVideo': 'true'
    };
    
    final response = await request('https://music.163.com/weapi/user/playlist', params, mode: CryptoMode.weapi);
    if (response['code'] == 200 && response['playlist'] != null) {
      final playlists = List.from(response['playlist']);
      return playlists.map((p) {
        return PlaylistModel(
          id: p['id'].toString(),
          title: p['name'] ?? 'Unknown Playlist',
          coverUrl: p['coverImgUrl'] ?? '',
          songCount: p['trackCount'] ?? 0,
          source: 'netease',
        );
      }).toList();
    }
    return [];
  }
}
