import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/book.dart';
import '../models/chapter.dart';
import '../services/chapter_splitter.dart';
import 'providers.dart';

class LibraryController extends Notifier<List<Book>> {
  @override
  List<Book> build() => ref.read(bookRepositoryProvider).all();

  void _refresh() => state = ref.read(bookRepositoryProvider).all();

  /// Build a book from raw pasted/imported text, splitting it into chapters
  /// deterministically (no AI), and persist it.
  Future<Book> addFromText({
    required String title,
    required String author,
    required String text,
    int wpm = 300,
  }) async {
    final chapters = [
      for (final c in ChapterSplitter.detect(text.trim()))
        Chapter(
          title: c.title,
          text: c.text,
          wordCount: c.wordCount,
          synthetic: c.synthetic,
        ),
    ];
    final book = Book(
      id: 'book-${DateTime.now().microsecondsSinceEpoch}',
      title: title.trim().isEmpty ? 'Untitled' : title.trim(),
      author: author.trim().isEmpty ? 'Anonymous' : author.trim(),
      chapters: chapters.isEmpty
          ? [Chapter(title: 'Section 1', text: text.trim(), wordCount: 0)]
          : chapters,
      addedAtMs: DateTime.now().millisecondsSinceEpoch,
      wpm: wpm,
    );
    await ref.read(bookRepositoryProvider).put(book);
    _refresh();
    return book;
  }

  Future<void> updateInfo(Book book,
      {required String title, required String author}) async {
    book
      ..title = title.trim().isEmpty ? book.title : title.trim()
      ..author = author.trim().isEmpty ? 'Anonymous' : author.trim();
    await ref.read(bookRepositoryProvider).save(book);
    _refresh();
  }

  Future<void> setBookWpm(Book book, int wpm) async {
    book.wpm = wpm;
    await ref.read(bookRepositoryProvider).save(book);
    _refresh();
  }

  /// Persist a chapter reading position (shared by reader + Boost).
  Future<void> saveProgress(Book book, int chapterIndex, int wordPosition,
      {bool? completed}) async {
    final ch = book.chapters[chapterIndex];
    ch.wordPosition = wordPosition.clamp(0, ch.wordCount);
    if (completed != null) ch.completed = completed;
    book.currentChapterIndex = chapterIndex;
    await ref.read(bookRepositoryProvider).save(book);
    _refresh();
  }

  Future<void> delete(Book book) async {
    await ref.read(bookRepositoryProvider).delete(book.id);
    _refresh();
  }

  Book? continueReading() => ref.read(bookRepositoryProvider).continueReading();
}

final libraryControllerProvider =
    NotifierProvider<LibraryController, List<Book>>(LibraryController.new);
