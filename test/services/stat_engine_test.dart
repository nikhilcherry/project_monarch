import 'package:flutter_test/flutter_test.dart';
import 'package:project_monarch/core/constants/game_balance.dart';
import 'package:project_monarch/models/enums.dart';
import 'package:project_monarch/models/exercise_entry.dart';
import 'package:project_monarch/models/workout_node.dart';
import 'package:project_monarch/services/stat_engine.dart';

void main() {
  group('StatEngine.distribute', () {
    test('grants at least the minimum primary stat for a tiny node', () {
      final node = WorkoutNode(
        id: 'n',
        title: 'Tiny',
        muscleGroup: MuscleGroup.chest, // primary STR
        exercises: [ExerciseEntry(name: 'x', targetSets: 1, targetReps: 1)],
      );
      final dist = StatEngine.distribute(node);
      expect(dist[StatType.str], greaterThanOrEqualTo(GameBalance.minPrimaryStatGain));
    });

    test('preserves designer-authored statRewards', () {
      final node = WorkoutNode(
        id: 'n',
        title: 'Boss',
        muscleGroup: MuscleGroup.legs, // primary STR, secondary AGI
        statRewards: const {StatType.vit: 5},
        exercises: [ExerciseEntry(name: 'x', targetSets: 4, targetReps: 12)],
      );
      final dist = StatEngine.distribute(node);
      // Designer reward kept...
      expect(dist[StatType.vit], greaterThanOrEqualTo(5));
      // ...and primary attribute added on top.
      expect(dist[StatType.str], isNotNull);
    });

    test('higher volume yields more primary stat', () {
      WorkoutNode make(int reps) => WorkoutNode(
            id: 'n',
            title: 't',
            muscleGroup: MuscleGroup.back,
            exercises: [
              ExerciseEntry(name: 'x', targetSets: 5, targetReps: reps, targetWeight: 50),
            ],
          );
      final low = StatEngine.distribute(make(5))[StatType.str]!;
      final high = StatEngine.distribute(make(20))[StatType.str]!;
      expect(high, greaterThan(low));
    });

    test('adds a secondary attribute distinct from the primary', () {
      final node = WorkoutNode(
        id: 'n',
        title: 't',
        muscleGroup: MuscleGroup.mobility, // primary FLEX, secondary AGI
        exercises: [
          ExerciseEntry(name: 'x', targetSets: 5, targetReps: 15, targetWeight: 40),
        ],
      );
      final dist = StatEngine.distribute(node);
      expect(dist[StatType.flex], isNotNull);
      expect(dist[StatType.agi], isNotNull);
    });

    test('totalPoints sums the distribution', () {
      final dist = {StatType.str: 3, StatType.end: 2};
      expect(StatEngine.totalPoints(dist), 5);
    });
  });
}
