import 'dart:io';

import 'package:material_ui/material_ui.dart';

/// Fixed candidate ports for the desktop consent redirect server.
///
/// The redirect after consent must land on a port the browser is willing to
/// navigate to: Chromium refuses `ERR_UNSAFE_PORT` for a list of well-known
/// service ports, and an OS-assigned ephemeral port (`listenPort: 0`) can
/// occasionally be one of them — the user then consents successfully but the
/// callback page never loads. Pinned unregistered ports avoid the blocked
/// list entirely; a few candidates absorb the rare case where another
/// process already holds one.
const List<int> consentRedirectPorts = [31415, 31416, 31417];

/// Returns the first of [candidates] that is free to bind on localhost, or
/// `0` (the OS picks an ephemeral port — the pre-fix behavior) when every
/// candidate is taken, which is pathological and merely re-rolls the old
/// dice instead of failing sign-in outright.
Future<int> pickConsentRedirectPort({
  List<int> candidates = consentRedirectPorts,
}) async {
  for (final port in candidates) {
    ServerSocket? probe;
    try {
      probe = await ServerSocket.bind('localhost', port);
      return port;
    } on SocketException catch (e) {
      debugPrint('Consent redirect port $port is busy: $e');
    } finally {
      await probe?.close();
    }
  }
  debugPrint('All consent redirect ports busy; falling back to ephemeral.');
  return 0;
}
