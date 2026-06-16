import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../controllers/library_controller.dart';
import '../../controllers/prefs_controller.dart';
import '../../core/theme/lumen_palette.dart';
import '../../core/theme/lumen_typography.dart';
import '../../widgets/pill_button.dart';

Future<void> showAddToLibrarySheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _AddToLibrarySheet(),
  );
}

class _AddToLibrarySheet extends ConsumerStatefulWidget {
  const _AddToLibrarySheet();

  @override
  ConsumerState<_AddToLibrarySheet> createState() => _AddToLibrarySheetState();
}

class _AddToLibrarySheetState extends ConsumerState<_AddToLibrarySheet> {
  final _title = TextEditingController();
  final _author = TextEditingController();
  final _content = TextEditingController();
  bool _pasting = false;

  @override
  void dispose() {
    _title.dispose();
    _author.dispose();
    _content.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    if (_content.text.trim().isEmpty) return;
    final wpm = ref.read(prefsControllerProvider).defaultWpm;
    await ref.read(libraryControllerProvider.notifier).addFromText(
          title: _title.text,
          author: _author.text,
          text: _content.text,
          wpm: wpm,
        );
    if (mounted) Navigator.of(context).pop();
  }

  void _soon(String what) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$what import is coming soon.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = ref.watch(prefsControllerProvider).palette;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border.all(color: palette.border),
      ),
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: palette.caption.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _Option(
                palette: palette,
                icon: Icons.content_paste_outlined,
                title: 'Paste text',
                subtitle: 'Manually add snippets or full chapters',
                onTap: () => setState(() => _pasting = true),
              ),
              Divider(color: palette.border, height: 24),
              _Option(
                palette: palette,
                icon: Icons.insert_drive_file_outlined,
                title: 'Import file',
                subtitle: '.txt, EPUB, or PDF',
                onTap: () => _soon('File'),
              ),
              Divider(color: palette.border, height: 24),
              _Option(
                palette: palette,
                icon: Icons.link,
                title: 'From a link',
                subtitle: 'Extract content from a web URL',
                onTap: () => _soon('Link'),
              ),
              if (_pasting) ...[
                const SizedBox(height: 28),
                Text('Add new text', style: LumenType.headlineMd(palette.accent)),
                const SizedBox(height: 20),
                _Field(palette: palette, label: 'Title', controller: _title, hint: 'The silent reader'),
                const SizedBox(height: 16),
                _Field(palette: palette, label: 'Author', controller: _author, hint: 'Anonymous'),
                const SizedBox(height: 16),
                _Field(
                  palette: palette,
                  label: 'Content',
                  controller: _content,
                  hint: 'Begin typing or paste your text here…',
                  maxLines: 6,
                ),
                const SizedBox(height: 24),
                PillButton(label: 'Add to library', filled: true, expand: true, onPressed: _add),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Option extends StatelessWidget {
  const _Option({
    required this.palette,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final LumenPalette palette;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: palette.border),
            ),
            child: Icon(icon, color: palette.accent, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: LumenType.bodyLg(palette.body).copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(subtitle, style: LumenType.caption(palette.caption)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.palette,
    required this.label,
    required this.controller,
    required this.hint,
    this.maxLines = 1,
  });

  final LumenPalette palette;
  final String label;
  final TextEditingController controller;
  final String hint;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: LumenType.labelMd(palette.body)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: LumenType.bodyLg(palette.body),
          cursorColor: palette.accent,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: LumenType.bodyLg(palette.caption),
            filled: true,
            fillColor: palette.background,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: palette.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: palette.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: palette.accent),
            ),
          ),
        ),
      ],
    );
  }
}
