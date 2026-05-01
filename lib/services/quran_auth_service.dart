import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:quran_recitation/secret.dart';
import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class QuranAuthService {
  final FlutterAppAuth _appAuth = const FlutterAppAuth();
  
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  bool _storageReady = false;

  // Pulling from the git-ignored secrets.dart file
  static const String _clientId = Secrets.clientId;
  static const String _clientSecret = Secrets.clientSecret;
  static const String _redirectUrl = 'quran2u://oauth2redirect'; // Must match build.gradle!
  
  // Production Endpoints
  static const String _authEndpoint = 'https://oauth2.quran.foundation/oauth2/auth';
  static const String _tokenEndpoint = 'https://oauth2.quran.foundation/oauth2/token';
  static const String _apiBaseUrl = 'https://apis.quran.foundation';

  static const List<String> _scopes = [
    'openid',
    'offline_access',
    'user',
    'collection',
    'bookmark',
    'profile',
  ];

  /// Ensure secure storage is functional; wipe if cipher is corrupted.
  Future<void> _ensureStorage() async {
    if (_storageReady) return;
    try {
      await _storage.read(key: 'x-auth-token');
      _storageReady = true;
    } catch (e) {
      debugPrint('[QuranAuth] Secure storage corrupted, resetting: $e');
      try { await _storage.deleteAll(); } catch (_) {}
      _storageReady = true;
    }
  }


  Future<bool> login() async {
    try {
      await _ensureStorage();

      debugPrint('[QuranAuth] Starting authorizeAndExchangeCode...');

      final result =
          await _appAuth.authorizeAndExchangeCode(
        AuthorizationTokenRequest(
          _clientId,
          _redirectUrl,
          clientSecret: _clientSecret,
          scopes: _scopes,
          promptValues: ['login'], // Force showing the login screen to choose an account
          serviceConfiguration: const AuthorizationServiceConfiguration(
            authorizationEndpoint: _authEndpoint,
            tokenEndpoint: _tokenEndpoint,
          ),
        ),
      );

      debugPrint('[QuranAuth] Result: ${result.accessToken != null ? "SUCCESS" : "null"}');

      if (result.accessToken != null) {
        await _storage.write(key: 'x-auth-token', value: result.accessToken!);
        if (result.refreshToken != null) {
          await _storage.write(key: 'x-refresh-token', value: result.refreshToken!);
        }
        if (result.idToken != null) {
          await _storage.write(key: 'id-token', value: result.idToken!);
        }
        await _storage.delete(key: 'is_guest');
        debugPrint('[QuranAuth] Login successful!');
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('[QuranAuth] ERROR: ${e.toString()}');
      throw Exception('OAuth Error: ${e.toString()}');
    }
  }

  Future<void> continueAsGuest() async {
    await _ensureStorage();
    await _storage.write(key: 'is_guest', value: 'true');
  }

  Future<bool> get isLoggedIn async {
    await _ensureStorage();
    final token = await _storage.read(key: 'x-auth-token');
    return token != null && token.isNotEmpty;
  }

  Future<bool> get isGuest async {
    await _ensureStorage();
    final guest = await _storage.read(key: 'is_guest');
    return guest == 'true';
  }

  Future<void> logout() async {
    await _ensureStorage();
    await _storage.delete(key: 'x-auth-token');
    await _storage.delete(key: 'x-refresh-token');
    await _storage.delete(key: 'id-token');
  }

  Future<bool> refreshToken() async {
    try {
      final refreshToken = await _storage.read(key: 'x-refresh-token');
      if (refreshToken == null) return false;

      final result = await _appAuth.token(TokenRequest(
        _clientId,
        _redirectUrl,
        clientSecret: _clientSecret,
        refreshToken: refreshToken,
        scopes: _scopes,
        serviceConfiguration: const AuthorizationServiceConfiguration(
          authorizationEndpoint: _authEndpoint,
          tokenEndpoint: _tokenEndpoint,
        ),
      ));

      if (result.accessToken != null) {
        await _storage.write(key: 'x-auth-token', value: result.accessToken!);
        if (result.refreshToken != null) {
          await _storage.write(key: 'x-refresh-token', value: result.refreshToken!);
        }
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('[QuranAuth] Failed to refresh token: $e');
      return false;
    }
  }

  // --- Cloud Sync Helpers ---

  Future<Map<String, String>> _getHeaders() async {
    final token = await _storage.read(key: 'x-auth-token');
    return {
      'x-auth-token': token ?? '',
      'x-client-id': _clientId,
      'Content-Type': 'application/json',
    };
  }

  Future<bool> syncBookmark({required int surahId, required int ayahNumber}) async {
    var headers = await _getHeaders();
    var response = await http.post(
      Uri.parse('$_apiBaseUrl/auth/v1/bookmarks'),
      headers: headers,
      body: jsonEncode({
        'key': surahId,
        'verseNumber': ayahNumber,
        'type': 'ayah',
        'mushafId': 1,
      }),
    );

    if (response.statusCode == 401) {
      final refreshed = await refreshToken();
      if (refreshed) {
        headers = await _getHeaders();
        response = await http.post(
          Uri.parse('$_apiBaseUrl/auth/v1/bookmarks'),
          headers: headers,
          body: jsonEncode({
            'key': surahId,
            'verseNumber': ayahNumber,
            'type': 'ayah',
            'mushafId': 1,
          }),
        );
      }
    }
    return response.statusCode == 200 || response.statusCode == 201;
  }

  Future<List<dynamic>> getBookmarks() async {
    var headers = await _getHeaders();
    var response = await http.get(
      Uri.parse('$_apiBaseUrl/auth/v1/bookmarks?mushafId=1&first=20'),
      headers: headers,
    );

    if (response.statusCode == 401) {
      final refreshed = await refreshToken();
      if (refreshed) {
        headers = await _getHeaders();
        response = await http.get(
          Uri.parse('$_apiBaseUrl/auth/v1/bookmarks?mushafId=1&first=20'),
          headers: headers,
        );
      }
    }

    debugPrint('================ CLOUD BOOKMARKS JSON ================');
    debugPrint('Status: ${response.statusCode}');
    debugPrint(response.body);
    debugPrint('======================================================');
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['data'] ?? [];
    }
    return [];
  }

  Future<List<dynamic>> getCollections() async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$_apiBaseUrl/auth/v1/collections'),
      headers: headers,
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['collections'] ?? [];
    }
    return [];
  }

  Future<Map<String, dynamic>?> getStreak() async {
    return null; // Add logic if you implement streaks later
  }

  Future<Map<String, dynamic>?> getUserProfile() async {
    final idToken = await _storage.read(key: 'id-token');
    if (idToken == null) return null;
    
    // Decode JWT payload (base64url-encoded middle segment)
    try {
      final parts = idToken.split('.');
      if (parts.length != 3) return null;
      
      String payload = parts[1];
      // Pad base64url to valid base64
      switch (payload.length % 4) {
        case 2: payload += '=='; break;
        case 3: payload += '='; break;
      }
      final decoded = utf8.decode(base64Url.decode(payload));
      return jsonDecode(decoded) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }
}