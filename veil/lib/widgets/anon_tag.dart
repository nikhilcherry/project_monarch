import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../core/utils/anon_identity.dart';

/// The little colored author chip, e.g. `a3f9c1` (+ an OP badge for the
/// original poster). Same color + code = same person *within this thread*.
class AnonTag extends StatelessWidget {
  const AnonTag({super.key, required this.hash, this.isOp = false});

  final String hash;
  final bool isOp;

  @override
  Widget build(BuildContext context) {
    final id = AnonId.fromCode(hash, isOp: isOp);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: id.color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          id.code,
          style: TextStyle(
            color: id.color,
            fontFamily: 'monospace',
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        if (isOp) ...[
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              'OP',
              style: TextStyle(
                color: AppColors.accent,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
