import 'package:flutter/material.dart';

/// The customizable colour set that defines a Lumen "look".
///
/// Five user-tunable tokens (the Customize-colours screen) plus two derived
/// surface/border tones. Three presets ship out of the box — Midnight, Archive,
/// Charcoal — and the user may override any token. Persisted as ARGB ints in
/// `UserPrefs`, so this stays a plain immutable value type (no Hive coupling).
@immutable
class LumenPalette {
  const LumenPalette({
    required this.preset,
    required this.background,
    required this.surface,
    required this.body,
    required this.heading,
    required this.caption,
    required this.accent,
    required this.border,
  });

  /// Which preset this palette is based on (or [LumenPreset.custom]).
  final LumenPreset preset;

  // The five customizable tokens shown on the Customize-colours screen.
  final Color background; // page / canvas
  final Color body; // primary reading text
  final Color heading; // serif chapter / book titles
  final Color caption; // muted metadata, small UI text
  final Color accent; // amber highlights, progress, ORP pivot

  // Derived tones (not directly edited, recomputed with the background).
  final Color surface; // elevated cards / sheets
  final Color border; // 1px hairline dividers

  bool get isLight => background.computeLuminance() > 0.5;

  static const LumenPalette midnight = LumenPalette(
    preset: LumenPreset.midnight,
    background: Color(0xFF0A0A0A),
    surface: Color(0xFF141414),
    body: Color(0xFFECECEC),
    heading: Color(0xFFF3F3F3),
    caption: Color(0xFF7A7A7A),
    accent: Color(0xFFFFB454),
    border: Color(0xFF262626),
  );

  static const LumenPalette archive = LumenPalette(
    preset: LumenPreset.archive,
    background: Color(0xFFF4ECD8),
    surface: Color(0xFFEDE3CC),
    body: Color(0xFF2B2620),
    heading: Color(0xFF1C1813),
    caption: Color(0xFF8A7E6B),
    accent: Color(0xFFB9772A),
    border: Color(0xFFDBCDAE),
  );

  static const LumenPalette charcoal = LumenPalette(
    preset: LumenPreset.charcoal,
    background: Color(0xFF1A1A1F),
    surface: Color(0xFF24242B),
    body: Color(0xFFE5E2E1),
    heading: Color(0xFFEFEDEC),
    caption: Color(0xFF8E8B92),
    accent: Color(0xFFFFB454),
    border: Color(0xFF34343C),
  );

  static const List<LumenPalette> presets = [midnight, archive, charcoal];

  static LumenPalette forPreset(LumenPreset preset) => switch (preset) {
        LumenPreset.midnight => midnight,
        LumenPreset.archive => archive,
        LumenPreset.charcoal => charcoal,
        LumenPreset.custom => midnight,
      };

  LumenPalette copyWith({
    LumenPreset? preset,
    Color? background,
    Color? surface,
    Color? body,
    Color? heading,
    Color? caption,
    Color? accent,
    Color? border,
  }) {
    return LumenPalette(
      preset: preset ?? this.preset,
      background: background ?? this.background,
      surface: surface ?? this.surface,
      body: body ?? this.body,
      heading: heading ?? this.heading,
      caption: caption ?? this.caption,
      accent: accent ?? this.accent,
      border: border ?? this.border,
    );
  }

  /// Override a single editable token; switches [preset] to [LumenPreset.custom].
  LumenPalette withToken(LumenToken token, Color color) {
    final custom = copyWith(preset: LumenPreset.custom);
    return switch (token) {
      LumenToken.background => custom.copyWith(
          background: color,
          // Keep surface/border legible against the new background.
          surface: Color.alphaBlend(
              (color.computeLuminance() > 0.5 ? Colors.black : Colors.white)
                  .withValues(alpha: 0.04),
              color),
          border: (color.computeLuminance() > 0.5 ? Colors.black : Colors.white)
              .withValues(alpha: 0.12),
        ),
      LumenToken.body => custom.copyWith(body: color),
      LumenToken.heading => custom.copyWith(heading: color),
      LumenToken.caption => custom.copyWith(caption: color),
      LumenToken.accent => custom.copyWith(accent: color),
    };
  }

  Color tokenColor(LumenToken token) => switch (token) {
        LumenToken.background => background,
        LumenToken.body => body,
        LumenToken.heading => heading,
        LumenToken.caption => caption,
        LumenToken.accent => accent,
      };

  /// Serialize the editable tokens (preset + ARGB ints) for `UserPrefs`.
  Map<String, int> toMap() => {
        'preset': preset.index,
        'background': background.toARGB32(),
        'surface': surface.toARGB32(),
        'body': body.toARGB32(),
        'heading': heading.toARGB32(),
        'caption': caption.toARGB32(),
        'accent': accent.toARGB32(),
        'border': border.toARGB32(),
      };

  factory LumenPalette.fromMap(Map<dynamic, dynamic> map) {
    final presetIdx = (map['preset'] as int?) ?? 0;
    final preset = LumenPreset.values[presetIdx.clamp(0, LumenPreset.values.length - 1)];
    if (preset != LumenPreset.custom) return forPreset(preset);
    return LumenPalette(
      preset: preset,
      background: Color(map['background'] as int),
      surface: Color(map['surface'] as int),
      body: Color(map['body'] as int),
      heading: Color(map['heading'] as int),
      caption: Color(map['caption'] as int),
      accent: Color(map['accent'] as int),
      border: Color(map['border'] as int),
    );
  }
}

/// Built-in palette presets (named on the onboarding "Pick your look" screen).
enum LumenPreset {
  midnight,
  archive,
  charcoal,
  custom;

  String get label => switch (this) {
        LumenPreset.midnight => 'Midnight',
        LumenPreset.archive => 'Archive',
        LumenPreset.charcoal => 'Charcoal',
        LumenPreset.custom => 'Custom',
      };
}

/// The five editable colour tokens on the Customize-colours screen.
enum LumenToken {
  background,
  body,
  heading,
  caption,
  accent;

  String get label => switch (this) {
        LumenToken.background => 'Background',
        LumenToken.body => 'Body text',
        LumenToken.heading => 'Heading',
        LumenToken.caption => 'Caption / small text',
        LumenToken.accent => 'Accent',
      };
}
