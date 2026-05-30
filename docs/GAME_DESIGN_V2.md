# Project Monarch — Game Design v2 (Economy & Progression Overhaul)

> Status: **DESIGN / not yet implemented.** This supersedes the v1 map/economy
> (which used Coins on the map and allowed node replays). See "Implementation
> Phasing" at the end.

---

## 0. Core Pillars

1. **Two hard-separated currencies.** Crystals progress the World Map and are
   earned *only* from time-gated Daily Quests. Coins buy Shop Realms and
   cosmetics and *never* touch the map.
2. **No grinding.** Map dungeons and Shop-realm levels are **one-time** — once
   cleared they cannot be replayed. This removes every infinite-resource loop.
3. **Never soft-locked.** Because the map can't be farmed, Daily Quests are the
   renewable crystal tap, balanced by a strict invariant (§3.3) so a player can
   always advance at least one node per day with zero savings.
4. **Full names, always.** No truncation, abbreviation, or ellipsis anywhere in
   generation or UI (§5).

---

## 1. Rank Ladder (shared scaling spine)

Nine ranks. For rank with tier `t` (0-based), define the **rank factor
`R = t + 1`** (1…9). Every table below scales off `t`/`R`.

| Rank | t | R |
|------|---|---|
| E | 0 | 1 |
| D | 1 | 2 |
| C | 2 | 3 |
| B | 3 | 4 |
| A | 4 | 5 |
| S | 5 | 6 |
| SS | 6 | 7 |
| SSS | 7 | 8 |
| National | 8 | 9 |

---

## 2. World Map — Non-Linear, Rank-Scaled, Fogged

### 2.1 Structure
- **Hub with 4 branching paths** at every rank (Path I–IV). The hub shows all
  four depth-1 entry nodes; everything else starts fogged.
- **Depth scales with rank:** `depth(t) = 5 + 2t`.
- **Nodes per region:** `4 × depth`.
- A region ends at a **Rank Gate** (boss). Clearing the deepest node of *any*
  one path unlocks the Gate; clearing the Gate advances the player to the next
  rank's region.

### 2.2 Crystal cost per node
`nodeCost(t, path, d) = 10·R · pathMultiplier(path)` (flat in depth `d`; depth
instead scales *rewards*, keeping the soft-lock guarantee clean).

| Path | Theme | Multiplier | Reward weight |
|------|-------|-----------|---------------|
| Path I (Trail of the Steadfast) | endurance | ×1.0 | baseline |
| Path II (Road of the Tempest) | agility | ×1.5 | +50% |
| Path III (Climb of the Titan) | strength | ×2.0 | +100% |
| Path IV (Ascent of the Monarch) | mixed/elite | ×3.0 | +200% |

**Path I is the guaranteed-affordable spine** (§3.3). Paths II–IV are optional
"save up for the better rewards" detours — never required to progress.

### 2.3 Map balancing table

| Rank | Depth | Nodes | Path I cost | Path II | Path III | Path IV | Crystals for 100% region¹ | Min days to rank-up² |
|------|------:|------:|------:|------:|------:|------:|------:|------:|
| E | 5 | 20 | 10 | 15 | 20 | 30 | 375 | 5 |
| D | 7 | 28 | 20 | 30 | 40 | 60 | 1,050 | 7 |
| C | 9 | 36 | 30 | 45 | 60 | 90 | 2,025 | 9 |
| B | 11 | 44 | 40 | 60 | 80 | 120 | 3,300 | 11 |
| A | 13 | 52 | 50 | 75 | 100 | 150 | 4,875 | 13 |
| S | 15 | 60 | 60 | 90 | 120 | 180 | 6,750 | 15 |
| SS | 17 | 68 | 70 | 105 | 140 | 210 | 8,925 | 17 |
| SSS | 19 | 76 | 80 | 120 | 160 | 240 | 11,400 | 19 |
| National | 21 | 84 | 90 | 135 | 180 | 270 | 14,175 | 21 |

