import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/penalty_template.dart';
import '../core/database/database_service.dart';
import '../models/consistency_log.dart';
import '../models/enums.dart';
import '../models/penalty_quest.dart';
import '../repositories/consistency_repository.dart';
import '../repositories/penalty_repository.dart';
import '../repositories/schedule_repository.dart';
import 'providers.dart';

final scheduleRepositoryProvider = Provider<ScheduleRepository>((ref) {
  return ScheduleRepository(DatabaseService.settingsBox);
});

final penaltyRepositoryProvider = Provider<PenaltyRepository>((ref) {
  return PenaltyRepository(DatabaseService.penaltiesBox);
});

/// The configured rest weekdays (Mon=1 … Sun=7).
final restDaysProvider = Provider<Set<int>>((ref) {
  return ref.watch(scheduleRepositoryProvider).restDays();
});

/// Live list of unresolved penalty quests. On build it runs the daily check,
/// so simply opening the app reconciles any missed mandatory days.
final penaltiesProvider =
    NotifierProvider<PenaltiesNotifier, List<PenaltyQuest>>(
        PenaltiesNotifier.new);

class PenaltiesNotifier extends Notifier<List<PenaltyQuest>> {
  PenaltyRepository get _penalties => ref.read(penaltyRepositoryProvider);
  ScheduleRepository get _schedule => ref.read(scheduleRepositoryProvider);
  ConsistencyRepository get _consistency =>
      ref.read(consistencyRepositoryProvider);

  @override
  List<PenaltyQuest> build() {
    // Reconcile missed days, then expose the active penalties.
    _runDailyCheck();
    return _penalties.active();
  }

  /// Walk every elapsed day since the last check up to yesterday. Rest days are
  /// stamped neutral; mandatory days with no positive activity count as missed.
  /// Missed days are docked EXP once and rolled into a single penalty quest.
  Future<void> _runDailyCheck() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final todayKey = ConsistencyRepository.keyFor(today);

    final lastKey = _schedule.lastCheckDayKey();
    // First run: look back a week so we don't fabricate a huge penalty history.
    DateTime cursor = lastKey != null
        ? _parse(lastKey).add(const Duration(days: 1))
        : today.subtract(const Duration(days: 7));

    var missed = 0;
    String? firstMissedKey;

    while (cursor.isBefore(today)) {
      final key = ConsistencyRepository.keyFor(cursor);
      final log = _consistency.forDay(cursor);
      final hadActivity = (log?.intensity ?? 0) > 0;

      if (_schedule.isRestDay(cursor)) {
        // Mark neutral rest day if nothing logged (keeps the heatmap honest).
        if (log == null) {
          await _consistency.record(
            ConsistencyLog(
                dayKey: key, outcome: DayOutcome.rest, intensity: 0),
          );
        }
      } else if (!hadActivity) {
        missed++;
        firstMissedKey ??= key;
        await _consistency.record(
          ConsistencyLog(
            dayKey: key,
            outcome: DayOutcome.penalty,
            intensity: 0,
            penaltyIssued: true,
          ),
        );
      }
      cursor = cursor.add(const Duration(days: 1));
    }

    if (missed > 0 && firstMissedKey != null) {
      await _issuePenalty(missed, firstMissedKey);
    }

    await _schedule.setLastCheckDayKey(todayKey);
  }

  Future<void> _issuePenalty(int missed, String dayKey) async {
    if (_penalties.existsForDay(dayKey)) return; // idempotent

    final quest = PenaltyTemplate.build(
      id: 'penalty_$dayKey',
      issuedDayKey: dayKey,
      missedDays: missed,
    );
    await _penalties.save(quest);

    // Apply the EXP dock once, now.
    await ref.read(rankProfileProvider.notifier).awardExp(quest.penaltyApplied);
  }

  /// Mark a penalty quest cleared (called after its checklist is completed).
  Future<void> resolve(String id) async {
    await _penalties.resolve(id);
    // Clearing a penalty redeems the day on the heatmap.
    final quest = _penalties.getById(id);
    if (quest != null) {
      await _consistency.record(
        ConsistencyLog(
          dayKey: quest.issuedDayKey,
          outcome: DayOutcome.partial,
          intensity: 2,
          penaltyIssued: true,
        ),
      );
      ref.invalidate(heatmapDataProvider);
      ref.invalidate(streakProvider);
    }
    state = _penalties.active();
  }

  static DateTime _parse(String dayKey) {
    final p = dayKey.split('-');
    return DateTime(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
  }
}
