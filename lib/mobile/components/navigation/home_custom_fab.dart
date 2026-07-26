import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:memno/logic/functionality/code_gen.dart';
import 'package:memno/logic/theme/app_colors.dart';
import 'package:memno/mobile/pages/inner_page.dart';
import 'package:memno/logic/theme/app_settings.dart';
import 'package:provider/provider.dart';

class CustomFAB extends StatelessWidget {
  const CustomFAB({super.key, required this.onSearch});

  final double radius = 50.0;
  final double height = 100.0;
  final double width = 200.0;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    final colors = Provider.of<AppColors>(context);

    return OpenContainer(
      transitionType: ContainerTransitionType.fade,
      openBuilder: (context, _) =>
          InnerPage(code: context.read<CodeGen>().codeList.last),
      closedElevation: 0,
      closedShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius + 10),
      ),
      closedColor: Colors.transparent,
      openColor: colors.bgClr,
      middleColor: colors.bgClr,
      closedBuilder: (context, openContainer) => GlassmorphicContainer(
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
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                shape: const CircleBorder(),
                fixedSize: Size(height - 20, height - 20),
              ),
              onPressed: () {
                Provider.of<AppSettings>(context, listen: false).triggerHaptic();
                context.read<CodeGen>().generateCode();
                openContainer();
              },
              child: const Icon(Icons.add_rounded, size: 30),
            ),
            const Spacer(),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                shape: const CircleBorder(),
                fixedSize: Size(height - 20, height - 20),
              ),
              onPressed: () {
                Provider.of<AppSettings>(context, listen: false).triggerHaptic();
                onSearch();
              },
              child: const Icon(Icons.search_rounded, size: 30),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}
