import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../controllers/library_controller.dart';
import '../../controllers/prefs_controller.dart';
import '../../core/theme/lumen_palette.dart';
import '../../core/theme/lumen_typography.dart';
import '../../models/book.dart';
import '../../models/chapter.dart';
import '../../widgets/book_cover.dart';
import '../../widgets/pill_button.dart';
import '../../widgets/progress_ring.dart';
import '../reader/boost_view.dart';
import '../reader/reader_view.dart';
import 'edit_book_view.dart';

class BookDetailView extends ConsumerWidget {
  const BookDetailView({super.key, required this.bookId});

  final String bookId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = ref.watch(prefsControllerProvider).palette;
    final books = ref.watch(libraryControllerProvider);
    final book = books.where((b) => b.id == bookId).firstOrNull;
    if (book == null) {
      return const Scaffold(body: Center(child: Text('Book not found')));
    }

    void open(int chapterIndex, {required bool boost}) {
      final route = MaterialPageRoute(
        builder: (_) => boost
            ? BoostView(bookId: bookId, chapterIndex: chapterIndex)
            : ReaderView(bookId: bookId, chapterIndex: chapterIndex),
      );
      Navigator.of(context).push(route);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Lumen', style: LumenType.titleSerif(palette.heading)),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => EditBookView(bookId: bookId)),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [
          Center(child: BookCover(book: book, palette: palette, width: 168, showMonogram: true)),
          const SizedBox(height: 24),
          Text(book.title, textAlign: TextAlign.center, style: LumenType.headlineLg(palette.heading)),
          const SizedBox(height: 8),
          Text(book.author,
              textAlign: TextAlign.center,
              style: LumenType.bodyLg(palette.caption).copyWith(fontStyle: FontStyle.italic)),
          const SizedBox(height: 28),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('PROGRESS', style: LumenType.overline(palette.caption)),
              Text('${book.progressPercent}%', style: LumenType.labelMd(palette.accent)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: book.progress,
              minHeight: 2,
              backgroundColor: palette.border,
              valueColor: AlwaysStoppedAnimation(palette.accent),
            ),
          ),
          const SizedBox(height: 28),
          Row(
            children: [
              Expanded(
                child: PillButton(
                  label: 'Read',
                  filled: true,
                  expand: true,
                  onPressed: () => open(book.currentChapterIndex, boost: false),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: PillButton(
                  label: 'Boost',
                  expand: true,
                  onPressed: () => open(book.currentChapterIndex, boost: true),
                ),
              ),
            ],
          ),
          const SizedBox(height: 36),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text('Chapters', style: LumenType.headlineMd(palette.heading)),
              Text('${book.chapters.length} Total', style: LumenType.caption(palette.caption)),
            ],
          ),
          const SizedBox(height: 8),
          for (var i = 0; i < book.chapters.length; i++)
            _ChapterRow(
              palette: palette,
              chapter: book.chapters[i],
              isCurrent: i == book.currentChapterIndex,
              wpm: book.wpm,
              onRead: () => open(i, boost: false),
              onBoost: () => open(i, boost: true),
            ),
        ],
      ),
    );
  }
}

class _ChapterRow extends StatelessWidget {
  const _ChapterRow({
    required this.palette,
    required this.chapter,
    required this.isCurrent,
    required this.wpm,
    required this.onRead,
    required this.onBoost,
  });

  final LumenPalette palette;
  final Chapter chapter;
  final bool isCurrent;
  final int wpm;
  final VoidCallback onRead;
  final VoidCallback onBoost;

  @override
  Widget build(BuildContext context) {
    final mins = (chapter.wordCount / wpm).ceil();
    final status = chapter.completed
        ? 'Completed'
        : isCurrent
            ? 'Current Reading'
            : '$mins min';
    final titleColor = chapter.completed || isCurrent ? palette.body : palette.caption;

    return InkWell(
      onTap: onRead,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: palette.border)),
        ),
        child: Row(
          children: [
            _leading(),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(chapter.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: LumenType.bodyLg(titleColor).copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(status,
                      style: LumenType.caption(isCurrent ? palette.accent : palette.caption)),
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.bolt_outlined, color: palette.accent),
              tooltip: 'Boost',
              onPressed: onBoost,
            ),
          ],
        ),
      ),
    );
  }

  Widget _leading() {
    if (chapter.completed) {
      return ProgressRing(
        progress: 1,
        accent: palette.accent,
        track: palette.border,
        size: 34,
        label: '✓',
        labelColor: palette.accent,
      );
    }
    if (isCurrent && chapter.progress > 0) {
      return ProgressRing(
        progress: chapter.progress,
        accent: palette.accent,
        track: palette.border,
        size: 34,
        label: '${(chapter.progress * 100).round()}%',
        labelColor: palette.accent,
      );
    }
    return ProgressRing(
      progress: 0,
      accent: palette.accent,
      track: palette.border,
      size: 34,
    );
  }
}
