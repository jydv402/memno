import 'package:flutter/material.dart';
import 'package:memno/components/inner_page.dart';
import 'package:memno/functionality/code_gen.dart';
import 'package:provider/provider.dart';

class MainTile extends StatelessWidget {
  const MainTile({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<CodeGen>(
      builder: (context, codeProvider, child) {
        if (!codeProvider.isReady) {
          return const Center(child: CircularProgressIndicator());
        }
        return codeProvider.codeList.isEmpty
            ? Center(
                child: Text(
                  "Generate Code to view",
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.inversePrimary),
                ),
              )
            : ListView.builder(
                itemCount: codeProvider.codeList.length,
                itemBuilder: (context, index) {
                  final code = codeProvider.codeList[index];
                  return ListTile(
                    title: Text(
                      "#$code",
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 24),
                    ),
                    trailing: IconButton(
                        onPressed: () {
                          codeProvider.clearList(code);
                        },
                        icon: const Icon(Icons.delete)),
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => InnerPage(code: code)));
                    },
                  );
                },
              );
      },
    );
  }
}
