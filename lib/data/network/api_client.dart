// lib/data/network/api_client.dart

import 'dart:convert';
import 'package:http/http.dart' as http;

/// Shared HTTP client wrapper — centralises error handling, timeouts,
/// and headers so every API service behaves consistently.
class ApiClient {
  final http.Client _client;

  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  /// Generic GET with optional custom headers.
  Future<Map<String, dynamic>> get(
    String url, {
    Map<String, String>? headers,
    Duration timeout = const Duration(seconds: 15),
  }) async {
    final response = await _client
        .get(Uri.parse(url), headers: headers)
        .timeout(timeout);

    if (response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    }
    throw ApiException(response.statusCode, 'GET $url failed: ${response.reasonPhrase}');
  }

  /// Generic GET that returns a raw string body (useful for lyrics).
  Future<String> getRaw(
    String url, {
    Map<String, String>? headers,
    Duration timeout = const Duration(seconds: 15),
  }) async {
    final response = await _client
        .get(Uri.parse(url), headers: headers)
        .timeout(timeout);

    if (response.statusCode == 200) {
      return response.body;
    }
    throw ApiException(response.statusCode, 'GET $url failed: ${response.reasonPhrase}');
  }

  /// Generic POST with optional custom headers and body.
  Future<Map<String, dynamic>> post(
    String url, {
    Map<String, String>? headers,
    Object? body,
    Duration timeout = const Duration(seconds: 15),
  }) async {
    final response = await _client
        .post(Uri.parse(url), headers: headers, body: body)
        .timeout(timeout);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isNotEmpty) {
        return json.decode(response.body) as Map<String, dynamic>;
      }
      return <String, dynamic>{};
    }
    throw ApiException(response.statusCode, 'POST $url failed: ${response.reasonPhrase}');
  }

  void dispose() => _client.close();
}

class ApiException implements Exception {
  final int statusCode;
  final String message;
  ApiException(this.statusCode, this.message);

  @override
  String toString() => 'ApiException($statusCode): $message';
}
