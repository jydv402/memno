import 'package:hive/hive.dart';

part 'preview_data.g.dart';

/// Cached OpenGraph-style metadata for one link preview.
///
/// Persisted by the preview layer so a previously fetched link renders
/// instantly on the next visit. All fields are nullable because pages
/// frequently omit metadata; the widget layer tolerates a completely empty
/// record and still renders the bare URL.
///
/// The generated adapter in `preview_data.g.dart` maps the `@HiveField`
/// slots below, so field indexes are frozen and new fields must be appended
/// rather than renumbered.
@HiveType(typeId: 2)
class PreviewDataModel {
  /// Page title as reported by the source page, or null when absent.
  @HiveField(0)
  final String? title;

  /// Page description or excerpt, or null when absent.
  @HiveField(1)
  final String? description;

  /// Absolute URL of the page's main image, or null when the page has none.
  @HiveField(2)
  final String? image;

  /// Rendered height of the main image in logical pixels, or null when
  /// unknown; the preview widget uses it to pick a rounded-corner style.
  @HiveField(3)
  final double? imageHeight;

  /// Rendered width of the main image in logical pixels, or null when
  /// unknown.
  @HiveField(4)
  final double? imageWidth;

  /// The link this metadata was fetched for; kept so a stored record can be
  /// traced back to its URL even after it leaves the in-memory map.
  @HiveField(5)
  final String? link;

  /// Path of the locally cached copy of [image] when the user enabled
  /// "Save Previews Locally", or null when the image must be loaded from
  /// the network every time.
  @HiveField(6)
  final String? localImagePath;

  /// Creates a record; every field is optional because sources vary wildly
  /// in which metadata they provide.
  PreviewDataModel({
    this.title,
    this.description,
    this.image,
    this.imageHeight,
    this.imageWidth,
    this.link,
    this.localImagePath,
  });
}
