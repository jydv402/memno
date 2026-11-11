import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart';
import 'package:flutter_link_previewer/flutter_link_previewer.dart';
import 'package:memno/logic/functionality/code_gen.dart';
import 'package:memno/logic/functionality/link_utils.dart';
import 'package:memno/logic/functionality/note_operations.dart';
import 'package:memno/logic/functionality/preview_map.dart';
import 'package:memno/logic/theme/app_colors.dart';
import 'package:memno/logic/theme/app_settings.dart';
import 'package:memno/mobile/components/pill_button.dart';
import 'package:memno/mobile/components/show_toast.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

class InnerPageTile extends StatefulWidget {
  const InnerPageTile({
    super.key,
    required this.code,
    required this.index,
    required this.value,
    required this.isEmbedded,
    required this.onEdit,
  });

  final int code;
  final int index;
  final String value;
  final bool isEmbedded;
  final VoidCallback onEdit;

  @override
  State<InnerPageTile> createState() => _InnerPageTileState();
}

class _InnerPageTileState extends State<InnerPageTile> {
  /// First valid URL inside [InnerPageTile.value], or null for plain text.
  String? _firstLink;

  @override
  void initState() {
    super.initState();
    _syncPreview();
  }

  @override
  void didUpdateWidget(covariant InnerPageTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _syncPreview();
    }
  }

  /// Ensures the cached preview for this tile's link is loaded into the
  /// in-memory cache. Runs once per value change from the widget lifecycle —
  /// never inside build() or a Selector, which must stay pure.
  void _syncPreview() {
    _firstLink = LinkUtils.extractFirstLink(widget.value);
    final firstLink = _firstLink;
    if (firstLink == null) return;
    final previewMap = context.read<PreviewMap>();
    final saveImagesLocally = context.read<AppSettings>().saveImagesLocally;
    previewMap.loadPreviewSync(firstLink, saveLocally: saveImagesLocally);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Provider.of<AppColors>(context);
    final firstLink = _firstLink;

    return Container(
      key: ValueKey(widget.value),
      width: MediaQuery.of(context).size.width,
      margin: const EdgeInsets.fromLTRB(2, 4, 2, 4),
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(50)),
        color: colors.box,
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.all(Radius.circular(50)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _TileActionBar(
              code: widget.code,
              index: widget.index,
              value: widget.value,
              firstLink: firstLink,
              onEdit: widget.onEdit,
            ),
            if (firstLink != null)
              _LinkContent(
                value: widget.value,
                firstLink: firstLink,
                isEmbedded: widget.isEmbedded,
              )
            else
              _PlainTextContent(value: widget.value),
          ],
        ),
      ),
    );
  }
}

/// Horizontal action-pill bar shown at the top of an [InnerPageTile].
class _TileActionBar extends StatelessWidget {
  const _TileActionBar({
    required this.code,
    required this.index,
    required this.value,
    required this.firstLink,
    required this.onEdit,
  });

