import 'package:hive/hive.dart';

part 'user_prefs.g.dart';

/// All app-wide preferences + lightweight aggregate stats. A single instance
/// lives at a fixed key in the prefs box.
@HiveType(typeId: 44)
class UserPrefs extends HiveObject {
  UserPrefs({
    Map<String, int>? paletteMap,
    this.defaultWpm = 300,
    this.smartPauses = false,
    this.fontScale = 1.0,
    this.onboardingDone = false,
    this.streakDays = 0,
    this.lastReadDayEpoch = 0,
    this.totalWordsRead = 0,
    this.totalReadMs = 0,
  }) : paletteMap = paletteMap ?? <String, int>{};

  /// Serialized [LumenPalette] (preset index + ARGB tokens).
  @HiveField(0)
  Map<String, int> paletteMap;

  /// Starting WPM for newly opened books (each book then remembers its own).
  @HiveField(1)
  int defaultWpm;

  /// Opt-in deterministic pause weighting in Boost.
  @HiveField(2)
  bool smartPauses;

  @HiveField(3)
  double fontScale;

  @HiveField(4)
  bool onboardingDone;

  @HiveField(5)
  int streakDays;

  /// Day-resolution epoch (ms since epoch / msPerDay) of the last reading day.
  @HiveField(6)
  int lastReadDayEpoch;

  @HiveField(7)
  int totalWordsRead;

  @HiveField(8)
  int totalReadMs;
}
