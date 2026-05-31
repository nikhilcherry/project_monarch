import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/database/database_service.dart';
import '../models/daily_quest.dart';
import '../repositories/daily_quest_repository.dart';
import 'habits_controller.dart';
import 'nutrition_controller.dart';
import 'providers.dart';

final dailyQuestRepositoryProvider = Provider<DailyQuestRepository>((ref) {
  return DailyQuestRepository(
    DatabaseService.dailyQuestsBox,
    DatabaseService.settingsBox,
  );
});

/// The three daily quest kinds. Not persisted (claim state lives on
/// [DailyQuest]); used to drive the UI and claim routing.
enum DailyQuestKind { checkIn, fieldDrill, overdrive }

/// View model for one quest card.
class DailyQuestVm {
  final DailyQuestKind kind;
  final String title;
  final String description;
  final int crystals;
  final int coins;

  /// Whether the unlock condition is met (Check-In is always available).
  final bool available;
  final bool claimed;

  const DailyQuestVm({
    required this.kind,
    required this.title,
    required this.description,
    required this.crystals,
    required this.coins,
    required this.available,
    required this.claimed,
  });

  bool get claimable => available && !claimed;
}

/// Immutable snapshot for the Daily screen.
class DailyQuestsState {
  final List<DailyQuestVm> quests;
  final int streak;
  final int streakTarget;
  final int streakCrystalReward;
  final bool streakBonusClaimedToday;

  const DailyQuestsState({
    required this.quests,
    required this.streak,
    required this.streakTarget,
    required this.streakCrystalReward,
    required this.streakBonusClaimedToday,
  });
}

final dailyQuestsProvider =
    NotifierProvider<DailyQuestsNotifier, DailyQuestsState>(
        DailyQuestsNotifier.new);

class DailyQuestsNotifier extends Notifier<DailyQuestsState> {
  DailyQuestRepository get _repo => ref.read(dailyQuestRepositoryProvider);

  // Payouts scale with the rank factor R (= tier + 1), per GAME_DESIGN_V2 §3.2.
  int get _r => ref.read(rankProfileProvider).rankFactor;
  int get _crystalsPerQuest => 10 * _r;
  int get _coinsPerQuest => 5 * _r;
  int get _streakCrystal => 50 * _r;
  int get _streakCoin => 25 * _r;

  @override
  DailyQuestsState build() {
    // Recompute when the things quests depend on change.
    ref.watch(rankProfileProvider);
    ref.watch(habitsProvider);
    ref.watch(nutritionProvider);
    return _read();
  }

  DailyQuestsState _read() {
    final q = _repo.today();
    final c = _crystalsPerQuest;
    final co = _coinsPerQuest;

    return DailyQuestsState(
      streak: _repo.streak(),
      streakTarget: DailyQuestRepository.streakTarget,
      streakCrystalReward: _streakCrystal,
      streakBonusClaimedToday: q.streakBonusClaimed,
      quests: [
        DailyQuestVm(
          kind: DailyQuestKind.checkIn,
          title: 'System Check-In',
          description: 'Report in to the System. Always available.',
          crystals: c,
          coins: co,
          available: true,
          claimed: q.checkInClaimed,
        ),
        DailyQuestVm(
          kind: DailyQuestKind.fieldDrill,
          title: 'Field Drill',
          description: 'Clear any dungeon on the World Map today.',
          crystals: c,
          coins: co,
          available: _clearedDungeonToday(),
          claimed: q.fieldDrillClaimed,
        ),
        DailyQuestVm(
          kind: DailyQuestKind.overdrive,
          title: 'Overdrive',
          description: 'Complete a wellness habit and hit a macro target today.',
          crystals: c,
          coins: co,
          available: _overdriveDone(),
          claimed: q.overdriveClaimed,
        ),
      ],
    );
  }

  // --- Condition checks -----------------------------------------------------

  bool _clearedDungeonToday() {
    final log = ref
        .read(consistencyRepositoryProvider)
        .forDay(DateTime.now());
    return (log?.questsCleared ?? 0) > 0;
  }

  bool _overdriveDone() {
    final habitsDone = ref.read(habitRepositoryProvider).doneTodayCount() > 0;
    final day = ref.read(nutritionRepositoryProvider).today();
    final t = ref.read(macroTargetsProvider);
    final macroHit = day.protein >= t.protein ||
        day.carbs >= t.carbs ||
        day.fats >= t.fats ||
        day.water >= t.water;
    return habitsDone && macroHit;
  }

  // --- Claiming -------------------------------------------------------------

  /// Claim a quest's reward if it's claimable. Returns the crystals granted
  /// (including any streak bonus that fired), or 0 if nothing was claimed.
  Future<int> claim(DailyQuestKind kind) async {
    final q = _repo.today();
    final profile = ref.read(rankProfileProvider.notifier);

    var crystalsGranted = 0;

    switch (kind) {
      case DailyQuestKind.checkIn:
        if (q.checkInClaimed) return 0;
        await profile.addCrystals(_crystalsPerQuest);
        await profile.addCoins(_coinsPerQuest);
        crystalsGranted += _crystalsPerQuest;
        var updated = q.copyWith(checkInClaimed: true);
        // Streak advances on check-in.
        updated = await _advanceStreak(updated);
        crystalsGranted += await _maybePayStreakBonus(updated);
        // _maybePayStreakBonus persists streakBonusClaimed; re-read for final.
        break;

      case DailyQuestKind.fieldDrill:
        if (q.fieldDrillClaimed || !_clearedDungeonToday()) return 0;
        await profile.addCrystals(_crystalsPerQuest);
        await profile.addCoins(_coinsPerQuest);
        crystalsGranted += _crystalsPerQuest;
        await _repo.save(q.copyWith(fieldDrillClaimed: true));
        break;

      case DailyQuestKind.overdrive:
        if (q.overdriveClaimed || !_overdriveDone()) return 0;
        await profile.addCrystals(_crystalsPerQuest);
        await profile.addCoins(_coinsPerQuest);
        crystalsGranted += _crystalsPerQuest;
        await _repo.save(q.copyWith(overdriveClaimed: true));
        break;
    }

    state = _read();
    return crystalsGranted;
  }

  /// Continue the streak if the last check-in was yesterday, else reset to 1.
  /// Returns the (persisted) today record with check-in marked.
  Future<DailyQuest> _advanceStreak(DailyQuest today) async {
    final yesterday = DailyQuestRepository.keyFor(
      DateTime.now().subtract(const Duration(days: 1)),
    );
    final last = _repo.lastCheckInDay();
    final newStreak = (last == yesterday) ? _repo.streak() + 1 : 1;
    await _repo.setStreak(newStreak);
    await _repo.setLastCheckInDay(_repo.todayKey);
    await _repo.save(today);
    return today;
  }

  /// Pay the weekly bonus when the streak lands on a multiple of the target.
  /// Returns crystals granted (0 if not due / already paid today).
  Future<int> _maybePayStreakBonus(DailyQuest today) async {
    if (today.streakBonusClaimed) return 0;
    final streak = _repo.streak();
    if (streak == 0 || streak % DailyQuestRepository.streakTarget != 0) return 0;

    await ref.read(rankProfileProvider.notifier).addCrystals(_streakCrystal);
    await ref.read(rankProfileProvider.notifier).addCoins(_streakCoin);
    await _repo.save(today.copyWith(streakBonusClaimed: true));
    return _streakCrystal;
  }
}
