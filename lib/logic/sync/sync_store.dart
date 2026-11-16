import 'dart:math';

import 'package:hive_flutter/hive_flutter.dart';

/// Local persistence for sync-only state that must never leave the device
/// except inside synced record metadata.
///
/// In this phase the store holds only the device id; later phases add the
/// sync cursor, the tombstone graveyard, and per-account namespaces. All
/// values live in the Hive box `syncBox` as plain strings, so no generated
/// adapter is required and the box shares the app's single storage root.
class SyncStore {
  /// Hive box holding sync state as string key/value pairs.
  static const String boxName = 'syncBox';

  /// Key of the device id entry inside [boxName].
  static const String deviceIdKey = 'device_id';

  Box<String>? _box;

  /// Returns the stable identifier of this device, generating and
  /// persisting a new one on first call.
  ///
  /// The id is 32 lowercase hex characters drawn from `Random.secure`. The
  /// note controller stamps it onto every record it edits and the sync
  /// merge uses it as the deterministic tie-breaker between edits that
  /// carry the same timestamp; it identifies a device, never a user.
  Future<String> deviceId() async {
    _box ??= await _openBox();
    final existing = _box!.get(deviceIdKey);
    if (existing != null && existing.isNotEmpty) return existing;

    final id = _generateId();
    await _box!.put(deviceIdKey, id);
    return id;
  }

  /// Reads the string stored under [key], or null when unset.
  Future<String?> value(String key) async {
    _box ??= await _openBox();
    return _box!.get(key);
  }

  /// Stores [value] under [key].
  Future<void> setValue(String key, String value) async {
    _box ??= await _openBox();
    await _box!.put(key, value);
  }

  /// Opens or reuses the `syncBox` Hive box.
  Future<Box<String>> _openBox() async {
    if (Hive.isBoxOpen(boxName)) {
      return Hive.box<String>(boxName);
    }
    return Hive.openBox<String>(boxName);
  }

  /// Generates 16 cryptographically secure random bytes as lowercase hex.
  String _generateId() {
    final rnd = Random.secure();
    return List<String>.generate(
      16,
      (_) => rnd.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
  }
}
