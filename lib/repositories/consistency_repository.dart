import 'package:hive/hive.dart';

import '../models/consistency_log.dart';
import '../models/enums.dart';

/// Persistence for the 365-day consistency heatmap. Entries are keyed by their
/// `yyyy-MM-dd` day-key for O(1) lookup/update.
class ConsistencyRepository {
  ConsistencyRepository(this._box);

  final Box<ConsistencyLog> _box;

  /// Stable day-key for [date] (date-only, no time component).
  static String keyFor(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  ConsistencyLog? forDay(DateTime date) => _box.get(keyFor(date));

  /// Upsert a day's record (e.g. after clearing quests).
  Future<void> record(ConsistencyLog log) => _box.put(log.dayKey, log);

  /// Convenience: stamp today's outcome/intensity, accumulating EXP & quests.
  Future<ConsistencyLog> logToday({
    required DayOutcome outcome,
    required int intensity,
    double expEarned = 0,
    int questsCleared = 0,
    bool penaltyIssued = false,
  }) async {
    final key = keyFor(DateTime.now());
    final existing = _box.get(key);
    final updated = ConsistencyLog(
      dayKey: key,
      outcome: outcome,
      intensity: intensity,
      expEarned: (existing?.expEarned ?? 0) + expEarned,
      questsCleared: (existing?.questsCleared ?? 0) + questsCleared,
      penaltyIssued: penaltyIssued || (existing?.penaltyIssued ?? false),
    );
    await _box.put(key, updated);
    return updated;
  }

  /// All logs as a {DateTime: intensity} map for the heatmap widget, restricted
  /// to roughly the last [days] days.
  Map<DateTime, int> heatmapData({int days = 365}) {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    final map = <DateTime, int>{};
    for (final log in _box.values) {
      final parts = log.dayKey.split('-');
      if (parts.length != 3) continue;
      final date = DateTime(
        int.parse(parts[0]),
        int.parse(parts[1]),
        int.parse(parts[2]),
      );
      if (date.isAfter(cutoff)) map[date] = log.intensity;
    }
    return map;
  }

  /// Current consecutive-day streak ending today (or yesterday).
  int currentStreak() {
    var streak = 0;
    var cursor = DateTime.now();
    // Allow today to be empty without breaking the streak.
    if (forDay(cursor) == null) {
      cursor = cursor.subtract(const Duration(days: 1));
    }
    while (true) {
      final log = forDay(cursor);
      if (log == null || log.intensity <= 0) break;
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }
}
