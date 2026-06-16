import 'dart:math' as math;

import '../core/constants/lumen_defaults.dart';
import 'orp_engine.dart';
import 'text_tokenizer.dart';

/// A single RSVP frame: the word to flash, its pivot, and how long to show it.
class RsvpFrame {
  const RsvpFrame({
    required this.word,
    required this.pivotIndex,
    required this.durationMs,
    this.endsSentence = false,
  });

  final String word;
  final int pivotIndex;
  final int durationMs;
  final bool endsSentence;
}

/// Turns text + a WPM into a list of timed [RsvpFrame]s that drive Boost.
///
/// Pure, deterministic mirror of `RsvpScheduler` in
/// `scripts/lumen/reading_engine.py`.
///   * [smartPauses] = false → every frame is the flat base duration.
///   * [smartPauses] = true  → a rule scales the base by word length and
///     trailing punctuation so dense prose reads naturally. No AI.
abstract final class RsvpScheduler {
  RsvpScheduler._();

  /// Milliseconds per word at [wpm] (clamped to the allowed range).
  static double baseMs(int wpm) {
    final clamped = wpm.clamp(LumenDefaults.minWpm, LumenDefaults.maxWpm);
    return 60000.0 / clamped;
  }

  static double _multiplier(ReadingToken token) {
    var mult = 1.0;
    final n = token.word.length;
    if (n <= LumenDefaults.shortWordLen) {
      mult *= LumenDefaults.shortWordScale;
    } else if (n > LumenDefaults.longWordLen) {
      final extra = (n - LumenDefaults.longWordLen) *
          LumenDefaults.longWordExtraPerChar;
      mult += math.min(extra, LumenDefaults.longWordMaxExtra);
    }
    // Strongest applicable punctuation pause wins.
    final trailingChars = token.trailing.split('');
    if (token.endsParagraph) {
      mult = math.max(mult, LumenDefaults.pauseParagraph);
    } else if (trailingChars.any(LumenDefaults.hardPunct.contains)) {
      mult = math.max(mult, LumenDefaults.pauseHard);
    } else if (trailingChars.any(LumenDefaults.softPunct.contains)) {
      mult = math.max(mult, LumenDefaults.pauseSoft);
    }
    return mult;
  }

  static List<RsvpFrame> schedule(
    String text,
    int wpm, {
    bool smartPauses = false,
  }) {
    final base = baseMs(wpm);
    final frames = <RsvpFrame>[];
    for (final tok in TextTokenizer.tokenize(text)) {
      final mult = smartPauses ? _multiplier(tok) : 1.0;
      frames.add(RsvpFrame(
        word: tok.display,
        pivotIndex: OrpEngine.pivotIndex(tok.word),
        durationMs: (base * mult).round(),
        endsSentence: tok.endsSentence,
      ));
    }
    return frames;
  }

  static int totalMs(List<RsvpFrame> frames) =>
      frames.fold(0, (sum, f) => sum + f.durationMs);

  static double estimateMinutes(
    String text,
    int wpm, {
    bool smartPauses = false,
  }) =>
      totalMs(schedule(text, wpm, smartPauses: smartPauses)) / 60000.0;
}
