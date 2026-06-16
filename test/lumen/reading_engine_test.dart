import 'package:flutter_test/flutter_test.dart';
import 'package:project_monarch/lumen/core/constants/lumen_defaults.dart';
import 'package:project_monarch/lumen/services/chapter_splitter.dart';
import 'package:project_monarch/lumen/services/orp_engine.dart';
import 'package:project_monarch/lumen/services/rsvp_scheduler.dart';
import 'package:project_monarch/lumen/services/text_tokenizer.dart';

/// 1:1 mirror of `scripts/lumen/test_reading_engine.py`. Keep both in sync.
void main() {
  group('OrpEngine', () {
    test('pivot index scales with word length', () {
      expect(OrpEngine.pivotIndex('a'), 0);
      expect(OrpEngine.pivotIndex('read'), 1);
      expect(OrpEngine.pivotIndex('reading'), 2);
      expect(OrpEngine.pivotIndex('comprehend'), 3);
      expect(OrpEngine.pivotIndex('internationalization'), 4);
    });

    test('split reassembles to the original word with a single pivot', () {
      final s = OrpEngine.split('reading');
      expect(s.before + s.pivot + s.after, 'reading');
      expect(s.pivot.length, 1);
    });

    test('empty word is safe', () {
      expect(OrpEngine.pivotIndex(''), 0);
      final s = OrpEngine.split('');
      expect(s.pivot, '');
    });
  });

  group('TextTokenizer', () {
    test('peels trailing punctuation and flags sentence ends', () {
      final toks = TextTokenizer.tokenize('Hello, world. Fast!');
      expect(toks.length, 3);
      expect(toks[0].word, 'Hello');
      expect(toks[0].trailing, ',');
      expect(toks[0].endsSentence, isFalse);
      expect(toks[1].endsSentence, isTrue);
    });

    test('flags paragraph boundaries', () {
      final toks = TextTokenizer.tokenize('One two three.\n\nFour five.');
      expect(toks.any((t) => t.endsParagraph), isTrue);
    });

    test('keeps apostrophes and hyphens inside words', () {
      final toks = TextTokenizer.tokenize("don't well-read");
      expect(toks[0].word, "don't");
      expect(toks[1].word, 'well-read');
    });

    test('word count handles mixed whitespace', () {
      expect(TextTokenizer.wordCount('a  b\tc\nd'), 4);
    });
  });

  group('RsvpScheduler', () {
    test('base ms derives from WPM and clamps to range', () {
      expect(RsvpScheduler.baseMs(300), 200.0);
      expect(RsvpScheduler.baseMs(600), 100.0);
      expect(RsvpScheduler.baseMs(10), RsvpScheduler.baseMs(LumenDefaults.minWpm));
      expect(RsvpScheduler.baseMs(9999), RsvpScheduler.baseMs(LumenDefaults.maxWpm));
    });

    test('flat scheduling gives uniform frame durations', () {
      final frames =
          RsvpScheduler.schedule('The quick brown fox jumps.', 300);
      expect(frames.length, 5);
      expect(frames.map((f) => f.durationMs).toSet().length, 1);
    });

    test('smart pauses lengthen total and hold sentence ends longer', () {
      const text = 'The quick brown fox jumps.';
      final flat = RsvpScheduler.schedule(text, 300);
      final smart = RsvpScheduler.schedule(text, 300, smartPauses: true);
      expect(RsvpScheduler.totalMs(smart),
          greaterThan(RsvpScheduler.totalMs(flat)));
      expect(smart.last.durationMs, greaterThan(flat.last.durationMs));
    });

    test('300 words at 300 wpm is ~1 minute (flat)', () {
      final mins = RsvpScheduler.estimateMinutes('word ' * 300, 300);
      expect(mins, closeTo(1.0, 0.01));
    });

    test('every pivot index lands within its word', () {
      final frames = RsvpScheduler.schedule('a longerword end.', 300);
      for (final f in frames) {
        expect(f.pivotIndex, lessThan(f.word.length));
        expect(f.pivotIndex, greaterThanOrEqualTo(0));
      }
    });
  });

  group('ChapterSplitter', () {
    test('detects real headings as non-synthetic chapters', () {
      const book = 'Chapter 1\nThe beginning was quiet.\n\n'
          'Chapter 2\nThen everything changed.\n\n'
          'Chapter 3\nAnd calm returned.';
      final chs = ChapterSplitter.detect(book);
      expect(chs.length, 3);
      expect(chs[0].title, 'Chapter 1');
      expect(chs[0].text.contains('Chapter 1'), isFalse);
      expect(chs.every((c) => !c.synthetic), isTrue);
    });

    test('auto-sections long unstructured text into capped synthetic blocks', () {
      final plain = List.generate(2500, (i) => 'w$i').join(' ');
      final auto = ChapterSplitter.detect(plain);
      expect(auto.length, 3);
      expect(auto.every((c) => c.synthetic), isTrue);
      expect(auto[0].wordCount, LumenDefaults.autoSectionWords);
      expect(auto[0].title, 'Section 1');
    });

    test('short text stays a single section', () {
      expect(ChapterSplitter.detect('just a few plain words').length, 1);
    });

    test('fromToc preserves order and is not synthetic', () {
      final toc = ChapterSplitter.fromToc([('Intro', 'hi'), ('Outro', 'bye')]);
      expect(toc.map((c) => c.title).toList(), ['Intro', 'Outro']);
      expect(toc.every((c) => !c.synthetic), isTrue);
    });
  });
}
