import 'dart:convert';
import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

// ── Quran Foundation OAuth2 config ─────────────────────────────────────────
// Environment: PRE-LIVE (switch to production values after QF approves)
//
// Pre-live:  authBase = https://prelive-oauth2.quran.foundation
//            apiBase  = https://apis-prelive.quran.foundation
// Production: authBase = https://oauth2.quran.foundation
//             apiBase  = https://apis.quran.foundation
//
// IMPORTANT: This is a confidential client (has client_secret).
// For production, keep client_secret on a backend server and do the
// token exchange there. For the hackathon prelive review this direct
// approach is acceptable since QF is aware it is a mobile app.
// ──────────────────────────────────────────────────────────────────────────
class QuranAuthService {
  // ── Credentials (filled in after QF provisions the client) ─────────────
  static const _clientId     = '32263b86-47da-435c-8271-9b49a7c301ea';
  static const _clientSecret = 'XmIF~wUce7W.BLa1poVHl2GuA~'; // confidential
  static const _redirectUri  = 'quran2u://oauth2redirect';

  // ── Endpoints ───────────────────────────────────────────────────────────
  static const _authEndpoint  = 'https://prelive-oauth2.quran.foundation/oauth2/auth';
  static const _tokenEndpoint = 'https://prelive-oauth2.quran.foundation/oauth2/token';
  static const _apiBase       = 'https://apis-prelive.quran.foundation';

  // ── Scopes (from https://api-docs.quran.foundation/docs/user_related_apis_versioned/scopes)
  // FIX: 'bookmarks'/'collections' do NOT exist as scopes.
  // Correct names: bookmark, collection, user, streak, reading_session, etc.
  static const _scopes = [
    'openid',
    'offline_access',
    'user',       // profile info
    'bookmark',   // bookmarked verses   ← was wrong: 'bookmarks'
    'collection', // saved collections   ← was wrong: 'collections'
    'streak',     // reading streaks
  ];

  // ── Storage keys ────────────────────────────────────────────────────────
  static const _kAccessToken  = 'access_token';
  static const _kXAuthToken   = 'x-auth-token'; // kept for authStateProvider compat
  static const _kRefreshToken = 'refresh_token';
  static const _kIsGuest      = 'is_guest';

  final FlutterAppAuth           _appAuth  = const FlutterAppAuth();
  final FlutterSecureStorage     _storage  = const FlutterSecureStorage();

  // ── Login ────────────────────────────────────────────────────────────────
  Future<bool> login() async {
    try {
      final AuthorizationTokenResponse? result =
          await _appAuth.authorizeAndExchangeCode(
        AuthorizationTokenRequest(
          _clientId,
          _redirectUri,
          clientSecret: _clientSecret,
          scopes: _scopes,
          serviceConfiguration: const AuthorizationServiceConfiguration(
            authorizationEndpoint: _authEndpoint,
            tokenEndpoint:         _tokenEndpoint,
          ),
        ),
      );

      if (result != null && result.accessToken != null) {
        await _storage.write(key: _kAccessToken,  value: result.accessToken);
        await _storage.write(key: _kXAuthToken,   value: result.accessToken);
        if (result.refreshToken != null) {
          await _storage.write(key: _kRefreshToken, value: result.refreshToken);
        }
        // Clear guest flag on successful login
        await _storage.delete(key: _kIsGuest);
        return true;
      }
      return false;
   } catch (e) {
      // 👇 Using standard print() instead of debugPrint
      print('================ OAUTH ERROR ================');
      print(e.toString());
      print('=============================================');
      return false;
    }
  }

  // ── Getters ──────────────────────────────────────────────────────────────
  Future<String?> getAccessToken()  => _storage.read(key: _kAccessToken);
  Future<String?> getRefreshToken() => _storage.read(key: _kRefreshToken);

  Future<bool> get isLoggedIn async {
    final token = await getAccessToken();
    return token != null;
  }

  // ── Guest mode ───────────────────────────────────────────────────────────
  Future<void> continueAsGuest() async {
    await _storage.write(key: _kIsGuest, value: 'true');
  }

  Future<bool> get isGuest async {
    final value = await _storage.read(key: _kIsGuest);
    return value == 'true';
  }

  // ── Logout ───────────────────────────────────────────────────────────────
  Future<void> logout() async => _storage.deleteAll();

