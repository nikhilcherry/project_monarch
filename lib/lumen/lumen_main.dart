import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/database/lumen_database.dart';
import 'views/lumen_app.dart';

/// Standalone entry point for Lumen, so it runs without touching Monarch's
/// `main.dart`:
///
///     flutter run -t lib/lumen/lumen_main.dart
///
/// Boot order (offline-first):
///   1. Bind the engine + lock to portrait.
///   2. Edge-to-edge system chrome.
///   3. Init Hive, register Lumen adapters, open boxes, seed the sample library.
///   4. Wrap in a Riverpod ProviderScope.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations(
    const [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown],
  );
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  await Hive.initFlutter();
  await LumenDatabase.init();

  runApp(const ProviderScope(child: LumenApp()));
}
