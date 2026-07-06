import 'package:flutter/material.dart';
import 'package:memno/mobile/components/inner_page_tile.dart';
import 'package:memno/mobile/components/morphing_fab.dart';
import 'package:memno/mobile/components/inner_page_top_bar.dart';
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
                    InnerPageTopBar(
                      head: head,
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
                    ),
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
                      return InnerPageTopBar(
                        head: head,
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
                      );
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
      floatingActionButton: MorphingFAB(
        isExpanded: _isFabExpanded,
        onExpand: () {
          setState(() {
            _isFabExpanded = true;
          });
        },
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
        isEmbedded: widget.isEmbedded,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  @override
  void dispose() {
    _linkController.dispose();
    super.dispose();
  }
}
