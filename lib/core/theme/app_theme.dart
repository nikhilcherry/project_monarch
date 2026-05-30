import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/app_colors.dart';

/// Builds the single, immutable dark theme for Project Monarch.
///
/// There is intentionally **no light theme** — the System only renders in the
/// void. Everything here funnels through [AppColors] so the neon-on-black
/// identity is enforced app-wide.
abstract final class AppTheme {
  AppTheme._();

  /// System overlay (status/navigation bar) tuned for true-black edge-to-edge.
  static const SystemUiOverlayStyle overlayStyle = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
    systemNavigationBarColor: AppColors.background,
    systemNavigationBarIconBrightness: Brightness.light,
  );

  static ThemeData get dark {
    final base = ThemeData.dark(useMaterial3: true);

    // Orbitron for the "System" display/headers, Rajdhani for body — both give
    // that crisp, technological HUD feel. Falls back gracefully if offline.
    final textTheme = _buildTextTheme(base.textTheme);

    const colorScheme = ColorScheme.dark(
      primary: AppColors.accent,
      onPrimary: AppColors.background,
      secondary: AppColors.accentDeep,
      onSecondary: AppColors.background,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      error: AppColors.danger,
      onError: AppColors.background,
      outline: AppColors.border,
    );

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.background,
      canvasColor: AppColors.background,
      colorScheme: colorScheme,
      textTheme: textTheme,
      primaryColor: AppColors.accent,
      dividerColor: AppColors.border,
      splashColor: AppColors.accent.withValues(alpha: 0.12),
      highlightColor: AppColors.accent.withValues(alpha: 0.08),

      // -----------------------------------------------------------------------
      // App bar — transparent over the void, neon title.
      // -----------------------------------------------------------------------
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        systemOverlayStyle: overlayStyle,
        iconTheme: const IconThemeData(color: AppColors.accent),
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: AppColors.textPrimary,
          letterSpacing: 1.5,
        ),
      ),

      // -----------------------------------------------------------------------
      // "System window" panels.
      // -----------------------------------------------------------------------
      cardTheme: CardThemeData(
        color: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),

      // -----------------------------------------------------------------------
      // Buttons — glowing neon primary action.
      // -----------------------------------------------------------------------
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: AppColors.background,
          disabledBackgroundColor: AppColors.surfaceElevated,
          disabledForegroundColor: AppColors.textDisabled,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.accent,
          side: const BorderSide(color: AppColors.accent, width: 1.2),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: AppColors.accent),
      ),

      // -----------------------------------------------------------------------
      // Inputs.
      // -----------------------------------------------------------------------
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        hintStyle: const TextStyle(color: AppColors.textSecondary),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.accent, width: 1.6),
        ),
      ),

      // -----------------------------------------------------------------------
      // Misc components.
      // -----------------------------------------------------------------------
      iconTheme: const IconThemeData(color: AppColors.accent),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.accent,
        linearTrackColor: AppColors.surfaceElevated,
        circularTrackColor: AppColors.surfaceElevated,
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: AppColors.accent,
        inactiveTrackColor: AppColors.surfaceElevated,
        thumbColor: AppColors.accent,
        overlayColor: AppColors.accent.withValues(alpha: 0.15),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 1,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.accent,
        unselectedItemColor: AppColors.textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? AppColors.accent
              : AppColors.textSecondary,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? AppColors.accent.withValues(alpha: 0.4)
              : AppColors.surfaceElevated,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surfaceElevated,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surfaceElevated,
        contentTextStyle: const TextStyle(color: AppColors.textPrimary),
        actionTextColor: AppColors.accent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.border),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Applies the Orbitron (display) + Rajdhani (body) pairing onto a base theme.
  static TextTheme _buildTextTheme(TextTheme base) {
    final display = GoogleFonts.orbitronTextTheme(base);
    final body = GoogleFonts.rajdhaniTextTheme(base);

    return base.copyWith(
      displayLarge: display.displayLarge,
      displayMedium: display.displayMedium,
      displaySmall: display.displaySmall,
      headlineLarge: display.headlineLarge,
      headlineMedium: display.headlineMedium,
      headlineSmall: display.headlineSmall,
      titleLarge: display.titleLarge?.copyWith(fontWeight: FontWeight.w700),
      titleMedium: body.titleMedium,
      titleSmall: body.titleSmall,
      bodyLarge: body.bodyLarge,
      bodyMedium: body.bodyMedium,
      bodySmall: body.bodySmall,
      labelLarge: body.labelLarge,
      labelMedium: body.labelMedium,
      labelSmall: body.labelSmall,
    ).apply(
      bodyColor: AppColors.textPrimary,
      displayColor: AppColors.textPrimary,
    );
  }
}
