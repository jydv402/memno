import 'package:memno/logic/functionality/code_gen.dart';

/// Category filter applied to note lists and grids.
enum NoteFilter { all, liked, empty }

/// Filters the notes in [codeGen] by [filter] and optional [query], then sorts
/// them most-recent-first (unparseable dates sort last). Returns note codes.
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
