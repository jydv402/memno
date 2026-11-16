import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:material_ui/material_ui.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path/path.dart' as p;
import 'package:memno/logic/database/code_data.dart';
import 'package:memno/logic/database/preview_data.dart';
import 'package:memno/logic/database/toggles_data.dart';
import 'package:memno/logic/functionality/code_gen.dart';
import 'package:memno/logic/functionality/preview_map.dart';
import 'package:memno/logic/sync/auth/google_auth_desktop.dart';
import 'package:memno/logic/sync/auth/google_auth_mobile.dart';
import 'package:memno/logic/sync/auth/sync_auth.dart';
import 'package:memno/logic/sync/auth/sync_auth_controller.dart';
import 'package:memno/desktop/desktop_shell.dart';
import 'package:memno/mobile/home.dart';
import 'package:memno/logic/theme/app_colors.dart';
import 'package:memno/logic/theme/app_settings.dart';
import 'package:provider/provider.dart';

/// Global navigator key used by share intent handler to push ShareTargetPage.
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// Boots Hive, registers the three generated adapters, wires the provider
/// tree, and starts the app on the platform-appropriate shell.
///
/// Desktop platforms (Windows, macOS, Linux) root at [DesktopShell]; every
/// other platform roots at the mobile [HomePage]. Storage lives under
/// `~/.memno` on desktop so it is easy to locate and back up, and in the
/// standard app-support directory elsewhere. Hive initialization failures
/// are caught and logged rather than fatal: the app can still start, and
/// the controllers surface their own empty state.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize Hive and register adapters
  try {
    if (!kIsWeb &&
        (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      final String? home = Platform.isWindows
          ? Platform.environment['USERPROFILE']
          : Platform.environment['HOME'];
      if (home != null) {
        Hive.init(p.join(home, '.memno'));
      } else {
        await Hive.initFlutter();
      }
    } else {
      await Hive.initFlutter();
    }

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
        ChangeNotifierProvider(create: (context) => AppSettings()),
        ChangeNotifierProxyProvider<AppSettings, AppColors>(
          create: (context) => AppColors(),
          update: (context, settings, colors) => colors!..update(settings),
        ),
        Provider<SyncAuth>(
          create: (context) =>
              Platform.isWindows || Platform.isMacOS || Platform.isLinux
              ? GoogleAuthDesktop() as SyncAuth
              : GoogleAuthMobile(),
        ),
        ChangeNotifierProvider<SyncAuthController>(
          create: (context) => SyncAuthController(context.read<SyncAuth>()),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

/// Root widget: reads the palette and settings from the provider tree and
/// builds the material app, choosing the shell by platform.
///
/// Both themes seed their [ColorScheme] from the app's lime accent so
/// material widgets harmonize with the custom palette; the theme mode is
/// passed straight through from [AppSettings.themeMode].
class MyApp extends StatelessWidget {
  /// Creates the root widget.
  const MyApp({super.key});

  /// Whether the current platform is one of the desktop targets (Windows,
  /// macOS, or Linux); evaluated per build so tests can run on any host.
  static bool get _isDesktopPlatform =>
      Platform.isWindows || Platform.isMacOS || Platform.isLinux;

  @override
  Widget build(BuildContext context) {
    final colors = Provider.of<AppColors>(context);
    final settings = Provider.of<AppSettings>(context);
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Memno',
      debugShowCheckedModeBanner: false,
      home: _isDesktopPlatform ? const DesktopShell() : const HomePage(),
      themeMode: switch (settings.themeMode) {
        AppThemeMode.system => ThemeMode.system,
        AppThemeMode.light => ThemeMode.light,
        AppThemeMode.dark => ThemeMode.dark,
      },
      theme: ThemeData(
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: colors.accnt,
          brightness: Brightness.light,
        ),
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
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: colors.accnt,
          brightness: Brightness.dark,
        ),
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
