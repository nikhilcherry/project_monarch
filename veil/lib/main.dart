import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/theme/app_theme.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // The committed firebase_options.dart is a placeholder. Until you run
  // `flutterfire configure`, show a setup screen instead of crashing.
  if (!DefaultFirebaseOptions.isConfigured) {
    runApp(const _SetupNeededApp());
    return;
  }

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Anonymous auth: a hidden uid per device, no profile collected.
  if (FirebaseAuth.instance.currentUser == null) {
    await FirebaseAuth.instance.signInAnonymously();
  }

  runApp(const ProviderScope(child: VeilApp()));
}

/// Shown while Firebase keys are still the committed placeholders.
class _SetupNeededApp extends StatelessWidget {
  const _SetupNeededApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Veil — setup',
      theme: AppTheme.dark,
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: const Padding(
              padding: EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Veil',
                      style: TextStyle(
                          fontSize: 40, fontWeight: FontWeight.w800)),
                  SizedBox(height: 12),
                  Text('Almost there — connect Firebase.',
                      style: TextStyle(fontSize: 18)),
                  SizedBox(height: 20),
                  Text(
                    'From the veil/ directory run:\n\n'
                    '  dart pub global activate flutterfire_cli\n'
                    '  flutterfire configure\n\n'
                    'That overwrites lib/firebase_options.dart with your '
                    'project keys. Then `flutter run` again.',
                    style: TextStyle(height: 1.5),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
