import 'package:hive/hive.dart';

part 'toggles_data.g.dart';

/// The single persisted user-preferences record.
///
/// Stored in the Hive box `togglesData` under key 0 and read/written only by
/// the settings controller, which keeps the in-memory state and this record
/// in sync. Defaults declared on the fields apply when an older record is
/// missing a field that was added later.
///
/// The generated adapter in `toggles_data.g.dart` maps the `@HiveField`
/// slots below, so field indexes are frozen and new fields must be appended
/// rather than renumbered.
@HiveType(typeId: 1)
class TogglesData extends HiveObject {
  /// Legacy boolean dark-mode flag, superseded by [themeMode]; kept so old
  /// records stay readable and can be migrated.
  @HiveField(0)
  bool darkMode;

  /// Removed header-density toggle; kept initialized but no longer read.
  @HiveField(1)
  bool compactHeader;

  /// Persisted index into the tri-state theme-mode enum (system, light,
  /// dark), or null for records written before the tri-state mode existed
  /// (those are migrated from [darkMode] on load).
  @HiveField(2)
  int? themeMode;

  /// Whether fetched link preview images are also stored on disk.
  @HiveField(3, defaultValue: true)
  bool saveImagesLocally;

  /// Dock edge as one of the strings `'bottom'`, `'top'`, `'left'`, or
  /// `'right'`.
  @HiveField(4, defaultValue: 'bottom')
  String dockPlacement;

  /// Whether light haptic feedback should fire on commit interactions.
  @HiveField(5, defaultValue: true)
  bool enableHaptics;

  /// Creates the preferences record; field defaults match first-launch
  /// defaults so a freshly constructed record can be persisted as is.
  TogglesData({
    this.darkMode = false,
    this.compactHeader = false,
    this.themeMode,
    this.saveImagesLocally = true,
    this.dockPlacement = 'left',
    this.enableHaptics = true,
  });
}
