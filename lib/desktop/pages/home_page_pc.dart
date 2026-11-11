import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:memno/desktop/components/desktop_notification.dart';
import 'package:memno/desktop/components/file_icon_tile.dart';
import 'package:memno/logic/functionality/code_gen.dart';
import 'package:memno/logic/functionality/note_list.dart';
import 'package:memno/logic/functionality/note_operations.dart';
import 'package:memno/logic/functionality/preview_map.dart';
import 'package:memno/logic/theme/app_colors.dart';
import 'package:provider/provider.dart';

/// Represents the desktop home page interface.
/// Renders a file-explorer style grid layout containing document icons for each note.
/// Supports filtering notes by category (All, Liked, or Empty) and handles note sorting
/// (most recently created/edited notes first), deletion, and pulsing search highlights.
///
/// File-explorer-style grid view for the desktop home page.
///
/// Accepts a [filter] indicating the current category filter, renders a header
/// with the filter name and count badge, and displays note pages as grid tiles.
class DesktopHomePage extends StatefulWidget {
  /// Current category filter (All Notes, Liked Notes, or Empty Notes).
  final NoteFilter filter;

  /// Callback when a file icon is tapped, passing the note code.
  final ValueChanged<int>? onCodeSelected;

  /// Optional code to visually highlight (e.g. from search result navigation).
  final int? highlightedCode;

  const DesktopHomePage({
    super.key,
    required this.filter,
    this.onCodeSelected,
    this.highlightedCode,
  });

  @override
  State<DesktopHomePage> createState() => _DesktopHomePageState();
}

class _DesktopHomePageState extends State<DesktopHomePage> {
  // Filtering and Sorting

  List<int> _filteredCodes(CodeGen codeGen) {
    return filterAndSortNotes(codeGen, filter: widget.filter);
  }

  String get _filterTitle {
    switch (widget.filter) {
      case NoteFilter.liked:
        return 'Liked Notes';
      case NoteFilter.empty:
        return 'Empty Notes';
      case NoteFilter.all:
        return 'All Notes';
    }
  }

  String get _emptyMessage {
    switch (widget.filter) {
      case NoteFilter.liked:
        return 'No liked codes yet';
      case NoteFilter.empty:
        return 'No empty codes yet';
      case NoteFilter.all:
        return "It's so empty here!\nClick the + button to generate a\nNew Code";
    }
  }

  // Build Method

  @override
  Widget build(BuildContext context) {
    final colors = Provider.of<AppColors>(context);

    return Consumer<CodeGen>(
      builder: (context, codeGen, _) {
        if (!codeGen.isReady) {
          return Center(child: CircularProgressIndicator(color: colors.accnt));
        }

        final codes = _filteredCodes(codeGen);

        return _buildContent(colors: colors, codeGen: codeGen, codes: codes);
      },
    );
  }

  Widget _buildContent({
    required AppColors colors,
    required CodeGen codeGen,
    required List<int> codes,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        //  Header Bar
        _HomeHeader(title: _filterTitle, count: codes.length),

        //  Grid / Empty State
        Expanded(
          child: codes.isEmpty
              ? _EmptyState(message: _emptyMessage)
              : GridView.builder(
                  padding: const EdgeInsets.all(24),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 160,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: codes.length,
                  itemBuilder: (context, index) {
                    final code = codes[index];
                    final isHighlighted = widget.highlightedCode == code;

                    return _MaybeHighlighted(
                      isHighlighted: isHighlighted,
                      accentColor: colors.accnt,
                      child: FileIconTile(
                        code: code,
                        title: codeGen.getHeadForCode(code),
                        entryCount: codeGen.getLinkListLength(code),
                        isLiked: codeGen.getLikeForCode(code),
                        onTap: () => widget.onCodeSelected?.call(code),
                        onDelete: () => _confirmDelete(context, codeGen, code),
                        onLike: () {
                          codeGen.toggleLike(code);
                          final isLikedNow = codeGen.getLikeForCode(code);
                          showDesktopNotification(
                            context,
                            isLikedNow
                                ? 'Added note #$code to Liked Notes'
                                : 'Removed note #$code from Liked Notes',
                          );
                        },
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _confirmDelete(BuildContext context, CodeGen codeGen, int code) {
    final colors = Provider.of<AppColors>(context, listen: false);
    final entryCount = codeGen.getLinkListLength(code);

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: colors.box,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: colors.pill.withValues(alpha: 0.3)),
          ),
          title: Text(
            'Delete Note',
            style: TextStyle(
              fontFamily: 'GoogleSans',
              fontWeight: FontWeight.bold,
              color: colors.textClr,
            ),
          ),
          content: Text(
            'Are you sure you want to delete note page #$code?\nThis page contains $entryCount entries and cannot be undone.',
            style: TextStyle(
              fontFamily: 'GoogleSans',
              color: colors.textClr.withValues(alpha: 0.8),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(
                  fontFamily: 'GoogleSans',
                  color: colors.textClr.withValues(alpha: 0.6),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(ctx).pop();

                // Perform deletion including cleaning up previews
                final previewMap = context.read<PreviewMap>();
                deleteNoteWithPreviews(codeGen, previewMap, code);

                showDesktopNotification(
                  context,
                  'Note page #$code has been deleted.',
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.dangerClr,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Delete',
                style: TextStyle(
                  fontFamily: 'GoogleSans',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// Pulsing Highlight Wrapper

/// Home-page header row: filter title with a rounded count badge.
class _HomeHeader extends StatelessWidget {
  const _HomeHeader({required this.title, required this.count});

  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    final colors = Provider.of<AppColors>(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 8),
      child: Row(
        children: [
          Text(
            title,
            style: TextStyle(
              fontFamily: 'GoogleSans',
              fontWeight: FontWeight.bold,
              fontSize: 28,
              color: colors.textClr,
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: colors.pill.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                fontFamily: 'GoogleSans',
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: colors.textClr,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Centered empty-state with the lottie animation and a filter-specific
/// message.
class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = Provider.of<AppColors>(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          LottieBuilder.asset('assets/empty.lottie', height: 180),
          Text(
            message,
            style: TextStyle(
              fontFamily: 'GoogleSans',
              fontSize: 16,
              color: colors.textClr,
              height: 2,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Wraps a child with a pulsing border animation when [isHighlighted] is true.
class _MaybeHighlighted extends StatefulWidget {
  final bool isHighlighted;
  final Color accentColor;
  final Widget child;

  const _MaybeHighlighted({
    required this.isHighlighted,
    required this.accentColor,
    required this.child,
  });

  @override
  State<_MaybeHighlighted> createState() => _MaybeHighlightedState();
}

class _MaybeHighlightedState extends State<_MaybeHighlighted>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _opacity = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    if (widget.isHighlighted) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant _MaybeHighlighted oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isHighlighted && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.isHighlighted && _controller.isAnimating) {
      _controller.stop();
      _controller.reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isHighlighted) return widget.child;

    return AnimatedBuilder(
      animation: _opacity,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: widget.accentColor.withValues(alpha: _opacity.value),
              width: 2,
            ),
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
