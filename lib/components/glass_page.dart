import 'package:flutter/material.dart';
import 'package:glassmorphism/glassmorphism.dart';

class GlassPageOverlay extends StatelessWidget {
  const GlassPageOverlay({super.key, required this.onClose});
  final VoidCallback onClose;

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
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Glass Page Overlay',
                        style: TextStyle(fontSize: 22, color: Colors.white)),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context)
                            .pop(); // You can add more logic here to close or perform actions
                      },
                      child: const Text('Close'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
