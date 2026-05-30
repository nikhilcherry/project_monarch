import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../controllers/nutrition_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/glow_panel.dart';
import '../../widgets/macro_ring.dart';

/// Target-based macro tracker. No calorie counting — tap a macro to log a
/// serving and watch its ring fill toward the daily target.
class NutritionView extends ConsumerWidget {
  const NutritionView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final day = ref.watch(nutritionProvider);
    final targets = ref.watch(macroTargetsProvider);
    final notifier = ref.read(nutritionProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('NUTRITION'),
        actions: [
          IconButton(
            tooltip: 'Reset today',
            icon: const Icon(Icons.refresh),
            onPressed: notifier.reset,
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Macro rings.
            GlowPanel(
              child: Column(
                children: [
                  const PanelLabel('Today\'s Macros'),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      MacroRing(
                        label: 'Protein',
                        value: day.protein,
                        target: targets.protein,
                        color: AppColors.str,
                      ),
                      MacroRing(
                        label: 'Carbs',
                        value: day.carbs,
                        target: targets.carbs,
                        color: AppColors.vit,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      MacroRing(
                        label: 'Fats',
                        value: day.fats,
                        target: targets.fats,
                        color: AppColors.flex,
                      ),
                      MacroRing(
                        label: 'Water',
                        value: day.water,
                        target: targets.water,
                        color: AppColors.accent,
                        unit: ' cups',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Tap-to-log buttons.
            GlowPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const PanelLabel('Log a Serving'),
                  const SizedBox(height: 12),
                  _LogRow(
                    label: 'Protein',
                    sub: '+${MacroTargets.proteinStep}g',
                    color: AppColors.str,
                    onAdd: notifier.addProtein,
                    onRemove: () => notifier.addProtein(-MacroTargets.proteinStep),
                  ),
                  _LogRow(
                    label: 'Carbs',
                    sub: '+${MacroTargets.carbStep}g',
                    color: AppColors.vit,
                    onAdd: notifier.addCarbs,
                    onRemove: () => notifier.addCarbs(-MacroTargets.carbStep),
                  ),
                  _LogRow(
                    label: 'Fats',
                    sub: '+${MacroTargets.fatStep}g',
                    color: AppColors.flex,
                    onAdd: notifier.addFats,
                    onRemove: () => notifier.addFats(-MacroTargets.fatStep),
                  ),
                  _LogRow(
                    label: 'Water',
                    sub: '+${MacroTargets.waterStep} cup',
                    color: AppColors.accent,
                    onAdd: notifier.addWater,
                    onRemove: () => notifier.addWater(-MacroTargets.waterStep),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LogRow extends StatelessWidget {
  const _LogRow({
    required this.label,
    required this.sub,
    required this.color,
    required this.onAdd,
    required this.onRemove,
  });

  final String label;
  final String sub;
  final Color color;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(width: 8, height: 32, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: textTheme.titleMedium),
                Text(sub,
                    style: textTheme.bodySmall
                        ?.copyWith(color: AppColors.textSecondary)),
              ],
            ),
          ),
          _RoundIconButton(icon: Icons.remove, color: color, onTap: onRemove),
          const SizedBox(width: 10),
          _RoundIconButton(icon: Icons.add, color: color, onTap: onAdd),
        ],
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: color.withOpacity(0.7), width: 1.5),
          color: color.withOpacity(0.10),
        ),
        child: Icon(icon, color: color, size: 22),
      ),
    );
  }
}
