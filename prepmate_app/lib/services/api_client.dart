import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

class ApiException implements Exception {
  final String message;
  final int status;
  final String? code;
  final Map<String, dynamic>? fields;

  const ApiException(this.message, {this.status = 0, this.code, this.fields});

  @override
  String toString() => message;
}

/// Thin wrapper around the PrepMate REST API. Authentication uses a Bearer token.
class ApiClient {
  ApiClient(String baseUrl) : baseUrl = baseUrl.replaceAll(RegExp(r'/+$'), '');

  final String baseUrl;
  final http.Client _client = http.Client();

  String? token;

  /// Called when a data request comes back 401 (the session expired).
  void Function()? onUnauthorized;

  Future<Map<String, dynamic>> _request(
    String method,
    String path, {
    Map<String, dynamic>? body,
    Duration timeout = const Duration(seconds: 60),
    bool isAuthRoute = false,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    final headers = <String, String>{
      'Accept': 'application/json',
      if (body != null) 'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
    final encoded = body == null ? null : jsonEncode(body);

    http.Response response;
    try {
      switch (method) {
        case 'POST':
          response = await _client
              .post(uri, headers: headers, body: encoded)
              .timeout(timeout);
          break;
        case 'PUT':
          response = await _client
              .put(uri, headers: headers, body: encoded)
              .timeout(timeout);
          break;
        case 'DELETE':
          response = await _client
              .delete(uri, headers: headers)
              .timeout(timeout);
          break;
        default:
          response = await _client.get(uri, headers: headers).timeout(timeout);
      }
    } on TimeoutException {
      throw const ApiException(
        'The server took too long to respond. If it was idle it may be waking up, so try again in a moment.',
        code: 'TIMEOUT',
      );
    } catch (_) {
      throw const ApiException(
        'Cannot reach the server. Check your internet connection and try again.',
        code: 'NETWORK',
      );
    }

    Map<String, dynamic> data = {};
    try {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is Map<String, dynamic>) data = decoded;
    } catch (_) {}

    if (response.statusCode < 200 || response.statusCode >= 300) {
      if (response.statusCode == 401 && !isAuthRoute) onUnauthorized?.call();
      throw ApiException(
        (data['error'] ?? 'Request failed (${response.statusCode}).')
            .toString(),
        status: response.statusCode,
        code: data['code']?.toString(),
        fields: data['fields'] is Map<String, dynamic>
            ? data['fields'] as Map<String, dynamic>
            : null,
      );
    }
    return data;
  }

  // ---- auth ----
  Future<Map<String, dynamic>> me() =>
      _request('GET', '/api/auth/me', isAuthRoute: true);

  Future<Map<String, dynamic>> signup(
    String name,
    String email,
    String password,
  ) => _request(
    'POST',
    '/api/auth/signup',
    body: {'name': name, 'email': email, 'password': password},
    isAuthRoute: true,
  );

  Future<Map<String, dynamic>> login(String email, String password) => _request(
    'POST',
    '/api/auth/login',
    body: {'email': email, 'password': password},
    isAuthRoute: true,
  );

  Future<void> logout() async {
    try {
      await _request(
        'POST',
        '/api/auth/logout',
        isAuthRoute: true,
        timeout: const Duration(seconds: 8),
      );
    } catch (_) {
      // Signing out locally is enough; the token is simply discarded.
    }
  }

  // ---- data ----
  Future<Map<String, dynamic>> loadData() => _request('GET', '/api/data');

  Future<Map<String, dynamic>> createApplication(
    Map<String, dynamic> application,
  ) => _request('POST', '/api/applications', body: application);

  Future<Map<String, dynamic>> updateApplication(
    String id,
    Map<String, dynamic> application,
  ) => _request('PUT', '/api/applications/$id', body: application);

  Future<void> deleteApplication(String id) async {
    await _request('DELETE', '/api/applications/$id');
  }

  Future<void> saveProgress(Map<String, dynamic> progress) async {
    await _request('PUT', '/api/progress', body: progress);
  }

  // ---- Gemini (through the server, so the key never reaches the app) ----
  Future<Map<String, dynamic>> gemini(
    String mode,
    Map<String, dynamic> payload,
  ) async {
    final data = await _request(
      'POST',
      '/api/gemini',
      body: {'mode': mode, ...payload},
      timeout: const Duration(seconds: 45),
    );
    final result = data['result'];
    if (result is! Map<String, dynamic>) {
      throw const ApiException('Gemini returned an empty response.');
    }
    return result;
  }
}
