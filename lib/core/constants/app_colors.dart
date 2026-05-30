import 'package:flutter/material.dart';

/// Central color palette for Project Monarch.
///
/// The identity is strict: a true-black void pierced by neon-blue "System"
/// light. Never hardcode hex values in widgets — pull from here so the
/// aesthetic stays consistent across every screen.
abstract final class AppColors {
  AppColors._();

  // ---------------------------------------------------------------------------
  // Core identity
  // ---------------------------------------------------------------------------

  /// True black background (#000000). The void the System projects onto.
  static const Color background = Color(0xFF000000);

  /// Primary neon-blue accent (#00E5FF). Glow, highlights, active states.
  static const Color accent = Color(0xFF00E5FF);

  /// Slightly deeper cyan for gradients / pressed states.
  static const Color accentDeep = Color(0xFF00B8D4);

  // ---------------------------------------------------------------------------
  // Surfaces (subtle elevation on top of true black)
  // ---------------------------------------------------------------------------

  /// Panels / cards — a faint lift off pure black so edges read as glass.
  static const Color surface = Color(0xFF0A0E12);

  /// Elevated surface (dialogs, sheets, selected map nodes).
  static const Color surfaceElevated = Color(0xFF12181F);

  /// Hairline borders for "System window" panels.
  static const Color border = Color(0x3300E5FF); // 20% accent

  // ---------------------------------------------------------------------------
  // Text
  // ---------------------------------------------------------------------------

  static const Color textPrimary = Color(0xFFE6FAFF);
  static const Color textSecondary = Color(0xFF7C8B93);
  static const Color textDisabled = Color(0xFF3A444A);

  // ---------------------------------------------------------------------------
  // Semantic / System feedback
  // ---------------------------------------------------------------------------

  /// Success — habit completed, quest cleared.
  static const Color success = Color(0xFF39FF14);

  /// Warning — the "System Warning" anti-cheat / penalty prompts.
  static const Color warning = Color(0xFFFFC400);

  /// Danger — failed penalty quest, broken streak.
  static const Color danger = Color(0xFFFF3B5C);

  /// In-game currency accent (coins — Shop).
  static const Color coin = Color(0xFFFFD54F);

  /// World Map currency accent (crystals — Daily Quests).
  static const Color crystal = Color(0xFFB388FF);

  // ---------------------------------------------------------------------------
  // Stat colors (radar chart — STR / AGI / VIT / END / FLEX)
  // ---------------------------------------------------------------------------

  static const Color str = Color(0xFFFF5252); // Strength
  static const Color agi = Color(0xFF69F0AE); // Agility
  static const Color vit = Color(0xFFFFD740); // Vitality
  static const Color end = Color(0xFF40C4FF); // Endurance
  static const Color flex = Color(0xFFB388FF); // Flexibility

  // ---------------------------------------------------------------------------
  // Gradients
  // ---------------------------------------------------------------------------

  /// Signature glow gradient for primary buttons / rank headers.
  static const LinearGradient accentGradient = LinearGradient(
    colors: [accent, accentDeep],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Soft vertical fade used behind panels for depth.
  static const LinearGradient panelGradient = LinearGradient(
    colors: [surfaceElevated, surface],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
