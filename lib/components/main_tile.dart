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
            ? const Center(
                child: Text(
                  "Generate Code to view",
                ),
              )
            : ListView.builder(
                itemCount: codeProvider.codeList.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(0, 0, 0, 4),
                      child: Stack(
                        children: [
                          Container(
                            height: 300,
                            decoration: BoxDecoration(
                              borderRadius:
                                  const BorderRadius.all(Radius.circular(50.0)),
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                          ),
                          Positioned(
                            bottom: 16,
                            right: 16,
                            child: Container(
                              width: 120,
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.tertiary,
                                borderRadius: BorderRadius.circular(50),
                              ),
                              child: Text(
                                "Test",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  } else {
                    final code = codeProvider.codeList[index - 1];
                    final date = codeProvider.getDateForCode(code);
                    final isLiked = codeProvider.getLikeForCode(code);
                    return subTile(context, code, date, isLiked);
                  }
                });
      },
    );
  }
}
