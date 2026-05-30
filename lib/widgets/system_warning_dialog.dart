import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';

/// The signature "System Warning" — an intentional friction gate shown before a
/// self-reported habit is marked complete. Because nothing technical can verify
/// the habit, this confronts the user with an honesty challenge in the System's
/// voice. Returns `true` only if the user confirms.
class SystemWarningDialog extends StatelessWidget {
  const SystemWarningDialog({
    super.key,
    required this.habitTitle,
  });

  final String habitTitle;

  static Future<bool> show(BuildContext context, String habitTitle) async {
    final result = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.85),
      builder: (_) => SystemWarningDialog(habitTitle: habitTitle),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.warning, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: AppColors.warning.withOpacity(0.35),
              blurRadius: 36,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.warning_amber_rounded,
                color: AppColors.warning, size: 44),
            const SizedBox(height: 12),
            Text('SYSTEM WARNING',
                style: textTheme.titleLarge?.copyWith(
                  color: AppColors.warning,
                  letterSpacing: 3,
                )),
            const SizedBox(height: 12),
            Text(
              'The System cannot verify this action.\n'
              'Deceiving the System only weakens the Hunter.',
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium
                  ?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: Text(
                'Did you truly complete:\n"$habitTitle"?',
                textAlign: TextAlign.center,
                style: textTheme.titleSmall
                    ?.copyWith(color: AppColors.textPrimary),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('NOT YET'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.warning,
                      foregroundColor: AppColors.background,
                    ),
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('I SWEAR IT'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
