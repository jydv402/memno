import 'dart:async';
import 'dart:io' show SocketException;

import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis_auth/googleapis_auth.dart' as gapis;
import 'package:material_ui/material_ui.dart';

import 'sync_auth.dart';

/// Observable sign-in state for the Settings "Sync" section, shared by the
/// desktop card and the mobile tile so the load / sign-in / sign-out flow
/// exists exactly once.
///
/// The controller wraps the platform [SyncAuth] implementation, starts
/// loading the current state at construction (like the other controllers in
/// the app), and guards against overlapping operations with [busy]. Its
/// mutating methods return a human-readable outcome message — success or
/// failure — so callers only have to display it; failure details are logged
/// with the full error and stack.
class SyncAuthController extends ChangeNotifier {
  /// Starts observing [_auth] and loads the current sign-in state.
  SyncAuthController(this._auth) {
    unawaited(load());
  }

  final SyncAuth _auth;
  bool _isReady = false;
  bool _busy = false;
  bool _signedIn = false;
  Account? _account;

  /// Whether the initial [load] finished; sections can render defaults
  /// before that without flicker risk.
  bool get isReady => _isReady;

  /// Whether a sign-in or sign-out operation is currently running; sections
  /// disable their controls while this is true.
  bool get busy => _busy;

  /// Whether a Google account is currently authorized for sync.
  bool get signedIn => _signedIn;

  /// The signed-in account, or null when signed out or not yet loaded.
  Account? get account => _account;

  /// Refreshes the sign-in state from [_auth]; failures are logged and
  /// surface as signed-out rather than throwing, so the settings page can
  /// always render.
  Future<void> load() async {
    try {
      _signedIn = await _auth.isSignedIn();
      _account = _signedIn ? await _auth.account() : null;
    } catch (e, st) {
      debugPrint('Sync sign-in state load failed: $e\n$st');
      _signedIn = false;
      _account = null;
    } finally {
      _isReady = true;
      notifyListeners();
    }
  }

  /// Runs the consent flow and returns the outcome message to display:
  /// `Signed in as …` on success, a friendly failure reason otherwise.
  Future<String> signIn() async {
    if (_busy) return 'Another sign-in is already running.';
    _busy = true;
    notifyListeners();
    try {
      await _auth.signIn();
      _signedIn = true;
      _account = await _auth.account();
      return 'Signed in as ${_account?.email ?? 'your Google account'}';
    } catch (e, st) {
      debugPrint('Sync sign-in failed: $e\n$st');
      return _describe(e, fallback: 'Sign-in failed. Please try again.');
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  /// Revokes the sync grant and returns the outcome message to display:
  /// `Signed out` on success, a friendly failure reason otherwise.
  Future<String> signOut() async {
    if (_busy) return 'Another sign-in is already running.';
    _busy = true;
    notifyListeners();
    try {
      await _auth.signOut();
      _signedIn = false;
      _account = null;
      return 'Signed out of Google';
    } catch (e, st) {
      debugPrint('Sync sign-out failed: $e\n$st');
      return _describe(e, fallback: 'Sign-out failed. Please try again.');
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  /// Maps [error] to a short user-facing message; [fallback] covers
  /// anything not worth a specific line. Details stay in the log.
  String _describe(Object error, {required String fallback}) {
    if (error is GoogleSignInException &&
        error.code == GoogleSignInExceptionCode.canceled) {
      return 'Sign-in cancelled';
    }
    if (error is gapis.UserConsentException) {
      return 'Consent was declined';
    }
    if (error is StateError) return error.message;
    if (error is SocketException) {
      return 'No connection to Google. Check your internet.';
    }
    return fallback;
  }
}
