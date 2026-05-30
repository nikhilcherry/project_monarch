import 'package:hive/hive.dart';

import 'enums.dart';

part 'habit.g.dart';

/// A manual VIT wellness habit (e.g. digital detox, 8h sleep, meditation).
///
/// Checked off by hand from the Habits screen. Because there's no sensor to
/// verify it, the UI shows a "System Warning" confirmation on check-off to
/// discourage cheating (Phase 5). Completing habits feeds the VIT stat.
@HiveType(typeId: 5)
class Habit extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  HabitCategory category;

  /// VIT (or other) points awarded when honestly completed.
  @HiveField(3)
  int statReward;

  /// Which stat this habit feeds — defaults to Vitality.
  @HiveField(4)
  StatType feedsStat;

  /// Current consecutive-day streak.
  @HiveField(5)
  int streak;

  /// Longest streak ever achieved.
  @HiveField(6)
  int bestStreak;

  /// Day-key (yyyy-MM-dd) this habit was last completed, or `null`.
  @HiveField(7)
  String? lastCompletedDay;

  /// Whether the habit is currently active in the daily rotation.
  @HiveField(8)
  bool active;

  Habit({
    required this.id,
    required this.title,
    this.category = HabitCategory.recovery,
    this.statReward = 1,
    this.feedsStat = StatType.vit,
    this.streak = 0,
    this.bestStreak = 0,
    this.lastCompletedDay,
    this.active = true,
  });

  /// True if already completed for [dayKey] (yyyy-MM-dd).
  bool isCompletedOn(String dayKey) => lastCompletedDay == dayKey;

  Habit copyWith({
    String? id,
    String? title,
    HabitCategory? category,
    int? statReward,
    StatType? feedsStat,
    int? streak,
    int? bestStreak,
    String? lastCompletedDay,
    bool? active,
  }) =>
      Habit(
        id: id ?? this.id,
        title: title ?? this.title,
        category: category ?? this.category,
        statReward: statReward ?? this.statReward,
        feedsStat: feedsStat ?? this.feedsStat,
        streak: streak ?? this.streak,
        bestStreak: bestStreak ?? this.bestStreak,
        lastCompletedDay: lastCompletedDay ?? this.lastCompletedDay,
        active: active ?? this.active,
      );

  @override
  String toString() => 'Habit($id "$title" streak:$streak)';
}
