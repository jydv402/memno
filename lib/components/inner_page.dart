import 'package:flutter/material.dart';
import 'package:memno/functionality/inner_page_fun.dart';
import 'package:memno/theme/app_colors.dart';
import 'package:provider/provider.dart';
import 'package:memno/functionality/code_gen.dart';
import 'package:flutter_link_previewer/flutter_link_previewer.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' show PreviewData;
import 'package:url_launcher/url_launcher.dart';
import 'package:memno/functionality/preview_map.dart';
import 'package:any_link_preview/any_link_preview.dart';

class InnerPage extends StatefulWidget {
  final int code;
  const InnerPage({super.key, required this.code});

  @override
  State<InnerPage> createState() => _InnerPageState();
}

class _InnerPageState extends State<InnerPage> {
  final TextEditingController _linkController = TextEditingController();
  final TextEditingController _editController = TextEditingController();
  final TextEditingController _headController = TextEditingController();

  Map<String, PreviewData> fetched = {};

  @override
  Widget build(BuildContext context) {
    final colors = Provider.of<AppColors>(context);

    return Hero(
      tag: 'fab_to_page',
      transitionOnUserGestures: true,
      child: Material(
        color: colors.accnt,
        child: Scaffold(
          appBar: AppBar(),
          body: Consumer2<CodeGen, PreviewMap>(
            builder: (context, codeProvider, previewMap, child) {
              final links = codeProvider.getLinksForCode(widget.code);

              return SafeArea(
                child: Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        itemCount: links.length,
                        itemBuilder: (context, index) {
                          final previewData = previewMap.cache[links[index]];
                          return Stack(
                            children: [
                              Container(
                                key: ValueKey(links[index]),
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
                                              links[index])
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
                                                launchUrl(
                                                    Uri.parse(links[index]));
                                              },
                                              onPreviewDataFetched: (data) {
                                                setState(() {
                                                  previewMap.storePreview(
                                                      links[index], data);
                                                });
                                              },
                                              previewData: previewData,
                                              text: links[index],
                                            )
                                          : Padding(
                                              padding:
                                                  const EdgeInsets.fromLTRB(
                                                      36, 26, 26, 26),
                                              child: Text(
                                                links[index],
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
                                          onPressed: () {},
                                          icon: Icons.copy_rounded,
                                        ),
                                        const Spacer(),
                                        InnerPageButton(
                                          icon: Icons.mode_edit_outline_rounded,
                                          onPressed: () => _editLink(
                                              context,
                                              codeProvider,
                                              index,
                                              links[index]),
                                        ),
                                        const Spacer(),
                                        InnerPageButton(
                                          icon: Icons.delete_outline_rounded,
                                          onPressed: () => codeProvider
                                              .deleteLink(widget.code, index),
                                        ),
                                        const Spacer(),
                                      ]),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _linkController,
                              decoration: const InputDecoration(
                                hintText: "Enter item",
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: () {
                              if (_linkController.text.isNotEmpty) {
                                codeProvider.addLink(
                                    widget.code, _linkController.text);
                                _linkController.clear();
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _editLink(BuildContext context, CodeGen codeProvider, int index,
      String currentLink) {
    final colors = Provider.of<AppColors>(context);
    _editController.text = currentLink;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: colors.box,
          title: Text(
            "Edit Link",
            style: TextStyle(color: colors.textClr),
          ),
          content: TextField(
            controller: _editController,
            decoration: const InputDecoration(hintText: "Enter new link"),
          ),
          actions: [
            TextButton(
              child: const Text("Cancel"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text("Save"),
              onPressed: () {
                if (_editController.text.isNotEmpty) {
                  codeProvider.editLink(
                      widget.code, index, _editController.text);
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _linkController.dispose();
    _editController.dispose();
    super.dispose();
  }
}
