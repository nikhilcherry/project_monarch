import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../controllers/prefs_controller.dart';
import '../../core/constants/lumen_defaults.dart';
import '../../core/theme/lumen_palette.dart';
import '../../core/theme/lumen_typography.dart';
import 'customize_colors_view.dart';

class SettingsView extends ConsumerWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(prefsControllerProvider);
    final ctrl = ref.read(prefsControllerProvider.notifier);
    final palette = settings.palette;

    return Scaffold(
      appBar: AppBar(title: Text('Settings', style: LumenType.titleSerif(palette.heading))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [
          _SectionLabel('APPEARANCE', palette),
          _Group(palette: palette, children: [
            _Row(
              palette: palette,
              label: 'Theme',
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final p in LumenPalette.presets)
                    Padding(
                      padding: const EdgeInsets.only(left: 10),
                      child: GestureDetector(
                        onTap: () => ctrl.setPreset(p.preset),
                        child: Container(
                          width: 30, height: 30,
                          decoration: BoxDecoration(
                            color: p.background,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: palette.preset == p.preset ? palette.accent : palette.border,
                              width: palette.preset == p.preset ? 2 : 1,
                            ),
                          ),
                          child: palette.preset == p.preset
                              ? Icon(Icons.check, size: 14, color: palette.accent)
                              : null,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            _Divider(palette),
            _Row(
              palette: palette,
              label: 'Customize colors',
              trailing: Icon(Icons.chevron_right, color: palette.caption),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CustomizeColorsView()),
              ),
            ),
          ]),
          const SizedBox(height: 28),
          _SectionLabel('READING', palette),
          _Group(palette: palette, children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Default WPM', style: LumenType.bodyLg(palette.body)),
                      Text('${settings.defaultWpm}', style: LumenType.labelMd(palette.accent)),
                    ],
                  ),
                  Slider(
                    value: settings.defaultWpm.toDouble(),
                    min: LumenDefaults.minWpm.toDouble(),
                    max: LumenDefaults.maxWpm.toDouble(),
                    onChanged: (v) => ctrl.setDefaultWpm(v.round()),
                  ),
                ],
              ),
            ),
            _Divider(palette),
            _Row(
              palette: palette,
              label: 'Smart pauses',
              trailing: Switch(
                value: settings.smartPauses,
                onChanged: ctrl.setSmartPauses,
              ),
            ),
            _Divider(palette),
            _Row(
              palette: palette,
              label: 'Font size',
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_fontLabel(settings.fontScale), style: LumenType.bodyMd(palette.caption)),
                  const SizedBox(width: 6),
                  Icon(Icons.chevron_right, color: palette.caption),
                ],
              ),
              onTap: () {
                const steps = [0.9, 1.0, 1.15, 1.3];
                final next = steps[(steps.indexOf(settings.fontScale) + 1) % steps.length];
                ctrl.setFontScale(next);
              },
            ),
          ]),
          const SizedBox(height: 28),
          _SectionLabel('ABOUT', palette),
          _Group(palette: palette, children: [
            _Row(
              palette: palette,
              label: 'Version',
              trailing: Text('1.0.0', style: LumenType.bodyMd(palette.caption)),
            ),
          ]),
          const SizedBox(height: 40),
          Center(
            child: Column(
              children: [
                Text('Lumen', style: LumenType.titleSerif(palette.caption).copyWith(fontStyle: FontStyle.italic)),
                const SizedBox(height: 4),
                Text('The Quiet Sanctuary for Minds.', style: LumenType.caption(palette.caption)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _fontLabel(double s) => switch (s) {
        0.9 => 'Small',
        1.15 => 'Large',
        1.3 => 'X-Large',
        _ => 'Medium',
      };
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text, this.palette);
  final String text;
  final LumenPalette palette;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10, left: 4),
        child: Text(text, style: LumenType.overline(palette.caption)),
      );
}

class _Group extends StatelessWidget {
  const _Group({required this.palette, required this.children});
  final LumenPalette palette;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: palette.border),
        ),
        child: Column(children: children),
      );
}

class _Row extends StatelessWidget {
  const _Row({
    required this.palette,
    required this.label,
    required this.trailing,
    this.onTap,
  });
  final LumenPalette palette;
  final String label;
  final Widget trailing;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: LumenType.bodyLg(palette.body)),
              trailing,
            ],
          ),
        ),
      );
}

class _Divider extends StatelessWidget {
  const _Divider(this.palette);
  final LumenPalette palette;
  @override
  Widget build(BuildContext context) =>
      Divider(color: palette.border, height: 1, indent: 16, endIndent: 16);
}
