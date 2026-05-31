# CLAUDE.md

Guidance for working in the **Project Monarch** codebase.

> Project Monarch — a gamified, **offline-first** premium fitness tracker
> inspired by the *System* from Solo Leveling. True-black (#000000) UI with
> neon-blue (#00E5FF) accents.

## Tech Stack

- **Flutter** (Dart `>=3.4`) — UI
- **Riverpod** (`flutter_riverpod`) — state management (manual `Notifier`s, no codegen)
- **Hive** — local database (100% offline source of truth)
- **fl_chart** — pentagon stat radar; **flutter_heatmap_calendar** — 365-day grid
- **Python** — reference math engine / tuning (`scripts/`)

## Setup

```bash
flutter pub get
# REQUIRED: generate Hive TypeAdapters (*.g.dart are gitignored)
dart run build_runner build --delete-conflicting-outputs
flutter run
```

If you add or change a `@HiveType` model, re-run `build_runner`.

## Testing

```bash
flutter test                      # Dart unit tests (lib code)
python3 scripts/test_math_engine.py   # executable math-engine reference tests
```

The Python suite mirrors the Dart engines 1:1 and is the quickest way to verify
EXP/overload/stat math without a Flutter SDK.

## Architecture — strict layering

UI never contains business math; logic never touches Hive directly.

```
lib/
├── main.dart            # boot: orientation, overlay, Hive + DatabaseService.init, ProviderScope
├── core/
│   ├── theme/           # AppTheme.dark (single dark theme, Orbitron/Rajdhani)
│   ├── constants/       # AppColors, GameBalance (tuning), seed data, catalogs
│   └── database/        # HiveBoxes (names), DatabaseService (adapter reg + boxes)
├── models/              # Hive @HiveType models  (data shape)
├── repositories/        # persistence over Hive boxes (the ONLY Hive callers)
├── services/            # pure engines: ExpEngine, StatEngine, OverloadEngine
├── controllers/         # Riverpod Notifiers (business logic, orchestration)
├── views/               # screens (one folder each) + AppShell bottom-nav
└── widgets/             # shared widgets (GlowPanel, RankHeader, dialogs, …)
scripts/                 # Python math engine + tests
test/                    # Dart unit tests
```

**Data flow:** `View` → watches `controller` (Riverpod) → calls `repository` →
reads/writes `Hive box`. Math goes through a `service` engine and returns
immutable results the controller persists.

### Hive typeId registry (keep unique!)

| typeId | Type |
|--------|------|
| 1 | UserStats |
| 2 | RankProfile |
| 3 | WorkoutNode |
| 4 | ExerciseEntry |
| 5 | Habit |
| 6 | ConsistencyLog |
| 7 | NutritionDay |
| 8 | PenaltyQuest |
| 9 | DailyQuest |
| 20–25 | enums (Rank, StatType, NodeStatus, MuscleGroup, HabitCategory, DayOutcome) |

When adding a model: pick the next free typeId, register its adapter in
`DatabaseService._registerAdapters`, open its box in `_openBoxes`, and add a
`HiveBoxes` constant.

## Game balance

All tuning lives in `lib/core/constants/game_balance.dart` (mirrored in
`scripts/math_engine.py`). EXP curve:

```
threshold(rank, level) = baseExp · (rankTier+1)^rankExponent · levelGrowth^(level-1)
```

## Core gameplay loop

Map → unlock node (coins) → Active Workout checklist → `complete()` awards EXP
(via ExpEngine) + stats (StatEngine) + coins, applies progressive overload
(OverloadEngine), marks the node done (cascades unlocks), logs the heatmap day →
stronger stats unlock harder nodes. Missed mandatory days issue **Penalty
Quests** (see `daily_controller.dart`); rest days are configurable.

## Conventions

- Colors/strings come from `core/constants` — never hardcode hex in widgets.
- Use `withValues(alpha:)`, not the deprecated `withOpacity`.
- Keep files modular; provide complete code (no truncated snippets).

## CI / Releases

`.github/workflows/auto-version.yml` cuts versioned releases — but it is
**opt-in**, not on every push (so multi-phase work commits freely without
making versions). It runs only on a manual *Run workflow* (workflow_dispatch)
**or** when a pushed commit message contains the marker `[release]`. The bump
follows Conventional Commits: `feat:` → minor, `fix:`/other → patch,
`!`/`BREAKING CHANGE` → major. When it runs it builds a **release APK**
(generating the `android/` scaffold + Hive adapters in CI first), then bumps
`pubspec.yaml`, tags `vX.Y.Z`, and publishes a GitHub Release with the APK
attached. The build runs *before* tagging, so a failed build cuts no release.
Its own release commits are prefixed `chore(release):` + `[skip ci]`.

To cut a release: include `[release]` in the commit, or run the workflow
manually from the Actions tab.
