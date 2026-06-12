import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'views/boards/boards_screen.dart';

class VeilApp extends ConsumerWidget {
  const VeilApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Veil',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const BoardsScreen(),
    );
  }
}
