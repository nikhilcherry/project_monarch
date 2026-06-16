import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../controllers/prefs_controller.dart';
import '../../core/theme/lumen_palette.dart';
import '../../core/theme/lumen_typography.dart';

class CustomizeColorsView extends ConsumerWidget {
  const CustomizeColorsView({super.key});

  static const _swatchChoices = <Color>[
    Color(0xFF0A0A0A), Color(0xFF131313), Color(0xFF1A1A1F), Color(0xFF202028),
    Color(0xFFF4ECD8), Color(0xFFFFFFFF), Color(0xFFECECEC), Color(0xFFE5E2E1),
    Color(0xFF7A7A7A), Color(0xFF9F8E7D), Color(0xFF2B2620),
    Color(0xFFFFB454), Color(0xFFB9772A), Color(0xFF00E5FF), Color(0xFF8FB4FF),
    Color(0xFFA6E3A1), Color(0xFFF38BA8),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = ref.watch(prefsControllerProvider).palette;
    final ctrl = ref.read(prefsControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text('Customize colors', style: LumenType.titleSerif(palette.heading)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
        children: [
          _Preview(palette: palette),
          const SizedBox(height: 28),
          Text('APPEARANCE TOKENS', style: LumenType.overline(palette.caption)),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: palette.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: palette.border),
            ),
            child: Column(
              children: [
                for (var i = 0; i < LumenToken.values.length; i++) ...[
                  if (i > 0) Divider(color: palette.border, height: 1, indent: 16, endIndent: 16),
                  _TokenRow(
                    palette: palette,
                    token: LumenToken.values[i],
                    onTap: () => _pick(context, ref, LumenToken.values[i]),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: TextButton(
              onPressed: ctrl.resetPaletteToPreset,
              child: Text('Reset to preset', style: LumenType.bodyMd(palette.caption)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pick(BuildContext context, WidgetRef ref, LumenToken token) async {
    final palette = ref.read(prefsControllerProvider).palette;
    final chosen = await showDialog<Color>(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: palette.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: palette.border),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(token.label, style: LumenType.headlineMd(palette.heading)),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final c in _swatchChoices)
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(c),
                      child: Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(
                          color: c,
                          shape: BoxShape.circle,
                          border: Border.all(color: palette.border),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (chosen != null) {
      ref.read(prefsControllerProvider.notifier).setToken(token, chosen);
    }
  }
}

class _Preview extends StatelessWidget {
  const _Preview({required this.palette});
  final LumenPalette palette;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: palette.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Sample Heading', style: LumenType.headlineMd(palette.heading)),
          const SizedBox(height: 12),
          Text(
            'Lumen lets you curate your reading environment with precision. '
            'Every token is tuned for legibility and calm during long sessions.',
            style: LumenType.bodyMd(palette.body),
          ),
          const SizedBox(height: 12),
          Text('A sample caption below the text', style: LumenType.caption(palette.caption)),
          const SizedBox(height: 18),
          Center(
            child: RichText(
              text: TextSpan(
                style: LumenType.headlineLg(palette.body).copyWith(letterSpacing: 2),
                children: [
                  const TextSpan(text: 'BE'),
                  TextSpan(text: 'Y', style: TextStyle(color: palette.accent)),
                  const TextSpan(text: 'OND'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TokenRow extends StatelessWidget {
  const _TokenRow({required this.palette, required this.token, required this.onTap});
  final LumenPalette palette;
  final LumenToken token;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Expanded(child: Text(token.label, style: LumenType.bodyLg(palette.body))),
            Container(
              width: 26, height: 26,
              decoration: BoxDecoration(
                color: palette.tokenColor(token),
                shape: BoxShape.circle,
                border: Border.all(color: palette.border),
              ),
            ),
            const SizedBox(width: 10),
            Icon(Icons.chevron_right, color: palette.caption),
          ],
        ),
      ),
    );
  }
}
