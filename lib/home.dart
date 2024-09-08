import 'package:flutter/material.dart';
import 'package:memno/components/inner_page.dart';
import 'package:memno/components/main_tile.dart';
import 'package:memno/components/settings_page.dart';
import 'package:memno/functionality/code_gen.dart';
import 'package:memno/theme/app_colors.dart';
import 'package:provider/provider.dart';
import 'package:glassmorphism/glassmorphism.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Provider.of<AppColors>(context);

    return Scaffold(
      backgroundColor: colors.bgClr,
      appBar: AppBar(
        backgroundColor: colors.bgClr,
        foregroundColor: colors.fgClr,
        surfaceTintColor: colors.bgClr,
        leading: IconButton(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const SettingsPage(),
            ),
          ),
          icon: const Icon(Icons.menu_rounded),
        ),
      ),
      body: const MainTile(),
      floatingActionButton: const CustomFAB(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

class CustomFAB extends StatelessWidget {
  const CustomFAB({
    super.key,
  });

  final double radius = 50.0;
  final double height = 100.0;
  final double width = 200.0;

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: 'fab_to_page',
      child: GlassmorphicContainer(
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
              const Color(0xFFffffff).withOpacity(0.1),
              const Color(0xFFFFFFFF).withOpacity(0.05),
            ],
            stops: const [
              0.1,
              1,
            ]),
        borderGradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFffffff).withOpacity(0.5),
            const Color((0xFFFFFFFF)).withOpacity(0.5),
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
                context.read<CodeGen>().generateCode();
                Navigator.of(context).push(PageRouteBuilder(
                  transitionDuration: const Duration(milliseconds: 600),
                  pageBuilder: (context, animation, secondaryAnimation) {
                    return InnerPage(
                        code: context.read<CodeGen>().codeList.last);
                  },
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) {
                    return ScaleTransition(
                      scale: Tween<double>(begin: 0.0, end: 1.0).animate(
                        CurvedAnimation(
                          parent: animation,
                          curve: Curves.fastLinearToSlowEaseIn,
                        ),
                      ),
                      child: child,
                    );
                  },
                ));
              },
              child: const Icon(
                Icons.add_rounded,
                size: 30,
              ),
            ),
            const Spacer(),
            ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  shape: const CircleBorder(),
                  fixedSize: Size(height - 20, height - 20),
                ),
                onPressed: () {},
                child: const Icon(Icons.search_rounded, size: 30)),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}
