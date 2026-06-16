import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../controllers/library_controller.dart';
import '../../controllers/prefs_controller.dart';
import '../../core/theme/lumen_palette.dart';
import '../../core/theme/lumen_typography.dart';
import '../../widgets/pill_button.dart';
import 'boost_view.dart';

/// Distraction-free reading. Chrome hides until you tap; a hairline progress
/// line tracks the chapter. Scroll position is mapped to a word cursor and
/// persisted, so Boost picks up from the same place.
class ReaderView extends ConsumerStatefulWidget {
  const ReaderView({super.key, required this.bookId, required this.chapterIndex});

  final String bookId;
  final int chapterIndex;

  @override
  ConsumerState<ReaderView> createState() => _ReaderViewState();
}

class _ReaderViewState extends ConsumerState<ReaderView> {
  final _scroll = ScrollController();
  bool _chromeVisible = true;
  double _fraction = 0;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    // Restore approximate position after first layout.
    WidgetsBinding.instance.addPostFrameCallback((_) => _restore());
  }

  void _restore() {
    final book = ref.read(libraryControllerProvider).where((b) => b.id == widget.bookId).firstOrNull;
    if (book == null || !_scroll.hasClients) return;
    final ch = book.chapters[widget.chapterIndex];
    if (ch.wordCount == 0) return;
    final f = (ch.wordPosition / ch.wordCount).clamp(0.0, 1.0);
    _scroll.jumpTo(f * _scroll.position.maxScrollExtent);
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    final max = _scroll.position.maxScrollExtent;
    setState(() => _fraction = max <= 0 ? 1 : (_scroll.offset / max).clamp(0.0, 1.0));
  }

  @override
  void dispose() {
    _persist();
    _scroll.dispose();
    super.dispose();
  }

  void _persist() {
    final book = ref.read(libraryControllerProvider).where((b) => b.id == widget.bookId).firstOrNull;
    if (book == null) return;
    final ch = book.chapters[widget.chapterIndex];
    final word = (_fraction * ch.wordCount).round();
    ref.read(libraryControllerProvider.notifier).saveProgress(
          book, widget.chapterIndex, word,
          completed: _fraction >= 0.98 ? true : null,
        );
  }

  void _cycleFont() {
    final ctrl = ref.read(prefsControllerProvider.notifier);
    final cur = ref.read(prefsControllerProvider).fontScale;
    const steps = [0.9, 1.0, 1.15, 1.3];
    final next = steps[(steps.indexOf(cur) + 1) % steps.length];
    ctrl.setFontScale(next);
  }

  @override
  Widget build(BuildContext context) {
    final palette = ref.watch(prefsControllerProvider).palette;
    final fontScale = ref.watch(prefsControllerProvider).fontScale;
    final book = ref.watch(libraryControllerProvider).where((b) => b.id == widget.bookId).firstOrNull;
    if (book == null) return const Scaffold(body: SizedBox.shrink());
    final chapter = book.chapters[widget.chapterIndex];
    final minsLeft = ((chapter.wordCount * (1 - _fraction)) / book.wpm).ceil();

    return Scaffold(
      body: Stack(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => setState(() => _chromeVisible = !_chromeVisible),
            child: SingleChildScrollView(
              controller: _scroll,
              padding: const EdgeInsets.fromLTRB(24, 110, 24, 96),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('CHAPTER ${widget.chapterIndex + 1}', style: LumenType.overline(palette.caption)),
                  const SizedBox(height: 10),
                  Text(chapter.title, style: LumenType.headlineLg(palette.heading).copyWith(fontStyle: FontStyle.italic)),
                  const SizedBox(height: 28),
                  Text(
                    chapter.text,
                    textAlign: TextAlign.justify,
                    style: LumenType.readingBody(palette.body, scale: fontScale),
                  ),
                ],
              ),
            ),
          ),
          // Top hairline progress.
          Positioned(
            top: 0, left: 0, right: 0,
            child: LinearProgressIndicator(
              value: _fraction,
              minHeight: 2,
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation(palette.accent),
            ),
          ),
          // Top chrome.
          _AnimatedChrome(
            visible: _chromeVisible,
            top: true,
            palette: palette,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back, color: palette.body),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    Expanded(
                      child: Text(chapter.title,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: LumenType.labelMd(palette.body)),
                    ),
                    IconButton(
                      icon: Text('Aa', style: LumenType.titleSerif(palette.body)),
                      onPressed: _cycleFont,
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Bottom chrome: status + Boost.
          _AnimatedChrome(
            visible: _chromeVisible,
            top: false,
            palette: palette,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${(_fraction * 100).round()}% read · $minsLeft mins left',
                        style: LumenType.caption(palette.caption)),
                    PillButton(
                      label: 'Boost',
                      onPressed: () {
                        _persist();
                        Navigator.of(context).pushReplacement(MaterialPageRoute(
                          builder: (_) => BoostView(bookId: widget.bookId, chapterIndex: widget.chapterIndex),
                        ));
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedChrome extends StatelessWidget {
  const _AnimatedChrome({
    required this.visible,
    required this.top,
    required this.palette,
    required this.child,
  });

  final bool visible;
  final bool top;
  final LumenPalette palette;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      top: top ? (visible ? 0 : -120) : null,
      bottom: top ? null : (visible ? 0 : -120),
      left: 0,
      right: 0,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 220),
        opacity: visible ? 1 : 0,
        child: Container(color: palette.background.withValues(alpha: 0.92), child: child),
      ),
    );
  }
}
