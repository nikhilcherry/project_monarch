import 'package:hive/hive.dart';

part 'chapter.g.dart';

/// One readable + boostable unit of a book.
///
/// Position is tracked at the word level so the reader and Boost share a single
/// place: closing Boost mid-chapter returns the reader to the same word.
@HiveType(typeId: 41)
class Chapter extends HiveObject {
  Chapter({
    required this.title,
    required this.text,
    required this.wordCount,
    this.synthetic = false,
    this.wordPosition = 0,
    this.completed = false,
  });

  @HiveField(0)
  String title;

  @HiveField(1)
  String text;

  /// Total words in [text] (precomputed by the tokenizer at import time).
  @HiveField(2)
  int wordCount;

  /// True when Lumen invented the boundary (auto-section), not a real heading.
  @HiveField(3)
  bool synthetic;

  /// Reading cursor: index of the next word to read (shared reader ↔ Boost).
  @HiveField(4)
  int wordPosition;

  @HiveField(5)
  bool completed;

  /// 0..1 progress through this chapter.
  double get progress {
    if (wordCount == 0) return completed ? 1 : 0;
    if (completed) return 1;
    return (wordPosition / wordCount).clamp(0.0, 1.0);
  }
}
