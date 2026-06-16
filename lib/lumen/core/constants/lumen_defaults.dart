/// Single source of truth for Lumen's reading + Boost tuning.
///
/// Mirrors `scripts/lumen/reading_engine.py` exactly — keep the two in lockstep
/// so the Python reference suite stays a valid mirror of the Dart engines.
/// Everything here is deterministic (no AI): the same text + settings always
/// produce the same Boost stream.
abstract final class LumenDefaults {
  LumenDefaults._();

  // ---------------------------------------------------------------------------
  // Words-per-minute — the user owns this number, remembered per book.
  // ---------------------------------------------------------------------------

  static const int minWpm = 100;
  static const int maxWpm = 800;
  static const int defaultWpm = 300;
  static const int wpmStep = 25;

  // ---------------------------------------------------------------------------
  // Smart-pause timing. Multipliers scale the base ms/word (= 60000 / wpm),
  // so changing WPM preserves the rhythm. Opt-in toggle; when off every frame
  // uses the flat base duration.
  // ---------------------------------------------------------------------------

  static const int longWordLen = 8;
  static const double longWordExtraPerChar = 0.04;
  static const double longWordMaxExtra = 0.6;

  static const double pauseSoft = 1.5; // , ; : — (brief breath)
  static const double pauseHard = 2.2; // . ! ?    (end of thought)
  static const double pauseParagraph = 2.6; // end of paragraph

  static const int shortWordLen = 3;
  static const double shortWordScale = 0.9;

  static const Set<String> softPunct = {',', ';', ':', '—', '–'};
  static const Set<String> hardPunct = {'.', '!', '?'};

  // ---------------------------------------------------------------------------
  // Chapter auto-sectioning when a text exposes no structure.
  // ---------------------------------------------------------------------------

  static const int autoSectionWords = 1000;
}
