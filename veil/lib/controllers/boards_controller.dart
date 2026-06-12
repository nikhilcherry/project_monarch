import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/board.dart';
import 'providers.dart';

/// Live list of boards, ordered. Seeds defaults on first run.
final boardsProvider = StreamProvider<List<Board>>((ref) {
  final repo = ref.watch(boardRepositoryProvider);
  // Fire-and-forget seed; the stream picks up the writes.
  ref.read(boardRepositoryProvider).ensureSeeded();
  return repo.watchBoards();
});
