import 'package:flutter/material.dart';
import 'package:memno/mobile/components/inner_page_tile.dart';
import 'package:memno/mobile/components/navigation/morphing_fab.dart';
import 'package:memno/mobile/components/inner_page_top_bar.dart';
import 'package:memno/mobile/components/show_toast.dart';
import 'package:memno/mobile/components/haptic_app_bar.dart';
import 'package:memno/logic/functionality/code_gen.dart';
import 'package:memno/logic/functionality/edit_mode.dart';
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

  EditMode _editMode = EditMode.add;
  int _editIndex = -1; // Index of the item being edited
  bool _isFabExpanded = true;

  /// Switches the FAB into [mode] with [initialText] pre-filled, then focuses
  /// the input once the morph animation has started.
  void _startInput(EditMode mode, String initialText) {
    setState(() {
      _editMode = mode;
      _linkController.text = initialText;
      _isFabExpanded = true;
    });
    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      FocusScope.of(context).requestFocus(_fabFocus);
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Provider.of<AppColors>(context);
    final codeProvider = Provider.of<CodeGen>(context);

    return Scaffold(
      backgroundColor: colors.bgClr,
      appBar: HapticAppBar(
        backgroundColor: colors.bgClr,
        foregroundColor: colors.fgClr,
        surfaceTintColor: colors.bgClr,
        implyLeading: !widget.isEmbedded,
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
                        _startInput(EditMode.editTitle, head);
                      },
                    ),
                    const SizedBox(height: 50),
                    Padding(
                      padding: const EdgeInsets.only(left: 24),
                      child: Text(
                        ">  Empty note page.\n>  Let's start with adding a new Link or Note.\n>  Add a space after Link to add a trailing Note.",
                        style: TextStyle(
                          color: colors.textClr,
                          fontFamily: 'GoogleSans',
                          height: 2,
                        ),
                      ),
                    ),
                  ],
                )
              // Otherwise, show the list of links with previews
              : ListView.builder(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).size.height * 0.30,
                  ),
                  itemCount: links.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      // Top bar with title
                      return InnerPageTopBar(
                        head: head,
                        onPressed: () {
                          _startInput(EditMode.editTitle, head);
                        },
                      );
                    } else {
                      return InnerPageTile(
                        code: widget.code,
                        index: index,
                        value: links[index - 1],
                        isEmbedded: widget.isEmbedded,
                        onEdit: () {
                          _startInput(EditMode.editEntry, links[index - 1]);
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
            switch (_editMode) {
              case EditMode.editEntry:
                // Edit existing link
                codeProvider.editLink(
                  widget.code,
                  _editIndex,
                  _linkController.text,
                );
                showToastMsg(context, "Entry edited!");
              case EditMode.editTitle:
                // Edit title
                codeProvider.addHead(widget.code, _linkController.text);
                showToastMsg(context, "New title added!");
              case EditMode.add:
                // Add new link
                codeProvider.addLink(widget.code, _linkController.text);
                showToastMsg(context, "New entry added!");
            }
          }
          setState(() {
            _editMode = EditMode.add;
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
            _editMode = EditMode.add;
            _editIndex = -1;
          });
          _linkController.clear();
          FocusScope.of(context).unfocus();
        },
        controller: _linkController,
        isEditMode: _editMode,
        fabFocus: _fabFocus,
        isEmbedded: widget.isEmbedded,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
    );
  }

  @override
  void dispose() {
    _linkController.dispose();
    super.dispose();
  }
}
