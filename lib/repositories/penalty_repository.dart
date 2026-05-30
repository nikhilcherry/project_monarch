import 'package:hive/hive.dart';

import '../models/penalty_quest.dart';

/// Persistence for issued penalty quests, keyed by their id.
class PenaltyRepository {
  PenaltyRepository(this._box);

  final Box<PenaltyQuest> _box;

  /// All unresolved penalties — what the dashboard nags about.
  List<PenaltyQuest> active() =>
      _box.values.where((p) => !p.resolved).toList();

  List<PenaltyQuest> all() => _box.values.toList();

  PenaltyQuest? getById(String id) => _box.get(id);

  Future<void> save(PenaltyQuest quest) => _box.put(quest.id, quest);

  /// True if a penalty was already issued for [dayKey] (avoids duplicates).
  bool existsForDay(String dayKey) =>
      _box.values.any((p) => p.issuedDayKey == dayKey);

  Future<void> resolve(String id) async {
    final quest = _box.get(id);
    if (quest == null) return;
    await _box.put(id, quest.copyWith(resolved: true));
  }
}
