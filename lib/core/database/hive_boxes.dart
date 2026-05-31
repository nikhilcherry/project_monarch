/// Canonical Hive box + key names.
///
/// Centralized so we never typo a box name and the persistence layer stays the
/// single offline source of truth. Singleton profile/stats live under a fixed
/// key inside their box; nodes/habits/logs are keyed by their own ids.
abstract final class HiveBoxes {
  HiveBoxes._();

  // Box names
  static const String userStats = 'box_user_stats';
  static const String rankProfile = 'box_rank_profile';
  static const String workoutNodes = 'box_workout_nodes';
  static const String habits = 'box_habits';
  static const String consistency = 'box_consistency';
  static const String nutrition = 'box_nutrition';
  static const String penalties = 'box_penalties';
  static const String dailyQuests = 'box_daily_quests';
  static const String settings = 'box_settings';

  // Fixed keys for singleton records.
  static const String primaryKey = 'primary';
}
