import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'lumen_palette.dart';

/// Lumen's type system: Newsreader (serif) for literary content — book titles,
/// chapter headings, the reading surface — and Inter (sans) for all functional
/// UI. Scale + tokens lifted directly from the Stitch DESIGN.md.
abstract final class LumenType {
  LumenType._();

  // --- Serif: Newsreader (headings & reading) ---

  static TextStyle headlineLg(Color c) => GoogleFonts.newsreader(
        color: c,
        fontSize: 32,
        fontWeight: FontWeight.w500,
        height: 1.2,
        letterSpacing: -0.02 * 32,
      );

  static TextStyle headlineMd(Color c) => GoogleFonts.newsreader(
        color: c,
        fontSize: 24,
        fontWeight: FontWeight.w500,
        height: 1.3,
      );

  static TextStyle titleSerif(Color c) => GoogleFonts.newsreader(
        color: c,
        fontSize: 20,
        fontWeight: FontWeight.w500,
        height: 1.3,
      );

  /// The immersive reading body — serif, generous line height.
  static TextStyle readingBody(Color c, {double scale = 1.0}) =>
      GoogleFonts.newsreader(
        color: c,
        fontSize: 18 * scale,
        fontWeight: FontWeight.w400,
        height: 1.7,
        letterSpacing: 0.1,
      );

  // --- Sans: Inter (UI) ---

  static TextStyle bodyLg(Color c) => GoogleFonts.inter(
        color: c,
        fontSize: 18,
        fontWeight: FontWeight.w400,
        height: 1.6,
        letterSpacing: -0.01 * 18,
      );

  static TextStyle bodyMd(Color c) => GoogleFonts.inter(
        color: c,
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.5,
      );

  static TextStyle labelMd(Color c) => GoogleFonts.inter(
        color: c,
        fontSize: 14,
        fontWeight: FontWeight.w500,
        height: 1.2,
        letterSpacing: 0.02 * 14,
      );

  /// Small all-caps section labels ("CONTINUE READING", "APPEARANCE").
  static TextStyle overline(Color c) => GoogleFonts.inter(
        color: c,
        fontSize: 12,
        fontWeight: FontWeight.w600,
        height: 1.2,
        letterSpacing: 1.5,
      );

  static TextStyle caption(Color c) => GoogleFonts.inter(
        color: c,
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.4,
      );

  /// Build a Material [TextTheme] from a palette (used by [ThemeData]).
  static TextTheme textTheme(LumenPalette p) => TextTheme(
        displayLarge: headlineLg(p.heading),
        headlineMedium: headlineMd(p.heading),
        titleLarge: titleSerif(p.heading),
        bodyLarge: bodyLg(p.body),
        bodyMedium: bodyMd(p.body),
        labelLarge: labelMd(p.body),
        labelMedium: labelMd(p.caption),
        bodySmall: caption(p.caption),
      );
}
