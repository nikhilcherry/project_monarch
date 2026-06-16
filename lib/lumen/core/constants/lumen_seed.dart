import '../../models/book.dart';
import '../../models/chapter.dart';
import '../../services/chapter_splitter.dart';

/// First-run sample library. Texts here are short original placeholders — the
/// point is to exercise the real, deterministic [ChapterSplitter] (heading
/// detection → chapters) and give the UI something to render on first launch.
abstract final class LumenSeed {
  LumenSeed._();

  static List<Book> library() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final books = [
      _make(
        id: 'architect-of-silence',
        title: 'The Architect of Silence',
        author: 'Elias Thorne',
        addedAtMs: now,
        wpm: 420,
        colorValue: 0xFF1B2430,
        text: _architectText,
      ),
      _make(
        id: 'meditations',
        title: 'Meditations',
        author: 'Marcus Aurelius',
        addedAtMs: now - 1,
        text: _meditationsText,
      ),
      _make(
        id: 'letters-young-poet',
        title: 'Letters to a Young Poet',
        author: 'Rainer Maria Rilke',
        addedAtMs: now - 2,
        text: _lettersText,
      ),
      _make(
        id: 'walden',
        title: 'Walden',
        author: 'H. D. Thoreau',
        addedAtMs: now - 3,
        text: _waldenText,
      ),
    ];

    // Reflect the mockups: Architect is mid-read — chapter 1 done, chapter 2
    // partway through, landing the book around a third complete.
    final architect = books.first;
    if (architect.chapters.length >= 2) {
      architect.chapters[0].completed = true;
      architect.chapters[1].wordPosition =
          (architect.chapters[1].wordCount * 0.34).round();
      architect.currentChapterIndex = 1;
    }
    return books;
  }

  static Book _make({
    required String id,
    required String title,
    required String author,
    required String text,
    required int addedAtMs,
    int wpm = 300,
    int? colorValue,
  }) {
    final chapters = [
      for (final c in ChapterSplitter.detect(text.trim()))
        Chapter(
          title: c.title,
          text: c.text,
          wordCount: c.wordCount,
          synthetic: c.synthetic,
        ),
    ];
    return Book(
      id: id,
      title: title,
      author: author,
      chapters: chapters,
      addedAtMs: addedAtMs,
      wpm: wpm,
      coverColorValue: colorValue,
    );
  }
}

const String _architectText = '''
Chapter 1: The First Foundation
He measured the room not in metres but in echoes. Every surface returned a
different answer, and from those answers he drew the shape of the empty space.
The work began, as it always did, with listening. Before a single line was set
down, the architect waited until the silence had a grain he could read.

Chapter 2: Echoes of the Void
The silence of the deep archive was not an absence of sound, but a presence of
history. Footsteps dissolved into the velvet dust of a building that had
forgotten the physical world. He moved through the stacks slowly, tracing the
spines, listening for the one shelf that would answer him back.

Chapter 3: The Geometric Pulse
Order arrived later, and never all at once. A plan revealed itself the way a
tide reveals a shoreline — patiently, and only to those willing to stand still
long enough to notice the water pulling back.

Chapter 4: Whispering Steel
The last room was the hardest. Its walls leaned inward, fraying into a fine mist
of digital artifacts, and the boundary between maker and reader began to thin
until neither could say where one ended and the other began.
''';

const String _meditationsText = '''
Book One: Debts and Lessons
Begin each morning by reminding yourself what is in your power and what is not.
From the steady you may learn patience; from the restless, the value of a quiet
mind. Gratitude is the first discipline, and the easiest to forget.

Book Two: On the River
Everything you see is already changing. The present is a narrow bridge between
two vast countries you will never visit. Walk it with attention, and waste none
of it on what other minds are doing.
''';

const String _lettersText = '''
The First Letter
You ask whether your work is good. Stop asking. Go into yourself and find the
reason that commands you to write; learn whether it has sent roots into the
deepest place of your heart.

The Second Letter
Be patient toward all that is unsolved in your heart. Try to love the questions
themselves, like locked rooms and like books written in a foreign tongue. Live
the questions now, and gradually, without noticing, live into the answer.
''';

const String _waldenText = '''
Economy
I went to the woods because I wished to live deliberately, to face only the
essential facts, and to see whether I could not learn what it had to teach.
Simplicity, and a clear morning, were the whole of my fortune.

Where I Lived
The cost of a thing is the amount of life required to be exchanged for it. I
desired that there be as many different persons in the world as possible, and
wished each to find and follow their own way.
''';
