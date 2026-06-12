import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/seed_boards.dart';
import '../models/board.dart';

/// Persistence for boards. The ONLY code that touches the `boards` collection.
class BoardRepository {
  BoardRepository(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _boards =>
      _db.collection('boards');

  Stream<List<Board>> watchBoards() {
    return _boards.orderBy('order').snapshots().map(
          (snap) => snap.docs
              .map((d) => Board.fromMap(d.id, d.data()))
              .toList(growable: false),
        );
  }

  /// First-run convenience: seed default boards if none exist.
  Future<void> ensureSeeded() async {
    final existing = await _boards.limit(1).get();
    if (existing.docs.isNotEmpty) return;
    final batch = _db.batch();
    for (final board in kSeedBoards) {
      batch.set(_boards.doc(board.id), board.toMap());
    }
    await batch.commit();
  }
}
