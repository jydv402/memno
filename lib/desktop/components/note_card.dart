import 'dart:io' show File;

import 'package:flutter/material.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart';
import 'package:flutter_link_previewer/flutter_link_previewer.dart';
import 'package:linkfy_text/linkfy_text.dart';
import 'package:memno/logic/functionality/link_utils.dart';
import 'package:memno/logic/functionality/preview_map.dart';
import 'package:memno/logic/theme/app_colors.dart';
import 'package:memno/logic/theme/app_settings.dart';
import 'package:provider/provider.dart';

/// A card widget for displaying a single note entry or link in the desktop
/// masonry grid layout.
///
/// Renders differently for URLs (blue linkified text) vs plain text (large bold
/// typography). An action bar with Edit, Copy, Share, and Delete buttons is
/// revealed on hover.
class NoteCard extends StatefulWidget {
  const NoteCard({
    super.key,
    required this.index,
    required this.content,
    required this.isUrl,
    required this.onEdit,
    required this.onCopy,
    required this.onShare,
    required this.onDelete,
  });

  /// 1-based index of this entry within the note page.
  final int index;

  /// Text content or URL string.
  final String content;

  /// Whether [content] is a URL (renders in linkified blue style).
  final bool isUrl;

  /// Called when the user taps the Edit action.
  final VoidCallback onEdit;

  /// Called when the user taps the Copy action.
  final VoidCallback onCopy;

  /// Called when the user taps the Share action.
  final VoidCallback onShare;

  /// Called when the user taps the Delete action.
  final VoidCallback onDelete;

  @override
  State<NoteCard> createState() => _NoteCardState();
}

class _NoteCardState extends State<NoteCard> {
  bool _isHovered = false;

  /// First valid URL inside [NoteCard.content], or null for plain text.
  String? _firstLink;

  @override
  void initState() {
    super.initState();
    _syncPreview();
  }

