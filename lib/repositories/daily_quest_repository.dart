import 'package:hive/hive.dart';

import '../models/daily_quest.dart';

/// Persistence for Daily Quests. Per-day claim state lives in the typed daily
/// box (one [DailyQuest] per day-key); the persistent check-in streak lives in
/// the settings box.
class DailyQuestRepository {
  DailyQuestRepository(this._box, this._settings);

  final Box<DailyQuest> _box;
  final Box<dynamic> _settings;

  static const _kStreak = 'checkin_streak';
  static const _kLastCheckIn = 'last_checkin_day';

  /// Days needed for the weekly streak bonus.
  static const int streakTarget = 7;

  static String keyFor(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  String get todayKey => keyFor(DateTime.now());

  /// Today's quest record, created (and persisted) on first access.
  DailyQuest today() {
    final existing = _box.get(todayKey);
    if (existing != null) return existing;
    final fresh = DailyQuest(dayKey: todayKey);
    _box.put(todayKey, fresh);
    return fresh;
  }

  Future<void> save(DailyQuest quest) => _box.put(quest.dayKey, quest);

  // --- Streak ---------------------------------------------------------------

  int streak() => _settings.get(_kStreak, defaultValue: 0) as int;

  String? lastCheckInDay() => _settings.get(_kLastCheckIn) as String?;

  Future<void> setStreak(int value) => _settings.put(_kStreak, value);

  Future<void> setLastCheckInDay(String dayKey) =>
      _settings.put(_kLastCheckIn, dayKey);
}
