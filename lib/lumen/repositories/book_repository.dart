import 'package:hive/hive.dart';

import '../models/book.dart';

/// Persistence over the books box. The only place that touches book storage.
class BookRepository {
  BookRepository(this._box);

  final Box<Book> _box;

  List<Book> all() {
    final list = _box.values.toList();
    list.sort((a, b) => b.addedAtMs.compareTo(a.addedAtMs));
    return list;
  }

  Book? byId(String id) => _box.get(id);

  Future<void> put(Book book) => _box.put(book.id, book);

  Future<void> delete(String id) => _box.delete(id);

  /// Persist in-place edits made to a [Book] already in the box.
  Future<void> save(Book book) => book.save();

  /// Most-recently-progressed unfinished book, for "Continue reading".
  Book? continueReading() {
    final inProgress = _box.values
        .where((b) => b.progress > 0 && b.progress < 1)
        .toList()
      ..sort((a, b) => b.progress.compareTo(a.progress));
    return inProgress.isNotEmpty ? inProgress.first : null;
  }
}
