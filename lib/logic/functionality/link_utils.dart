import 'package:any_link_preview/any_link_preview.dart';

/// Provides utility helpers for link extraction and validation.
class LinkUtils {
  LinkUtils._();

  /// Scans [text] and returns the first valid URL token if found.
  /// Returns null if no valid URL is found.
  static String? extractFirstLink(String text) {
    if (text.isEmpty) return null;
    // Split by any whitespace characters (spaces, tabs, newlines)
    final tokens = text.split(RegExp(r'\s+'));
    for (final token in tokens) {
      if (AnyLinkPreview.isValidLink(token)) {
        return token;
      }
    }
    return null;
  }

  /// Cleans the input [val] by removing the specified [link] and any leading/trailing punctuation or whitespace.
  /// Returns the cleaned string.
  static String cleanText(String val, String link) {
    final t = val.replaceFirst(link, '').trim();
    final pattern = RegExp(r'^[:\-\|\s,;]+|[:\-\|\s,;]+$');
    return t.replaceAll(pattern, '').trim();
  }

  /// Returns true if [text] contains at least one valid URL.
  static bool hasLink(String text) {
    return extractFirstLink(text) != null;
  }

  /// Ensures the URL has a scheme prefix (defaults to https:// if missing).
  static String normalizeUrl(String url) {
    final trimmedURL = url.trim();
    if (!trimmedURL.startsWith(RegExp(r'^[a-zA-Z0-9+.-]+://'))) {
      return 'https://$trimmedURL';
    }
    return trimmedURL;
  }
}
