import 'package:hive/hive.dart';

import '../core/constants/default_habits.dart';
import '../models/habit.dart';
import 'consistency_repository.dart';

/// Persistence + streak logic for VIT wellness habits.
class HabitRepository {
  HabitRepository(this._box);

  final Box<Habit> _box;

  Future<void> seedIfEmpty() async {
    if (_box.isEmpty) {
      for (final habit in DefaultHabits.build()) {
        await _box.put(habit.id, habit);
      }
    }
  }

  List<Habit> getAll() => _box.values.where((h) => h.active).toList();

  Habit? getById(String id) => _box.get(id);

  Future<void> save(Habit habit) => _box.put(habit.id, habit);

  /// Honestly complete a habit for today: advance/extend the streak and stamp
  /// today's day-key. Returns the updated habit (or the same if already done).
  ///
  /// Streak rule: completing on the day after [Habit.lastCompletedDay] extends
  /// the streak; a gap resets it to 1.
  Future<Habit> completeToday(String id) async {
    final habit = _box.get(id);
    if (habit == null) return Habit(id: id, title: 'Unknown');

    final today = ConsistencyRepository.keyFor(DateTime.now());
    if (habit.isCompletedOn(today)) return habit; // idempotent

    final yesterday = ConsistencyRepository.keyFor(
      DateTime.now().subtract(const Duration(days: 1)),
    );
    final continued = habit.lastCompletedDay == yesterday;
    final newStreak = continued ? habit.streak + 1 : 1;

    final updated = habit.copyWith(
      streak: newStreak,
      bestStreak: newStreak > habit.bestStreak ? newStreak : habit.bestStreak,
      lastCompletedDay: today,
    );
    await _box.put(id, updated);
    return updated;
  }

  /// True when a habit has already been completed today.
  bool isDoneToday(Habit habit) =>
      habit.isCompletedOn(ConsistencyRepository.keyFor(DateTime.now()));

  /// How many active habits are done today — drives daily progress UI.
  int doneTodayCount() {
    final today = ConsistencyRepository.keyFor(DateTime.now());
    return _box.values.where((h) => h.active && h.isCompletedOn(today)).length;
  }
}
