import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:memno/desktop/pages/home_page_pc.dart';
import 'package:memno/desktop/pages/note_page_pc.dart';
import 'package:memno/desktop/components/desktop_notification.dart';
import 'package:memno/desktop/pages/search_overlay_pc.dart';
import 'package:memno/desktop/pages/settings_page_pc.dart';
import 'package:memno/desktop/components/desktop_dock.dart';
import 'package:memno/logic/functionality/code_gen.dart';
import 'package:memno/logic/theme/app_colors.dart';
import 'package:provider/provider.dart';

/// Root scaffold for the desktop UI.
///
/// Combines a [DesktopSidebar] with an [Expanded] content area that displays
/// the home grid, note detail page, or settings depending on navigation state.
/// Provides keyboard shortcuts and auto-collapses the sidebar at narrow widths.
class DesktopShell extends StatefulWidget {
  const DesktopShell({super.key});

  @override
  State<DesktopShell> createState() => _DesktopShellState();
}

class _DesktopShellState extends State<DesktopShell> {
  /// 0 = All Notes, 1 = Liked, 2 = Empty, 3 = Settings
  int _selectedDestination = 0;

  /// When non-null, shows the note page instead of the grid.
  int? _openedNoteCode;

  /// Code to highlight in the grid (from search result).
  int? _highlightedCode;

  // ───────────────────────────────────────────────────────────
  //  Navigation Helpers
  // ───────────────────────────────────────────────────────────

  void _openNote(int code) {
    setState(() {
      _openedNoteCode = code;
      _highlightedCode = null;
    });
  }

  void _closeNote() {
    setState(() {
      _openedNoteCode = null;
    });
  }

  void _changeDestination(int index) {
    setState(() {
      _selectedDestination = index;
      _openedNoteCode = null;
      _highlightedCode = null;
    });
  }

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

  void _createNewPage() {
    final codeProvider = context.read<CodeGen>();
    codeProvider.generateCode().then((_) {
      if (!mounted) return;
      if (codeProvider.codeList.isNotEmpty) {
        final newCode = codeProvider.codeList.last;
        setState(() {
          _openedNoteCode = newCode;
          _selectedDestination = 0;
        });
        showDesktopNotification(context, 'New code page generated!');
      }
    });
  }

  // ───────────────────────────────────────────────────────────
  //  Build
  // ───────────────────────────────────────────────────────────

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

        return CallbackShortcuts(
          bindings: <ShortcutActivator, VoidCallback>{
            // Ctrl+N: New page
            const SingleActivator(LogicalKeyboardKey.keyN, control: true):
                _createNewPage,

            // Ctrl+F: Search
            const SingleActivator(LogicalKeyboardKey.keyF, control: true):
                _openSearch,

            // Ctrl+,: Settings
            const SingleActivator(LogicalKeyboardKey.comma, control: true): () {
              _changeDestination(3);
            },

            // Ctrl+1/2/3: Switch filter
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

            // Escape: Go back
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
                  // ── Content Area ──
                  Positioned.fill(
                    child: _buildContent(colors),
                  ),

                  // ── Floating Dock ──
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
      filterIndex: _selectedDestination,
      onCodeSelected: _openNote,
      highlightedCode: _highlightedCode,
    );
  }
}
