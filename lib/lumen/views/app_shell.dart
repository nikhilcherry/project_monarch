import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/prefs_controller.dart';
import '../core/theme/lumen_typography.dart';
import 'library/library_view.dart';
import 'settings/settings_view.dart';
import 'stats/stats_view.dart';

/// Bottom-nav scaffold hosting the three primary tabs.
class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  int _index = 0;

  static const _tabs = [
    (icon: Icons.auto_stories_outlined, active: Icons.auto_stories, label: 'Library'),
    (icon: Icons.bar_chart_outlined, active: Icons.bar_chart, label: 'Stats'),
    (icon: Icons.settings_outlined, active: Icons.settings, label: 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    final palette = ref.watch(prefsControllerProvider).palette;
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: const [LibraryView(), StatsView(), SettingsView()],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: palette.background,
          border: Border(top: BorderSide(color: palette.border)),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 64,
            child: Row(
              children: [
                for (var i = 0; i < _tabs.length; i++)
                  Expanded(
                    child: _NavItem(
                      icon: _index == i ? _tabs[i].active : _tabs[i].icon,
                      label: _tabs[i].label,
                      selected: _index == i,
                      accent: palette.accent,
                      muted: palette.caption,
                      onTap: () => setState(() => _index = i),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.accent,
    required this.muted,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final Color accent;
  final Color muted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? accent : muted;
    return InkResponse(
      onTap: onTap,
      radius: 48,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(label, style: LumenType.caption(color)),
        ],
      ),
    );
  }
}
