import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../controllers/library_controller.dart';
import '../../controllers/prefs_controller.dart';
import '../../core/theme/lumen_palette.dart';
import '../../core/theme/lumen_typography.dart';
import '../../widgets/book_cover.dart';
import '../../widgets/pill_button.dart';

class EditBookView extends ConsumerStatefulWidget {
  const EditBookView({super.key, required this.bookId});
  final String bookId;

  @override
  ConsumerState<EditBookView> createState() => _EditBookViewState();
}

class _EditBookViewState extends ConsumerState<EditBookView> {
  late final TextEditingController _title;
  late final TextEditingController _author;
  int? _coverColor;
  bool _ready = false;

  static const _tints = <int?>[
    null, 0xFF1B2430, 0xFF2A1F2D, 0xFF1F2A24, 0xFF2D2620, 0xFF222433,
  ];

  @override
  void initState() {
    super.initState();
    final book = ref.read(libraryControllerProvider).where((b) => b.id == widget.bookId).firstOrNull;
    _title = TextEditingController(text: book?.title ?? '');
    _author = TextEditingController(text: book?.author ?? '');
    _coverColor = book?.coverColorValue;
    _ready = true;
  }

  @override
  void dispose() {
    _title.dispose();
    _author.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = ref.watch(prefsControllerProvider).palette;
    final book = ref.watch(libraryControllerProvider).where((b) => b.id == widget.bookId).firstOrNull;
    if (book == null || !_ready) return const Scaffold(body: SizedBox.shrink());

    // Preview cover reflecting the in-progress tint choice.
    book.coverColorValue = _coverColor;

    return Scaffold(
      appBar: AppBar(title: Text('Edit book', style: LumenType.titleSerif(palette.heading))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
        children: [
          Center(child: BookCover(book: book, palette: palette, width: 150, showMonogram: true)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                onPressed: () => setState(() {
                  final i = _tints.indexOf(_coverColor);
                  _coverColor = _tints[(i + 1) % _tints.length];
                }),
                child: Text('Replace', style: LumenType.bodyMd(palette.caption)),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () => setState(() => _coverColor = null),
                child: Text('Auto-generate cover', style: LumenType.bodyMd(palette.caption)),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _Label('Title', palette.body),
          _Input(controller: _title, palette: palette),
          const SizedBox(height: 20),
          _Label('Author', palette.body),
          _Input(controller: _author, palette: palette),
          const SizedBox(height: 40),
          PillButton(
            label: 'Save',
            filled: true,
            expand: true,
            onPressed: () async {
              book.coverColorValue = _coverColor;
              await ref.read(libraryControllerProvider.notifier).updateInfo(
                    book, title: _title.text, author: _author.text,
                  );
              if (context.mounted) Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text, this.color);
  final String text;
  final Color color;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text, style: LumenType.labelMd(color)),
      );
}

class _Input extends StatelessWidget {
  const _Input({required this.controller, required this.palette});
  final TextEditingController controller;
  final LumenPalette palette;
  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: LumenType.bodyLg(palette.body),
      cursorColor: palette.accent,
      decoration: InputDecoration(
        filled: true,
        fillColor: palette.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: palette.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: palette.accent),
        ),
      ),
    );
  }
}
