import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:memno/desktop/pages/home_page_pc.dart';
import 'package:memno/desktop/pages/note_page_pc.dart';
import 'package:memno/desktop/components/desktop_notification.dart';
import 'package:memno/desktop/pages/search_overlay_pc.dart';
import 'package:memno/desktop/pages/settings_page_pc.dart';
import 'package:memno/desktop/components/desktop_dock.dart';
import 'package:memno/logic/functionality/code_gen.dart';
import 'package:memno/logic/functionality/note_list.dart';
import 'package:memno/logic/theme/app_colors.dart';
import 'package:provider/provider.dart';

/// Root shell of the desktop UI: hosts the page content area, the floating
/// [DesktopDock], the global keyboard shortcuts, and the search overlay.
///
/// The body is a [Stack]: a full-bleed content area (home grid, note page, or
/// settings, chosen by navigation state), a keyboard-shortcuts help button
/// pinned near the bottom-left corner, and the dock overlaid on top of
/// everything so it floats over the content instead of reserving space.
///
/// All navigation state lives in this widget: the selected dock destination
/// (indexed like [NoteFilter.values], with destination 3 meaning Settings),
/// the currently open note code, and the note code highlighted after a search
/// selection. The shortcuts themselves follow desktop conventions and are
/// also listed in the reference dialog opened by the help button.
class DesktopShell extends StatefulWidget {
  /// Creates the shell; navigation starts on the All Notes grid with no note
  /// open and nothing highlighted.
  const DesktopShell({super.key});

  @override
  State<DesktopShell> createState() => _DesktopShellState();
}

class _DesktopShellState extends State<DesktopShell> {
  /// Dock destination currently active, indexed like [NoteFilter.values]
  /// (0: all, 1: liked, 2: empty) with 3 as a pseudo-destination for Settings.
  int _selectedDestination = 0;

  /// Six-digit code of the note currently open in the detail page, or null
  /// when the grid or settings page is showing.
  int? _openedNoteCode;

  /// Note code to outline with the pulsing highlight in the grid, set when a
  /// [DesktopSearchOverlay] result is chosen; null means no highlight.
  int? _highlightedCode;

  // Navigation state is mutated only through the three helpers below so the
  // priority rules in _buildContent stay in sync with every entry point.

  /// Opens [code] in the note detail page and clears any search highlight.
  void _openNote(int code) {
    setState(() {
      _openedNoteCode = code;
      _highlightedCode = null;
    });
  }

  /// Closes the open note and returns the shell to the last grid destination.
  void _closeNote() {
    setState(() {
      _openedNoteCode = null;
    });
  }

  /// Switches the active dock destination to [index], closing any open note
  /// and clearing the search highlight so the new view starts clean.
  void _changeDestination(int index) {
    setState(() {
      _selectedDestination = index;
      _openedNoteCode = null;
      _highlightedCode = null;
    });
  }

  /// Opens the Spotlight-style [DesktopSearchOverlay] as a modal dialog with a
  /// transparent barrier so the underlying content stays visible.
  ///
  /// Choosing a result highlights that code, closes any open note, and forces
  /// the destination back to All Notes so the highlighted tile is guaranteed
  /// to exist in the filtered grid.
  void _openSearch() {
    showDialog(
      context: context,
      barrierColor: Colors.transparent,
      builder: (ctx) => DesktopSearchOverlay(
        onResultSelected: (code) {
          setState(() {
            _highlightedCode = code;
            _openedNoteCode = null;
            // Switch to All Notes to ensure the code is visible
            _selectedDestination = 0;
          });
        },
      ),
    );
  }

  /// Generates a fresh note code, opens it in the detail page, and shows a
  /// confirmation notification.
  ///
  /// Waits on [CodeGen.generateCode], guards against the widget being
  /// unmounted during that await, then switches to All Notes so the new page
  /// is findable in the grid. Side effects: navigation state change plus a
  /// [showDesktopNotification] toast.
  void _createNewPage() {
    final codeProvider = context.read<CodeGen>();
    codeProvider.generateCode().then((newCode) {
      if (!mounted) return;
      setState(() {
        _openedNoteCode = newCode;
        _selectedDestination = 0;
      });
      showDesktopNotification(context, 'New code page generated!');
    });
  }

  // Build Method

