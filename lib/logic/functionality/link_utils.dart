import 'package:any_link_preview/any_link_preview.dart';
import 'package:url_launcher/url_launcher.dart';

/// Provides utility helpers for link extraction and validation.
class LinkUtils {
  LinkUtils._();

  /// Extracts the first token of [text] that validates as a URL, or null
  /// when [text] is empty or holds no valid link.
  ///
  /// Tokens are split on any whitespace run; a URL embedded mid-sentence is
  /// only recognized when it is whitespace-separated from surrounding
  /// words. Validation is delegated to [AnyLinkPreview.isValidLink], which
  /// is the same rule the preview fetcher applies, so extraction and
  /// rendering can never disagree about what counts as a link.
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

  /// Returns the trailing note of [val] after removing the leading [link]
  /// and any leftover separator punctuation.
  ///
  /// Users write "https://example.com some thought" in one entry; this
  /// strips the URL and the colon, pipe, dash, comma, and semicolon noise
  /// around it, returning only the thought. The result may be empty when
  /// the entry was the URL alone.
  static String cleanText(String val, String link) {
    final t = val.replaceFirst(link, '').trim();
    final pattern = RegExp(r'^[:\-\|\s,;]+|[:\-\|\s,;]+$');
    return t.replaceAll(pattern, '').trim();
  }

  /// Whether [text] contains at least one token that validates as a URL;
  /// equivalent to [extractFirstLink] returning non-null.
  static bool hasLink(String text) {
    return extractFirstLink(text) != null;
  }

  /// Returns [url] with an `https://` scheme prepended when it lacks one,
  /// so scheme-less input such as `example.com/page` still launches.
  ///
  /// A URL that already carries any valid scheme is returned trimmed and
  /// unchanged; the check accepts schemes like `http`, `ftp`, and app
  /// schemes, not just `https`.
  static String normalizeUrl(String url) {
    final trimmedURL = url.trim();
    if (!trimmedURL.startsWith(RegExp(r'^[a-zA-Z0-9+.-]+://'))) {
      return 'https://$trimmedURL';
    }
    return trimmedURL;
  }

  /// Opens [url] in the platform's external browser app after normalizing its
  /// scheme. Does nothing when [url] contains no valid link or cannot be
  /// parsed as a URI.
  static Future<void> openExternalUrl(String url) async {
    final link = extractFirstLink(url);
    if (link == null) return;
    final uri = Uri.tryParse(normalizeUrl(link));
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
