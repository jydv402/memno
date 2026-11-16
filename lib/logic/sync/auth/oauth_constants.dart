/// OAuth client id for the Android client; matched by package name + SHA-1
/// at sign-in time, so it is informational only.
const String memnoAndroidClientId = String.fromEnvironment(
  'MEMNO_ANDROID_CLIENT_ID',
);

/// OAuth client id for the Windows "Desktop app" client; empty when the
/// `.env` file was not injected at build time.
const String memnoDesktopClientId = String.fromEnvironment(
  'MEMNO_DESKTOP_CLIENT_ID',
);

/// OAuth client secret for the Windows "Desktop app" client; not
/// confidential for installed apps (Google's stance), injected so it stays
/// out of the source tree.
const String memnoDesktopClientSecret = String.fromEnvironment(
  'MEMNO_DESKTOP_CLIENT_SECRET',
);
