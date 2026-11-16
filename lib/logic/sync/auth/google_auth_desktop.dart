import 'dart:async';
import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:googleapis_auth/auth_io.dart' as gapis;
import 'package:http/http.dart' as http;
import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import 'consent_port.dart';
import 'oauth_constants.dart';
import 'sync_auth.dart';

/// Windows/desktop sign-in: the system browser opens the Google consent
/// page, the redirect lands on a loopback port, and the refresh token is
/// persisted in secure storage so later launches rebuild the client
/// silently via `clientViaRefreshToken`.
///
/// The consent also requests `openid` and `email` so the flow returns an id
/// token from which the account identity is decoded once and stored beside
/// the token; [syncScopes] stays untouched.
final class GoogleAuthDesktop implements SyncAuth {
  /// Creates the desktop authenticator.
  GoogleAuthDesktop();

  static const String _refreshTokenKey = 'memno.sync.refresh_token';
  static const String _accountKey = 'memno.sync.account';

  static const List<String> _scopes = [...syncScopes, 'openid', 'email'];

  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  gapis.AuthClient? _client;

  /// The desktop client credentials, failing loudly when the build did not
  /// inject the `.env` constants instead of failing later mid-consent.
  gapis.ClientId get _clientId {
    if (memnoDesktopClientId.isEmpty || memnoDesktopClientSecret.isEmpty) {
      throw StateError(
        'Desktop OAuth constants were not injected; build with '
        '--dart-define-from-file=.env (see .env.example).',
      );
    }
    return gapis.ClientId(memnoDesktopClientId, memnoDesktopClientSecret);
  }

  @override
  Future<bool> isSignedIn() => _storage.containsKey(key: _refreshTokenKey);

  @override
  Future<Account?> account() async {
    final stored = await _storage.read(key: _accountKey);
    if (stored == null || stored.isEmpty) return null;
    try {
      final map = jsonDecode(stored) as Map<String, dynamic>;
      return Account(id: map['id'] as String, email: map['email'] as String);
    } catch (e) {
      debugPrint('Desktop stored account unreadable: $e');
      return null;
    }
  }

  @override
  Future<gapis.AuthClient> client() async {
    final existing = _client;
    if (existing != null) return existing;
    final refreshToken = await _storage.read(key: _refreshTokenKey);
    if (refreshToken == null || refreshToken.isEmpty) {
      throw StateError('No stored desktop sign-in; call signIn() first.');
    }
    final client = await gapis.clientViaRefreshToken(
      _clientId,
      refreshToken,
      _scopes,
    );
    _client = client;
    return client;
  }

  @override
  Future<void> signIn() async {
    // Pinned redirect port: an ephemeral one can be a browser-blocked port
    // (ERR_UNSAFE_PORT) and the consent would complete with no way to
    // deliver the authorization code back to the app.
    final listenPort = await pickConsentRedirectPort();
    final client = await gapis.clientViaUserConsent(_clientId, _scopes, (uri) {
      unawaited(
        launchUrl(
          Uri.parse(uri),
          mode: LaunchMode.externalApplication,
        ).catchError((Object e) {
          debugPrint('Opening browser for consent failed: $e');
          return false;
        }),
      );
    }, listenPort: listenPort);
    final credentials = client.credentials;
    await _storage.write(
      key: _refreshTokenKey,
      value: credentials.refreshToken,
    );
    final account = _accountFromIdToken(credentials.idToken);
    if (account != null) {
      await _storage.write(
        key: _accountKey,
        value: jsonEncode({'id': account.id, 'email': account.email}),
      );
    }
    _closeExisting();
    _client = client;
  }

  @override
  Future<void> signOut() async {
    final refreshToken = await _storage.read(key: _refreshTokenKey);
    if (refreshToken != null && refreshToken.isNotEmpty) {
      try {
        await http.post(
          Uri.parse('https://oauth2.googleapis.com/revoke?token=$refreshToken'),
          headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        );
      } catch (e, st) {
        debugPrint(
          'Token revoke failed (grant stays until revoked at '
          'myaccount.google.com/permissions): $e\n$st',
        );
      }
    }
    await _storage.delete(key: _refreshTokenKey);
    await _storage.delete(key: _accountKey);
    _closeExisting();
  }

  /// Decodes the account identity (`sub`, `email`) from an id token
  /// payload, or null when the token is malformed.
  Account? _accountFromIdToken(String? idToken) {
    if (idToken == null) return null;
    try {
      final parts = idToken.split('.');
      if (parts.length < 2) return null;
      final payload =
          jsonDecode(
                utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
              )
              as Map<String, dynamic>;
      return Account(
        id: payload['sub'] as String? ?? '',
        email: payload['email'] as String? ?? '',
      );
    } catch (e) {
      debugPrint('Id token unreadable: $e');
      return null;
    }
  }

  void _closeExisting() {
    _client?.close();
    _client = null;
  }
}
