import 'package:flutter/material.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:memno/mobile/components/inner_page_tile.dart';
import 'package:memno/mobile/components/pill_button.dart';
import 'package:memno/mobile/components/show_toast.dart';
import 'package:memno/logic/functionality/code_gen.dart';
import 'package:memno/logic/theme/app_colors.dart';
import 'package:provider/provider.dart';

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
      body: Consumer<CodeGen>(
        builder: (context, codeProvider, child) {
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
                  padding: .only(
                    bottom: MediaQuery.of(context).size.height * 0.30,
                  ),
                  itemCount: links.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      // Top bar with title
                      return innerPageTopBar(context, head);
                    } else {
                      return InnerPageTile(
                        code: widget.code,
                        index: index,
                        value: links[index - 1],
                        isEmbedded: widget.isEmbedded,
                        onEdit: () {
                          setState(() {
                            _isEditMode = 1;
                            _editIndex = index - 1;
                            _linkController.text = links[index - 1];
                            _isFabExpanded = true;
                          });
                          Future.delayed(const Duration(milliseconds: 300), () {
                            if (context.mounted) {
                              FocusScope.of(context).requestFocus(_fabFocus);
                            }
                          });
                        },
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
                  PillButton(
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
