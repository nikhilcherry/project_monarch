import 'package:hive/hive.dart';

import '../core/database/hive_boxes.dart';
import '../models/nutrition_day.dart';
import 'consistency_repository.dart';

/// Persistence for daily macro intake + the user's macro targets.
///
/// Daily intake lives in the typed nutrition box (one [NutritionDay] per day).
/// Targets are small scalars kept in the dynamic settings box so they can be
/// edited without a dedicated model/adapter.
class NutritionRepository {
  NutritionRepository(this._days, this._settings);

  final Box<NutritionDay> _days;
  final Box<dynamic> _settings;

  // Settings keys for targets.
  static const _kProtein = 'target_protein';
  static const _kCarbs = 'target_carbs';
  static const _kFats = 'target_fats';
  static const _kWater = 'target_water';

  String get _todayKey => ConsistencyRepository.keyFor(DateTime.now());

  /// Today's intake record, created (and persisted) on first access.
  NutritionDay today() {
    final key = _todayKey;
    final existing = _days.get(key);
    if (existing != null) return existing;
    final fresh = NutritionDay(dayKey: key);
    _days.put(key, fresh);
    return fresh;
  }

  /// The user's configured macro targets (defaults if never set).
  MacroTargets targets() {
    const d = MacroTargets();
    return MacroTargets(
      protein: _settings.get(_kProtein, defaultValue: d.protein) as int,
      carbs: _settings.get(_kCarbs, defaultValue: d.carbs) as int,
      fats: _settings.get(_kFats, defaultValue: d.fats) as int,
      water: _settings.get(_kWater, defaultValue: d.water) as int,
    );
  }

  Future<void> saveTargets(MacroTargets t) async {
    await _settings.putAll({
      _kProtein: t.protein,
      _kCarbs: t.carbs,
      _kFats: t.fats,
      _kWater: t.water,
    });
  }

  /// Add (or subtract, when [delta] is negative) to a macro for today, clamped
  /// at zero. Returns the updated record.
  Future<NutritionDay> adjust({
    int protein = 0,
    int carbs = 0,
    int fats = 0,
    int water = 0,
  }) async {
    final day = today();
    final updated = day.copyWith(
      protein: (day.protein + protein).clamp(0, 9999),
      carbs: (day.carbs + carbs).clamp(0, 9999),
      fats: (day.fats + fats).clamp(0, 9999),
      water: (day.water + water).clamp(0, 99),
    );
    await _days.put(updated.dayKey, updated);
    return updated;
  }

  /// Reset today's intake to zero.
  Future<NutritionDay> resetToday() async {
    final fresh = NutritionDay(dayKey: _todayKey);
    await _days.put(fresh.dayKey, fresh);
    return fresh;
  }
}
