/// Short month names used by [formatNoteDate].
const List<String> _months = [
  "Jan",
  "Feb",
  "Mar",
  "Apr",
  "May",
  "Jun",
  "Jul",
  "Aug",
  "Sep",
  "Oct",
  "Nov",
  "Dec",
];

/// Formats [date] as e.g. "11 Nov 2026, 3:05 pm" (12-hour clock, no leading
/// zero on the hour).
String formatNoteDate(DateTime date) {
  final minute = date.minute.toString().padLeft(2, '0');
  final suffix = date.hour >= 12 ? 'pm' : 'am';
  final hour12 = date.hour == 0
      ? 12
      : date.hour > 12
      ? date.hour - 12
      : date.hour;
  return "${date.day} ${_months[date.month - 1]} ${date.year}, $hour12:$minute $suffix";
}
