import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../controllers/daily_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../models/exercise_entry.dart';
import '../../models/penalty_quest.dart';
import '../../widgets/glow_panel.dart';

/// Redemption checklist for a [PenaltyQuest]. Same fast checklist feel as a
/// dungeon, but framed in punishing red — clearing it resolves the penalty.
class PenaltyQuestView extends ConsumerStatefulWidget {
  const PenaltyQuestView({super.key, required this.quest});

  final PenaltyQuest quest;

  @override
  ConsumerState<PenaltyQuestView> createState() => _PenaltyQuestViewState();
}

class _PenaltyQuestViewState extends ConsumerState<PenaltyQuestView> {
  late final List<ExerciseEntry> _exercises = widget.quest.exercises
      .map((e) => e.copyWith(completed: false))
      .toList();

  int get _done => _exercises.where((e) => e.completed).length;
  bool get _allDone => _exercises.isNotEmpty && _done == _exercises.length;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('PENALTY QUEST'),
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: AppColors.danger),
        titleTextStyle: textTheme.titleLarge
            ?.copyWith(color: AppColors.danger, letterSpacing: 2),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: GlowPanel(
                glow: true,
                borderColor: AppColors.danger,
                child: Row(
                  children: [
                    const Icon(Icons.gpp_bad,
                        color: AppColors.danger, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.quest.reason,
                              style: textTheme.titleMedium
                                  ?.copyWith(color: AppColors.danger)),
                          Text(
                            'Clear this quest to redeem yourself.',
                            style: textTheme.bodySmall
                                ?.copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _exercises.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, i) {
                  final e = _exercises[i];
                  return GestureDetector(
                    onTap: () => setState(
                        () => _exercises[i] = e.copyWith(completed: !e.completed)),
                    child: GlowPanel(
                      glow: e.completed,
                      borderColor:
                          e.completed ? AppColors.success : AppColors.danger,
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          Icon(
                            e.completed
                                ? Icons.check_circle
                                : Icons.radio_button_unchecked,
                            color: e.completed
                                ? AppColors.success
                                : AppColors.textSecondary,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              '${e.name} — ${e.targetSets}×${e.targetReps}',
                              style: textTheme.titleMedium?.copyWith(
                                color: e.completed
                                    ? AppColors.textSecondary
                                    : AppColors.textPrimary,
                                decoration: e.completed
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        _allDone ? AppColors.danger : AppColors.surfaceElevated,
                    foregroundColor: _allDone
                        ? AppColors.background
                        : AppColors.textDisabled,
                  ),
                  onPressed: _allDone ? _resolve : null,
                  icon: const Icon(Icons.shield),
                  label: Text(
                    _allDone ? 'REDEEM' : 'COMPLETE ALL ($_done/${_exercises.length})',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _resolve() async {
    await ref.read(penaltiesProvider.notifier).resolve(widget.quest.id);
    if (mounted) Navigator.of(context).pop();
  }
}
