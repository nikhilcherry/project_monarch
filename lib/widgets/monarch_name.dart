import 'package:flutter/material.dart';

/// A text widget for **names** (dungeons, realms, titles, quests, habits) that
/// enforces Project Monarch's strict naming rule: names are ALWAYS shown in
/// full — never truncated, abbreviated, or ellipsized. It wraps freely and
/// never sets [TextOverflow.ellipsis].
///
/// Use this anywhere a generated or catalog name is displayed so no screen can
/// accidentally re-introduce a "The Awak…" clip.
class MonarchName extends StatelessWidget {
  const MonarchName(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
  });

  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;

  /// Optional soft cap on lines. Null = unlimited (always fully shown). Even
  /// when set, overflow is visible (wrapped), never ellipsized.
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: style,
      textAlign: textAlign,
      softWrap: true,
      maxLines: maxLines,
      overflow: TextOverflow.visible,
    );
  }
}
