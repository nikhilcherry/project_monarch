import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/prefs_controller.dart';
import '../core/theme/lumen_theme.dart';
import 'app_shell.dart';
import 'onboarding/onboarding_view.dart';

/// Root of the Lumen app. Rebuilds the whole theme when the palette changes,
/// so preset switches and custom-colour edits retint everything instantly.
class LumenApp extends ConsumerWidget {
  const LumenApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(prefsControllerProvider);
    return MaterialApp(
      title: 'Lumen',
      debugShowCheckedModeBanner: false,
      theme: LumenTheme.fromPalette(settings.palette),
      home: settings.onboardingDone ? const AppShell() : const OnboardingView(),
    );
  }
}
