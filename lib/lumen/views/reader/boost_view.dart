import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../controllers/library_controller.dart';
import '../../controllers/prefs_controller.dart';
import '../../core/constants/lumen_defaults.dart';
import '../../core/theme/lumen_palette.dart';
import '../../core/theme/lumen_typography.dart';
import '../../models/book.dart';
import '../../services/rsvp_scheduler.dart';
import '../../widgets/progress_ring.dart';

/// RSVP + ORP speed-reading. One word at the focal point, pivot letter tinted
/// amber, faint context above/below, a progress ring below. Hybrid controls:
/// tap reveals the control bar; long-press pauses; vertical swipe nudges WPM;
/// left swipe rewinds a sentence. Deterministic timing — no AI.
class BoostView extends ConsumerStatefulWidget {
  const BoostView({super.key, required this.bookId, required this.chapterIndex});

  final String bookId;
  final int chapterIndex;

  @override
  ConsumerState<BoostView> createState() => _BoostViewState();
}

class _BoostViewState extends ConsumerState<BoostView> {
  List<RsvpFrame> _frames = const [];
  int _index = 0;
  int _startIndex = 0;
  int _wpm = 300;
  bool _smartPauses = false;
  bool _playing = false;
  bool _controls = false;
  Timer? _tick;
  Timer? _controlsTimer;
  final _stopwatch = Stopwatch();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _setup());
  }

  void _setup() {
    final book = _book;
    if (book == null) return;
    final chapter = book.chapters[widget.chapterIndex];
    _wpm = book.wpm;
    _smartPauses = ref.read(prefsControllerProvider).smartPauses;
    _frames = RsvpScheduler.schedule(chapter.text, _wpm, smartPauses: _smartPauses);
    _index = chapter.wordPosition.clamp(0, _frames.isEmpty ? 0 : _frames.length - 1);
    _startIndex = _index;
    setState(() {});
    _play();
  }

  Book? get _book =>
      ref.read(libraryControllerProvider).where((b) => b.id == widget.bookId).firstOrNull;

  void _rebuildFrames() {
    final book = _book;
    if (book == null) return;
    _frames = RsvpScheduler.schedule(
        book.chapters[widget.chapterIndex].text, _wpm, smartPauses: _smartPauses);
  }

  void _play() {
    if (_frames.isEmpty) return;
    setState(() => _playing = true);
    _stopwatch.start();
    _scheduleNext();
  }

  void _pause() {
    _tick?.cancel();
    _stopwatch.stop();
    setState(() => _playing = false);
  }

  void _scheduleNext() {
    _tick?.cancel();
    if (_index >= _frames.length) {
      _finish();
      return;
    }
    _tick = Timer(Duration(milliseconds: _frames[_index].durationMs), () {
      if (_index < _frames.length - 1) {
        setState(() => _index++);
        _scheduleNext();
      } else {
        _finish();
      }
    });
  }

  void _finish() {
    _tick?.cancel();
    _stopwatch.stop();
    setState(() => _playing = false);
    final book = _book;
    if (book != null) {
      ref.read(libraryControllerProvider.notifier).saveProgress(
            book, widget.chapterIndex, _frames.length,
            completed: true,
          );
    }
    if (mounted) Navigator.of(context).pop();
  }

  void _changeWpm(int delta) {
    setState(() {
      _wpm = (_wpm + delta).clamp(LumenDefaults.minWpm, LumenDefaults.maxWpm);
      _rebuildFrames();
    });
    if (_playing) _scheduleNext();
    _revealControls();
  }

  void _rewindSentence() {
    var i = _index - 1;
    // Step back past the current sentence to the start of the previous one.
    while (i > 0 && !_frames[i - 1].endsSentence) {
      i--;
    }
    setState(() => _index = i.clamp(0, _frames.length - 1));
    if (_playing) _scheduleNext();
  }

  void _revealControls() {
    setState(() => _controls = true);
    _controlsTimer?.cancel();
    _controlsTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _controls = false);
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    _controlsTimer?.cancel();
    _persist();
    super.dispose();
  }

  void _persist() {
    final book = _book;
    if (book == null || _frames.isEmpty) return;
    ref.read(libraryControllerProvider.notifier).saveProgress(book, widget.chapterIndex, _index);
    ref.read(libraryControllerProvider.notifier).setBookWpm(book, _wpm);
    final words = (_index - _startIndex).clamp(0, _frames.length);
    if (words > 0) {
      ref.read(prefsControllerProvider.notifier).recordSession(
            wordsRead: words,
            durationMs: _stopwatch.elapsedMilliseconds,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = ref.watch(prefsControllerProvider).palette;
    final hasFrames = _frames.isNotEmpty && _index < _frames.length;
    final progress = _frames.isEmpty ? 0.0 : (_index + 1) / _frames.length;

    return Scaffold(
      backgroundColor: palette.background,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _revealControls,
        onLongPressStart: (_) => _pause(),
        onLongPressEnd: (_) => _play(),
        onVerticalDragEnd: (d) {
          final v = d.primaryVelocity ?? 0;
          if (v < 0) _changeWpm(LumenDefaults.wpmStep);
          if (v > 0) _changeWpm(-LumenDefaults.wpmStep);
        },
        onHorizontalDragEnd: (d) {
          if ((d.primaryVelocity ?? 0) < 0) _rewindSentence();
        },
        child: SafeArea(
          child: Stack(
            children: [
              Positioned(
                top: 8, left: 8,
                child: IconButton(
                  icon: Icon(Icons.close, color: palette.caption),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Context word above.
                    SizedBox(
                      height: 28,
                      child: Text(
                        _index > 0 ? _frames[_index - 1].word : '',
                        style: LumenType.bodyLg(palette.caption.withValues(alpha: 0.4)),
                      ),
                    ),
                    const SizedBox(height: 18),
                    // Crosshair tick (top).
                    Container(width: 2, height: 14, color: palette.accent.withValues(alpha: 0.8)),
                    const SizedBox(height: 12),
                    // Focal word with ORP pivot.
                    if (hasFrames) _FocalWord(frame: _frames[_index], palette: palette),
                    const SizedBox(height: 12),
                    // Crosshair tick (bottom).
                    Container(width: 2, height: 14, color: palette.accent.withValues(alpha: 0.8)),
                    const SizedBox(height: 18),
                    SizedBox(
                      height: 28,
                      child: Text(
                        _index < _frames.length - 1 ? _frames[_index + 1].word : '',
                        style: LumenType.bodyLg(palette.caption.withValues(alpha: 0.4)),
                      ),
                    ),
                  ],
                ),
              ),
              // Progress ring.
              Align(
                alignment: const Alignment(0, 0.72),
                child: ProgressRing(
                  progress: progress,
                  accent: palette.accent,
                  track: palette.border,
                  size: 96,
                  stroke: 2,
                  label: '${(progress * 100).round()}%',
                  labelColor: palette.caption,
                ),
              ),
              // Control bar (tap to reveal).
              AnimatedPositioned(
                duration: const Duration(milliseconds: 220),
                left: 0, right: 0,
                bottom: _controls ? 24 : -140,
                child: _ControlBar(
                  palette: palette,
                  wpm: _wpm,
                  playing: _playing,
                  onWpm: (v) {
                    setState(() {
                      _wpm = v.round();
                      _rebuildFrames();
                    });
                    if (_playing) _scheduleNext();
                  },
                  onPlayPause: () => _playing ? _pause() : _play(),
                  onRewind: _rewindSentence,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FocalWord extends StatelessWidget {
  const _FocalWord({required this.frame, required this.palette});

  final RsvpFrame frame;
  final LumenPalette palette;

  @override
  Widget build(BuildContext context) {
    final w = frame.word;
    final i = frame.pivotIndex.clamp(0, w.isEmpty ? 0 : w.length - 1);
    final before = w.substring(0, i);
    final pivot = w.isEmpty ? '' : w.substring(i, i + 1);
    final after = w.isEmpty ? '' : w.substring(i + 1);
    final style = LumenType.headlineLg(palette.body).copyWith(fontSize: 40, fontWeight: FontWeight.w400);
    return RichText(
      text: TextSpan(style: style, children: [
        TextSpan(text: before),
        TextSpan(text: pivot, style: TextStyle(color: palette.accent)),
        TextSpan(text: after),
      ]),
    );
  }
}

class _ControlBar extends StatelessWidget {
  const _ControlBar({
    required this.palette,
    required this.wpm,
    required this.playing,
    required this.onWpm,
    required this.onPlayPause,
    required this.onRewind,
  });

  final LumenPalette palette;
  final int wpm;
  final bool playing;
  final ValueChanged<double> onWpm;
  final VoidCallback onPlayPause;
  final VoidCallback onRewind;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: palette.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                IconButton(
                  icon: Icon(Icons.replay, color: palette.body),
                  onPressed: onRewind,
                ),
                IconButton(
                  icon: Icon(playing ? Icons.pause : Icons.play_arrow, color: palette.accent, size: 30),
                  onPressed: onPlayPause,
                ),
                Expanded(
                  child: Slider(
                    value: wpm.toDouble(),
                    min: LumenDefaults.minWpm.toDouble(),
                    max: LumenDefaults.maxWpm.toDouble(),
                    onChanged: onWpm,
                  ),
                ),
                SizedBox(
                  width: 64,
                  child: Text('$wpm\nwpm',
                      textAlign: TextAlign.center, style: LumenType.caption(palette.caption)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
