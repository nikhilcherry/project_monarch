import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';

/// A reusable "System window" — the signature glassy panel with a hairline neon
/// border and a soft outer glow. Used to frame every block on the dashboard.
class GlowPanel extends StatelessWidget {
  const GlowPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.glow = false,
    this.borderColor,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  /// When true, intensifies the outer glow (e.g. active / highlighted panel).
  final bool glow;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final color = borderColor ?? AppColors.accent;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        gradient: AppColors.panelGradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 1),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: glow ? 0.25 : 0.10),
            blurRadius: glow ? 28 : 14,
            spreadRadius: glow ? 1 : 0,
          ),
        ],
      ),
      child: child,
    );
  }
}

/// Small uppercase section label with a leading neon tick — the "System" voice.
class PanelLabel extends StatelessWidget {
  const PanelLabel(this.text, {super.key, this.trailing});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 3, height: 14, color: AppColors.accent),
        const SizedBox(width: 8),
        Text(
          text.toUpperCase(),
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: AppColors.textSecondary,
                letterSpacing: 2,
              ),
        ),
        const Spacer(),
        if (trailing != null) trailing!,
      ],
    );
  }
}
