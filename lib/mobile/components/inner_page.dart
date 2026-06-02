import 'dart:io';

import 'package:any_link_preview/any_link_preview.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_link_previewer/flutter_link_previewer.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:linkfy_text/linkfy_text.dart';
import 'package:memno/mobile/components/inner_page_fun.dart';
import 'package:memno/mobile/components/show_toast.dart';
import 'package:memno/logic/functionality/code_gen.dart';
import 'package:memno/logic/functionality/preview_map.dart';
import 'package:memno/logic/theme/app_colors.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// Main page widget for displaying and editing a list of links and a title.
class InnerPage extends StatefulWidget {
  final int code;
  final bool isEmbedded;
  const InnerPage({super.key, required this.code, this.isEmbedded = false});

  @override
  State<InnerPage> createState() => _InnerPageState();
}

class _InnerPageState extends State<InnerPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _linkController = TextEditingController();
  final FocusNode _fabFocus = FocusNode();

  int _isEditMode = 0; // 0: add, 1: edit, 2: edit title, 3: delete
  int _editIndex = -1; // Index of the item being edited/deleted
  bool _isFabExpanded = false;

  @override
  Widget build(BuildContext context) {
    final colors = Provider.of<AppColors>(context);
    final codeProvider = Provider.of<CodeGen>(context);

    return Scaffold(
      backgroundColor: colors.bgClr,
      appBar: AppBar(
        backgroundColor: colors.bgClr,
        foregroundColor: colors.fgClr,
        surfaceTintColor: colors.bgClr,
        automaticallyImplyLeading: !widget.isEmbedded,
      ),
      body: Consumer2<CodeGen, PreviewMap>(
        builder: (context, codeProvider, previewMap, child) {
          final links = codeProvider.getLinksForCode(widget.code);
          String head = codeProvider.getHeadForCode(widget.code);

          // If there are no links, show an empty state
          return links.isEmpty
              ? ListView(
                  children: [
                    innerPageTopBar(context, head),
                    const SizedBox(height: 50),
                    Center(
                      child: Text(
                        "It's so empty here...",
                        style: TextStyle(
                          color: colors.textClr,
                          fontFamily: 'GoogleSans',
                        ),
                      ),
                    ),
                  ],
                )
              // Otherwise, show the list of links with previews
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 160),
                  itemCount: links.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      // Top bar with title
                      return innerPageTopBar(context, head);
                    } else {
                      return Container(
                        key: ValueKey(links[index - 1]),
                        width: MediaQuery.of(context).size.width,
                        margin: const EdgeInsets.fromLTRB(2, 4, 2, 4),
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.all(
                            Radius.circular(50),
                          ),
                          color: colors.box,
                        ),
                        child: ClipRRect(
                          borderRadius: const BorderRadius.all(
                            Radius.circular(50),
                          ),
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
                                      InnerPageButton(
                                        icon: Icons.tag_rounded,
                                        label: index.toString(),
                                        onPressed: () {},
                                        backgroundColor: Colors.black,
                                        foregroundColor: Colors.white,
                                        iconColor: Colors.white,
                                      ),

                                      // Edit Button
                                      InnerPageButton(
                                        label: "Edit",
                                        icon: Icons.edit_note_rounded,
                                        onPressed: () {
                                          setState(() {
                                            _isEditMode = 1;
                                            _editIndex = index - 1;
                                            _linkController.text =
                                                links[index - 1];
                                            _isFabExpanded = true;
                                          });
                                          Future.delayed(
                                            const Duration(milliseconds: 300),
                                            () {
                                              if (context.mounted) {
                                                FocusScope.of(
                                                  context,
                                                ).requestFocus(_fabFocus);
                                              }
                                            },
                                          );
                                        },
                                      ),
                                      // Copy Button
                                      InnerPageButton(
                                        label: "Copy",
                                        onPressed: () {
                                          showToastMsg(context, "Item copied!");
                                          Clipboard.setData(
                                            ClipboardData(
                                              text: links[index - 1],
                                            ),
                                          );
                                        },
                                        icon: Icons.copy_rounded,
                                      ),
                                      // Share Button
                                      InnerPageButton(
                                        label: "Share",
                                        onPressed: () {
                                          SharePlus.instance.share(
                                            ShareParams(text: links[index - 1]),
                                          );
                                        },
                                        icon: Icons.share_outlined,
                                      ),

                                      // Delete Button
                                      InnerPageButton(
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
                                                  onPressed: () =>
                                                      Navigator.pop(
                                                        dialogContext,
                                                      ),
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
                                                    Navigator.pop(
                                                      dialogContext,
                                                    );
                                                    context
                                                        .read<PreviewMap>()
                                                        .deletePreviewForLink(
                                                          links[index - 1],
                                                        );
                                                    context
                                                        .read<CodeGen>()
                                                        .deleteLink(
                                                          widget.code,
                                                          index - 1,
                                                        );
                                                    showToastMsg(
                                                      context,
                                                      "Entry deleted!",
                                                    );
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
                              AnyLinkPreview.isValidLink(
                                    //Check if the link is valid or not
                                    links[index - 1].split(' ').first,
                                  )
                                  ? Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // Show the link text
                                        Padding(
                                          padding: const EdgeInsets.fromLTRB(
                                            22,
                                            4,
                                            22,
                                            0,
                                          ),
                                          child: LinkifyText(
                                            links[index - 1],
                                            onTap: (link) {
                                              launchUrl(
                                                Uri.parse(link.value!),
                                                mode: LaunchMode
                                                    .externalApplication,
                                              );
                                            },
                                            linkStyle: TextStyle(
                                              color: Colors.blue[300],
                                              fontFamily: 'GoogleSans',
                                              fontSize: 16,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),

                                        // Show the link preview
                                        LinkPreview(
                                          requestTimeout: const Duration(
                                            seconds: 10,
                                          ),
                                          minWidth: widget.isEmbedded
                                              ? 400
                                              : MediaQuery.of(
                                                      context,
                                                    ).size.width +
                                                    50,
                                          gap: 20,
                                          backgroundColor: Colors.transparent,
                                          sideBorderColor: Colors.transparent,
                                          imageBuilder: (image) {
                                            return Container(
                                              decoration: BoxDecoration(
                                                // Check if the image is a square or a rectangle
                                                // if square -> curve is 10
                                                // if rectangle -> curve is 30
                                                borderRadius:
                                                    previewMap
                                                            .loadPreviewSync(
                                                              links[index - 1],
                                                              saveLocally: colors
                                                                  .saveImagesLocally,
                                                            )
                                                            ?.image
                                                            ?.height ==
                                                        previewMap
                                                            .loadPreviewSync(
                                                              links[index - 1],
                                                              saveLocally: colors
                                                                  .saveImagesLocally,
                                                            )
                                                            ?.image
                                                            ?.width
                                                    ? BorderRadius.circular(
                                                        10,
                                                        // Square image
                                                      )
                                                    : BorderRadius.circular(
                                                        30,
                                                        // Rectangle image
                                                      ),
                                                image: DecorationImage(
                                                  image:
                                                      previewMap
                                                              .localImagePaths[links[index -
                                                              1]] !=
                                                          null
                                                      ? FileImage(
                                                          File(
                                                            previewMap
                                                                .localImagePaths[links[index -
                                                                1]]!,
                                                          ),
                                                        )
                                                      : NetworkImage(image)
                                                            as ImageProvider,
                                                  fit: BoxFit.cover,
                                                ),
                                              ),
                                            );
                                          },
                                          outsidePadding:
                                              const EdgeInsets.fromLTRB(
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
                                          onLinkPreviewDataFetched:
                                              (data) async {
                                                await previewMap.savePreview(
                                                  link: links[index - 1],
                                                  data: data,
                                                  saveLocally:
                                                      colors.saveImagesLocally,
                                                );
                                              },

                                          // Load from the previously saved data
                                          linkPreviewData: previewMap
                                              .loadPreviewSync(
                                                links[index - 1],
                                                saveLocally:
                                                    colors.saveImagesLocally,
                                              ),

                                          // The link to be fetched
                                          text: links[index - 1],
                                        ),
                                      ],
                                    )
                                  :
                                    // If the link is not a valid URL, it is a normal note. Add it as is
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                        36,
                                        14,
                                        26,
                                        26,
                                      ),
                                      child: Text(
                                        links[index - 1],
                                        style: TextStyle(
                                          color: colors.textClr,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'GoogleSans',
                                          fontSize: 24,
                                        ),
                                      ),
                                    ),
                            ],
                          ),
                        ),
                      );
                    }
                  },
                );
        },
      ),
      // Floating action button for adding/editing/deleting entries
      floatingActionButton: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (child, animation) =>
            ScaleTransition(scale: animation, child: child),
        child: _isFabExpanded
            ? CustomInnerFAB(
                key: const ValueKey('expandedFAB'),
                isEmbedded: widget.isEmbedded,
                onCollapse: () {
                  setState(() {
                    _isFabExpanded = false;
                  });
                },
                onConfirm: () {
                  if (_linkController.text.isNotEmpty) {
                    if (_isEditMode == 1) {
                      // Edit existing link
                      codeProvider.editLink(
                        widget.code,
                        _editIndex,
                        _linkController.text,
                      );
                      showToastMsg(context, "Entry edited!");
                    } else if (_isEditMode == 2) {
                      // Edit title
                      codeProvider.addHead(widget.code, _linkController.text);
                      showToastMsg(context, "New title added!");
                    } else {
                      // Add new link
                      codeProvider.addLink(widget.code, _linkController.text);
                      showToastMsg(context, "New entry added!");
                    }
                  }
                  setState(() {
                    _isEditMode = 0;
                    _editIndex = -1;
                  });
                  _linkController.clear();
                  FocusScope.of(context).unfocus();
                },
                onCancel: () {
                  if (_linkController.text.isNotEmpty) {
                    showToastMsg(context, "Action cancelled!");
                  }
                  setState(() {
                    _isEditMode = 0;
                    _editIndex = -1;
                  });
                  _linkController.clear();
                  FocusScope.of(context).unfocus();
                },
                controller: _linkController,
                isEditMode: _isEditMode,
                fabFocus: _fabFocus,
              )
            : CollapsedInnerFAB(
                key: const ValueKey('collapsedFAB'),
                onExpand: () {
                  setState(() {
                    _isFabExpanded = true;
                  });
                },
              ),
      ),
      floatingActionButtonLocation: _isFabExpanded
          ? FloatingActionButtonLocation.centerFloat
          : FloatingActionButtonLocation.startFloat,
    );
  }

  /// Top bar widget showing the title and edit button
  Widget innerPageTopBar(BuildContext context, String head) {
    final colors = Provider.of<AppColors>(context);
    return Container(
      alignment: Alignment.centerLeft,
      width: MediaQuery.of(context).size.width,
      margin: const EdgeInsets.fromLTRB(2, 0, 2, 4),
      height: 160,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(50),
        color: colors.accnt,
      ),
      child: Stack(
        children: [
          // Title text
          Positioned(
            top: 42,
            left: 0,
            right: 0,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Text(
                "\t\t$head",
                style: const TextStyle(
                  fontFamily: 'GoogleSans',
                  fontWeight: FontWeight.w700,
                  fontSize: 48,
                ),
              ),
            ),
          ),
          // Edit title button
          Positioned(
            bottom: 10,
            right: 10,
            child: IconButton(
              tooltip: "Edit title",
              onPressed: () {
                setState(() {
                  _isEditMode = 2;
                  _linkController.text = head;
                  _isFabExpanded = true;
                });
                Future.delayed(const Duration(milliseconds: 300), () {
                  if (!context.mounted) return;
                  FocusScope.of(context).requestFocus(_fabFocus);
                });
              },
              icon: const Icon(Icons.mode_edit_outline_outlined),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _linkController.dispose();
    super.dispose();
  }
}

/// Custom floating action bar for adding/editing/deleting links or title.
class CustomInnerFAB extends StatelessWidget {
  const CustomInnerFAB({
    super.key,
    required this.onConfirm,
    required this.onCancel,
    required this.onCollapse,
    required this.controller,
    required this.isEditMode,
    required this.fabFocus,
    this.isEmbedded = false,
  });
  final VoidCallback onConfirm;
  final VoidCallback onCancel;
  final VoidCallback onCollapse;
  final TextEditingController controller;
  final int isEditMode;
  final FocusNode fabFocus;
  final bool isEmbedded;

  @override
  Widget build(BuildContext context) {
    final colors = Provider.of<AppColors>(context);

    return SizedBox(
      width: isEmbedded ? 500.0 : (MediaQuery.of(context).size.width - 25),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 50,
            width: double.infinity,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                spacing: 8,
                children: [
                  InnerPageButton(
                    label: "Collapse",
                    icon: Icons.keyboard_arrow_down_rounded,
                    onPressed: onCollapse,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            height: 130,
            decoration: BoxDecoration(
              color: colors.bgClr,
              borderRadius: BorderRadius.circular(50),
              border: Border.all(color: colors.fgClr, width: 1),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Text field for link or title input
                Expanded(
                  flex: 5,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(42),
                      color: colors.box,
                    ),
                    child: TextField(
                      autocorrect: true,
                      autofillHints: [
                        AutofillHints.url,
                        AutofillHints.email,
                        AutofillHints.username,
                        AutofillHints.password,
                      ],
                      focusNode: fabFocus,
                      controller: controller,
                      minLines: null,
                      maxLines: null,
                      expands: true,
                      style: TextStyle(
                        color: colors.fgClr,
                        fontFamily: 'GoogleSans',
                      ),
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        border: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        errorBorder: InputBorder.none,
                        disabledBorder: InputBorder.none,
                      ),
                    ),
                  ),
                ),
                // Confirm and cancel buttons
                Expanded(
                  flex: 1,
                  child: Column(
                    children: [
                      const Spacer(),
                      IconButton(
                        onPressed: onConfirm,
                        icon: Icon(
                          isEditMode == 0
                              ? Icons.add_rounded
                              : Icons.check_rounded,
                          color: Colors.green,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: onCancel,
                        icon: const Icon(
                          Icons.close_rounded,
                          color: Colors.red,
                        ),
                      ),
                      const Spacer(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class CollapsedInnerFAB extends StatelessWidget {
  const CollapsedInnerFAB({super.key, required this.onExpand});
  final VoidCallback onExpand;

  final double radius = 50.0;
  final double height = 50.0;
  final double width = 50.0;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
      child: GlassmorphicContainer(
        width: width,
        height: height,
        alignment: Alignment.center,
        blur: 20,
        borderRadius: radius + 10,
        border: 2,
        linearGradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFffffff).withValues(alpha: 0.1),
            const Color(0xFFFFFFFF).withValues(alpha: 0.05),
          ],
          stops: const [0.1, 1],
        ),
        borderGradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFffffff).withValues(alpha: 0.5),
            const Color((0xFFFFFFFF)).withValues(alpha: 0.5),
          ],
        ),
        child: Center(
          child: SizedBox(
            width: height - 20,
            height: height - 20,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                shape: const CircleBorder(),
                padding: EdgeInsets.zero,
              ),
              onPressed: onExpand,
              child: const Icon(Icons.open_in_full_rounded, size: 15),
            ),
          ),
        ),
      ),
    );
  }
}
