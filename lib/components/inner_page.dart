import 'package:flutter/material.dart';
import 'package:memno/components/glass_page.dart';
import 'package:memno/components/inner_page_fun.dart';
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

class _InnerPageState extends State<InnerPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _linkController = TextEditingController();
  final TextEditingController _editController = TextEditingController();
  final TextEditingController _headController = TextEditingController();

  bool _isGlassVisible = false;
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  Map<String, PreviewData> fetched = {};

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.fastLinearToSlowEaseIn,
      ),
    );
  }

  void _showGlassPage() {
    setState(() {
      _isGlassVisible = true;
    });
    _controller.forward();
  }

  void _hideGlassPage() {
    setState(() {
      _isGlassVisible = false;
    });
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Provider.of<AppColors>(context);

    return Hero(
      tag: 'fab_to_page',
      transitionOnUserGestures: true,
      child: Material(
        color: colors.accnt,
        child: Scaffold(
          backgroundColor: colors.bgClr,
          appBar: AppBar(
            backgroundColor: colors.bgClr,
            foregroundColor: colors.fgClr,
            surfaceTintColor: colors.bgClr,
          ),
          body: Stack(
            children: [
              Consumer2<CodeGen, PreviewMap>(
                builder: (context, codeProvider, previewMap, child) {
                  final links = codeProvider.getLinksForCode(widget.code);

                  return links.isEmpty
                      ? const Center(
                          child: Text('Empty'),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.only(bottom: 130),
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
                                            icon:
                                                Icons.mode_edit_outline_rounded,
                                            onPressed: () => _editLink(
                                                context,
                                                codeProvider,
                                                index,
                                                links[index],
                                                colors),
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
                        );
                },
              ),
              if (_isGlassVisible)
                ScaleTransition(
                    scale: _scaleAnimation,
                    child: GlassPageOverlay(
                      onClose: _hideGlassPage,
                      child: Stack(
                        children: [
                          Container(
                            width: MediaQuery.of(context).size.width - 50,
                            height: 400,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(50),
                              color: colors.box,
                            ),
                          )
                        ],
                      ),
                    ))
            ],
          ),
          floatingActionButton: _isGlassVisible
              ? null
              : CustomInnerFAB(
                  onPressed: _showGlassPage,
                ),
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerFloat,
        ),
      ),
    );
  }

  void _editLink(BuildContext context, CodeGen codeProvider, int index,
      String currentLink, AppColors colors) {
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
    _controller.dispose();
    _linkController.dispose();
    _editController.dispose();
    super.dispose();
  }
}
