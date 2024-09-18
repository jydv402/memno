import 'package:flutter/material.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:memno/theme/app_colors.dart';
import 'package:provider/provider.dart';

class InnerPageButton extends StatelessWidget {
  const InnerPageButton({
    super.key,
    required this.icon,
    required this.onPressed,
  });

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Provider.of<AppColors>(context);
    return ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.btnClr,
          shape: const CircleBorder(),
          padding: const EdgeInsets.all(16),
        ),
        onPressed: onPressed,
        child: Icon(icon, color: colors.btnIcon));
  }
}

//Custom Inner FAB similar to one in home page (Unused)

// class CustomInnerFAB extends StatelessWidget {
//   const CustomInnerFAB({
//     super.key,
//     required this.onPressed1,
//     required this.onPressed2,
//   });

//   final double radius = 50.0;
//   final double height = 100.0;
//   final double width = 200.0;
//   final VoidCallback onPressed1;
//   final VoidCallback onPressed2;

//   @override
//   Widget build(BuildContext context) {
//     return GlassmorphicContainer(
//       width: width,
//       height: height,
//       alignment: Alignment.center,
//       blur: 20,
//       borderRadius: radius + 10,
//       border: 2,
//       linearGradient: LinearGradient(
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//           colors: [
//             const Color(0xFFffffff).withOpacity(0.1),
//             const Color(0xFFFFFFFF).withOpacity(0.05),
//           ],
//           stops: const [
//             0.1,
//             1,
//           ]),
//       borderGradient: LinearGradient(
//         begin: Alignment.topLeft,
//         end: Alignment.bottomRight,
//         colors: [
//           const Color(0xFFffffff).withOpacity(0.5),
//           const Color((0xFFFFFFFF)).withOpacity(0.5),
//         ],
//       ),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           const Spacer(),
//           ElevatedButton(
//             style: ElevatedButton.styleFrom(
//               backgroundColor: Colors.black,
//               foregroundColor: Colors.white,
//               shape: const CircleBorder(),
//               fixedSize: Size(height - 20, height - 20),
//             ),
//             onPressed: onPressed1,
//             child: const Icon(
//               Icons.add_rounded,
//               size: 30,
//             ),
//           ),
//           const Spacer(),
//           ElevatedButton(
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Colors.black,
//                 foregroundColor: Colors.white,
//                 shape: const CircleBorder(),
//                 fixedSize: Size(height - 20, height - 20),
//               ),
//               onPressed: onPressed2,
//               child: const Icon(Icons.copy_rounded, size: 30)),
//           const Spacer(),
//         ],
//       ),
//     );
//   }
// }
