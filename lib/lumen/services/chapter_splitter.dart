import '../core/constants/lumen_defaults.dart';
import 'text_tokenizer.dart';

/// A readable + boostable unit of a book.
class ReadingChapter {
  ReadingChapter({
    required this.title,
    required this.text,
    this.synthetic = false,
  }) : wordCount = TextTokenizer.wordCount(text);

  final String title;
  final String text;

  /// True when Lumen invented the boundary (auto-section fallback) rather than
  /// reading it from the file's TOC or a detected heading.
  final bool synthetic;
  final int wordCount;
}

/// Breaks a book into chapters so progress always has a reachable finish line.
///
/// Pure mirror of `ChapterSplitter` in `scripts/lumen/reading_engine.py`.
/// Order of preference:
///   1. [fromToc] — real chapters handed in from an EPUB/PDF table of contents.
///   2. [detect] — no TOC: find heading lines ("Chapter 3", "IV.", ALL-CAPS).
///   3. [autoSection] — nothing detectable: even ~1000-word blocks.
abstract final class ChapterSplitter {
  ChapterSplitter._();

  static final List<RegExp> _headingPatterns = [
    RegExp(r'^\s*chapter\s+([0-9]+|[ivxlcdm]+|[a-z]+)\b', caseSensitive: false),
    RegExp(r'^\s*([0-9]{1,3})[\.\)]\s+\S'), // "12. Title"
    RegExp(r'^\s*([IVXLCDM]{1,7})[\.\)]\s+\S'), // "IV. Title"
    RegExp(r'^\s*(part|book|section)\s+\S+', caseSensitive: false),
  ];

  static bool _isHeading(String line) {
    final s = line.trim();
    if (s.isEmpty || s.length > 80) return false;
    for (final pat in _headingPatterns) {
      if (pat.hasMatch(s)) return true;
    }
    // Short ALL-CAPS line without terminal punctuation reads as a heading.
    final hasLetter = s.contains(RegExp(r'[A-Za-z]'));
    final notPunctEnd = !'.!?,;:'.contains(s[s.length - 1]);
    if (s.length <= 48 && s.toUpperCase() == s && hasLetter && notPunctEnd) {
      return true;
    }
    return false;
  }

  /// Detect chapters from headings, falling back to [autoSection].
  static List<ReadingChapter> detect(String text) {
    final lines = text.split('\n');
    final headingIdxs = <int>[];
    for (var i = 0; i < lines.length; i++) {
      if (_isHeading(lines[i])) headingIdxs.add(i);
    }
    if (headingIdxs.length >= 2) {
      final chapters = <ReadingChapter>[];
      final bounds = [...headingIdxs, lines.length];
      for (var j = 0; j < headingIdxs.length; j++) {
        final start = bounds[j];
        final end = bounds[j + 1];
        final title = lines[start].trim();
        final body = lines.sublist(start + 1, end).join('\n').trim();
        if (body.isNotEmpty) {
          chapters.add(ReadingChapter(title: title, text: body));
        }
      }
      if (chapters.isNotEmpty) return chapters;
    }
    return autoSection(text);
  }

  /// Slice unstructured text into evenly sized synthetic sections.
  static List<ReadingChapter> autoSection(
    String text, {
    int wordsPer = LumenDefaults.autoSectionWords,
  }) {
    final words =
        RegExp(r'\S+').allMatches(text).map((m) => m.group(0)!).toList();
    if (words.isEmpty) {
      return [ReadingChapter(title: 'Section 1', text: text.trim(), synthetic: true)];
    }
    final chapters = <ReadingChapter>[];
    for (var idx = 0; idx < words.length; idx += wordsPer) {
      final end = (idx + wordsPer < words.length) ? idx + wordsPer : words.length;
      final chunk = words.sublist(idx, end).join(' ');
      final n = idx ~/ wordsPer + 1;
      chapters.add(ReadingChapter(
        title: 'Section $n',
        text: chunk,
        synthetic: true,
      ));
    }
    return chapters;
  }

  /// Build chapters from an explicit (title, body) TOC, e.g. an EPUB spine.
  static List<ReadingChapter> fromToc(List<(String, String)> toc) =>
      [for (final (title, body) in toc) ReadingChapter(title: title, text: body)];
}
