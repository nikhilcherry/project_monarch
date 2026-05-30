import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/database/database_service.dart';
import '../models/enums.dart'; // DayOutcome
import '../models/habit.dart';
import '../repositories/habit_repository.dart';
import 'providers.dart';

final habitRepositoryProvider = Provider<HabitRepository>((ref) {
  return HabitRepository(DatabaseService.habitsBox);
});

/// Live list of active habits + the check-off action that feeds the stat.
final habitsProvider =
    NotifierProvider<HabitsNotifier, List<Habit>>(HabitsNotifier.new);

class HabitsNotifier extends Notifier<List<Habit>> {
  HabitRepository get _repo => ref.read(habitRepositoryProvider);

  @override
  List<Habit> build() {
    final repo = _repo;
    repo.seedIfEmpty();
    return repo.getAll();
  }

  bool isDoneToday(Habit habit) => _repo.isDoneToday(habit);

  int get doneTodayCount => _repo.doneTodayCount();

  /// Confirm-and-complete a habit: extends streak, awards its stat, and stamps
  /// the consistency heatmap with a partial-day mark.
  ///
  /// Call ONLY after the user has cleared the "System Warning" dialog — that's
  /// the deliberate friction that makes self-reported honesty meaningful.
  Future<void> confirmComplete(Habit habit) async {
    if (_repo.isDoneToday(habit)) return;

    final updated = await _repo.completeToday(habit.id);

    // Feed the stat this habit develops (usually VIT).
    await ref
        .read(userStatsProvider.notifier)
        .applyRewards({updated.feedsStat: updated.statReward});

    // Light heatmap contribution — habits keep a day "alive" even without a
    // full dungeon clear. Intensity 1 won't override a workout's 4.
    await ref.read(consistencyRepositoryProvider).logToday(
          outcome: DayOutcome.partial,
          intensity: 1,
          questsCleared: 0,
        );
    ref.invalidate(heatmapDataProvider);
    ref.invalidate(streakProvider);

    state = _repo.getAll();
  }
}
