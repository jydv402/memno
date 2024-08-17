import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:memno/functionality/code_gen.dart';

class InnerPage extends StatefulWidget {
  final int code;
  const InnerPage({super.key, required this.code});

  @override
  State<InnerPage> createState() => _InnerPageState();
}

class _InnerPageState extends State<InnerPage> {
  final TextEditingController _linkController = TextEditingController();
  final TextEditingController _editController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("#${widget.code}"),
        ),
        body: Consumer<CodeGen>(
          builder: (context, codeProvider, child) {
            final links = codeProvider.getLinksForCode(widget.code);

            return Column(
              children: [
                Expanded(
                  child: ListView.builder(
                      itemCount: links.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          title: Text(links[index]),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () {
                              codeProvider.deleteLink(widget.code, index);
                            },
                          ),
                          onTap: () {
                            _editLink(
                                context, codeProvider, index, links[index]);
                          },
                        );
                      }),
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
                        )
                      ],
                    ))
              ],
            );
          },
        ));
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
