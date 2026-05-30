import 'package:hive_flutter/hive_flutter.dart';

import '../../models/consistency_log.dart';
import '../../models/enums.dart';
import '../../models/exercise_entry.dart';
import '../../models/habit.dart';
import '../../models/rank_profile.dart';
import '../../models/user_stats.dart';
import '../../models/workout_node.dart';
import 'hive_boxes.dart';

/// Owns Hive bootstrap: registers every generated [TypeAdapter] exactly once and
/// opens all boxes the app needs. Call [DatabaseService.init] from `main()`
/// after `Hive.initFlutter()`.
///
/// Keeping registration in one place avoids duplicate-typeId crashes and gives
/// the repositories (next layer) a guaranteed-open set of boxes to read/write.
abstract final class DatabaseService {
  DatabaseService._();

  static bool _initialized = false;

  /// Register adapters + open boxes. Idempotent.
  static Future<void> init() async {
    if (_initialized) return;

    _registerAdapters();
    await _openBoxes();

    _initialized = true;
  }

  static void _registerAdapters() {
    // Enums (typeIds 20–25)
    _safeRegister(RankAdapter());
    _safeRegister(StatTypeAdapter());
    _safeRegister(NodeStatusAdapter());
    _safeRegister(MuscleGroupAdapter());
    _safeRegister(HabitCategoryAdapter());
    _safeRegister(DayOutcomeAdapter());

    // Models (typeIds 1–6)
    _safeRegister(UserStatsAdapter());
    _safeRegister(RankProfileAdapter());
    _safeRegister(WorkoutNodeAdapter());
    _safeRegister(ExerciseEntryAdapter());
    _safeRegister(HabitAdapter());
    _safeRegister(ConsistencyLogAdapter());
  }

  /// Register an adapter only if its typeId isn't already taken (hot-restart safe).
  static void _safeRegister<T>(TypeAdapter<T> adapter) {
    if (!Hive.isAdapterRegistered(adapter.typeId)) {
      Hive.registerAdapter(adapter);
    }
  }

  static Future<void> _openBoxes() async {
    await Future.wait([
      Hive.openBox<UserStats>(HiveBoxes.userStats),
      Hive.openBox<RankProfile>(HiveBoxes.rankProfile),
      Hive.openBox<WorkoutNode>(HiveBoxes.workoutNodes),
      Hive.openBox<Habit>(HiveBoxes.habits),
      Hive.openBox<ConsistencyLog>(HiveBoxes.consistency),
      Hive.openBox<dynamic>(HiveBoxes.settings),
    ]);
  }

  // ---------------------------------------------------------------------------
  // Typed box accessors — repositories use these instead of touching Hive.
  // ---------------------------------------------------------------------------

  static Box<UserStats> get userStatsBox =>
      Hive.box<UserStats>(HiveBoxes.userStats);

  static Box<RankProfile> get rankProfileBox =>
      Hive.box<RankProfile>(HiveBoxes.rankProfile);

  static Box<WorkoutNode> get workoutNodesBox =>
      Hive.box<WorkoutNode>(HiveBoxes.workoutNodes);

  static Box<Habit> get habitsBox => Hive.box<Habit>(HiveBoxes.habits);

  static Box<ConsistencyLog> get consistencyBox =>
      Hive.box<ConsistencyLog>(HiveBoxes.consistency);

  static Box<dynamic> get settingsBox => Hive.box<dynamic>(HiveBoxes.settings);

  /// Wipe everything — used by a "reset progress" action / tests.
  static Future<void> clearAll() async {
    await Future.wait([
      userStatsBox.clear(),
      rankProfileBox.clear(),
      workoutNodesBox.clear(),
      habitsBox.clear(),
      consistencyBox.clear(),
      settingsBox.clear(),
    ]);
  }
}
