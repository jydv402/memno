import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:ota_update/ota_update.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

Future<Map<String, dynamic>?> getLatestGitHubRelease() async {
  try {
    final response = await http.get(
      Uri.parse("https://api.github.com/repos/jydv402/memno/releases/latest"),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      return null;
    }
  } catch (e) {
    return null;
  }
}

/// Returns the correct APK download URL for the device's CPU architecture.
/// Falls back to the first .apk asset if no arch-specific match is found.
String? getDownloadUrlForDevice(Map<String, dynamic> release) {
  final assets = release['assets'] as List<dynamic>?;
  if (assets == null || assets.isEmpty) return null;

  // Map Dart's architecture strings to the APK filename conventions
  final arch = _getDeviceArch();

  // Try to find an asset matching this device's architecture
  for (final asset in assets) {
    final name = (asset['name'] as String?)?.toLowerCase() ?? '';
    if (name.endsWith('.apk') && name.contains(arch)) {
      return asset['browser_download_url'] as String?;
    }
  }

  // Fallback: return the first .apk asset
  for (final asset in assets) {
    final name = (asset['name'] as String?)?.toLowerCase() ?? '';
    if (name.endsWith('.apk')) {
      return asset['browser_download_url'] as String?;
    }
  }

  return null;
}

/// Detects the device CPU architecture and maps it to standard APK ABI names.
String _getDeviceArch() {
  // SysInfo.kernelArchitecture returns values like "aarch64", "armv7l", "x86_64"
  final machine = _getMachineArch();

  if (machine.contains('aarch64') || machine.contains('arm64')) {
    return 'arm64-v8a';
  } else if (machine.contains('arm')) {
    return 'armeabi-v7a';
  } else if (machine.contains('x86_64') || machine.contains('amd64')) {
    return 'x86_64';
  }

  // Default fallback for unknown architectures
  return 'arm64-v8a';
}

/// Gets the machine architecture string from the OS.
String _getMachineArch() {
  try {
    // On Android/Linux, `uname -m` returns the architecture
    final result = Process.runSync('uname', ['-m']);
    return (result.stdout as String).trim().toLowerCase();
  } catch (_) {
    // Fallback: most Android devices are arm64
    return 'aarch64';
  }
}

bool isNewerVersion(String latest, String current, String buildNumber) {
  //print("Comparing versions: Latest: $latest, Current: $current");
  // eg latest = "1.2.3+11", current = "1.2.2"
  // Remove after '+' if present in latest version
  final latestParts =
      latest.split('+')[0].split('.').map(int.parse).toList() +
      (latest.contains('+') ? [int.parse(latest.split('+')[1])] : []);
  final currentParts =
      current.split('.').map(int.parse).toList() + [int.parse(buildNumber)];

  //print("Latest parts: $latestParts, Current parts: $currentParts");

  for (int i = 0; i < latestParts.length; i++) {
    if (i >= currentParts.length || latestParts[i] > currentParts[i]) {
      return true;
    } else if (latestParts[i] < currentParts[i]) {
      return false;
    }
  }
  return false;
}

/// Triggers an OTA update using the provided [url].
/// Returns a Stream of OtaEvent containing the download progress and status.
Stream<OtaEvent> startOtaUpdate(String url) {
  try {
    return OtaUpdate().execute(
      url,
      androidProviderAuthority: 'com.jdmakes.memno.ota_update_provider',
    );
  } catch (e) {
    rethrow;
  }
}

/// High-level check for updates.
/// Returns a Map if an update is available, null otherwise.
Future<Map<String, dynamic>?> checkUpdateAvailable() async {
  try {
    final info = await PackageInfo.fromPlatform();
    final currVer = info.version;
    final buildNumber = info.buildNumber;

    if (currVer.isEmpty || buildNumber.isEmpty) return null;

    final release = await getLatestGitHubRelease();
    if (release == null) return null;

    final latestVerWithTag = release['tag_name'].toString();
    // Some tags start with 'v', remove it if needed
    final latestVer = latestVerWithTag.startsWith('v')
        ? latestVerWithTag.substring(1).split('+')[0]
        : latestVerWithTag.split('+')[0];

    if (isNewerVersion(latestVer, currVer, buildNumber)) {
      return {
        'version': latestVer,
        'url': getDownloadUrlForDevice(release),
        'notes': release['body'] ?? "No release notes available.",
      };
    }
  } catch (e) {
    // Silent fail
  }
  return null;
}

/// Deletes any lingering .apk files in the app's download directory to save space.
Future<void> cleanupUpdateFiles() async {
  try {
    if (Platform.isAndroid) {
      // ota_update stores files in getExternalFilesDir(null)
      final directory = await getExternalStorageDirectory();
      if (directory != null && await directory.exists()) {
        final List<FileSystemEntity> files = directory.listSync();
        for (final file in files) {
          if (file is File && file.path.toLowerCase().endsWith('.apk')) {
            await file.delete();
          }
        }
      }
    }
  } catch (e) {
    // Silent fail
  }
}
