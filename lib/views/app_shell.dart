import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import 'dashboard/dashboard_view.dart';
import 'world_map/world_map_view.dart';

/// Root navigation shell with a neon bottom bar. Screens still to come
/// (Active Workout, Nutrition, Habits, Shop) slot in as they're built; for now
/// the shell hosts the Dashboard and the World Map.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  // IndexedStack keeps each screen's state alive when switching tabs.
  static const List<Widget> _pages = [
    DashboardView(),
    WorldMapView(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: BottomNavigationBar(
          currentIndex: _index,
          onTap: (i) => setState(() => _index = i),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard),
              label: 'Status',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.map_outlined),
              activeIcon: Icon(Icons.map),
              label: 'Map',
            ),
          ],
        ),
      ),
    );
  }
}
