import 'package:hive/hive.dart';

/// Stores the weekly training schedule — which weekdays are configured as rest
/// days. Everything else is a mandatory day. Backed by the settings box.
///
/// Weekdays follow Dart's `DateTime.weekday`: Mon=1 … Sun=7.
class ScheduleRepository {
  ScheduleRepository(this._settings);

  final Box<dynamic> _settings;

  static const _kRestDays = 'schedule_rest_days';
  static const _kLastCheck = 'schedule_last_check';

  /// Default: Sunday is the lone rest day.
  static const List<int> _defaultRestDays = [DateTime.sunday];

  Set<int> restDays() {
    final raw = _settings.get(_kRestDays, defaultValue: _defaultRestDays);
    return {...(raw as List).cast<int>()};
  }

  Future<void> setRestDays(Set<int> days) =>
      _settings.put(_kRestDays, days.toList()..sort());

  bool isRestDay(DateTime date) => restDays().contains(date.weekday);

  /// Toggle a single weekday's rest status.
  Future<void> toggleRestDay(int weekday) async {
    final days = restDays();
    if (days.contains(weekday)) {
      days.remove(weekday);
    } else {
      days.add(weekday);
    }
    await setRestDays(days);
  }

  /// The last day-key the daily penalty check processed (or null on first run).
  String? lastCheckDayKey() =>
      _settings.get(_kLastCheck, defaultValue: null) as String?;

  Future<void> setLastCheckDayKey(String dayKey) =>
      _settings.put(_kLastCheck, dayKey);
}
