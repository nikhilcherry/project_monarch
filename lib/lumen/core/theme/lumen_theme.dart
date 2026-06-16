import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'lumen_palette.dart';
import 'lumen_typography.dart';

/// Builds a Material [ThemeData] from a [LumenPalette] so the whole app retints
/// instantly when the user switches preset or customizes a colour.
abstract final class LumenTheme {
  LumenTheme._();

  static ThemeData fromPalette(LumenPalette p) {
    final brightness = p.isLight ? Brightness.light : Brightness.dark;
    final scheme = ColorScheme.fromSeed(
      seedColor: p.accent,
      brightness: brightness,
    ).copyWith(
      surface: p.background,
      primary: p.accent,
      onPrimary: p.isLight ? Colors.white : const Color(0xFF1A1200),
      outline: p.border,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: p.background,
      colorScheme: scheme,
      textTheme: LumenType.textTheme(p),
      dividerColor: p.border,
      dividerTheme: DividerThemeData(
        color: p.border,
        thickness: 1,
        space: 1,
      ),
      iconTheme: IconThemeData(color: p.body, size: 24),
      splashFactory: InkRipple.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: p.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: LumenType.titleSerif(p.heading),
        iconTheme: IconThemeData(color: p.body),
        systemOverlayStyle: p.isLight
            ? SystemUiOverlayStyle.dark
            : SystemUiOverlayStyle.light,
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: p.accent,
        inactiveTrackColor: p.border,
        thumbColor: p.accent,
        overlayColor: p.accent.withValues(alpha: 0.15),
        trackHeight: 2,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? Colors.white : p.caption,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? p.accent
              : p.border,
        ),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),
    );
  }
}
