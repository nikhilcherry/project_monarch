import 'package:flutter_test/flutter_test.dart';
import 'package:project_monarch/core/constants/game_balance.dart';
import 'package:project_monarch/models/exercise_entry.dart';
import 'package:project_monarch/services/overload_engine.dart';

void main() {
  group('OverloadEngine.progress', () {
    test('weighted lifts gain load by the overload step', () {
      final entry = ExerciseEntry(
        name: 'Bench Press',
        targetSets: 3,
        targetReps: 8,
        targetWeight: 60,
        overloadStep: 2.5,
      );
      final next = OverloadEngine.progress(entry);

      expect(next.targetWeight, 62.5);
      expect(next.targetSets, 3);
      expect(next.targetReps, 8);
      expect(next.completed, false);
    });

    test('bodyweight movements gain reps', () {
      final entry = ExerciseEntry(name: 'Push-ups', targetSets: 3, targetReps: 10);
      final next = OverloadEngine.progress(entry);

      expect(next.targetWeight, isNull);
      expect(next.targetReps, 10 + GameBalance.defaultRepStep);
      expect(next.targetSets, 3);
    });

    test('reps roll into an extra set past the threshold', () {
      final entry = ExerciseEntry(
        name: 'Squats',
        targetSets: 3,
        targetReps: GameBalance.repRolloverThreshold, // at the cap
      );
      final next = OverloadEngine.progress(entry);

      expect(next.targetSets, 4); // gained a set
      expect(next.targetReps, 8); // reset to working range
    });

    test('does not mutate the original entry', () {
      final entry = ExerciseEntry(name: 'Dips', targetReps: 10, targetWeight: 20);
      OverloadEngine.progress(entry);
      expect(entry.targetWeight, 20); // unchanged
    });

    test('progressAll progresses every entry', () {
      final entries = [
        ExerciseEntry(name: 'A', targetReps: 10),
        ExerciseEntry(name: 'B', targetReps: 10, targetWeight: 40),
      ];
      final next = OverloadEngine.progressAll(entries);
      expect(next[0].targetReps, 11);
      expect(next[1].targetWeight, 42.5);
    });
  });
}
