import 'package:hive/hive.dart';

import '../core/database/hive_boxes.dart';
import '../models/enums.dart';
import '../models/user_stats.dart';

/// Persistence for the singleton [UserStats] (the radar-chart attributes).
class StatsRepository {
  StatsRepository(this._box);

  final Box<UserStats> _box;

  UserStats getOrCreate() {
    final existing = _box.get(HiveBoxes.primaryKey);
    if (existing != null) return existing;

    final fresh = UserStats.initial();
    _box.put(HiveBoxes.primaryKey, fresh);
    return fresh;
  }

  Future<void> save(UserStats stats) => _box.put(HiveBoxes.primaryKey, stats);

  /// Apply a batch of {StatType: points} rewards and persist.
  Future<UserStats> applyRewards(Map<StatType, int> rewards) async {
    final stats = getOrCreate().copyWith();
    stats.applyRewards(rewards);
    await save(stats);
    return stats;
  }
}
