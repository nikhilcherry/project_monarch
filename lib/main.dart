import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/constants/app_strings.dart';
import 'core/database/database_service.dart';
import 'core/theme/app_theme.dart';
import 'views/app_shell.dart';

/// Entry point for Project Monarch.
///
/// Boot order matters for an offline-first app:
///   1. Bind the Flutter engine.
///   2. Lock orientation + apply the true-black system overlay.
///   3. Initialize Hive (local source of truth).  Hive adapters/boxes are
///      registered in Phase 3 — for now we just open the engine so the rest of
///      the app can assume storage is ready.
///   4. Wrap the app in a Riverpod [ProviderScope].
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait — the System HUD is designed vertically.
  await SystemChrome.setPreferredOrientations(
    const [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown],
  );

  // Edge-to-edge true-black chrome.
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(AppTheme.overlayStyle);

  // Local database — fully offline. Boots the Hive engine, registers every
  // TypeAdapter and opens all boxes (single source of truth).
  await Hive.initFlutter();
  await DatabaseService.init();

  runApp(const ProviderScope(child: MonarchApp()));
}

/// Root widget. Owns the single dark theme and the (placeholder) home shell.
class MonarchApp extends StatelessWidget {
  const MonarchApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      theme: AppTheme.dark,
      darkTheme: AppTheme.dark,
      // Navigation shell (Status + Map for now; more tabs as screens land).
      home: const AppShell(),
    );
  }
}
