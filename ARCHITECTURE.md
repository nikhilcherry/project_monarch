# Project Monarch — Architecture

> Gamified, **offline-first** premium fitness tracker inspired by the *System* from Solo Leveling.

## Layered Structure

The project enforces a strict separation between **UI**, **Business Logic**, and **Data**.

```
project_monarch/
├── pubspec.yaml
├── lib/
│   ├── main.dart                  # App entry point (Phase 2)
│   │
│   ├── core/                      # Cross-cutting foundations
│   │   ├── theme/                 # True-black + neon-blue visual identity (Phase 2)
│   │   ├── constants/             # Colors, sizes, EXP/rank tuning constants
│   │   ├── router/                # go_router config (branching map flow)
│   │   └── utils/                 # Formatters, extensions, helpers
│   │
│   ├── models/                    # Data layer — Hive models (Phase 3)
│   │                              #   UserStats, ExpProfile, WorkoutNode, Habit...
│   │
│   ├── repositories/              # Persistence abstraction over Hive boxes
│   ├── services/                  # Math engine, EXP scaling, stat distribution (Phase 4)
│   ├── controllers/               # Business logic — Riverpod notifiers/providers
│   │
│   ├── views/                     # UI layer — one folder per screen (Phase 5)
│   │   ├── dashboard/             #   Radar chart + heatmap + rank header
│   │   ├── world_map/             #   Branching campaign node map
│   │   ├── active_workout/        #   Fast text checklist + penalty quests
│   │   ├── nutrition/             #   Target-based macro tracker
│   │   ├── habits/                #   VIT wellness check-offs
│   │   └── shop/                  #   Coin economy + cosmetics
│   │
│   └── widgets/                   # Shared reusable widgets (glow buttons, panels)
│
├── scripts/                       # Python local math/automation scripts
├── assets/                        # images / icons / map art
└── test/                          # Unit + widget tests
```

## Core Principles

1. **Offline First** — All EXP scaling, progressive-overload math, and stat
   tracking run locally. No network dependency for core functionality. Hive is
   the single source of truth.
2. **Modularity** — UI (`views/`, `widgets/`) never contains business math.
   Logic lives in `services/` + `controllers/`; data shape lives in `models/`.
3. **Reactive State** — Riverpod drives granular rebuilds so stat/EXP widgets
   update without rebuilding the whole tree.

## Visual Identity

- Background: **#000000** (true black)
- Accent / glow: **#00E5FF** (neon blue)
- Minimalist, sleek, no dense text walls.

## Build Pipeline

Generated code (`*.g.dart`, `*.freezed.dart`) is produced via:

```bash
dart run build_runner build --delete-conflicting-outputs
```

## Roadmap

- [x] **Phase 1** — Project init: `pubspec.yaml` + folder structure
- [ ] **Phase 2** — Core theme & `main.dart`
- [ ] **Phase 3** — Hive models (UserStats, EXP, Workout Nodes)
- [ ] **Phase 4** — Math engine (EXP scaling, stat distribution)
- [ ] **Phase 5** — UI screens (Dashboard → Map → Workout → Nutrition)
