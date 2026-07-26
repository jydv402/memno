import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart';
import 'package:flutter_link_previewer/flutter_link_previewer.dart';
import 'package:memno/logic/functionality/code_gen.dart';
import 'package:memno/logic/functionality/link_utils.dart';
import 'package:memno/logic/functionality/preview_map.dart';
import 'package:memno/logic/theme/app_colors.dart';
import 'package:memno/logic/theme/app_settings.dart';
import 'package:memno/mobile/components/pill_button.dart';
import 'package:memno/mobile/components/show_toast.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class InnerPageTile extends StatelessWidget {
  final int code;
  final int index;
  final String value;
  final bool isEmbedded;
  final VoidCallback onEdit;

  const InnerPageTile({
    super.key,
    required this.code,
    required this.index,
    required this.value,
    required this.isEmbedded,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Provider.of<AppColors>(context);
    final previewMap = Provider.of<PreviewMap>(context, listen: false);
    final settings = Provider.of<AppSettings>(context, listen: false);
    final saveImagesLocally = settings.saveImagesLocally;
    final firstLink = LinkUtils.extractFirstLink(value);

    return Container(
      key: ValueKey(value),
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
            // Button bar (copy, edit, delete) moved to the top of the column
            SizedBox(
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
                          launchUrl(
                            Uri.parse(LinkUtils.normalizeUrl(firstLink)),
                            mode: LaunchMode.externalApplication,
                          );
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
                      onPressed: () {
                        final colors = Provider.of<AppColors>(
                          context,
                          listen: false,
                        );
                        showDialog(
                          context: context,
                          builder: (dialogContext) => AlertDialog(
                            backgroundColor: colors.box,
                            title: Text(
                              "Delete Entry",
                              style: TextStyle(
                                fontFamily: 'GoogleSans',
                                color: colors.textClr,
                              ),
                            ),
                            content: Text(
                              "Do you want to delete entry no.$index? This is irreversible.",
                              style: TextStyle(
                                fontFamily: 'GoogleSans',
                                color: colors.textClr,
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  settings.triggerHaptic();
                                  Navigator.pop(dialogContext);
                                },
                                child: Text(
                                  "Cancel",
                                  style: TextStyle(
                                    fontFamily: 'GoogleSans',
                                    color: colors.textClr,
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  settings.triggerHaptic();
                                  Navigator.pop(dialogContext);
                                  if (firstLink != null) {
                                    context
                                        .read<PreviewMap>()
                                        .deletePreviewForLink(firstLink);
                                  }
                                  context.read<CodeGen>().deleteLink(
                                    code,
                                    index - 1,
                                  );
                                  showToastMsg(context, "Entry deleted!");
                                },
                                child: Text(
                                  "Delete",
                                  style: TextStyle(
                                    fontFamily: 'GoogleSans',
                                    color: Colors.red,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 24),
                  ],
                ),
              ),
            ),
            // Content section below the button bar
            (() {
              if (firstLink != null) {
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
                          launchUrl(
                            Uri.parse(LinkUtils.normalizeUrl(firstLink)),
                            mode: LaunchMode.externalApplication,
                          );
                        },
                        child: Text(
                          firstLink,
                          style: TextStyle(
                            color: Colors.blue[300],
                            fontFamily: 'GoogleSans',
                            fontSize: 16,
                            decoration: TextDecoration.underline,
                            decorationColor: Colors.blue[300],
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
                      selector: (context, pm) {
                        if (!pm.cache.containsKey(firstLink)) {
                          pm.loadPreviewSync(
                            firstLink,
                            saveLocally: saveImagesLocally,
                          );
                        }
                        return pm.cache[firstLink];
                      },
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
                                previewData?.image?.height ==
                                previewData?.image?.width;
                            return Container(
                              decoration: BoxDecoration(
                                borderRadius: isSquare
                                    ? BorderRadius.circular(10)
                                    : BorderRadius.circular(30),
                                image: DecorationImage(
                                  image:
                                      previewMap.localImagePaths[firstLink] !=
                                          null
                                      ? FileImage(
                                          File(
                                            previewMap
                                                .localImagePaths[firstLink]!,
                                          ),
                                        )
                                      : NetworkImage(image) as ImageProvider,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            );
                          },
                          outsidePadding: const EdgeInsets.fromLTRB(
                            10,
                            10,
                            10,
                            18,
                          ),
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
              } else {
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
            })(),
          ],
        ),
      ),
    );
  }
}
