import 'package:flutter/material.dart';
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
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                key: ValueKey(links[index]),
                                margin:
                                    const EdgeInsets.fromLTRB(16, 32, 16, 6),
                                decoration: const BoxDecoration(
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(26),
                                  ),
                                  color: Color(0xFFf4dfcd),
                                ),
                                child: ClipRRect(
                                    borderRadius: const BorderRadius.all(
                                      Radius.circular(26),
                                    ),
                                    child: LinkPreview(
                                      requestTimeout:
                                          const Duration(seconds: 10),
                                      width: MediaQuery.of(context).size.width,
                                      enableAnimation: true,
                                      openOnPreviewImageTap: true,
                                      openOnPreviewTitleTap: true,
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
                                    )),
                              ),
                              Container(
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                decoration: const BoxDecoration(
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(26),
                                  ),
                                  color: Color(0xFFf4dfcd),
                                ),
                                child: const Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Spacer(),
                                        Text('1'),
                                        Spacer(),
                                        Text('2'),
                                        Spacer(),
                                        Text('3'),
                                        Spacer(),
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
          title: const Text("Edit Link"),
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
