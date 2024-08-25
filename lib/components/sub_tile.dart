import 'package:flutter/material.dart';
import 'package:memno/components/inner_page.dart';
import 'package:memno/functionality/code_gen.dart';
import 'package:provider/provider.dart';

Widget subTile(BuildContext context, int code, String date, bool isLiked) {
  const Color tileColor = Color(0xFFf4dfcd);
  return Consumer(builder: (context, codeProvider, child) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GestureDetector(
        onTap: () {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => InnerPage(
              code: code,
            ),
          ));
        },
        child: SizedBox(
          height: 220,
          width: MediaQuery.of(context).size.width,
          child: Stack(
            children: [
              Container(
                  padding: const EdgeInsets.all(16),
                  height: 200,
                  width: MediaQuery.of(context).size.width,
                  decoration: BoxDecoration(
                    color: tileColor,
                    borderRadius: BorderRadius.circular(26),
                  ),
                  child: Text("#$code")),
              Positioned(
                  bottom: 30,
                  left: 16,
                  child: Text(
                      "Created on ${date.substring(8, 10)} ${months[int.parse(date.substring(5, 7)) - 1]} ${date.substring(0, 4)}, ${date.substring(11, 16)}")),
              Positioned(
                right: 16,
                top: 10,
                child: IconButton(
                  key: ValueKey(code),
                  onPressed: () {
                    context.read<CodeGen>().toggleLike(code);
                  },
                  icon: isLiked == true
                      ? const Icon(Icons.favorite_rounded)
                      : const Icon(Icons.favorite_border_rounded),
                ),
              ),
              Positioned(
                right: 10,
                bottom: 0,
                child: FloatingActionButton(
                    elevation: 2,
                    backgroundColor: Theme.of(context).colorScheme.secondary,
                    onPressed: () {
                      //call the clearList func
                      context.read<CodeGen>().clearList(code);
                    },
                    child: const Icon(Icons.delete, color: Colors.black)),
              ),
            ],
          ),
        ),
      ),
    );
  });
}

List months = [
  "Jan",
  "Feb",
  "Mar",
  "Apr",
  "May",
  "Jun",
  "Jul",
  "Aug",
  "Sep",
  "Oct",
  "Nov",
  "Dec",
];
