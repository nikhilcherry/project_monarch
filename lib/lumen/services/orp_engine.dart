/// Optimal Recognition Point — the amber pivot letter in Boost (RSVP).
///
/// Pure, deterministic mirror of `OrpEngine` in
/// `scripts/lumen/reading_engine.py`. Returns a letter *index* (not a pixel)
/// so the UI stays free to align that letter to a fixed focal column and tint
/// it with the accent colour. Based on the Spritz heuristic: the recognition
/// point sits just left of centre and drifts right as words grow.
abstract final class OrpEngine {
  OrpEngine._();

  /// Index of the pivot letter within [word].
  static int pivotIndex(String word) {
    final n = word.length;
    if (n <= 1) return 0;
    if (n <= 5) return 1;
    if (n <= 9) return 2;
    if (n <= 13) return 3;
    return 4;
  }

  /// Split [word] into the three parts the UI renders: text before the pivot,
  /// the single pivot letter, and text after it.
  static ({String before, String pivot, String after}) split(String word) {
    final i = pivotIndex(word);
    if (word.isEmpty) return (before: '', pivot: '', after: '');
    return (
      before: word.substring(0, i),
      pivot: word.substring(i, i + 1),
      after: word.substring(i + 1),
    );
  }
}
