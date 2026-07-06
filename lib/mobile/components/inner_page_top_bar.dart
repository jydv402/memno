import 'package:flutter/material.dart';
import 'package:memno/logic/theme/app_colors.dart';
import 'package:provider/provider.dart';

class InnerPageTopBar extends StatelessWidget {
  final String head;
  final VoidCallback? onPressed;
  const InnerPageTopBar({super.key, required this.head, this.onPressed});

  @override
  Widget build(BuildContext context) {
    final colors = Provider.of<AppColors>(context);
    return Container(
      alignment: Alignment.centerLeft,
      width: MediaQuery.of(context).size.width,
      margin: const EdgeInsets.fromLTRB(2, 0, 2, 4),
      height: 160,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(50),
        color: colors.accnt,
      ),
      child: Stack(
        children: [
          // Title text
          Positioned(
            top: 42,
            left: 0,
            right: 0,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Text(
                "\t\t$head",
                style: const TextStyle(
                  fontFamily: 'GoogleSans',
                  fontWeight: FontWeight.w700,
                  fontSize: 48,
                  color: Colors.black,
                ),
              ),
            ),
          ),
          // Edit title button
          Positioned(
            bottom: 10,
            right: 10,
            child: IconButton(
              tooltip: "Edit title",
              onPressed: onPressed,
              icon: const Icon(Icons.mode_edit_outline_outlined),
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}
