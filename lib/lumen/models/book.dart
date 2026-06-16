import 'package:hive/hive.dart';

import 'chapter.dart';

part 'book.g.dart';

/// A book/article in the library. The single source of truth for its chapters,
/// reading position, and per-book WPM.
@HiveType(typeId: 40)
class Book extends HiveObject {
  Book({
    required this.id,
    required this.title,
    required this.author,
    required this.chapters,
    required this.addedAtMs,
    this.currentChapterIndex = 0,
    this.wpm = 300,
    this.coverColorValue,
  });

  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String author;

  @HiveField(3)
  List<Chapter> chapters;

  @HiveField(4)
  int addedAtMs;

  @HiveField(5)
  int currentChapterIndex;

  /// Per-book reading speed, remembered across sessions.
  @HiveField(6)
  int wpm;

  /// Optional ARGB tint for the auto-generated typographic cover (null = accent).
  @HiveField(7)
  int? coverColorValue;

  int get totalWords =>
      chapters.fold(0, (sum, c) => sum + c.wordCount);

  int get wordsRead =>
      chapters.fold(0, (sum, c) => sum + (c.completed ? c.wordCount : c.wordPosition));

  /// Overall 0..1 progress across the whole book.
  double get progress {
    final total = totalWords;
    if (total == 0) return 0;
    return (wordsRead / total).clamp(0.0, 1.0);
  }

  int get progressPercent => (progress * 100).round();

  Chapter get currentChapter =>
      chapters[currentChapterIndex.clamp(0, chapters.length - 1)];

  /// First letter, for the typographic cover monogram.
  String get monogram => title.trim().isEmpty ? '?' : title.trim()[0].toUpperCase();
}
