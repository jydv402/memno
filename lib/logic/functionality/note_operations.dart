import 'package:memno/logic/functionality/code_gen.dart';
import 'package:memno/logic/functionality/link_utils.dart';
import 'package:memno/logic/functionality/preview_map.dart';

/// Deletes note page [code] together with the cached preview of every link it
/// holds. A preview is only deleted when no surviving note still references
/// the same link, so two notes sharing a URL keep their shared preview.
Future<void> deleteNoteWithPreviews(
  CodeGen codeGen,
  PreviewMap previewMap,
  int code,
) async {
  final links = codeGen.getLinksForCode(code);
  // Remove the note first so the reference check below doesn't count it.
  await codeGen.clearList(code);
  for (final link in links) {
    if (!isLinkReferenced(codeGen, link)) {
      await previewMap.deletePreviewForLink(link);
    }
  }
}

/// Deletes the entry at [index] of note page [code] together with the cached
/// preview of its link — but only when no surviving entry still references
/// the same link.
Future<void> deleteEntryWithPreviews(
  CodeGen codeGen,
  PreviewMap previewMap,
  int code,
  int index,
) async {
  final entries = codeGen.getLinksForCode(code);
  if (index < 0 || index >= entries.length) return;
  final firstLink = LinkUtils.extractFirstLink(entries[index]);

  // Remove the entry first so the reference check below doesn't count it.
  await codeGen.deleteLink(code, index);
  if (firstLink == null) return;
  if (!isLinkReferenced(codeGen, firstLink)) {
    await previewMap.deletePreviewForLink(firstLink);
  }
}

/// Returns true when any note in [codeGen] still contains [link] as the first
/// valid URL of one of its entries.
bool isLinkReferenced(CodeGen codeGen, String link) {
  for (final code in codeGen.codeList) {
    for (final entry in codeGen.getLinksForCode(code)) {
      if (LinkUtils.extractFirstLink(entry) == link) {
        return true;
      }
    }
  }
  return false;
}

/// Deletes every note page together with every cached preview — the wipe-all
/// counterpart of [deleteNoteWithPreviews]. Nothing survives, so no reference
/// check is needed.
Future<void> clearAllWithPreviews(
  CodeGen codeGen,
  PreviewMap previewMap,
) async {
  final allLinks = <String>{};
  for (final code in codeGen.codeList) {
    for (final entry in codeGen.getLinksForCode(code)) {
      final link = LinkUtils.extractFirstLink(entry);
      if (link != null) allLinks.add(link);
    }
  }
  await codeGen.clearAll();
  for (final link in allLinks) {
    await previewMap.deletePreviewForLink(link);
  }
}
