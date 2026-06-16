import '../core/constants/lumen_defaults.dart';

/// One displayable word plus the punctuation context that follows it.
class ReadingToken {
  const ReadingToken({
    required this.word,
    this.trailing = '',
    this.endsParagraph = false,
  });

  /// The visible word (letters/digits/apostrophes/hyphens, no trailing space).
  final String word;

  /// Punctuation immediately after the word, e.g. "," or ".".
  final String trailing;

  /// True when this is the last word of a paragraph (a blank line follows).
  final bool endsParagraph;

  /// Whether the trailing punctuation closes a sentence.
  bool get endsSentence =>
      trailing.split('').any(LumenDefaults.hardPunct.contains);

  /// Word + its trailing punctuation, as shown in a single RSVP frame.
  String get display => '$word$trailing';
}

/// Splits raw text into [ReadingToken]s. Pure mirror of `TextTokenizer` in
/// `scripts/lumen/reading_engine.py`.
abstract final class TextTokenizer {
  TextTokenizer._();

  static final RegExp _word = RegExp(r'\S+');
  static final RegExp _paragraphBreak = RegExp(r'\n\s*\n');
  // (word core)(trailing non-word punctuation). Keeps ' ’ - inside the word.
  static final RegExp _peel = RegExp(r"^(.*?)([^\w'’\-]*)$", unicode: true);

  static List<ReadingToken> tokenize(String text) {
    final tokens = <ReadingToken>[];
    final paragraphs = text.trim().split(_paragraphBreak);
    for (final para in paragraphs) {
      final raws = _word.allMatches(para).map((m) => m.group(0)!).toList();
      for (var i = 0; i < raws.length; i++) {
        final raw = raws[i];
        final m = _peel.firstMatch(raw);
        final core = (m != null && m.group(1)!.isNotEmpty) ? m.group(1)! : raw;
        final trailing = m?.group(2) ?? '';
        tokens.add(ReadingToken(
          word: core,
          trailing: trailing,
          endsParagraph: i == raws.length - 1,
        ));
      }
    }
    return tokens;
  }

  static int wordCount(String text) => _word.allMatches(text).length;
}