  @override
  Widget build(BuildContext context) {
    final colors = Provider.of<AppColors>(context);

    return Consumer<CodeGen>(
      builder: (context, codeGen, _) {
        if (!codeGen.isReady) {
          return Scaffold(
            backgroundColor: colors.bgClr,
            body: Center(child: CircularProgressIndicator(color: colors.accnt)),
          );
        }

        // The whole shell is keyboard reachable: CallbackShortcuts sits above
        // the content so bindings win before any focused child sees the key.
        return CallbackShortcuts(
          bindings: <ShortcutActivator, VoidCallback>{
            const SingleActivator(LogicalKeyboardKey.keyN, control: true):
                _createNewPage,

            const SingleActivator(LogicalKeyboardKey.keyF, control: true):
                _openSearch,

            // Comma is the conventional settings key on desktop platforms.
            const SingleActivator(LogicalKeyboardKey.comma, control: true): () {
              _changeDestination(3);
            },

            // Digits map positionally onto [NoteFilter.values]; Settings has
            // no digit shortcut and is reached via Ctrl+, or the dock.
            const SingleActivator(
              LogicalKeyboardKey.digit1,
              control: true,
            ): () {
              _changeDestination(0);
            },
            const SingleActivator(
              LogicalKeyboardKey.digit2,
              control: true,
            ): () {
              _changeDestination(1);
            },
            const SingleActivator(
              LogicalKeyboardKey.digit3,
              control: true,
            ): () {
              _changeDestination(2);
            },

            // Escape backs out of an open note only; with no note open it is
            // left untouched so the focused widget keeps handling it.
            const SingleActivator(LogicalKeyboardKey.escape): () {
              if (_openedNoteCode != null) {
                _closeNote();
              }
            },
          },
          child: Focus(
            autofocus: true,
            child: Scaffold(
              body: Stack(
                children: [
                  Positioned.fill(child: _buildContent(colors)),

                  // Sits in the corner rather than inside the dock so it stays
                  // discoverable even while the dock is collapsed to a pill.
                  Positioned(
                    bottom: 24,
                    left: 24,
                    child: IconButton(
                      tooltip: 'Keyboard Shortcuts',
                      icon: Icon(
                        Icons.keyboard_rounded,
                        color: colors.textClr.withValues(alpha: 0.5),
                        size: 20,
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: colors.box,
                        hoverColor: colors.pill.withValues(alpha: 0.2),
                        padding: const EdgeInsets.all(8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => _showShortcutsDialog(context, colors),
                    ),
                  ),

                  // Overlay on top of the content so it can float and
                  // auto-collapse without reserving layout space.
                  Positioned.fill(
                    child: DesktopDock(
                      selectedIndex: _selectedDestination,
                      onDestinationChanged: _changeDestination,
                      onSearchTap: _openSearch,
                      onNewPage: _createNewPage,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildContent(AppColors colors) {
    // Note page takes priority
    if (_openedNoteCode != null) {
      return DesktopNotePage(
        key: ValueKey(_openedNoteCode),
        code: _openedNoteCode!,
        onBack: _closeNote,
      );
    }

    // Settings page
    if (_selectedDestination == 3) {
      return const DesktopSettingsPage();
    }

    // Home grid (All / Liked / Empty)
    return DesktopHomePage(
      key: ValueKey(_selectedDestination),
      filter: NoteFilter.values[_selectedDestination],
      onCodeSelected: _openNote,
      highlightedCode: _highlightedCode,
    );
  }

  void _showShortcutsDialog(BuildContext context, AppColors colors) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.box,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Icon(Icons.keyboard_rounded, color: colors.accnt),
            const SizedBox(width: 12),
            Text(
              'Keyboard Shortcuts',
              style: TextStyle(
                fontFamily: 'GoogleSans',
                fontWeight: FontWeight.bold,
                color: colors.textClr,
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _ShortcutGroupHeader(title: 'Global Navigation'),
                const SizedBox(height: 8),
                const _ShortcutRow('Ctrl + N', 'Create new code page'),
                const _ShortcutRow('Ctrl + F', 'Open Spotlight search'),
                const _ShortcutRow('Ctrl + ,', 'Open settings page'),
                const _ShortcutRow('Ctrl + 1', 'Filter by "All Notes"'),
                const _ShortcutRow('Ctrl + 2', 'Filter by "Liked Notes"'),
                const _ShortcutRow('Ctrl + 3', 'Filter by "Empty Notes"'),
                const _ShortcutRow('Escape', 'Go back / Close note'),
                const SizedBox(height: 20),
                _ShortcutGroupHeader(
                  title: 'Note Editor (When editing a note)',
                ),
                const SizedBox(height: 8),
                const _ShortcutRow('Ctrl + Enter', 'Save / Confirm entry'),
                const _ShortcutRow('Escape', 'Cancel editing'),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            style: TextButton.styleFrom(
              foregroundColor: colors.textClr,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Close',
              style: TextStyle(
                fontFamily: 'GoogleSans',
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Accent-colored group header inside the keyboard-shortcuts dialog.
class _ShortcutGroupHeader extends StatelessWidget {
  const _ShortcutGroupHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final colors = Provider.of<AppColors>(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontFamily: 'GoogleSans',
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: colors.accnt,
          ),
        ),
        const Divider(height: 16, thickness: 1),
      ],
    );
  }
}

/// One keyboard-shortcut row: pill-style key badges on the left, description
/// on the right.
class _ShortcutRow extends StatelessWidget {
  const _ShortcutRow(this.keys, this.description);

  final String keys;
  final String description;

  @override
  Widget build(BuildContext context) {
    final colors = Provider.of<AppColors>(context);
    final parts = keys.split(' + ');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        spacing: 12,
        children: [
          Expanded(
            flex: 2,
            child: Row(
              children: [
                for (var i = 0; i < parts.length; i++) ...[
                  _KeyBadge(keyLabel: parts[i]),
                  if (i != parts.length - 1)
                    Text(
                      ' + ',
                      style: TextStyle(
                        fontFamily: 'GoogleSans',
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: colors.textClr.withValues(alpha: 0.6),
                      ),
                    ),
                ],
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              description,
              style: TextStyle(
                fontFamily: 'GoogleSans',
                fontSize: 14,
                color: colors.textClr.withValues(alpha: 0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A single key rendered as a small bordered pill.
class _KeyBadge extends StatelessWidget {
  const _KeyBadge({required this.keyLabel});

  final String keyLabel;

  @override
  Widget build(BuildContext context) {
    final colors = Provider.of<AppColors>(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colors.pill.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: colors.pill.withValues(alpha: 0.6), width: 1),
      ),
      child: Text(
        keyLabel,
        style: TextStyle(
          fontFamily: 'GoogleSans',
          fontWeight: FontWeight.bold,
          fontSize: 12,
          color: colors.textClr,
        ),
      ),
    );
  }
}
