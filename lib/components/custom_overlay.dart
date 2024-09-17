import 'package:flutter/material.dart';

class CustomOverlay extends StatelessWidget {
  final Widget child;

  const CustomOverlay({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          child,
          Positioned.fill(
            child: IgnorePointer(
              ignoring: true,
              child: Container(color: Colors.transparent),
            ),
          ),
        ],
      ),
    );
  }
}
