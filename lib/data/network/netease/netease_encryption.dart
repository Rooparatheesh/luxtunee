import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart';
import 'package:pointycastle/export.dart' as pc;

enum CryptoMode { weapi, eapi, linux, api }

class NeteaseEncryption {
  static const String _base62 =
      "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
  static const String _presetKey = "0CoJUm6Qyw8W8jud";
  static const String _iv = "0102030405060708";
  static const String _linuxKey = "rFgB&h#%2?^eDg:Q";
  static const String _eapiKey = "e82ckenh8dichen8";
  static const String _eapiFormat = "%s-36cd479b6b5-%s-36cd479b6b5-%s";
  static const String _eapiSalt = "nobody%suse%smd5forencrypt";
  static const String _publicKeyPem = """
-----BEGIN PUBLIC KEY-----
MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQDgtQn2JZ34ZC28NWYpAUd98iZ37BUrX/aKzmFb
t7clFSs6sXqHauqKWqdtLkF2KexO40H1YTX8z2lSgBBOAxLsvaklV8k4cBFK9snQXE9/DDaFt6Rr7iVZ
MldczhC0JNgTz+SHXT6CBHuX3e9SdB1Ua44oncaTWz7OBGLbCiK45wIDAQAB
-----END PUBLIC KEY-----""";

  static final Random _random = Random.secure();

  static String _randomKey() {
    final sb = StringBuffer();
    for (int i = 0; i < 16; i++) {
      sb.write(_base62[_random.nextInt(_base62.length)]);
    }
    return sb.toString();
  }

  static String _aesEncrypt(
    String text,
    String keyStr,
    String ivStr,
    String mode,
    String format,
  ) {
    final key = Key.fromUtf8(keyStr);
    final iv = IV.fromUtf8(ivStr);

    Encrypter encrypter;
    if (mode.toLowerCase() == 'cbc') {
      encrypter = Encrypter(AES(key, mode: AESMode.cbc, padding: 'PKCS7'));
    } else if (mode.toLowerCase() == 'ecb') {
      encrypter = Encrypter(AES(key, mode: AESMode.ecb, padding: 'PKCS7'));
    } else {
      throw Exception('Unknown AES mode: $mode');
    }

    final encrypted = encrypter.encrypt(text, iv: iv);

    if (format.toLowerCase() == 'base64') {
      return encrypted.base64;
    } else if (format.toLowerCase() == 'hex') {
      return encrypted.bytes
          .map((b) => b.toRadixString(16).padLeft(2, '0'))
          .join('');
    } else {
      throw Exception('Unknown format: $format');
    }
  }

  static String _rsaEncrypt(String text) {
    final parser = RSAKeyParser();
    final publicKey = parser.parse(_publicKeyPem) as pc.RSAPublicKey;

    final cipher = pc.RSAEngine()
      ..init(true, pc.PublicKeyParameter<pc.RSAPublicKey>(publicKey));

    final input = utf8.encode(text);
    final result = cipher.process(Uint8List.fromList(input));

    return result.map((b) => b.toRadixString(16).padLeft(2, '0')).join('');
  }

  static String md5Hex(String data) {
    final bytes = utf8.encode(data);
    final digest = md5.convert(bytes);
    return digest.toString();
  }

  static Map<String, String> weApiEncrypt(Map<String, dynamic> payload) {
    final jsonStr = jsonEncode(payload);
    final secretKey = _randomKey();

    final enc1 = _aesEncrypt(jsonStr, _presetKey, _iv, 'cbc', 'base64');
    final params = _aesEncrypt(enc1, secretKey, _iv, 'cbc', 'base64');

    final reversedKey = secretKey.split('').reversed.join('');
    final encSecKey = _rsaEncrypt(reversedKey);

    return {'params': params, 'encSecKey': encSecKey};
  }

  static Map<String, String> eApiEncrypt(
    String url,
    Map<String, dynamic> payload,
  ) {
    final data = jsonEncode(payload);
    final apiUrl = url.replaceAll('/eapi', '/api');

    final saltStr = _eapiSalt
        .replaceFirst('%s', apiUrl)
        .replaceFirst('%s', data);
    final md5Hash = md5Hex(saltStr);

    final message = _eapiFormat
        .replaceFirst('%s', apiUrl)
        .replaceFirst('%s', data)
        .replaceFirst('%s', md5Hash);

    final cipher = _aesEncrypt(
      message,
      _eapiKey,
      '',
      'ecb',
      'hex',
    ).toUpperCase();
    return {'params': cipher};
  }

  static Map<String, String> linuxApiEncrypt(Map<String, dynamic> payload) {
    final jsonStr = jsonEncode(payload);
    final eparams = _aesEncrypt(jsonStr, _linuxKey, '', 'ecb', 'hex');
    return {'eparams': eparams};
  }
}