¹ `100% = 10R · depth · (1.0+1.5+2.0+3.0) = 10R · depth · 7.5`
² Min days = `depth`, clearing only Path I on the guaranteed daily income (§3).

### 2.4 Fog of War
- Every node has a `revealed` flag. At region start only the 4 depth-1 entries
  are revealed (dim, "unscanned"); all else is rendered **blurred** (Flutter
  `ImageFiltered` + `BackdropFilter`, low opacity) with faint dotted paths.
- Completing a node reveals its direct successors on that branch and lightly
  de-blurs immediate neighbors. Reveal cascades outward as you descend.

### 2.5 Anti-grind
- A node's status terminal state is `cleared`; the UI shows it checked and the
  "Enter" action is permanently disabled. No replay → no repeat crystals/coins.

---

## 3. Currencies & Daily Quests

### 3.1 Currency rules
| Currency | Earned from | Spent on | Can it touch the map? |
|----------|------------|----------|-----------------------|
| **Crystals** | **Daily Quests only** | World Map node unlocks | Yes — *only* thing that does |
| **Coins** | Map nodes, Shop-realm levels, Daily Quests | Shop (Realms + cosmetics) | **Never** |

### 3.2 Daily Quests (the renewable crystal tap)
Each day offers three quests; crystal payouts scale with rank (`R`):

| Quest | Completable how | Crystals | Coins |
|-------|-----------------|---------:|------:|
| **System Check-In** (mandatory, always doable) | open app + confirm one set of any movement | **10·R** | 5·R |
| **Field Drill** (bonus) | complete today's mandatory training day | +10·R | +5·R |
| **Overdrive** (bonus) | complete a habit + hit a macro target | +10·R | +5·R |
| **7-Day Streak** (weekly) | 7 consecutive check-ins | +50·R once | +25·R |

- **Guaranteed daily crystals** = `10·R` (Check-In alone).
- **Max daily crystals** = `30·R` (+ `50·R` on streak days).
- Crystals **persist** across missed days — you never lose banked crystals, so a
  busy week just slows you, never resets you.

### 3.3 ★ The Soft-Lock Invariant (the "never stuck" guarantee)

> **Invariant:** at every rank, the *guaranteed* daily crystal income equals the
> cost of the cheapest frontier node.
>
> `dailyGuaranteed(t) = 10·R = nodeCost(t, Path I, d)`  for all depths `d`.

Because Path I costs a flat `10·R` and the mandatory Check-In *always* pays
`10·R`, a player with **zero** banked crystals can always afford the next Path I
node after exactly one day. Progress therefore can never permanently halt.

Corollaries:
- **Rank transitions are safe.** On reaching rank `t+1`, both the new Path I
  cost and the new guaranteed income become `10·(R+1)` — they rise together, so
  the invariant holds across the boundary with no "wall."
- **Choice, not gates.** Paths II–IV cost 1.5–3 guaranteed-days each; saving for
  them is a *reward optimization*, never a requirement.
- **Pity is automatic.** Since Check-In needs only app-open + one set (doable
  offline in under a minute), the guarantee survives even on a hectic day.

**Safety check (unit-testable):** for every `t`,
`dailyGuaranteed(t) ≥ min over paths,depths of nodeCost(t,·,·)`. This is asserted
in the math-engine tests so a future balance edit can never silently break it.

### 3.4 Throughput sanity (Path I only, guaranteed income)
| Rank | Guaranteed/day | Path I region cost (10R·depth) | Days (Path I clear) |
|------|---------------:|-------------------------------:|--------------------:|
| E | 10 | 50 | 5 |
| D | 20 | 140 | 7 |
| C | 30 | 270 | 9 |
| … | … | … | = depth |
| National | 90 | 1,890 | 21 |

Full-completionist (all 4 paths) at max daily income (`30R`):
`100% / 30R = depth · 7.5 / 3 = 2.5 · depth` days — e.g. E ≈ 13 days, National ≈
53 days. Healthy long-tail without ever blocking the critical path.

