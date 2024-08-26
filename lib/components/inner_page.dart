import 'package:flutter/material.dart';
import 'package:memno/functionality/inner_page_fun.dart';
import 'package:provider/provider.dart';
import 'package:memno/functionality/code_gen.dart';
import 'package:flutter_link_previewer/flutter_link_previewer.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' show PreviewData;
import 'package:url_launcher/url_launcher.dart';
import 'package:memno/functionality/preview_map.dart';

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
    return Hero(
      tag: 'fab_to_page',
      transitionOnUserGestures: true,
      child: Material(
        color: Theme.of(context).colorScheme.secondary,
        child: Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false,
          ),
          body: Consumer2<CodeGen, PreviewMap>(
            builder: (context, codeProvider, previewMap, child) {
              final links = codeProvider.getLinksForCode(widget.code);

              return SafeArea(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                      child: TextField(
                          controller: _headController,
                          onChanged: (value) {
                            codeProvider.addHead(
                                widget.code, _headController.text);
                          },
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintStyle: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                            ),
                            hintText: codeProvider.getHeadForCode(widget.code),
                          )),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: links.length,
                        itemBuilder: (context, index) {
                          final previewData = previewMap.cache[links[index]];
                          return Stack(
                            children: [
                              Container(
                                key: ValueKey(links[index]),
                                margin: const EdgeInsets.fromLTRB(2, 4, 2, 4),
                                decoration: BoxDecoration(
                                  borderRadius: const BorderRadius.all(
                                    Radius.circular(50),
                                  ),
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                ),
                                child: ClipRRect(
                                    borderRadius: const BorderRadius.all(
                                      Radius.circular(50),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.only(top: 70),
                                      child: LinkPreview(
                                        requestTimeout:
                                            const Duration(seconds: 10),
                                        width:
                                            MediaQuery.of(context).size.width +
                                                50,
                                        enableAnimation: true,
                                        openOnPreviewImageTap: true,
                                        openOnPreviewTitleTap: true,
                                        metadataTextStyle: TextStyle(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                        ),
                                        metadataTitleStyle: TextStyle(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        onLinkPressed: (url) {
                                          launchUrl(Uri.parse(links[index]));
                                        },
                                        onPreviewDataFetched: (data) {
                                          setState(() {
                                            previewMap.storePreview(
                                                links[index], data);
                                          });
                                        },
                                        previewData: previewData,
                                        text: links[index],
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
    _editController.text = currentLink;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            "Edit Link",
            style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
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
