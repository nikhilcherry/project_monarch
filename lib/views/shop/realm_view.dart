import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../controllers/shop_realms_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../models/exercise_entry.dart';
import '../../models/shop_realm.dart';
import '../../services/realm_generator.dart';
import '../../widgets/glow_panel.dart';

/// A single Shop Realm — a linear gauntlet. Shows progress and the current
/// level's checklist; clearing it advances to the next level. One-time, no
/// replay.
class RealmView extends ConsumerStatefulWidget {
  const RealmView({super.key, required this.realmId});

  final String realmId;

  @override
  ConsumerState<RealmView> createState() => _RealmViewState();
}

class _RealmViewState extends ConsumerState<RealmView> {
  late int _level;
  late List<ExerciseEntry> _exercises;
  late List<bool> _checked;

  @override
  void initState() {
    super.initState();
    final realm = _currentRealm();
    _loadLevel(realm);
  }

  ShopRealm _currentRealm() =>
      ref.read(shopRealmsProvider).firstWhere((r) => r.id == widget.realmId);

  void _loadLevel(ShopRealm realm) {
    _level = realm.currentLevel;
    _exercises = RealmGenerator.exercises(
        realm.muscleGroup, _level, realm.unlockTier);
    _checked = List<bool>.filled(_exercises.length, false);
  }

  bool get _allChecked =>
      _checked.isNotEmpty && _checked.every((c) => c);

  Future<void> _clear() async {
    await ref
        .read(shopRealmsProvider.notifier)
        .clearCurrentLevel(widget.realmId);
    if (!mounted) return;
    setState(() => _loadLevel(_currentRealm()));
  }

  @override
  Widget build(BuildContext context) {
    final realm =
        ref.watch(shopRealmsProvider).firstWhere((r) => r.id == widget.realmId);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: Text(realm.name.toUpperCase())),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            GlowPanel(
              glow: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(realm.name,
                      softWrap: true, style: textTheme.titleLarge),
                  const SizedBox(height: 4),
                  Text('${realm.clearedLevels} / ${realm.length} levels cleared',
                      style: textTheme.bodySmall
                          ?.copyWith(color: AppColors.textSecondary)),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Stack(
                      children: [
                        Container(height: 8, color: AppColors.surfaceElevated),
                        LayoutBuilder(
                          builder: (context, c) => Container(
                            height: 8,
                            width: c.maxWidth *
                                (realm.clearedLevels / realm.length)
                                    .clamp(0.0, 1.0),
                            decoration: const BoxDecoration(
                              gradient: AppColors.accentGradient,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (realm.isComplete)
              const _RealmClearedBanner()
            else
              _CurrentLevelCard(
                level: _level,
                exercises: _exercises,
                checked: _checked,
                onToggle: (i) => setState(() => _checked[i] = !_checked[i]),
                onClear: _allChecked ? _clear : null,
              ),
          ],
        ),
      ),
    );
  }
}

class _CurrentLevelCard extends StatelessWidget {
  const _CurrentLevelCard({
    required this.level,
    required this.exercises,
    required this.checked,
    required this.onToggle,
    required this.onClear,
  });

  final int level;
  final List<ExerciseEntry> exercises;
  final List<bool> checked;
  final void Function(int) onToggle;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return GlowPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PanelLabel('Level $level'),
          const SizedBox(height: 12),
          for (var i = 0; i < exercises.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: GestureDetector(
                onTap: () => onToggle(i),
                child: Row(
                  children: [
                    Icon(
                      checked[i]
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      color: checked[i]
                          ? AppColors.success
                          : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '${exercises[i].name} — '
                        '${exercises[i].targetSets}×${exercises[i].targetReps}',
                        style: textTheme.bodyLarge?.copyWith(
                          decoration: checked[i]
                              ? TextDecoration.lineThrough
                              : null,
                          color: checked[i]
                              ? AppColors.textSecondary
                              : AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: onClear,
              icon: const Icon(Icons.verified),
              label: Text(onClear != null ? 'CLEAR LEVEL' : 'COMPLETE ALL SETS'),
            ),
          ),
        ],
      ),
    );
  }
}

class _RealmClearedBanner extends StatelessWidget {
  const _RealmClearedBanner();

  @override
  Widget build(BuildContext context) {
    return GlowPanel(
      glow: true,
      borderColor: AppColors.success,
      child: Row(
        children: [
          const Icon(Icons.emoji_events, color: AppColors.success, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Text('Realm conquered. Every level has fallen.',
                style: Theme.of(context).textTheme.titleMedium),
          ),
        ],
      ),
    );
  }
}
