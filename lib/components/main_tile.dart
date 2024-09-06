import 'package:flutter/material.dart';
import 'package:memno/components/sub_tile.dart';
import 'package:memno/functionality/code_gen.dart';
import 'package:memno/theme/app_colors.dart';
import 'package:provider/provider.dart';

class MainTile extends StatelessWidget {
  const MainTile({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Provider.of<AppColors>(context);
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
                padding: const EdgeInsets.only(bottom: 130),
                itemCount: codeProvider.codeList.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return TopAccentBox(
                      colors: colors,
                      length: codeProvider.codeList.length,
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

class TopAccentBox extends StatelessWidget {
  const TopAccentBox({
    super.key,
    required this.colors,
    required this.length,
  });

  final AppColors colors;
  final int length;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 0, 2, 4),
      child: Stack(
        children: [
          Container(
            height: 300,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.all(Radius.circular(50.0)),
              color: colors.accnt,
            ),
          ),
          const Positioned(
              top: 26,
              left: 26,
              child: Text("Hi,\nI'm Memno",
                  style: TextStyle(
                      fontFamily: 'Product',
                      fontWeight: FontWeight.w700,
                      fontSize: 52))),
          Positioned(
            bottom: 16,
            right: 16,
            child: Container(
              width: 130,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colors.accntPill,
                borderRadius: BorderRadius.circular(50),
              ),
              child: Text(
                "$length  Codes",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Product',
                  color: colors.accntText,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
