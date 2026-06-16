import 'package:hive/hive.dart';

part 'reading_session.g.dart';

/// A single completed reading/Boost stint — the raw rows behind the Stats
/// screen (words read, time focused, current WPM, the velocity sparkline).
@HiveType(typeId: 43)
class ReadingSession extends HiveObject {
  ReadingSession({
    required this.timestampMs,
    required this.wordsRead,
    required this.wpm,
    required this.durationMs,
    this.boosted = false,
  });

  @HiveField(0)
  int timestampMs;

  @HiveField(1)
  int wordsRead;

  @HiveField(2)
  int wpm;

  @HiveField(3)
  int durationMs;

  /// Whether this stint used Boost (RSVP) rather than normal reading.
  @HiveField(4)
  bool boosted;

  DateTime get timestamp => DateTime.fromMillisecondsSinceEpoch(timestampMs);
}
