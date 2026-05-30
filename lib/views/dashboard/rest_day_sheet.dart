import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../controllers/daily_controller.dart';
import '../../core/constants/app_colors.dart';

/// Bottom sheet to configure which weekdays are rest days. Everything not marked
/// as rest is a mandatory training day (a miss triggers a penalty quest).
class RestDaySheet extends ConsumerWidget {
  const RestDaySheet({super.key});

  static const _labels = {
    DateTime.monday: 'Monday',
    DateTime.tuesday: 'Tuesday',
    DateTime.wednesday: 'Wednesday',
    DateTime.thursday: 'Thursday',
    DateTime.friday: 'Friday',
    DateTime.saturday: 'Saturday',
    DateTime.sunday: 'Sunday',
  };

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const RestDaySheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final restDays = ref.watch(restDaysProvider);
    final schedule = ref.read(scheduleRepositoryProvider);
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text('REST DAYS', style: textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(
            'Untoggled days are mandatory. Miss one and the System issues a penalty.',
            style: textTheme.bodySmall
                ?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          ..._labels.entries.map((e) {
            final isRest = restDays.contains(e.key);
            return SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(e.value, style: textTheme.titleMedium),
              subtitle: Text(isRest ? 'Rest day' : 'Mandatory',
                  style: textTheme.bodySmall?.copyWith(
                    color: isRest ? AppColors.accent : AppColors.textSecondary,
                  )),
              value: isRest,
              onChanged: (_) async {
                await schedule.toggleRestDay(e.key);
                ref.invalidate(restDaysProvider);
              },
            );
          }),
        ],
      ),
    );
  }
}
