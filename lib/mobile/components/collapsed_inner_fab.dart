import 'package:flutter/material.dart';
import 'package:glassmorphism/glassmorphism.dart';

class CollapsedInnerFAB extends StatelessWidget {
  const CollapsedInnerFAB({super.key, required this.onExpand});
  final VoidCallback onExpand;

  final double radius = 50.0;
  final double height = 50.0;
  final double width = 50.0;

  @override
  Widget build(BuildContext context) {
    return GlassmorphicContainer(
      width: width,
      height: height,
      alignment: Alignment.center,
      blur: 20,
      borderRadius: radius + 10,
      border: 2,
      linearGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          const Color(0xFFffffff).withValues(alpha: 0.1),
          const Color(0xFFFFFFFF).withValues(alpha: 0.05),
        ],
        stops: const [0.1, 1],
      ),
      borderGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          const Color(0xFFffffff).withValues(alpha: 0.5),
          const Color((0xFFFFFFFF)).withValues(alpha: 0.5),
        ],
      ),
      child: Center(
        child: SizedBox(
          width: height - 20,
          height: height - 20,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              shape: const CircleBorder(),
              padding: EdgeInsets.zero,
            ),
            onPressed: onExpand,
            child: const Icon(Icons.open_in_full_rounded, size: 15),
          ),
        ),
      ),
    );
  }
}
