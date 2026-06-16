import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../controllers/prefs_controller.dart';
import '../../core/theme/lumen_palette.dart';
import '../../core/theme/lumen_typography.dart';
import '../../widgets/pill_button.dart';

/// Three calm slides: Read beautifully → Boost → Pick your look.
class OnboardingView extends ConsumerStatefulWidget {
  const OnboardingView({super.key});

  @override
  ConsumerState<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends ConsumerState<OnboardingView> {
  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _finish() => ref.read(prefsControllerProvider.notifier).completeOnboarding();

  @override
  Widget build(BuildContext context) {
    final palette = ref.watch(prefsControllerProvider).palette;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Lumen', style: LumenType.titleSerif(palette.heading)),
                  TextButton(
                    onPressed: _finish,
                    child: Text('Skip', style: LumenType.bodyMd(palette.caption)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView(
                controller: _controller,
                onPageChanged: (i) => setState(() => _page = i),
                children: [
                  _Slide(
                    palette: palette,
                    title: 'Read beautifully.',
                    subtitle:
                        'A quiet, distraction-free reader tuned for long, focused sessions.',
                    visual: _ReaderGlyph(palette: palette),
                  ),
                  _Slide(
                    palette: palette,
                    title: 'Boost when you want to.',
                    subtitle:
                        'Flash through any text one word at a time, with the focal letter anchored.',
                    visual: _BoostGlyph(palette: palette),
                  ),
                  _PickYourLook(palette: palette, onStart: _finish),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 24, top: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < 3; i++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: _page == i ? 18 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: _page == i ? palette.accent : palette.border,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Slide extends StatelessWidget {
  const _Slide({
    required this.palette,
    required this.title,
    required this.subtitle,
    required this.visual,
  });

  final LumenPalette palette;
  final String title;
  final String subtitle;
  final Widget visual;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(height: 120, child: Center(child: visual)),
          const SizedBox(height: 56),
          Text(title, textAlign: TextAlign.center, style: LumenType.headlineLg(palette.heading)),
          const SizedBox(height: 16),
          Text(subtitle, textAlign: TextAlign.center, style: LumenType.bodyMd(palette.caption)),
        ],
      ),
    );
  }
}

class _PickYourLook extends ConsumerWidget {
  const _PickYourLook({required this.palette, required this.onStart});

  final LumenPalette palette;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Pick your look.', style: LumenType.headlineLg(palette.heading)),
          const SizedBox(height: 16),
          Text('Choose the canvas that best suits your environment.',
              textAlign: TextAlign.center, style: LumenType.bodyMd(palette.caption)),
          const SizedBox(height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (final preset in LumenPalette.presets)
                _Swatch(
                  preset: preset,
                  selected: palette.preset == preset.preset,
                  accent: palette.accent,
                  caption: palette.caption,
                  onTap: () =>
                      ref.read(prefsControllerProvider.notifier).setPreset(preset.preset),
                ),
            ],
          ),
          const SizedBox(height: 48),
          PillButton(label: 'Start reading', filled: true, onPressed: onStart),
        ],
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({
    required this.preset,
    required this.selected,
    required this.accent,
    required this.caption,
    required this.onTap,
  });

  final LumenPalette preset;
  final bool selected;
  final Color accent;
  final Color caption;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Column(
        children: [
          GestureDetector(
            onTap: onTap,
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: preset.background,
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? accent : preset.border,
                  width: selected ? 2.5 : 1,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(preset.preset.label, style: LumenType.caption(caption)),
        ],
      ),
    );
  }
}

class _ReaderGlyph extends StatelessWidget {
  const _ReaderGlyph({required this.palette});
  final LumenPalette palette;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < 4; i++)
          Container(
            margin: const EdgeInsets.symmetric(vertical: 5),
            width: i == 3 ? 90 : 150,
            height: 4,
            decoration: BoxDecoration(
              color: i == 0 ? palette.accent.withValues(alpha: 0.8) : palette.caption.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
      ],
    );
  }
}

class _BoostGlyph extends StatelessWidget {
  const _BoostGlyph({required this.palette});
  final LumenPalette palette;

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: LumenType.headlineLg(palette.body),
        children: [
          TextSpan(text: 'bey'),
          TextSpan(text: 'o', style: TextStyle(color: palette.accent)),
          TextSpan(text: 'nd'),
        ],
      ),
    );
  }
}
