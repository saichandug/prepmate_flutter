import 'package:flutter/foundation.dart';

import '../models/application.dart';
import '../services/api_client.dart';
import '../services/token_store.dart';

enum AuthStatus { checking, signedOut, signedIn }

class AuthController extends ChangeNotifier {
  AuthController(this._api, this._store) {
    _api.onUnauthorized = _handleUnauthorized;
  }

  final ApiClient _api;
  final TokenStore _store;

  AuthStatus status = AuthStatus.checking;
  AppUser? user;

  /// Restores a previous session, if there is one.
  Future<void> init() async {
    final saved = await _store.read();
    if (saved == null || saved.isEmpty) {
      status = AuthStatus.signedOut;
      notifyListeners();
      return;
    }
    _api.token = saved;
    try {
      final data = await _api.me();
      user = AppUser.fromJson(Map<String, dynamic>.from(data['user'] as Map));
      status = AuthStatus.signedIn;
    } on ApiException catch (e) {
      // Only drop the token when the server says it is invalid, not when offline.
      if (e.status == 401) {
        await _clearSession();
      } else {
        status = AuthStatus.signedOut;
      }
    }
    notifyListeners();
  }

  /// Throws [ApiException]; its `code` is ACCOUNT_NOT_FOUND, INVALID_CREDENTIALS, etc.
  Future<void> login(String email, String password) async {
    final data = await _api.login(email, password);
    await _finishAuth(data);
  }

  Future<void> signup(String name, String email, String password) async {
    final data = await _api.signup(name, email, password);
    await _finishAuth(data);
  }

  Future<void> _finishAuth(Map<String, dynamic> data) async {
    final token = data['token']?.toString();
    if (token == null || token.isEmpty) {
      throw const ApiException(
        'The server did not return a session. Update the backend and try again.',
      );
    }
    _api.token = token;
    await _store.write(token);
    user = AppUser.fromJson(Map<String, dynamic>.from(data['user'] as Map));
    status = AuthStatus.signedIn;
    notifyListeners();
  }

  Future<void> logout() async {
    await _api.logout();
    await _clearSession();
    notifyListeners();
  }

  void _handleUnauthorized() {
    if (status != AuthStatus.signedIn) return;
    _clearSession().then((_) => notifyListeners());
  }

  Future<void> _clearSession() async {
    _api.token = null;
    user = null;
    status = AuthStatus.signedOut;
    await _store.clear();
  }
}
