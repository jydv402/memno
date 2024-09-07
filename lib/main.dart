import 'package:flutter/material.dart';
import 'package:memno/functionality/code_gen.dart';
import 'package:memno/functionality/preview_map.dart';
import 'package:memno/home.dart';
import 'package:memno/theme/app_colors.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  runApp(MultiProvider(providers: [
    ChangeNotifierProvider(create: (context) => CodeGen()),
    ChangeNotifierProvider(create: (context) => PreviewMap()),
    ChangeNotifierProvider(create: (context) => AppColors()),
  ], child: const MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Provider.of<AppColors>(context);
    return MaterialApp(
      title: 'MemNo',
      debugShowCheckedModeBanner: false,
      home: const HomePage(),
      theme: ThemeData(
          elevatedButtonTheme: ElevatedButtonThemeData(
              style: ButtonStyle(
                  overlayColor: WidgetStateProperty.all(
                      colors.accnt.withOpacity(0.025)))),
          textSelectionTheme: TextSelectionThemeData(
            cursorColor: colors.fgClr,
            selectionColor: colors.fgClr,
            selectionHandleColor: colors.fgClr,
          ),
          switchTheme: SwitchThemeData(
              trackColor:
                  WidgetStateProperty.all(colors.accnt.withOpacity(0.3)),
              overlayColor: WidgetStateProperty.all(colors.accnt))),
    );
  }
}
