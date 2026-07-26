import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:memno/logic/functionality/code_gen.dart';
import 'package:memno/logic/theme/app_colors.dart';
import 'package:provider/provider.dart';

/// Implements the spotlight-style floating search overlay for the desktop UI.
/// Renders a blurred overlay with an interactive search input at the bottom and search results above it.
/// Supports keyboard navigation (up/down arrow keys, enter to select, escape to close),
/// debounced search queries, and shows search highlights based on notes' titles or codes.
///
/// A Spotlight-style floating search overlay.
///
/// Displays a blurred backdrop with a bottom-anchored search bar and a results
/// panel that appears above it. Supports keyboard navigation (Esc, Enter,
/// Arrow Up/Down).
class DesktopSearchOverlay extends StatefulWidget {
  /// Called when a search result is selected, passing the note code.
  final ValueChanged<int> onResultSelected;

  const DesktopSearchOverlay({super.key, required this.onResultSelected});

  @override
  State<DesktopSearchOverlay> createState() => _DesktopSearchOverlayState();
}

class _DesktopSearchOverlayState extends State<DesktopSearchOverlay>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  Timer? _debounceTimer;

  List<int> _results = [];
  int _highlightedIndex = -1;

  late final AnimationController _slideController;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );

    _slideController.forward();

    // Autofocus the search field after frame renders.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _slideController.dispose();
    super.dispose();
  }

  // Search Logic

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _performSearch(query);
    });
  }

  void _performSearch(String query) {
    final codeGen = context.read<CodeGen>();
    if (query.isEmpty) {
      setState(() {
        _results = [];
        _highlightedIndex = -1;
      });
      return;
    }

    final queryLower = query.toLowerCase();
    final filtered = codeGen.codeList.where((code) {
      final codeString = code.toString();
      final heading = codeGen.getHeadForCode(code).toLowerCase();
      return codeString.contains(queryLower) || heading.contains(queryLower);
    }).toList();

    // Sort by date, most recent first (Schwartzian transform)
    final parsedDates = <int, DateTime>{};
    for (final code in filtered) {
      final dateStr = codeGen.getDateForCode(code);
      parsedDates[code] =
          DateTime.tryParse(dateStr) ?? DateTime.fromMillisecondsSinceEpoch(0);
    }
    filtered.sort((a, b) => parsedDates[b]!.compareTo(parsedDates[a]!));

    setState(() {
      _results = filtered;
      _highlightedIndex = filtered.isNotEmpty ? 0 : -1;
    });
  }

  void _dismiss() {
    _slideController.reverse().then((_) {
      if (mounted) Navigator.of(context).pop();
    });
  }

  void _selectResult(int code) {
    widget.onResultSelected(code);
    Navigator.of(context).pop();
  }

  // Keyboard Handling

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }

    if (event.logicalKey == LogicalKeyboardKey.escape) {
      _dismiss();
      return KeyEventResult.handled;
    }

    if (event.logicalKey == LogicalKeyboardKey.enter) {
      if (_highlightedIndex >= 0 && _highlightedIndex < _results.length) {
        _selectResult(_results[_highlightedIndex]);
      }
      return KeyEventResult.handled;
    }

    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      if (_results.isNotEmpty) {
        setState(() {
          _highlightedIndex = (_highlightedIndex + 1) % _results.length;
        });
      }
      return KeyEventResult.handled;
    }

    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      if (_results.isNotEmpty) {
        setState(() {
          _highlightedIndex =
              (_highlightedIndex - 1 + _results.length) % _results.length;
        });
      }
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  // Build Method

  @override
  Widget build(BuildContext context) {
    final colors = Provider.of<AppColors>(context);

    return Material(
      color: Colors.transparent,
      child: Focus(
        onKeyEvent: _handleKeyEvent,
        child: Stack(
          children: [
            //  Blurred Backdrop
            Positioned.fill(
              child: GestureDetector(
                onTap: _dismiss,
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: Container(color: Colors.black.withValues(alpha: 0.3)),
                ),
              ),
            ),

            //  Search Bar + Results
            Positioned(
              left: 0,
              right: 0,
              bottom: 48,
              child: SlideTransition(
                position: _slideAnimation,
                child: Center(
                  child: SizedBox(
                    width: 560,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Results panel (above search bar)
                        if (_results.isNotEmpty) _buildResultsPanel(colors),

                        // Search bar
                        _buildSearchBar(colors),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Search Bar Widget

  Widget _buildSearchBar(AppColors colors) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: colors.box,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: colors.pill.withValues(alpha: 0.3)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Icon(
            Icons.search_rounded,
            color: colors.iconClr.withValues(alpha: 0.5),
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              onChanged: _onSearchChanged,
              style: TextStyle(
                fontFamily: 'GoogleSans',
                fontSize: 16,
                color: colors.textClr,
              ),
              decoration: InputDecoration(
                hintText: 'Search notes…',
                hintStyle: TextStyle(
                  fontFamily: 'GoogleSans',
                  fontSize: 16,
                  color: colors.textClr.withValues(alpha: 0.4),
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: Icon(Icons.close_rounded, color: colors.iconClr, size: 20),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () {
                _searchController.clear();
                _performSearch('');
              },
            ),
        ],
      ),
    );
  }

  // Results Panel Widget

  Widget _buildResultsPanel(AppColors colors) {
    final codeGen = context.read<CodeGen>();

    return Container(
      constraints: const BoxConstraints(maxHeight: 400),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: colors.box,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        border: Border.all(color: colors.pill.withValues(alpha: 0.3)),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        child: ListView.builder(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: _results.length,
          itemBuilder: (context, index) {
            final code = _results[index];
            final heading = codeGen.getHeadForCode(code);
            final entryCount = codeGen.getLinkListLength(code);
            final isLiked = codeGen.getLikeForCode(code);
            final isHighlighted = index == _highlightedIndex;

            return Material(
              color: isHighlighted
                  ? colors.accnt.withValues(alpha: 0.15)
                  : Colors.transparent,
              child: ListTile(
                leading: Icon(
                  Icons.folder_rounded,
                  color: colors.iconClr.withValues(alpha: 0.7),
                  size: 22,
                ),
                title: Text(
                  heading,
                  style: TextStyle(
                    fontFamily: 'GoogleSans',
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: colors.textClr,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  '#$code · $entryCount ${entryCount == 1 ? 'entry' : 'entries'}',
                  style: TextStyle(
                    fontFamily: 'GoogleSans',
                    fontSize: 12,
                    color: colors.textClr.withValues(alpha: 0.6),
                  ),
                ),
                trailing: isLiked
                    ? Icon(
                        Icons.favorite_rounded,
                        color: colors.accnt,
                        size: 18,
                      )
                    : null,
                hoverColor: colors.pill.withValues(alpha: 0.3),
                onTap: () => _selectResult(code),
              ),
            );
          },
        ),
      ),
    );
  }
}
