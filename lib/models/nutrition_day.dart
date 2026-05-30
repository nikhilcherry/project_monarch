import 'package:hive/hive.dart';

part 'nutrition_day.g.dart';

/// One day's macro intake, tracked toward targets — grams of protein/carbs/fats
/// plus water (in cups). Deliberately **no calorie counting**: the user taps to
/// add servings and watches rings fill toward their goals.
///
/// Keyed in its box by [dayKey] (yyyy-MM-dd).
@HiveType(typeId: 7)
class NutritionDay extends HiveObject {
  @HiveField(0)
  String dayKey;

  @HiveField(1)
  int protein; // grams

  @HiveField(2)
  int carbs; // grams

  @HiveField(3)
  int fats; // grams

  @HiveField(4)
  int water; // cups

  NutritionDay({
    required this.dayKey,
    this.protein = 0,
    this.carbs = 0,
    this.fats = 0,
    this.water = 0,
  });

  NutritionDay copyWith({
    String? dayKey,
    int? protein,
    int? carbs,
    int? fats,
    int? water,
  }) =>
      NutritionDay(
        dayKey: dayKey ?? this.dayKey,
        protein: protein ?? this.protein,
        carbs: carbs ?? this.carbs,
        fats: fats ?? this.fats,
        water: water ?? this.water,
      );

  @override
  String toString() =>
      'NutritionDay($dayKey P:$protein C:$carbs F:$fats W:$water)';
}

/// The macros a single tap/serving adds, and the daily targets to fill toward.
/// Tunable; stored as plain values in the settings box (see repository).
class MacroTargets {
  final int protein;
  final int carbs;
  final int fats;
  final int water;

  const MacroTargets({
    this.protein = 150,
    this.carbs = 250,
    this.fats = 70,
    this.water = 8,
  });

  /// Default per-tap serving increments.
  static const int proteinStep = 25;
  static const int carbStep = 40;
  static const int fatStep = 10;
  static const int waterStep = 1;
}
