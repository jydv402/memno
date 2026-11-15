/// Mode of the note input bar, shared by the mobile FAB and the desktop
/// input bar.
///
/// Each mode changes the input hint text and, on desktop, the confirm
/// button's color token: [add] maps to the success (green) token,
/// [editEntry] to the info (blue) token, and [editTitle] to the warning
/// (orange) token.
enum EditMode {
  /// Accepts text for a brand-new entry appended to the open note.
  add,

  /// Accepts replacement text for an existing entry, tracked by index.
  editEntry,

  /// Accepts a new title for the open note page.
  editTitle,
}
