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


// class CustomInnerButton extends StatefulWidget {
//   const CustomInnerButton({
//     super.key,
//     required this.onPressed,
//     required this.onConfirm,
//     required this.onCancel,
//     required this.controller,
//   });

//   final VoidCallback onPressed;
//   final VoidCallback onConfirm;
//   final VoidCallback onCancel;
//   final TextEditingController controller;

//   @override
//   State<CustomInnerButton> createState() => _CustomInnerButtonState();
// }

// class _CustomInnerButtonState extends State<CustomInnerButton> {
//   final double radius = 50.0;

//   final double height = 100.0;

//   final double width = 100.0;

//   bool isTxtFldVisible = false;

//   @override
//   Widget build(BuildContext context) {
//     final colors = Provider.of<AppColors>(context);
//     return isTxtFldVisible == true
//         ? Container(
//             padding: const EdgeInsets.all(8),
//             width: MediaQuery.of(context).size.width - 25,
//             height: 130,
//             decoration: BoxDecoration(
//                 color: colors.bgClr,
//                 borderRadius: BorderRadius.circular(50),
//                 border: Border.all(color: colors.fgClr, width: 1)),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.center,
//               crossAxisAlignment: CrossAxisAlignment.center,
//               children: [
//                 Container(
//                   padding: const EdgeInsets.all(8),
//                   width: MediaQuery.of(context).size.width - 100,
//                   decoration: BoxDecoration(
//                       borderRadius: BorderRadius.circular(46),
//                       color: colors.box),
//                   child: TextField(
//                     controller: widget.controller,
//                     minLines: null,
//                     maxLines: null,
//                     expands: true,
//                     style: TextStyle(
//                       color: colors.fgClr,
//                       fontFamily: 'Product',
//                     ),
//                     decoration: const InputDecoration(
//                       contentPadding:
//                           EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//                       border: InputBorder.none,
//                       focusedBorder: InputBorder.none,
//                       enabledBorder: InputBorder.none,
//                       errorBorder: InputBorder.none,
//                       disabledBorder: InputBorder.none,
//                     ),
//                   ),
//                 ),
//                 const Spacer(),
//                 Column(
//                   children: [
//                     const Spacer(),
//                     IconButton(
//                         onPressed: () {
//                           setState(() {
//                             isTxtFldVisible = false;
//                           });
//                           widget.onConfirm();
//                         },
//                         icon: const Icon(Icons.check_rounded,
//                             color: Colors.green)),
//                     const Spacer(),
//                     IconButton(
//                         onPressed: () {
//                           setState(() {
//                             isTxtFldVisible = false;
//                           });
//                           widget.onCancel();
//                         },
//                         icon:
//                             const Icon(Icons.close_rounded, color: Colors.red)),
//                     const Spacer(),
//                   ],
//                 ),
//                 const Spacer(),
//               ],
//             ),
//           )
//         : GlassmorphicContainer(
//             width: width,
//             height: height,
//             alignment: Alignment.center,
//             blur: 20,
//             borderRadius: radius + 10,
//             border: 2,
//             linearGradient: LinearGradient(
//                 begin: Alignment.topLeft,
//                 end: Alignment.bottomRight,
//                 colors: [
//                   const Color(0xFFffffff).withOpacity(0.1),
//                   const Color(0xFFFFFFFF).withOpacity(0.05),
//                 ],
//                 stops: const [
//                   0.1,
//                   1,
//                 ]),
//             borderGradient: LinearGradient(
//               begin: Alignment.topLeft,
//               end: Alignment.bottomRight,
//               colors: [
//                 const Color(0xFFffffff).withOpacity(0.5),
//                 const Color((0xFFFFFFFF)).withOpacity(0.5),
//               ],
//             ),
//             child: ElevatedButton(
//               style: ElevatedButton.styleFrom(
//                   backgroundColor: Colors.black,
//                   foregroundColor: Colors.white,
//                   shape: const CircleBorder(),
//                   minimumSize: const Size(80, 80)),
//               onPressed: () {
//                 setState(() {
//                   isTxtFldVisible = true;
//                 });
//                 widget.onPressed();
//               },
//               child: const Icon(
//                 Icons.add_rounded,
//                 size: 30,
//               ),
//             ),
//           );
//   }
// }
