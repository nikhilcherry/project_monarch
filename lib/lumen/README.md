# Lumen

> A beautiful, offline, minimalist reader with a **Boost** button.
> Read normally, or flash through any text with RSVP speed-reading — same text,
> same place, instant switch. No accounts, no AI, no nagging.

Lumen is a second product living inside the Project Monarch repo. It is a
self-contained subtree under `lib/lumen/` so it shares tooling now and can be
extracted into its own package later. It does **not** depend on Monarch's
gameplay code.

---

## Product decisions (locked)

| Area | Decision |
|------|----------|
| **Platform** | Flutter (cross-platform), Hive offline-first, no AI / no network required |
| **North star** | A *beautiful everyday reader* first; speed-reading is the killer trick inside it |
| **Brand** | **Lumen** · warm amber accent `#FFB454` · serif body (Newsreader/Literata) + Inter UI |
| **Themes** | 3 presets — true-black, sepia, soft-dark — **+ full per-colour override** |
| **Customisable colours** | Background · Body text · Heading · Caption/small UI text · Accent (per theme, live preview) |
| **Book info** | Editable core fields: title, author, cover (replace or auto-generate a typographic cover) |
| **Chapters** | Real TOC → heading detection → even ~1000-word auto-sections. Per-chapter ring **+** overall book % |
| **Boost** | RSVP + ORP amber pivot; surroundings dimmed; hybrid gesture + tap-to-reveal controls |
| **WPM** | User-owned, **per book**, range **100–800** (±25 steps); global default in Settings |
| **Timing** | Uniform `60000/wpm` by default; **smart pauses an opt-in toggle** (deterministic, no AI) |
| **Stats** | Minimal counters (words read, time, current WPM, streak) **+ one WPM sparkline**. Display only |
| **Cut features** | ❌ comprehension quizzes ❌ training plans / coach ❌ adaptive auto-WPM ❌ any AI/LLM |

### Differentiation
1. **Best-in-class typography** — nice enough to use daily even without Boost.
2. **Seamless reader ↔ Boost handoff** — same text, same position, both ways.
3. **Genuinely minimal & offline** — restraint as the selling point.

---

## Architecture (mirrors Monarch's strict layering)

```
lib/lumen/
├── core/
│   ├── constants/   # LumenDefaults (WPM, pause tuning, auto-section size)  ✅
│   └── theme/        # LumenTheme: 3 presets + custom palette, fonts          ⬜
├── models/           # Hive: Book, Chapter, ReadingPosition, ReadingSession,
│                     #       UserPrefs, ThemePalette                          ⬜
├── repositories/     # the only Hive callers (library, positions, prefs)      ⬜
├── services/         # PURE engines (no Hive, no Flutter) — unit-tested:
│   ├── orp_engine.dart        # pivot-letter math                            ✅
│   ├── text_tokenizer.dart     # words / sentences / paragraphs              ✅
│   ├── rsvp_scheduler.dart     # timed frame stream from text + WPM          ✅
│   ├── chapter_splitter.dart   # TOC → headings → auto-sections              ✅
│   ├── article_extractor.dart  # URL → clean article                        ⬜
│   └── epub_parser.dart        # EPUB/PDF → chapters                         ⬜
├── controllers/      # Riverpod Notifiers: Library, Reader, Boost, Prefs     ⬜
└── views/            # Library, BookDetail, Reader, Boost, Settings,
                      # CustomizeColors, EditBook, Stats, Onboarding          ⬜

scripts/lumen/        # Python mirror of the engines + reference tests        ✅
test/lumen/           # Dart unit tests (1:1 with the Python suite)           ✅
```

**Data flow:** `View` → watches `controller` (Riverpod) → calls `repository` →
reads/writes its Hive box. All reading math goes through the pure `services/`
engines, which take plain Dart types and return immutable results — no Hive,
no AI, fully deterministic and testable.

### Hive typeId registry (reserved band — must not collide with Monarch's 1–10 / 20–25)

| typeId | Type |
|--------|------|
| 40 | Book |
| 41 | Chapter |
| 42 | ReadingPosition |
| 43 | ReadingSession |
| 44 | UserPrefs |
| 45 | ThemePalette |
| 60–65 | enums (ThemePreset, ImportSource, ReadMode, …) |

When adding a model: pick the next free id **in Lumen's band**, register its
adapter, open its box, and add a `LumenBoxes` constant.

---

## The engines (built ✅)

Pure functions, identical in Dart (`lib/lumen/services/`) and Python
(`scripts/lumen/reading_engine.py`). The Python suite is the quickest way to
tune the *feel* without a Flutter SDK.

- **`OrpEngine`** — `pivotIndex(word)` / `split(word) → (before, pivot, after)`.
  Spritz heuristic: pivot just left of centre, drifting right as words grow.
- **`TextTokenizer`** — splits prose into words with trailing punctuation,
  sentence-end and paragraph-end flags. Keeps `'` and `-` inside words.
- **`RsvpScheduler`** — `schedule(text, wpm, smartPauses)` → timed `RsvpFrame`s.
  Base = `60000/wpm`. Smart pauses scale that base by word length + punctuation
  (short words ×0.9, long words +0.04/char, soft punct ×1.5, hard ×2.2,
  paragraph ×2.6), so the rhythm survives any WPM. Off = perfectly uniform.
- **`ChapterSplitter`** — `fromToc` → `detect` (headings) → `autoSection`
  (even ~1000-word synthetic blocks). Synthetic sections are flagged so the UI
  can label them honestly.

### Running the reference suite
```bash
python3 scripts/lumen/reading_engine.py            # demo a Boost stream
python3 scripts/lumen/reading_engine.py --table    # WPM → ms/word table
python3 scripts/lumen/test_reading_engine.py       # 38 reference assertions
flutter test test/lumen/                           # Dart mirror tests
```

---

## Tuning

All reading/Boost tuning lives in
`lib/lumen/core/constants/lumen_defaults.dart`, mirrored in
`scripts/lumen/reading_engine.py`. Keep the two in lockstep.

## Roadmap (no re-architecture needed)

Built: the deterministic engine core + reference tests.
Next: theme/palette, Hive models + repositories, Riverpod controllers, the
Stitch-designed screens, then EPUB/PDF/URL import. Later speed-reading methods
(bionic bold-anchor, guided pacer, chunking columns) are just new views over
the same `RsvpScheduler` stream.
