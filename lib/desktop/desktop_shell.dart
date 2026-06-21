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

/// Serves as the main entry point and shell layout for the desktop interface.
/// Manages the overall page scaffold, coordinates hotkeys/keyboard shortcuts,
/// maintains navigation state across All, Liked, Empty, and Settings views,
/// handles spotlight search modal display, and coordinates notifications.
///
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
  /// Index of the currently active navigation destination (All, Liked, Empty, Settings).
  int _selectedDestination = 0;

  /// When non-null, shows the note page instead of the grid.
  int? _openedNoteCode;

  /// Code to highlight in the grid (from search result).
  int? _highlightedCode;

  // Navigation Helpers

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
                  // Content Area
                  Positioned.fill(child: _buildContent(colors)),

                  // Keyboard Shortcuts Help Button
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

                  // Floating Dock
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
                _buildShortcutGroupHeader('Global Navigation', colors),
                const SizedBox(height: 8),
                _buildShortcutRow('Ctrl + N', 'Create new code page', colors),
                _buildShortcutRow('Ctrl + F', 'Open Spotlight search', colors),
                _buildShortcutRow('Ctrl + ,', 'Open settings page', colors),
                _buildShortcutRow('Ctrl + 1', 'Filter by "All Notes"', colors),
                _buildShortcutRow(
                  'Ctrl + 2',
                  'Filter by "Liked Notes"',
                  colors,
                ),
                _buildShortcutRow(
                  'Ctrl + 3',
                  'Filter by "Empty Notes"',
                  colors,
                ),
                _buildShortcutRow('Escape', 'Go back / Close note', colors),
                const SizedBox(height: 20),
                _buildShortcutGroupHeader(
                  'Note Editor (When editing a note)',
                  colors,
                ),
                const SizedBox(height: 8),
                _buildShortcutRow(
                  'Ctrl + Enter',
                  'Save / Confirm entry',
                  colors,
                ),
                _buildShortcutRow('Escape', 'Cancel editing', colors),
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

  Column _buildShortcutGroupHeader(String title, AppColors colors) {
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

  Padding _buildShortcutRow(String keys, String description, AppColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        spacing: 12,
        children: [
          Expanded(
            flex: 2,
            child: Row(
              children: keys.split(' + ').map((key) {
                final isLast = key == keys.split(' + ').last;
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: colors.pill.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: colors.pill.withValues(alpha: 0.6),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        key,
                        style: TextStyle(
                          fontFamily: 'GoogleSans',
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: colors.textClr,
                        ),
                      ),
                    ),
                    if (!isLast)
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
                );
              }).toList(),
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
