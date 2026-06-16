import 'package:flutter/material.dart';

import '../core/theme/lumen_palette.dart';
import '../core/theme/lumen_typography.dart';
import '../models/book.dart';

/// Auto-generated typographic cover — a serif monogram + title + author on a
/// tonal tile with a hairline amber edge. Lumen ships no cover images; this is
/// the consistent fallback (and the "auto-generate cover" action).
class BookCover extends StatelessWidget {
  const BookCover({
    super.key,
    required this.book,
    required this.palette,
    this.width = 120,
    this.aspectRatio = 0.7,
    this.showMonogram = false,
  });

  final Book book;
  final LumenPalette palette;
  final double width;
  final double aspectRatio;
  final bool showMonogram;

  @override
  Widget build(BuildContext context) {
    final tile = book.coverColorValue != null
        ? Color(book.coverColorValue!)
        : palette.surface;

    // When width is unbounded (grid cells), let the parent constrain height.
    final resolvedHeight = width.isFinite ? width / aspectRatio : null;

    return Container(
      width: width.isFinite ? width : double.infinity,
      height: resolvedHeight,
      decoration: BoxDecoration(
        color: tile,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: palette.accent.withValues(alpha: 0.45)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (showMonogram) ...[
            Text(book.monogram,
                style: LumenType.headlineMd(palette.body)
                    .copyWith(fontStyle: FontStyle.italic)),
            const SizedBox(height: 10),
            Container(width: 28, height: 1, color: palette.accent.withValues(alpha: 0.6)),
            const SizedBox(height: 10),
          ],
          Flexible(
            child: Text(
              book.title,
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: LumenType.titleSerif(palette.body),
            ),
          ),
          const SizedBox(height: 8),
          Container(width: 20, height: 1, color: palette.caption.withValues(alpha: 0.5)),
          const SizedBox(height: 8),
          Text(
            book.author,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: LumenType.caption(palette.caption).copyWith(
              fontStyle: FontStyle.italic,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
