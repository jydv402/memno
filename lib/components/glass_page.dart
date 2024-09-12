import 'package:flutter/material.dart';
import 'package:glassmorphism/glassmorphism.dart';

class GlassPageOverlay extends StatelessWidget {
  const GlassPageOverlay(
      {super.key, required this.onClose, required this.child});
  final VoidCallback onClose;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GestureDetector(
          onTap: onClose,
          child: Center(
            child: GlassmorphicContainer(
              width: MediaQuery.of(context).size.width - 25,
              height: MediaQuery.of(context).size.height - 150,
              borderRadius: 50,
              blur: 20,
              alignment: Alignment.center,
              border: 2,
              linearGradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFFffffff).withOpacity(0.1),
                  const Color(0xFFFFFFFF).withOpacity(0.05),
                ],
                stops: const [0.1, 1],
              ),
              borderGradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFFffffff).withOpacity(0.5),
                  const Color(0xFFFFFFFF).withOpacity(0.5),
                ],
              ),
              child: Padding(padding: const EdgeInsets.all(16.0), child: child),
            ),
          ),
        ),
      ],
    );
  }
}