  final int code;
  final int index;
  final String value;
  final String? firstLink;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 80,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          spacing: 8,
          children: [
            const SizedBox(width: 12),
            // Index Badge (Unified Style)
            PillButton(
              icon: Icons.tag_rounded,
              label: index.toString(),
              onPressed: () {},
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              iconColor: Colors.white,
            ),

            // Open Link Button
            if (firstLink != null)
              PillButton(
                label: "Open Link",
                icon: Icons.public,
                onPressed: () {
                  LinkUtils.openExternalUrl(firstLink!);
                },
              ),

            // Edit Button
            PillButton(
              label: "Edit",
              icon: Icons.edit_note_rounded,
              onPressed: onEdit,
            ),
            // Copy Button
            PillButton(
              label: "Copy",
              onPressed: () {
                showToastMsg(context, "Item copied!");
                Clipboard.setData(ClipboardData(text: value));
              },
              icon: Icons.copy_rounded,
            ),
            // Share Button
            PillButton(
              label: "Share",
              onPressed: () {
                SharePlus.instance.share(ShareParams(text: value));
              },
              icon: Icons.share_outlined,
            ),

            // Delete Button
            PillButton(
              label: "Delete",
              icon: Icons.delete_outline_rounded,
              onPressed: () => _confirmDelete(context),
            ),
            const SizedBox(width: 24),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    final settings = Provider.of<AppSettings>(context, listen: false);
    final colors = Provider.of<AppColors>(context, listen: false);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: colors.box,
        title: Text(
          "Delete Entry",
          style: TextStyle(fontFamily: 'GoogleSans', color: colors.textClr),
        ),
        content: Text(
          "Do you want to delete entry no.$index? This is irreversible.",
          style: TextStyle(fontFamily: 'GoogleSans', color: colors.textClr),
        ),
        actions: [
          TextButton(
            onPressed: () {
              settings.triggerHaptic();
              Navigator.pop(dialogContext);
            },
            child: Text(
              "Cancel",
              style: TextStyle(fontFamily: 'GoogleSans', color: colors.textClr),
            ),
          ),
          TextButton(
            onPressed: () {
              settings.triggerHaptic();
              Navigator.pop(dialogContext);
              deleteEntryWithPreviews(
                context.read<CodeGen>(),
                context.read<PreviewMap>(),
                code,
                index - 1,
              );
              showToastMsg(context, "Entry deleted!");
            },
            child: Text(
              "Delete",
              style: TextStyle(
                fontFamily: 'GoogleSans',
                color: colors.dangerClr,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Link-style content of an [InnerPageTile]: the link text, optional trailing
/// note, and the metadata preview.
class _LinkContent extends StatelessWidget {
  const _LinkContent({
    required this.value,
    required this.firstLink,
    required this.isEmbedded,
  });

  final String value;
  final String firstLink;
  final bool isEmbedded;

  @override
  Widget build(BuildContext context) {
    final colors = Provider.of<AppColors>(context);
    final settings = Provider.of<AppSettings>(context, listen: false);
    final previewMap = Provider.of<PreviewMap>(context, listen: false);
    final saveImagesLocally = settings.saveImagesLocally;
    final text = LinkUtils.cleanText(value, firstLink);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Show the link text on top
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 4, 22, 0),
          child: InkWell(
            onTap: () {
              settings.triggerHaptic();
              LinkUtils.openExternalUrl(firstLink);
            },
            child: Text(
              firstLink,
              style: TextStyle(
                color: colors.linkClr,
                fontFamily: 'GoogleSans',
                fontSize: 16,
                decoration: TextDecoration.underline,
                decorationColor: colors.linkClr,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),

        // Show the description text after the link (if present)
        if (text.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 8, 22, 0),
            child: Text(
              text,
              style: TextStyle(
                color: colors.textClr,
                fontFamily: 'GoogleSans',
                fontSize: 24,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

        // Show the link preview (rebuild isolated)
        Selector<PreviewMap, LinkPreviewData?>(
          selector: (context, pm) => pm.cache[firstLink],
          builder: (context, previewData, child) {
            return LinkPreview(
              requestTimeout: const Duration(seconds: 10),
              minWidth: isEmbedded
                  ? 400
                  : MediaQuery.of(context).size.width + 50,
              gap: 20,
              backgroundColor: Colors.transparent,
              sideBorderColor: Colors.transparent,
              imageBuilder: (image) {
                final isSquare =
                    previewData?.image?.height == previewData?.image?.width;
                return Container(
                  decoration: BoxDecoration(
                    borderRadius: isSquare
                        ? BorderRadius.circular(10)
                        : BorderRadius.circular(30),
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
              outsidePadding: const EdgeInsets.fromLTRB(10, 10, 10, 18),
              enableAnimation: true,

              // Style of the head text
              titleTextStyle: TextStyle(
                color: colors.textClr,
                fontWeight: FontWeight.bold,
                fontSize: 32,
                fontFamily: 'GoogleSans',
              ),

              // Style of the description text
              descriptionTextStyle: TextStyle(
                color: colors.textClr,
                fontFamily: 'GoogleSans',
                fontSize: 14,
              ),

              // Save the preview data locally when it is fetched
              onLinkPreviewDataFetched: (data) async {
                await previewMap.savePreview(
                  link: firstLink,
                  data: data,
                  saveLocally: saveImagesLocally,
                );
              },

              // Load from the previously saved data
              linkPreviewData: previewData,

              // The link to be fetched
              text: firstLink,
            );
          },
        ),
      ],
    );
  }
}

/// Plain-text content of an [InnerPageTile] (no valid link inside).
class _PlainTextContent extends StatelessWidget {
  const _PlainTextContent({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = Provider.of<AppColors>(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(36, 14, 26, 26),
      child: Text(
        value,
        style: TextStyle(
          color: colors.textClr,
          fontWeight: FontWeight.bold,
          fontFamily: 'GoogleSans',
          fontSize: 24,
        ),
      ),
    );
  }
}
