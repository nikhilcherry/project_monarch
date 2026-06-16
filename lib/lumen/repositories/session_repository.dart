import 'package:hive/hive.dart';

import '../models/reading_session.dart';

/// Persistence for reading sessions (the data behind the Stats screen).
class SessionRepository {
  SessionRepository(this._box);

  final Box<ReadingSession> _box;

  Future<void> add(ReadingSession session) => _box.add(session);

  List<ReadingSession> all() {
    final list = _box.values.toList();
    list.sort((a, b) => a.timestampMs.compareTo(b.timestampMs));
    return list;
  }

  /// Total words read across every session.
  int get totalWords => _box.values.fold(0, (s, e) => s + e.wordsRead);

  /// Total focused milliseconds across every session.
  int get totalMs => _box.values.fold(0, (s, e) => s + e.durationMs);

  /// Most recent session's WPM, or null if there are none yet.
  int? get currentWpm {
    if (_box.isEmpty) return null;
    return all().last.wpm;
  }
}