  @override
  void didUpdateWidget(covariant NoteCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.content != widget.content) {
      _syncPreview();
    }
  }

  /// Ensures the cached preview for this card's link is loaded into the
  /// in-memory cache. Runs once per content change from the widget lifecycle —
  /// never inside build() or a Selector, which must stay pure.
  void _syncPreview() {
    _firstLink = LinkUtils.extractFirstLink(widget.content);
    final firstLink = _firstLink;
    if (firstLink == null) return;
    final previewMap = context.read<PreviewMap>();
    final saveImagesLocally = context.read<AppSettings>().saveImagesLocally;
    previewMap.loadPreviewSync(firstLink, saveLocally: saveImagesLocally);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Provider.of<AppColors>(context);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: colors.box,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: _isHovered ? 0.12 : 0.04),
              blurRadius: _isHovered ? 12 : 4,
              offset: Offset(0, _isHovered ? 4 : 1),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Index badge
              _buildIndexBadge(colors),
              const SizedBox(height: 12),

              // Content section
              _buildContent(colors),

              // Action bar (hover-only)
              AnimatedSize(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                alignment: Alignment.topCenter,
                child: _isHovered
                    ? _buildActionBar(colors)
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIndexBadge(AppColors colors) {
    return Container(
      width: 28,
      height: 28,
      decoration: const BoxDecoration(
        color: Colors.black,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        '#${widget.index}',
        style: const TextStyle(
          fontFamily: 'GoogleSans',
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildContent(AppColors colors) {
    if (widget.isUrl) {
      final firstLink = _firstLink;
      if (firstLink == null) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            widget.content,
            style: TextStyle(
              fontFamily: 'GoogleSans',
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: colors.textClr,
              height: 1.2,
            ),
          ),
        );
      }
      final previewMap = Provider.of<PreviewMap>(context, listen: false);
      final saveImagesLocally = Provider.of<AppSettings>(
        context,
        listen: false,
      ).saveImagesLocally;
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            LinkifyText(
              widget.content,
              onTap: (link) {
                if (link.value != null) {
                  LinkUtils.openExternalUrl(link.value!);
                }
              },
              linkStyle: TextStyle(
                color: colors.linkClr,
                fontFamily: 'GoogleSans',
                fontSize: 13,
                decoration: TextDecoration.underline,
                decorationColor: colors.linkClr,
              ),
              textStyle: TextStyle(
                color: colors.textClr,
                fontFamily: 'GoogleSans',
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 8),
            // Show the link preview (rebuild isolated)
            Selector<PreviewMap, LinkPreviewData?>(
              selector: (context, pm) => pm.cache[firstLink],
              builder: (context, previewData, child) {
                return LinkPreview(
                  requestTimeout: const Duration(seconds: 10),
                  minWidth: 280,
                  gap: 12,
                  backgroundColor: Colors.transparent,
                  sideBorderColor: Colors.transparent,
                  imageBuilder: (image) {
                    final isSquare =
                        previewData?.image?.height == previewData?.image?.width;
                    return Container(
                      decoration: BoxDecoration(
                        borderRadius: isSquare
                            ? BorderRadius.circular(10)
                            : BorderRadius.circular(16),
                        image: DecorationImage(
                          image: previewMap.localImagePaths[firstLink] != null
                              ? FileImage(
                                  File(previewMap.localImagePaths[firstLink]!),
                                )
                              : NetworkImage(image) as ImageProvider,
                          fit: BoxFit.cover,
                        ),
                      ),
                    );
                  },
                  outsidePadding: const EdgeInsets.symmetric(vertical: 4),
                  enableAnimation: true,
                  titleTextStyle: TextStyle(
                    color: colors.textClr,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    fontFamily: 'GoogleSans',
                  ),
                  descriptionTextStyle: TextStyle(
                    color: colors.textClr.withValues(alpha: 0.7),
                    fontFamily: 'GoogleSans',
                    fontSize: 12,
                  ),
                  onLinkPreviewDataFetched: (data) async {
                    await previewMap.savePreview(
                      link: firstLink,
                      data: data,
                      saveLocally: saveImagesLocally,
                    );
                  },
                  linkPreviewData: previewData,
                  text: firstLink,
                );
              },
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        widget.content,
        style: TextStyle(
          fontFamily: 'GoogleSans',
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: colors.textClr,
          height: 1.2,
        ),
      ),
    );
  }

  Widget _buildActionBar(AppColors colors) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _ActionPill(
              icon: Icons.edit_outlined,
              label: 'Edit',
              onTap: widget.onEdit,
              colors: colors,
            ),
            const SizedBox(width: 6),
            _ActionPill(
              icon: Icons.copy_outlined,
              label: 'Copy',
              onTap: widget.onCopy,
              colors: colors,
            ),
            const SizedBox(width: 6),
            _ActionPill(
              icon: Icons.share_outlined,
              label: 'Share',
              onTap: widget.onShare,
              colors: colors,
            ),
            const SizedBox(width: 6),
            _ActionPill(
              icon: Icons.delete_outline_rounded,
              label: 'Delete',
              onTap: widget.onDelete,
              colors: colors,
              isDestructive: true,
            ),
          ],
        ),
      ),
    );
  }
}

/// A small rounded pill button with icon + label for the [NoteCard] action bar.
class _ActionPill extends StatefulWidget {
  const _ActionPill({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.colors,
    this.isDestructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final AppColors colors;
  final bool isDestructive;

  @override
  State<_ActionPill> createState() => _ActionPillState();
}

class _ActionPillState extends State<_ActionPill> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final fgColor = widget.isDestructive
        ? widget.colors.dangerClr
        : widget.colors.textClr;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: _isHovered
                ? widget.colors.pill
                : widget.colors.pill.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, size: 14, color: fgColor),
              const SizedBox(width: 4),
              Text(
                widget.label,
                style: TextStyle(
                  fontFamily: 'GoogleSans',
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: fgColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
