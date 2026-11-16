import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis_auth/googleapis_auth.dart' as gapis;
import 'package:material_ui/material_ui.dart';

import 'sync_auth.dart';

/// Android/mobile sign-in: the native account picker resolves the identity
/// and the platform authorization is bridged into a [gapis.AuthClient] for
/// [syncScopes].
///
/// The bridged client carries a static access token without a refresh
/// token; the plugin issues fresh tokens on each successful
/// `authorizeScopes`, so on an auth failure the sync layer must rebuild the
/// client through this class (handled in Phase 2).
final class GoogleAuthMobile implements SyncAuth {
  /// Creates the mobile authenticator.
  GoogleAuthMobile();

  final GoogleSignIn _signIn = GoogleSignIn.instance;
  bool _initialized = false;
  GoogleSignInAccount? _account;
  GoogleSignInClientAuthorization? _authorization;

  /// Runs [GoogleSignIn.initialize] once; later calls are no-ops.
  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    await _signIn.initialize();
    _initialized = true;
  }

  /// Returns the signed-in account, trying the silent path first.
  Future<GoogleSignInAccount?> _resolveAccount() async {
    await _ensureInitialized();
    try {
      _account ??= await _signIn.attemptLightweightAuthentication();
    } catch (e) {
      debugPrint('Silent sign-in unavailable: $e');
    }
    return _account;
  }

  @override
  Future<bool> isSignedIn() async => await _resolveAccount() != null;

  @override
  Future<Account?> account() async {
    final account = _account ?? await _resolveAccount();
    if (account == null) return null;
    return Account(id: account.id, email: account.email);
  }

  @override
  Future<gapis.AuthClient> client() async {
    final account = _account ?? await _resolveAccount();
    if (account == null) {
      throw StateError('No mobile sign-in; call signIn() first.');
    }
    _authorization ??=
        await account.authorizationClient.authorizationForScopes(syncScopes) ??
        await account.authorizationClient.authorizeScopes(syncScopes);
    return _authorization!.authClient(scopes: syncScopes);
  }

  @override
  Future<void> signIn() async {
    await _ensureInitialized();
    final account =
        await _signIn.attemptLightweightAuthentication() ??
        await _signIn.authenticate();
    _account = account;
    _authorization = await account.authorizationClient.authorizeScopes(
      syncScopes,
    );
  }

  @override
  Future<void> signOut() async {
    try {
      await _signIn.disconnect();
    } catch (e, st) {
      debugPrint('Mobile disconnect failed: $e\n$st');
    }
    _account = null;
    _authorization = null;
  }
}
