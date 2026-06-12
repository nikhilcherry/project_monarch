import 'package:flutter/material.dart';

/// Central palette. Never hardcode hex in widgets — reference these.
///
/// Veil leans into a calm, near-dark "after hours" board aesthetic: deep
/// slate surfaces, a single violet accent, and warm/cool author tints that
/// the anonymous-identity hasher draws from.
abstract final class AppColors {
  static const Color background = Color(0xFF0E0F13);
  static const Color surface = Color(0xFF161821);
  static const Color surfaceAlt = Color(0xFF1E212C);
  static const Color border = Color(0xFF2A2E3A);

  static const Color accent = Color(0xFF8B7CFF); // veil violet
  static const Color accentDim = Color(0xFF5A4FB0);

  static const Color textPrimary = Color(0xFFE7E9F0);
  static const Color textSecondary = Color(0xFF9AA0B3);
  static const Color textFaint = Color(0xFF656B7E);

  static const Color danger = Color(0xFFFF6B6B);
  static const Color success = Color(0xFF4EC29A);

  /// Distinct, readable tints used to color anonymous author tags.
  /// The identity hasher picks one deterministically per (uid, thread).
  static const List<Color> anonPalette = <Color>[
    Color(0xFF8B7CFF), // violet
    Color(0xFF4EC29A), // mint
    Color(0xFF5BB8FF), // sky
    Color(0xFFFF9E64), // amber
    Color(0xFFFF7AB6), // rose
    Color(0xFF74E0D8), // teal
    Color(0xFFC792EA), // lilac
    Color(0xFFE6D86B), // gold
  ];
}
