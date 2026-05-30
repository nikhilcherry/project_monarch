import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/database/database_service.dart';
import '../models/nutrition_day.dart';
import '../repositories/nutrition_repository.dart';

final nutritionRepositoryProvider = Provider<NutritionRepository>((ref) {
  return NutritionRepository(
    DatabaseService.nutritionBox,
    DatabaseService.settingsBox,
  );
});

/// User macro targets (rarely change) — read-only provider for the UI.
final macroTargetsProvider = Provider<MacroTargets>((ref) {
  return ref.watch(nutritionRepositoryProvider).targets();
});

/// Today's live macro intake + tap-to-add/remove actions.
final nutritionProvider =
    NotifierProvider<NutritionNotifier, NutritionDay>(NutritionNotifier.new);

class NutritionNotifier extends Notifier<NutritionDay> {
  NutritionRepository get _repo => ref.read(nutritionRepositoryProvider);

  @override
  NutritionDay build() => _repo.today();

  Future<void> addProtein([int n = MacroTargets.proteinStep]) async =>
      state = await _repo.adjust(protein: n);

  Future<void> addCarbs([int n = MacroTargets.carbStep]) async =>
      state = await _repo.adjust(carbs: n);

  Future<void> addFats([int n = MacroTargets.fatStep]) async =>
      state = await _repo.adjust(fats: n);

  Future<void> addWater([int n = MacroTargets.waterStep]) async =>
      state = await _repo.adjust(water: n);

  Future<void> reset() async => state = await _repo.resetToday();
}
