import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../controllers/library_controller.dart';
import '../../controllers/prefs_controller.dart';
import '../../core/theme/lumen_palette.dart';
import '../../core/theme/lumen_typography.dart';
import '../../models/book.dart';
import '../../widgets/book_cover.dart';
import '../../widgets/progress_ring.dart';
import '../book/book_detail_view.dart';
import 'add_to_library_sheet.dart';

class LibraryView extends ConsumerWidget {
  const LibraryView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = ref.watch(prefsControllerProvider).palette;
    final books = ref.watch(libraryControllerProvider);
    final continueBook = ref.read(libraryControllerProvider.notifier).continueReading();

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => showAddToLibrarySheet(context),
        backgroundColor: palette.accent,
        foregroundColor: palette.isLight ? Colors.white : const Color(0xFF1A1200),
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Text('Lumen', style: LumenType.headlineMd(palette.heading)),
              ),
            ),
            if (continueBook != null)
              SliverToBoxAdapter(
                child: _ContinueCard(book: continueBook, palette: palette),
              ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                child: Text('Library', style: LumenType.headlineMd(palette.heading)),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 96),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 24,
                  childAspectRatio: 0.52,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, i) => _GridCard(book: books[i], palette: palette),
                  childCount: books.length,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void _openBook(BuildContext context, Book book) {
  Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => BookDetailView(bookId: book.id)),
  );
}

class _ContinueCard extends StatelessWidget {
  const _ContinueCard({required this.book, required this.palette});

  final Book book;
  final LumenPalette palette;

  @override
  Widget build(BuildContext context) {
    final remaining = book.totalWords - book.wordsRead;
    final minsLeft = (remaining / book.wpm).ceil();
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('CONTINUE READING', style: LumenType.overline(palette.caption)),
          const SizedBox(height: 12),
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => _openBook(context, book),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: palette.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: palette.border),
              ),
              child: Row(
                children: [
                  BookCover(book: book, palette: palette, width: 72, showMonogram: true),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(book.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: LumenType.titleSerif(palette.heading)),
                        const SizedBox(height: 6),
                        Text(book.author, style: LumenType.bodyMd(palette.caption)),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Icon(Icons.schedule, size: 15, color: palette.caption),
                            const SizedBox(width: 6),
                            Text('$minsLeft min left', style: LumenType.caption(palette.caption)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  ProgressRing(
                    progress: book.progress,
                    accent: palette.accent,
                    track: palette.border,
                    size: 48,
                    label: '${book.progressPercent}%',
                    labelColor: palette.accent,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GridCard extends StatelessWidget {
  const _GridCard({required this.book, required this.palette});

  final Book book;
  final LumenPalette palette;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => _openBook(context, book),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: BookCover(book: book, palette: palette, width: double.infinity, aspectRatio: 0.74),
          ),
          const SizedBox(height: 10),
          Text(book.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: LumenType.bodyMd(palette.body).copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(book.author,
              maxLines: 1, overflow: TextOverflow.ellipsis, style: LumenType.caption(palette.caption)),
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
        ],
      ),
    );
  }
}
