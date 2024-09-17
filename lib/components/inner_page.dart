import 'package:any_link_preview/any_link_preview.dart';
import 'package:delightful_toast/delight_toast.dart';
import 'package:delightful_toast/toast/components/toast_card.dart';
import 'package:delightful_toast/toast/utils/enums.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' show PreviewData;
import 'package:flutter_link_previewer/flutter_link_previewer.dart';
import 'package:memno/components/inner_page_fun.dart';
import 'package:memno/functionality/code_gen.dart';
import 'package:memno/functionality/preview_map.dart';
import 'package:memno/theme/app_colors.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class InnerPage extends StatefulWidget {
  final int code;
  const InnerPage({super.key, required this.code});

  @override
  State<InnerPage> createState() => _InnerPageState();
}

class _InnerPageState extends State<InnerPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _linkController = TextEditingController();

  Map<String, PreviewData> fetched = {};

  int _isEditMode = 0;
  int _editIndex = -1;

  @override
  Widget build(BuildContext context) {
    final colors = Provider.of<AppColors>(context);
    final codeProvider = Provider.of<CodeGen>(context);

    void showToastInnerPage(String msg) {
      DelightToastBar(
        autoDismiss: true,
        snackbarDuration: const Duration(seconds: 2),
        position: DelightSnackbarPosition.top,
        builder: (context) => ToastCard(
          color: Provider.of<AppColors>(context).box,
          title: Text(
            msg,
            style: TextStyle(
              fontFamily: 'Product',
              color: Provider.of<AppColors>(context).textClr,
            ),
          ),
        ),
      ).show(context);
    }

    return Hero(
      tag: 'fab_to_page',
      transitionOnUserGestures: true,
      child: Material(
        type: MaterialType.transparency,
        child: Scaffold(
          backgroundColor: colors.bgClr,
          appBar: AppBar(
            backgroundColor: colors.bgClr,
            foregroundColor: colors.fgClr,
            surfaceTintColor: colors.bgClr,
          ),
          body: Consumer2<CodeGen, PreviewMap>(
            builder: (context, codeProvider, previewMap, child) {
              final links = codeProvider.getLinksForCode(widget.code);

              return links.isEmpty
                  ? Center(
                      child: Text(
                        "It's so empty here...",
                        style: TextStyle(
                            color: colors.textClr, fontFamily: 'Product'),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.only(bottom: 160),
                      itemCount: links.length + 1,
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          String head =
                              codeProvider.getHeadForCode(widget.code);
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
                                Positioned(
                                  top: 38,
                                  left: 24,
                                  child: Text(
                                      head.length > 12
                                          ? "${head.substring(0, 12)}..."
                                          : head,
                                      style: const TextStyle(
                                          fontFamily: 'Product',
                                          fontWeight: FontWeight.w700,
                                          fontSize: 48)),
                                ),
                                Positioned(
                                    bottom: 10,
                                    right: 10,
                                    child: IconButton(
                                        tooltip: "Edit title",
                                        onPressed: () {
                                          setState(() {
                                            _isEditMode = 2;
                                            _linkController.text = head;
                                          });
                                        },
                                        icon: const Icon(
                                            Icons.mode_edit_outline_outlined)))
                              ],
                            ),
                          );
                        } else {
                          final previewData =
                              previewMap.cache[links[index - 1]];
                          return Stack(
                            children: [
                              Container(
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
                                    child: Padding(
                                      padding: const EdgeInsets.only(top: 70),
                                      child: AnyLinkPreview.isValidLink(
                                              links[index - 1])
                                          ? LinkPreview(
                                              requestTimeout:
                                                  const Duration(seconds: 10),
                                              width: MediaQuery.of(context)
                                                      .size
                                                      .width +
                                                  50,
                                              enableAnimation: true,
                                              openOnPreviewImageTap: true,
                                              openOnPreviewTitleTap: true,
                                              metadataTextStyle: TextStyle(
                                                color: colors.textClr,
                                              ),
                                              metadataTitleStyle: TextStyle(
                                                color: colors.textClr,
                                                fontWeight: FontWeight.bold,
                                              ),
                                              onLinkPressed: (url) {
                                                launchUrl(Uri.parse(
                                                    links[index - 1]));
                                              },
                                              onPreviewDataFetched: (data) {
                                                setState(() {
                                                  previewMap.storePreview(
                                                      links[index - 1], data);
                                                });
                                              },
                                              previewData: previewData,
                                              text: links[index - 1],
                                            )
                                          : Padding(
                                              padding:
                                                  const EdgeInsets.fromLTRB(
                                                      36, 26, 26, 26),
                                              child: Text(
                                                links[index - 1],
                                                style: TextStyle(
                                                  color: colors.textClr,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                    )),
                              ),
                              Positioned(
                                top: 5,
                                right: 10,
                                child: SizedBox(
                                  width: 200,
                                  height: 80,
                                  child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Spacer(),
                                        InnerPageButton(
                                          onPressed: () {
                                            showToastInnerPage("Link copied!");
                                            Clipboard.setData(
                                              ClipboardData(
                                                  text: links[index - 1]),
                                            );
                                          },
                                          icon: Icons.copy_rounded,
                                        ),
                                        const Spacer(),
                                        InnerPageButton(
                                          icon:
                                              Icons.mode_edit_outline_outlined,
                                          onPressed: () {
                                            setState(() {
                                              _isEditMode = 1;
                                              _editIndex = index - 1;
                                              _linkController.text =
                                                  links[index - 1];
                                            });
                                          },
                                        ),
                                        const Spacer(),
                                        InnerPageButton(
                                          icon: Icons.delete_outline_rounded,
                                          onPressed: () =>
                                              codeProvider.deleteLink(
                                                  widget.code, index - 1),
                                        ),
                                        const Spacer(),
                                      ]),
                                ),
                              ),
                            ],
                          );
                        }
                      });
            },
          ),
          floatingActionButton: CustomInnerFAB(
            onConfirm: () {
              if (_linkController.text.isNotEmpty) {
                if (_isEditMode == 1) {
                  codeProvider.editLink(
                      widget.code, _editIndex, _linkController.text);
                } else if (_isEditMode == 2) {
                  codeProvider.addHead(widget.code, _linkController.text);
                } else {
                  codeProvider.addLink(widget.code, _linkController.text);
                }
              }
              setState(() {
                _isEditMode = 0;
                _editIndex = -1;
              });
              _linkController.clear();
            },
            onCancel: () {
              setState(() {
                _isEditMode = 0;
                _editIndex = -1;
              });
              _linkController.clear();
            },
            controller: _linkController,
            isEditMode: _isEditMode,
          ),
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerFloat,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _linkController.dispose();

    super.dispose();
  }
}

class CustomInnerFAB extends StatelessWidget {
  const CustomInnerFAB(
      {super.key,
      required this.onConfirm,
      required this.onCancel,
      required this.controller,
      required this.isEditMode});
  final VoidCallback onConfirm;
  final VoidCallback onCancel;
  final TextEditingController controller;
  final int isEditMode;

  @override
  Widget build(BuildContext context) {
    final colors = Provider.of<AppColors>(context);

    return Container(
      padding: const EdgeInsets.all(8),
      width: MediaQuery.of(context).size.width - 25,
      height: 130,
      decoration: BoxDecoration(
          color: colors.bgClr,
          borderRadius: BorderRadius.circular(50),
          border: Border.all(color: colors.fgClr, width: 1)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 5,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(42), color: colors.box),
              child: TextField(
                controller: controller,
                minLines: null,
                maxLines: null,
                expands: true,
                style: TextStyle(
                  color: colors.fgClr,
                  fontFamily: 'Product',
                ),
                decoration: const InputDecoration(
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  border: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                ),
              ),
            ),
          ),
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
                        color: Colors.green)),
                const Spacer(),
                IconButton(
                    onPressed: onCancel,
                    icon: const Icon(Icons.close_rounded, color: Colors.red)),
                const Spacer(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
