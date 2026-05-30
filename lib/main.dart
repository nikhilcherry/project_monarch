import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/constants/app_colors.dart';
import 'core/constants/app_strings.dart';
import 'core/theme/app_theme.dart';

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

  // Local database — fully offline. (Adapters registered in Phase 3.)
  await Hive.initFlutter();

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
      // Routing (go_router) is wired in a later phase; a temporary boot screen
      // confirms the theme/identity is live.
      home: const _BootScreen(),
    );
  }
}

/// Temporary launch screen proving the neon-on-black identity renders.
/// Replaced by the Dashboard + go_router shell in Phase 5.
class _BootScreen extends StatelessWidget {
  const _BootScreen();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Glowing System sigil placeholder.
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.accent, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accent.withValues(alpha: 0.5),
                    blurRadius: 32,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(
                Icons.bolt,
                color: AppColors.accent,
                size: 48,
              ),
            ),
            const SizedBox(height: 28),
            Text(
              AppStrings.appName,
              style: textTheme.headlineSmall?.copyWith(
                letterSpacing: 4,
                shadows: [
                  Shadow(
                    color: AppColors.accent.withValues(alpha: 0.6),
                    blurRadius: 18,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              AppStrings.tagline,
              style: textTheme.titleMedium?.copyWith(
                color: AppColors.accent,
                letterSpacing: 8,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
