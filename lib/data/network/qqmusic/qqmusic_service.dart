import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:archive/archive.dart';

class QqMusicApiService {
  final Map<String, String> _persistedCookies = {};

  bool hasLogin() => _persistedCookies.containsKey('uin') && _persistedCookies['uin']!.isNotEmpty;

  void setPersistedCookies(Map<String, String> cookies) {
    _persistedCookies.addAll(cookies);
  }

  void logout() {
    _persistedCookies.clear();
  }

  String _buildCookieHeader() {
    if (_persistedCookies.isEmpty) return '';
    return _persistedCookies.entries.map((e) => '${e.key}=${e.value}').join('; ');
  }

  int _getGtk() {
    final skey = _persistedCookies['p_skey'] ?? _persistedCookies['skey'] ?? '';
    int hash = 5381;
    for (int i = 0; i < skey.length; i++) {
      hash += (hash << 5) + skey.codeUnitAt(i);
    }
    return hash & 0x7fffffff;
  }

  String _extractUin() {
    final uinStr = _persistedCookies['uin'] ??
        _persistedCookies['p_uin'] ??
        _persistedCookies['luin'] ??
        _persistedCookies['wxuin'] ??
        '0';
    final cleaned = uinStr.replaceAll(RegExp(r'[^0-9]'), '');
    return cleaned.isEmpty ? '0' : cleaned;
  }

  String _extractKeyst() {
    return _persistedCookies['qm_keyst'] ?? '';
  }

  String _decompressIfNeeded(Uint8List data) {
    if (data.isEmpty) return '';
    try {
      final directStr = utf8.decode(data, allowMalformed: true).trim();
      if (directStr.startsWith('{') || directStr.startsWith('[')) {
        return directStr;
      }
    } catch (_) {}

    try {
      int offset = 0;
      for (int i = 0; i < (data.length < 10 ? data.length : 10); i++) {
        if (data[i] == 0x78 && i + 1 < data.length) {
          offset = i;
          break;
        }
      }
      final zlibData = offset > 0 ? data.sublist(offset) : data;
      final decompressed = ZLibDecoder().decodeBytes(zlibData);
      return utf8.decode(decompressed);
    } catch (e) {
      return utf8.decode(data, allowMalformed: true).trim();
    }
  }

  Future<dynamic> _makeGetRequest(String url) async {
    final headers = {
      'Referer': 'https://y.qq.com/',
      'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    };
    final cookieHeader = _buildCookieHeader();
    if (cookieHeader.isNotEmpty) headers['Cookie'] = cookieHeader;

    // TODO: Add QQMusicEncryptInterceptor logic here once available
    // Currently missing QQSignGenerator implementation

    final response = await http.get(Uri.parse(url), headers: headers);
    final responseStr = _decompressIfNeeded(response.bodyBytes);
    return jsonDecode(responseStr);
  }

  Future<dynamic> _makePostRequest(String url, Map<String, dynamic> payload) async {
    final headers = {
      'Accept': 'application/json',
      'Referer': 'https://y.qq.com/',
      'Origin': 'https://y.qq.com',
      'Content-Type': 'application/json; charset=utf-8',
      'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    };
    final cookieHeader = _buildCookieHeader();
    if (cookieHeader.isNotEmpty) headers['Cookie'] = cookieHeader;

    // TODO: Add QQMusicEncryptInterceptor logic here once available

    final response = await http.post(Uri.parse(url), headers: headers, body: jsonEncode(payload));
    final responseStr = _decompressIfNeeded(response.bodyBytes);
    return jsonDecode(responseStr);
  }

  Future<dynamic> getUserPlaylists({int start = 0, int count = 100}) async {
    final uin = _extractUin();
    final gtk = _getGtk();
    final ein = (start + count - 1) < start ? start : (start + count - 1);
    final url = "https://c.y.qq.com/fav/fcgi-bin/fcg_get_profile_order_asset.fcg?" +
        "format=json&inCharset=utf-8&outCharset=utf-8&notice=0" +
        "&platform=yqq&needNewCode=1" +
        "&uin=$uin&g_tk=$gtk&cid=205360956&userid=$uin&reqtype=3&sin=$start&ein=$ein";

    return await _makeGetRequest(url);
  }

  Future<String> getSongDownloadUrl(String songMid, {int songtype = 0, String? filename}) async {
    final uin = _extractUin();
    final keyst = _extractKeyst();
    final param = {
      "guid": "327783793guid",
      "songmid": [songMid],
      "songtype": [songtype],
      "uin": uin,
      "loginflag": 1,
      "platform": "20",
      "xcdn": 1
    };
    if (filename != null) param["filename"] = [filename];

    final payload = {
      "req_0": {
        "module": "music.vkey.GetEVkey",
        "method": "GetUrl",
        "param": param
      },
      "comm": {
        "uin": uin,
        "format": "json",
        "ct": 19,
        "cv": 1602,
        "authst": keyst
      }
    };

    final response = await _makePostRequest("https://u6.y.qq.com/cgi-bin/musics.fcg", payload);
    return response.toString(); // Parse exact URL based on response structure
  }
}
