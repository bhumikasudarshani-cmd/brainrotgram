import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../api/api_constants.dart';

// ---------- Keys for secure storage ----------
const _keyAccessToken = 'brainrotgram_access_token';
const _keyRefreshToken = 'brainrotgram_refresh_token';
const _keyIdToken = 'brainrotgram_id_token';
const _keyExpiresAt = 'brainrotgram_expires_at';

// ---------- User model (from ID token claims) ----------
class AuthUser {
  final String name;
  final String email;
  final String? pictureUrl;

  const AuthUser({
    required this.name,
    required this.email,
    this.pictureUrl,
  });

  String get initials =>
      name.isNotEmpty ? name[0].toUpperCase() : email[0].toUpperCase();

  factory AuthUser.fromIdTokenClaims(Map<String, dynamic> claims) {
    return AuthUser(
      name: claims['name'] as String? ?? claims['email'] as String? ?? '',
      email: claims['email'] as String? ?? '',
      pictureUrl: claims['picture'] as String?,
    );
  }
}

// ---------- Auth state ----------
enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthState {
  final AuthStatus status;
  final AuthUser? user;
  final String? accessToken;
  final bool isLoading;

  const AuthState({
    this.status = AuthStatus.unknown,
    this.user,
    this.accessToken,
    this.isLoading = false,
  });

  AuthState copyWith({
    AuthStatus? status,
    AuthUser? user,
    String? accessToken,
    bool? isLoading,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      accessToken: accessToken ?? this.accessToken,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

// ---------- Auth notifier ----------
class AuthNotifier extends StateNotifier<AuthState> {
  final FlutterAppAuth _appAuth;
  final FlutterSecureStorage _storage;

  AuthNotifier({
    FlutterAppAuth? appAuth,
    FlutterSecureStorage? storage,
  })  : _appAuth = appAuth ?? const FlutterAppAuth(),
        _storage = storage ?? const FlutterSecureStorage(),
        super(const AuthState()) {
    _tryRestoreSession();
  }

  // --- Public API ---

  /// Sign in with Google via Cognito (Authorization Code + PKCE).
  Future<void> signIn() async {
    state = state.copyWith(isLoading: true);

    try {
      final result = await _appAuth.authorizeAndExchangeCode(
        AuthorizationTokenRequest(
          ApiConstants.clientId,
          ApiConstants.redirectUri,
          serviceConfiguration: const AuthorizationServiceConfiguration(
            authorizationEndpoint: ApiConstants.authorizeEndpoint,
            tokenEndpoint: ApiConstants.tokenEndpoint,
          ),
          scopes: ApiConstants.scopes.split(' '),
          additionalParameters: {'identity_provider': 'Google'},
        ),
      );

      await _handleTokenResponse(result);
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        isLoading: false,
      );
    }
  }

  /// Refresh the access token silently.
  Future<bool> refreshToken() async {
    final refreshToken = await _storage.read(key: _keyRefreshToken);
    if (refreshToken == null) return false;

    try {
      final result = await _appAuth.token(
        TokenRequest(
          ApiConstants.clientId,
          ApiConstants.redirectUri,
          serviceConfiguration: const AuthorizationServiceConfiguration(
            authorizationEndpoint: ApiConstants.authorizeEndpoint,
            tokenEndpoint: ApiConstants.tokenEndpoint,
          ),
          refreshToken: refreshToken,
          scopes: ApiConstants.scopes.split(' '),
        ),
      );

      await _handleTokenResponse(result);
      return true;
    } catch (_) {
      // Refresh failed — force sign out
    }

    await signOut();
    return false;
  }

  /// Sign out: clear storage, navigate to gate.
  Future<void> signOut() async {
    await _storage.deleteAll();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  /// Get the current access token, refreshing if needed.
  Future<String?> getValidAccessToken() async {
    final expiresAtStr = await _storage.read(key: _keyExpiresAt);
    if (expiresAtStr != null) {
      final expiresAt = DateTime.tryParse(expiresAtStr);
      if (expiresAt != null &&
          expiresAt.isBefore(DateTime.now().add(const Duration(minutes: 1)))) {
        final success = await refreshToken();
        if (!success) return null;
      }
    }
    return state.accessToken ?? await _storage.read(key: _keyAccessToken);
  }

  // --- Private helpers ---

  Future<void> _tryRestoreSession() async {
    final accessToken = await _storage.read(key: _keyAccessToken);
    final idToken = await _storage.read(key: _keyIdToken);

    if (accessToken != null && idToken != null) {
      final user = _parseIdToken(idToken);
      state = AuthState(
        status: AuthStatus.authenticated,
        user: user,
        accessToken: accessToken,
      );
    } else {
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
  }

  Future<void> _handleTokenResponse(TokenResponse result) async {
    await _storage.write(key: _keyAccessToken, value: result.accessToken);
    await _storage.write(key: _keyRefreshToken, value: result.refreshToken);
    if (result.idToken != null) {
      await _storage.write(key: _keyIdToken, value: result.idToken);
    }
    if (result.accessTokenExpirationDateTime != null) {
      await _storage.write(
        key: _keyExpiresAt,
        value: result.accessTokenExpirationDateTime!.toIso8601String(),
      );
    }

    final idToken =
        result.idToken ?? await _storage.read(key: _keyIdToken);
    final user = idToken != null ? _parseIdToken(idToken) : null;

    state = AuthState(
      status: AuthStatus.authenticated,
      user: user,
      accessToken: result.accessToken,
    );
  }

  AuthUser? _parseIdToken(String idToken) {
    try {
      final parts = idToken.split('.');
      if (parts.length != 3) return null;
      final payload = parts[1];
      final normalized = base64Url.normalize(payload);
      final decoded = utf8.decode(base64Url.decode(normalized));
      final claims = json.decode(decoded) as Map<String, dynamic>;
      return AuthUser.fromIdTokenClaims(claims);
    } catch (_) {
      return null;
    }
  }
}

// ---------- Providers ----------
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
