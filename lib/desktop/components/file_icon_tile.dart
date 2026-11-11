import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:memno/logic/theme/app_colors.dart';
import 'package:provider/provider.dart';

/// A file-explorer-style icon card representing a single note page.
///
/// Displays the 6-digit code on a document icon area, with a title below.
/// On hover, the card scales up and tilts slightly to simulate being picked up.
class FileIconTile extends StatefulWidget {
  const FileIconTile({
    super.key,
    required this.code,
    required this.title,
    required this.entryCount,
    required this.isLiked,
    required this.onTap,
    this.onDelete,
    this.onLike,
  });

  /// 6-digit note page code.
  final int code;

  /// Display title of the note page.
  final String title;

  /// Number of entries/links in the note page.
  final int entryCount;

  /// Whether this note page is liked/favorited.
  final bool isLiked;

  /// Callback invoked when the tile is tapped.
  final VoidCallback onTap;

  /// Optional callback invoked when right-click delete is selected.
  final VoidCallback? onDelete;

  final VoidCallback? onLike;

  @override
  State<FileIconTile> createState() => _FileIconTileState();
}

class _FileIconTileState extends State<FileIconTile> {
  bool _isHovered = false;

  void _showContextMenu(BuildContext context, TapDownDetails details) {
    final colors = Provider.of<AppColors>(context, listen: false);

    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        details.globalPosition.dx,
        details.globalPosition.dy,
        details.globalPosition.dx,
        details.globalPosition.dy,
      ),
      color: colors.box,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colors.pill.withValues(alpha: 0.3)),
      ),
      items: [
        if (widget.onLike != null)
          PopupMenuItem(
            value: 'like',
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: _ContextMenuItem(
                icon: widget.isLiked
                    ? Icons.favorite_border_rounded
                    : Icons.favorite_rounded,
                label: widget.isLiked ? 'Unlike Note' : 'Like Note',
                color: widget.isLiked ? colors.textClr : colors.likeClr,
              ),
            ),
          ),
        if (widget.onDelete != null)
          PopupMenuItem(
            value: 'delete',
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: _ContextMenuItem(
                icon: Icons.delete_outline_rounded,
                label: 'Delete Note',
                color: colors.dangerClr,
              ),
            ),
          ),
      ],
    ).then((value) {
      if (value == 'delete') {
        widget.onDelete?.call();
      }
      if (value == 'like') {
        widget.onLike?.call();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Provider.of<AppColors>(context);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        onSecondaryTapDown: (widget.onDelete != null || widget.onLike != null)
            ? (details) => _showContextMenu(context, details)
            : null,
        child: AnimatedScale(
          scale: _isHovered ? 1.05 : 1.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            width: 140,
            height: 160,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateZ(_isHovered ? -2 * math.pi / 180 : 0),
            transformAlignment: Alignment.center,
            decoration: BoxDecoration(
              color: colors.box,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: _isHovered ? 0.15 : 0.06,
                  ),
                  blurRadius: _isHovered ? 16 : 6,
                  offset: Offset(0, _isHovered ? 8 : 2),
                ),
              ],
            ),
            child: Column(
              children: [
                // Document icon area
                Expanded(child: _DocumentArea(tile: widget)),
                // Title area
                _TitleArea(tile: widget),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The document-icon half of a [FileIconTile]: code text, like overlay, and
/// entry-count badge.
class _DocumentArea extends StatelessWidget {
  const _DocumentArea({required this.tile});

  final FileIconTile tile;

  @override
  Widget build(BuildContext context) {
    final colors = Provider.of<AppColors>(context);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colors.pill,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Stack(
        children: [
          // Centered code text
          Center(
            child: Text(
              '#${tile.code}',
              style: TextStyle(
                fontFamily: 'GoogleSans',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: colors.textClr.withValues(alpha: 0.7),
                letterSpacing: 0.5,
              ),
            ),
          ),

          // Heart icon overlay (top-right) if liked
          if (tile.isLiked)
            Positioned(
              top: 8,
              right: 8,
              child: Icon(
                Icons.favorite_rounded,
                size: 16,
                color: colors.likeClr,
              ),
            ),

          // Entry count badge (bottom-right)
          Positioned(
            bottom: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: colors.box.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${tile.entryCount}',
                style: TextStyle(
                  fontFamily: 'GoogleSans',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: colors.textClr,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The title strip below the document area of a [FileIconTile].
class _TitleArea extends StatelessWidget {
  const _TitleArea({required this.tile});

  final FileIconTile tile;

  @override
  Widget build(BuildContext context) {
    final colors = Provider.of<AppColors>(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: colors.box,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
      ),
      child: Text(
        tile.title,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontFamily: 'GoogleSans',
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: colors.textClr,
          height: 1.3,
        ),
      ),
    );
  }
}

/// Icon + label row used inside the right-click context menu.
class _ContextMenuItem extends StatelessWidget {
  const _ContextMenuItem({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = Provider.of<AppColors>(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'GoogleSans',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: colors.textClr,
          ),
        ),
      ],
    );
  }
}
