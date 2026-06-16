import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/prefs_controller.dart';
import '../core/theme/lumen_typography.dart';

/// The rounded primary/secondary action button from the mockups:
/// `filled` → solid amber with dark label; otherwise an amber-outlined pill.
class PillButton extends ConsumerWidget {
  const PillButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.filled = false,
    this.expand = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool filled;
  final bool expand;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = ref.watch(prefsControllerProvider).palette;
    final child = Material(
      color: filled ? palette.accent : Colors.transparent,
      shape: StadiumBorder(
        side: filled ? BorderSide.none : BorderSide(color: palette.accent, width: 1.4),
      ),
      child: InkWell(
        onTap: onPressed,
        customBorder: const StadiumBorder(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: LumenType.labelMd(
              filled ? (palette.isLight ? Colors.white : const Color(0xFF1A1200)) : palette.accent,
            ).copyWith(fontSize: 15),
          ),
        ),
      ),
    );
    return expand ? SizedBox(width: double.infinity, child: child) : child;
  }
}
