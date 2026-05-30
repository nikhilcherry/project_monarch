import '../../models/enums.dart';
import '../../models/habit.dart';

/// Seed VIT wellness habits loaded on first run. These are manually checked off
/// (no sensor verifies them), so the UI guards each with a "System Warning".
abstract final class DefaultHabits {
  DefaultHabits._();

  static List<Habit> build() => [
        Habit(
          id: 'sleep_8h',
          title: '8 Hours of Sleep',
          category: HabitCategory.recovery,
          statReward: 2,
          feedsStat: StatType.vit,
        ),
        Habit(
          id: 'digital_detox',
          title: 'Digital Detox (1h)',
          category: HabitCategory.mindfulness,
          statReward: 2,
          feedsStat: StatType.vit,
        ),
        Habit(
          id: 'hydration',
          title: 'Drink 3L Water',
          category: HabitCategory.hydration,
          statReward: 1,
          feedsStat: StatType.vit,
        ),
        Habit(
          id: 'meditation',
          title: 'Meditate 10 min',
          category: HabitCategory.mindfulness,
          statReward: 1,
          feedsStat: StatType.vit,
        ),
        Habit(
          id: 'mobility_routine',
          title: 'Morning Mobility',
          category: HabitCategory.recovery,
          statReward: 1,
          feedsStat: StatType.flex,
        ),
        Habit(
          id: 'cold_shower',
          title: 'Cold Shower',
          category: HabitCategory.discipline,
          statReward: 1,
          feedsStat: StatType.vit,
        ),
      ];
}