---

## 4. The Shop — Coin-Bought Alternate Realms

### 4.1 Rules
- Coins (never crystals) buy **Realms** in the Shop.
- A Realm is an **isolated, strictly linear gauntlet** — a single path of
  `20 + 2t` progressively harder levels — reachable *only* by tapping it inside
  the Shop (independent of the World Map).
- Realm levels are **one-time** (no replay), same anti-grind rule.

### 4.2 Rank-based availability (cumulative)
`buyableRealms(t) = 4 + 2t`.

| Rank | New realms added | Cumulative buyable | Realm length (20+2t) |
|------|-----------------:|-------------------:|---------------------:|
| E | 4 | 4 | 20 |
| D | +2 | 6 | 22 |
| C | +2 | 8 | 24 |
| B | +2 | 10 | 26 |
| A | +2 | 12 | 28 |
| S | +2 | 14 | 30 |
| SS | +2 | 16 | 32 |
| SSS | +2 | 18 | 34 |
| National | +2 | 20 | 36 |

### 4.3 Realm unlock cost (coins)
`realmCost(t, i) = 200·R · (1 + 0.25·i)` where `i` is the realm's index within
its unlock rank (0-based). E.g. at E: 200 / 250 / 300 / 350 coins.

### 4.4 Example Realm names (full, no truncation)
"The Sunken Coliseum", "Halls of the Frostbound", "The Emberforge Spire",
"Verdant Labyrinth", "Cathedral of Echoes", "The Obsidian Gauntlet".

---

## 5. Strict Naming Conventions

- **Never** truncate/abbreviate/ellipsize names anywhere — generation *or* UI.
  Always "The Awakening", never "The Awak…".
- **Generation:** node/realm names are assembled from full word pools
  (`[Article] [Theme Noun] of [Modifier]`, or curated hand names) — no numeric
  fallbacks like "Node 7".
- **UI rule (enforced in widgets):** name `Text` widgets must use
  `softWrap: true`, `maxLines: 2`, and **must not** set
  `overflow: TextOverflow.ellipsis`. Tiles size to fit the full name (wrap to a
  second line) rather than clipping. A shared `MonarchName` text widget will
  centralize this so no screen can re-introduce ellipsis.

---

## 6. Data Model Changes (Hive)

New/changed `@HiveType`s (next free typeIds after current 1–8):

| typeId | Type | Purpose |
|-------|------|---------|
| 9 | `Wallet` (or extend `RankProfile`) | add `crystals` alongside `coins` |
| 10 | `MapRegion` | per-rank region: paths × depth, fog state |
| 11 | `MapPathNode` | path id, depth, crystal cost, `revealed`, `cleared` |
| 12 | `DailyQuestSet` | day-key, the 3 quests + claimed flags |
| 13 | `ShopRealm` | id, unlock rank, length, `owned`, current level |
| 14 | `RealmLevel` | linear level: index, `cleared` |
| 26 | `PathId` enum | I / II / III / IV |

(Generator/registration follow the existing `DatabaseService` pattern.)

---

## 7. Implementation Phasing (proposed)

1. **Currencies split** — add Crystals to the wallet; convert map unlocks to
   Crystals; lock Coins out of the map; Shop to Coins only. (+ migration)
2. **Daily Quests** — `DailyQuestSet`, the 3-quest controller, crystal/coin
   payouts, streak bonus; wire Check-In as the guaranteed tap.
3. **Rank-scaled branching map + no-replay** — regenerate regions as 4×depth
   graphs per rank; disable replay; Rank Gate → next region.
4. **Fog of War** — `revealed` cascade + blurred rendering.
5. **Shop Realms** — linear gauntlet model, rank-gated availability, coin
   unlock, isolated entry from Shop UI.
6. **Naming pass** — `MonarchName` widget + generator; purge any ellipsis.
7. **Balance tests** — assert the §3.3 soft-lock invariant in the math engine.

Each phase ships its own APK via the existing release workflow.
