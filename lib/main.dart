import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:memno/logic/database/code_data.dart';
import 'package:memno/logic/database/preview_data.dart';
import 'package:memno/logic/database/toggles_data.dart';
import 'package:memno/logic/functionality/code_gen.dart';
import 'package:memno/logic/functionality/preview_map.dart';
import 'package:memno/desktop/desktop_shell.dart';
import 'package:memno/mobile/home.dart';
import 'package:memno/logic/theme/app_colors.dart';
import 'package:provider/provider.dart';

/// Global navigator key used by share intent handler to push ShareTargetPage.
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// Obtain flavor type for update logic
// Will be used to logically disable OTA update check and UI.
const String updateLogic = String.fromEnvironment(
  'UPDATE_LOGIC',
  defaultValue: 'withOTA',
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize Hive and register adapters
  try {
    await Hive.initFlutter();

    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(CodeDataAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(TogglesDataAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(PreviewDataModelAdapter());
    }
    await Hive.openBox<PreviewDataModel>('previewsBox');
  } catch (e, st) {
    debugPrint('Error: $e\nStacktrace: $st');
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => CodeGen()),
        ChangeNotifierProvider(create: (context) => PreviewMap()),
        ChangeNotifierProvider(create: (context) => AppColors()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static bool get _isDesktopPlatform =>
      Platform.isWindows || Platform.isMacOS || Platform.isLinux;

  @override
  Widget build(BuildContext context) {
    final colors = Provider.of<AppColors>(context);
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Memno',
      debugShowCheckedModeBanner: false,
      home: _isDesktopPlatform ? const DesktopShell() : const HomePage(),
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: colors.accnt),
        scaffoldBackgroundColor: colors.bgClr,
        canvasColor: colors.bgClr,
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ButtonStyle(
            overlayColor: WidgetStateProperty.all(
              colors.accnt.withValues(alpha: 0.025),
            ),
          ),
        ),
        textSelectionTheme: TextSelectionThemeData(
          cursorColor: colors.fgClr,
          selectionColor: colors.accnt.withValues(alpha: 0.25),
          selectionHandleColor: colors.fgClr,
        ),
      ),
    );
  }
}
