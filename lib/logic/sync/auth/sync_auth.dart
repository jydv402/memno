import 'package:googleapis_auth/googleapis_auth.dart';

/// The Google Drive scope requested for sync; non-sensitive, app-data only.
const List<String> syncScopes = [
  'https://www.googleapis.com/auth/drive.appdata',
];

/// The signed-in Google identity, shown in Settings.
final class Account {
  /// Stable Google account id.
  final String id;

  /// Email address.
  final String email;

  /// Creates an account record.
  const Account({required this.id, required this.email});
}

/// Sign-in contract; one implementation per platform, both ending in the
/// same [AuthClient] the Drive layer consumes.
abstract interface class SyncAuth {
  /// Whether a Google account is already authorized for [syncScopes].
  Future<bool> isSignedIn();

  /// The signed-in account, or null when signed out.
  Future<Account?> account();

  /// An auto-refreshing client authorized for [syncScopes]; throws when
  /// signed out — call [signIn] first.
  Future<AuthClient> client();

  /// Runs the platform consent flow (silent first, interactive fallback).
  Future<void> signIn();

  /// Revokes the grant and deletes any stored token.
  Future<void> signOut();
}
