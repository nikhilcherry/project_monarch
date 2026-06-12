// GENERATED FILE — PLACEHOLDER.
//
// This is a committed template so the project compiles before Firebase is
// wired up. Replace it with a real one by running:
//
//     dart pub global activate flutterfire_cli
//     flutterfire configure
//
// That command provisions web/android/ios apps in your Firebase project and
// overwrites this file with real keys. Until then, the app will throw a clear
// error on startup telling you to run it (see main.dart).
//
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static const bool isConfigured = false;

  static FirebaseOptions get currentPlatform {
    if (!isConfigured) {
      throw UnsupportedError(
        'Firebase is not configured yet.\n'
        'Run `flutterfire configure` from the veil/ directory to generate '
        'lib/firebase_options.dart with your project keys.',
      );
    }
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        return web;
    }
  }

  // Replaced by `flutterfire configure`.
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'TODO',
    appId: 'TODO',
    messagingSenderId: 'TODO',
    projectId: 'TODO',
  );
  static const FirebaseOptions android = web;
  static const FirebaseOptions ios = web;
}