  // ── Token refresh (confidential client → HTTP Basic Auth) ────────────────
  // Per docs: confidential clients MUST use client authentication for refresh.
  // Basic Auth header = base64(clientId:clientSecret)
  Future<bool> _refreshAccessToken() async {
    final refreshToken = await getRefreshToken();
    if (refreshToken == null) return false;

    try {
      final credentials = base64Encode(
        utf8.encode('$_clientId:$_clientSecret'),
      );

      final response = await http.post(
        Uri.parse(_tokenEndpoint),
        headers: {
          'Content-Type':  'application/x-www-form-urlencoded',
          'Authorization': 'Basic $credentials',
        },
        body: {
          'grant_type':    'refresh_token',
          'refresh_token': refreshToken,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await _storage.write(key: _kAccessToken,  value: data['access_token']);
        await _storage.write(key: _kXAuthToken,   value: data['access_token']);
        if (data['refresh_token'] != null) {
          await _storage.write(key: _kRefreshToken, value: data['refresh_token']);
        }
        return true;
      }
    } catch (_) {}
    return false;
  }

  // ── Authenticated request with ONE 401 retry ─────────────────────────────
  // Per docs: "if 401: refresh once → retry once → if still fails, surface error"
  // No infinite loops.
  Future<http.Response> _apiRequest(
    String endpoint, {
    String method                   = 'GET',
    Map<String, dynamic>? body,
    bool isRetry                   = false,
  }) async {
    final token = await getAccessToken();

    Map<String, String> headers(String? t) => {
          'x-auth-token': t ?? '',
          'x-client-id':  _clientId,
          'Content-Type': 'application/json',
          'Accept':       'application/json',
        };

    final uri = Uri.parse('$_apiBase$endpoint');

    http.Response response;
    if (method == 'POST') {
      response = await http.post(
        uri,
        headers: headers(token),
        body:    body != null ? jsonEncode(body) : null,
      );
    } else if (method == 'DELETE') {
      response = await http.delete(uri, headers: headers(token));
    } else {
      response = await http.get(uri, headers: headers(token));
    }

    // One-shot 401 retry after token refresh
    if (response.statusCode == 401 && !isRetry) {
      final refreshed = await _refreshAccessToken();
      if (refreshed) {
        return _apiRequest(endpoint, method: method, body: body, isRetry: true);
      }
    }

    return response;
  }

  // ════════════════════════════════════════════════════════════════════════
  // User API endpoints
  // All paths: {apiBase}/auth/v1/...
  // Headers: x-auth-token + x-client-id (injected by _apiRequest)
  // ════════════════════════════════════════════════════════════════════════

  // ── Profile ──────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>?> getUserProfile() async {
    final res = await _apiRequest('/auth/v1/profile');
    return res.statusCode == 200
        ? jsonDecode(res.body) as Map<String, dynamic>
        : null;
  }

  // ── Bookmarks ─────────────────────────────────────────────────────────────
  /// Fetch all cloud bookmarks for the logged-in user.
  Future<List<dynamic>> getBookmarks() async {
    final res = await _apiRequest('/auth/v1/bookmarks');
    if (res.statusCode != 200) return [];
    final decoded = jsonDecode(res.body);
    // Response shape: { "data": [...] } or directly a list
    if (decoded is Map && decoded['data'] != null) {
      return decoded['data'] as List;
    }
    if (decoded is List) return decoded;
    return [];
  }

  /// Push a single ayah bookmark to Quran.com.
  /// Payload confirmed by Gemini's testing against the prelive API.
  Future<bool> syncBookmark({
    required int surahId,
    required int ayahNumber,
  }) async {
    final res = await _apiRequest(
      '/auth/v1/bookmarks',
      method: 'POST',
      body: {
        'key':         surahId,
        'type':        'ayah',
        'verseNumber': ayahNumber,
        'mushaf':      1,
      },
    );
    return res.statusCode == 200 || res.statusCode == 201;
  }

  /// Delete a bookmark by its cloud ID.
  Future<bool> deleteBookmark(String bookmarkId) async {
    final res = await _apiRequest(
      '/auth/v1/bookmarks/$bookmarkId',
      method: 'DELETE',
    );
    return res.statusCode == 200 || res.statusCode == 204;
  }

  // ── Collections ───────────────────────────────────────────────────────────
  /// Fetch all collections for the logged-in user.
  Future<List<dynamic>> getCollections() async {
    final res = await _apiRequest('/auth/v1/collections');
    if (res.statusCode != 200) return [];
    final decoded = jsonDecode(res.body);
    if (decoded is Map && decoded['data'] != null) {
      return decoded['data'] as List;
    }
    if (decoded is List) return decoded;
    return [];
  }

  /// Create a new collection.
  Future<Map<String, dynamic>?> createCollection({
    required String name,
    String? description,
  }) async {
    final res = await _apiRequest(
      '/auth/v1/collections',
      method: 'POST',
      body: {
        'name': name,
        if (description != null) 'description': description,
      },
    );
    return (res.statusCode == 200 || res.statusCode == 201)
        ? jsonDecode(res.body) as Map<String, dynamic>
        : null;
  }

  // ── Streaks ───────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>?> getStreak() async {
    final res = await _apiRequest('/auth/v1/streak');
    return res.statusCode == 200
        ? jsonDecode(res.body) as Map<String, dynamic>
        : null;
  }
}