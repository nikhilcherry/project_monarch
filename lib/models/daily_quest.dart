import 'package:hive/hive.dart';

part 'daily_quest.g.dart';

/// One calendar day's Daily Quest claim state. Keyed in its box by [dayKey]
/// (yyyy-MM-dd). The three quests are the renewable Crystal tap (see
/// docs/GAME_DESIGN_V2.md §3.2); persistent streak state lives in the settings
/// box via [DailyQuestRepository].
@HiveType(typeId: 9)
class DailyQuest extends HiveObject {
  @HiveField(0)
  String dayKey;

  /// "System Check-In" — always claimable. The guaranteed crystal income.
  @HiveField(1)
  bool checkInClaimed;

  /// "Field Drill" — claimable once a dungeon has been cleared today.
  @HiveField(2)
  bool fieldDrillClaimed;

  /// "Overdrive" — claimable once a habit + a macro target are done today.
  @HiveField(3)
  bool overdriveClaimed;

  /// The weekly 7-day-streak bonus was paid out on this day.
  @HiveField(4)
  bool streakBonusClaimed;

  DailyQuest({
    required this.dayKey,
    this.checkInClaimed = false,
    this.fieldDrillClaimed = false,
    this.overdriveClaimed = false,
    this.streakBonusClaimed = false,
  });

  DailyQuest copyWith({
    bool? checkInClaimed,
    bool? fieldDrillClaimed,
    bool? overdriveClaimed,
    bool? streakBonusClaimed,
  }) =>
      DailyQuest(
        dayKey: dayKey,
        checkInClaimed: checkInClaimed ?? this.checkInClaimed,
        fieldDrillClaimed: fieldDrillClaimed ?? this.fieldDrillClaimed,
        overdriveClaimed: overdriveClaimed ?? this.overdriveClaimed,
        streakBonusClaimed: streakBonusClaimed ?? this.streakBonusClaimed,
      );
}
