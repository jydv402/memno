import 'package:memno/logic/functionality/code_gen.dart';

/// Category filter applied to note lists and grids.
///
/// The declaration order matters to callers: the desktop shell maps dock
/// destination indexes straight onto `values`, with index 3 (Settings)
/// handled separately and never passed here.
enum NoteFilter {
  /// Shows every note page regardless of like state or content.
  all,

  /// Shows only pages whose favorite flag is set.
  liked,

  /// Shows only pages with zero entries.
  empty,
}

/// Returns the codes of the notes in [codeGen] that pass [filter], narrowed
/// by a case-insensitive [query] when non-empty, sorted most-recently-edited
/// first.
///
/// The returned list is always a fresh mutable list; callers may reorder or
/// mutate it freely. Notes whose stored date cannot be parsed sort last,
/// anchored at the Unix epoch, so corrupt or missing dates never crash the
/// list.
List<int> filterAndSortNotes(
  CodeGen codeGen, {
  NoteFilter filter = NoteFilter.all,
  String query = '',
}) {
  List<int> codes;
  switch (filter) {
    case NoteFilter.all:
      codes = List<int>.from(codeGen.codeList);
    case NoteFilter.liked:
      codes = codeGen.codeList
          .where((code) => codeGen.getLikeForCode(code))
          .toList();
    case NoteFilter.empty:
      codes = codeGen.codeList
          .where((code) => codeGen.getLinkListLength(code) == 0)
          .toList();
  }

  final queryLower = query.toLowerCase();
  if (queryLower.isNotEmpty) {
    codes = codes.where((code) {
      final head = codeGen.getHeadForCode(code).toLowerCase();
      return code.toString().contains(queryLower) || head.contains(queryLower);
    }).toList();
  }

  // Schwartzian transform: parse each date once before sorting.
  final parsedDates = <int, DateTime>{};
  for (final code in codes) {
    final dateStr = codeGen.getDateForCode(code);
    parsedDates[code] =
        DateTime.tryParse(dateStr) ?? DateTime.fromMillisecondsSinceEpoch(0);
  }
  codes.sort((a, b) => parsedDates[b]!.compareTo(parsedDates[a]!));

  return codes;
}
