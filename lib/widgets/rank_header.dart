import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../models/rank_profile.dart';
import 'glow_panel.dart';

/// Top-of-dashboard hero: big rank badge, equipped title/badge, level, the neon
/// EXP progress bar, and the coin balance.
class RankHeader extends StatelessWidget {
  const RankHeader({
    super.key,
    required this.profile,
    this.title = 'Novice Hunter',
    this.badgeIcon,
  });

  final RankProfile profile;

  /// Equipped cosmetic title from the shop.
  final String title;

  /// Equipped cosmetic badge icon, or null if none.
  final IconData? badgeIcon;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return GlowPanel(
      glow: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _RankBadge(label: profile.rank.label),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (badgeIcon != null) ...[
                          Icon(badgeIcon, color: AppColors.accent, size: 16),
                          const SizedBox(width: 6),
                        ],
                        Flexible(
                          child: Text(
                            title,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.bodySmall?.copyWith(
                              color: AppColors.accent,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text('LEVEL ${profile.level}',
                        style: textTheme.titleMedium?.copyWith(
                          color: AppColors.textPrimary,
                          letterSpacing: 1.5,
                        )),
                    const SizedBox(height: 2),
                    Text(
                      profile.isMaxRank ? 'APEX REACHED' : 'NEXT: ${_nextLabel()}',
                      style: textTheme.bodySmall
                          ?.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              _CoinPill(coins: profile.coins),
            ],
          ),
          const SizedBox(height: 16),
          _ExpBar(profile: profile),
        ],
      ),
    );
  }

  String _nextLabel() => profile.rank.next?.label ?? '—';
}

class _RankBadge extends StatelessWidget {
  const _RankBadge({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    // Pull just the letter(s) for the big glyph (e.g. "S" from "S-Rank").
    final glyph = label.split('-').first;
    return Container(
      width: 64,
      height: 64,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppColors.accentGradient,
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withValues(alpha: 0.6),
            blurRadius: 24,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Text(
        glyph,
        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: AppColors.background,
              fontWeight: FontWeight.w900,
            ),
      ),
    );
  }
}

class _CoinPill extends StatelessWidget {
  const _CoinPill({required this.coins});
  final int coins;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.coin.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.monetization_on, color: AppColors.coin, size: 16),
          const SizedBox(width: 6),
          Text('$coins',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppColors.coin,
                    fontWeight: FontWeight.w700,
                  )),
        ],
      ),
    );
  }
}

class _ExpBar extends StatelessWidget {
  const _ExpBar({required this.profile});
  final RankProfile profile;

  @override
  Widget build(BuildContext context) {
    final progress = profile.rankProgress;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Stack(
            children: [
              Container(height: 12, color: AppColors.surfaceElevated),
              LayoutBuilder(
                builder: (context, c) => Container(
                  height: 12,
                  width: c.maxWidth * progress,
                  decoration: BoxDecoration(
                    gradient: AppColors.accentGradient,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accent.withValues(alpha: 0.7),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'EXP ${profile.currentExp.toStringAsFixed(0)} / '
          '${profile.expToNextRank.toStringAsFixed(0)}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
      ],
    );
  }
}
