import 'package:flutter/material.dart';
import 'package:memno/components/sub_tile.dart';
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
                  style:
                      TextStyle(color: Theme.of(context).colorScheme.primary),
                ),
              )
            : ListView.builder(
                itemCount: codeProvider.codeList.length,
                itemBuilder: (context, index) {
                  final code = codeProvider.codeList[index];
                  final date = codeProvider.getDateForCode(code);
                  final isLiked = codeProvider.getLikeForCode(code);
                  return subTile(context, code, date, isLiked);
                },
              );
      },
    );
  }
}
