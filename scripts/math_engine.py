#!/usr/bin/env python3
"""Project Monarch — Math Engine reference & tuning script.

This Python module mirrors the Dart engines in `lib/services/` 1:1 so designers
can tune the curve offline (plot tables, sanity-check rank-up pacing) without
launching the Flutter app. Keep the constants here in lockstep with
`lib/core/constants/game_balance.dart`.

Usage:
    python3 scripts/math_engine.py              # print the rank/EXP tuning table
    python3 scripts/math_engine.py --simulate   # simulate awarding EXP over time
"""

from __future__ import annotations

import argparse
from dataclasses import dataclass, replace
from enum import IntEnum

# ---------------------------------------------------------------------------
# Balance constants  (mirror of GameBalance)
# ---------------------------------------------------------------------------

BASE_EXP = 100.0
RANK_EXPONENT = 1.8
LEVEL_GROWTH = 1.12
LEVELS_PER_RANK = 10

STAT_PER_VOLUME = 0.02
MIN_PRIMARY_STAT_GAIN = 1
SECONDARY_STAT_RATIO = 0.4

DEFAULT_WEIGHT_STEP = 2.5
DEFAULT_REP_STEP = 1
REP_ROLLOVER_THRESHOLD = 15

COINS_PER_HUNDRED_EXP = 5.0
PENALTY_EXP = -50.0


class Rank(IntEnum):
    E = 0
    D = 1
    C = 2
    B = 3
    A = 4
    S = 5
    SS = 6
    SSS = 7
    NATIONAL = 8

    @property
    def label(self) -> str:
        return "NATIONAL" if self is Rank.NATIONAL else f"{self.name}-Rank"

    @property
    def nxt(self) -> "Rank | None":
        return Rank(self + 1) if self < Rank.NATIONAL else None


# ---------------------------------------------------------------------------
# EXP / Rank engine  (mirror of ExpEngine)
# ---------------------------------------------------------------------------

def exp_for_level(rank: Rank, level: int) -> float:
    """EXP needed to advance one level at the given rank/level."""
    rank_factor = (rank + 1) ** RANK_EXPONENT
    level_factor = LEVEL_GROWTH ** max(0, level - 1)
    return BASE_EXP * rank_factor * level_factor


def exp_for_rank_band(rank: Rank) -> float:
    """Total EXP to clear an entire rank band."""
    return sum(exp_for_level(rank, lvl) for lvl in range(1, LEVELS_PER_RANK + 1))


@dataclass
class RankProfile:
    rank: Rank = Rank.E
    level: int = 1
    current_exp: float = 0.0
    lifetime_exp: float = 0.0
    coins: int = 0
    exp_to_next: float = BASE_EXP


@dataclass
class ExpAwardResult:
    profile: RankProfile
    exp_gained: float
    levels_gained: int
    ranks_gained: int
    coins_gained: int


def _coins_for(exp: float) -> int:
    return int(exp / 100 * COINS_PER_HUNDRED_EXP)


def award(profile: RankProfile, amount: float) -> ExpAwardResult:
    """Award EXP, cascading through level-ups and rank-ups (mirror of Dart)."""
    rank = profile.rank
    level = profile.level
    current_exp = profile.current_exp + amount
    lifetime = profile.lifetime_exp + max(0.0, amount)

    levels_gained = 0
    ranks_gained = 0

    if current_exp < 0:
        current_exp = 0.0  # penalties clamp at zero; no de-leveling

    threshold = exp_for_level(rank, level)
    while current_exp >= threshold:
        current_exp -= threshold
        level += 1
        levels_gained += 1

        if level > LEVELS_PER_RANK:
            nxt = rank.nxt
            if nxt is None:
                level = LEVELS_PER_RANK
                current_exp = min(current_exp, threshold)
                break
            rank = nxt
            level = 1
            ranks_gained += 1

        threshold = exp_for_level(rank, level)

    coins_gained = _coins_for(max(0.0, amount))
    updated = replace(
        profile,
        rank=rank,
        level=level,
        current_exp=current_exp,
        lifetime_exp=lifetime,
        coins=profile.coins + coins_gained,
        exp_to_next=threshold,
    )
    return ExpAwardResult(updated, amount, levels_gained, ranks_gained, coins_gained)


# ---------------------------------------------------------------------------
# Stat & overload engines (mirror of StatEngine / OverloadEngine)
# ---------------------------------------------------------------------------

def distribute_stats(total_volume: float, base_rewards: dict[str, int] | None = None) -> dict[str, int]:
    """Volume -> primary/secondary stat points (group mapping handled in Dart)."""
    result = dict(base_rewards or {})
    primary = max(MIN_PRIMARY_STAT_GAIN, round(total_volume * STAT_PER_VOLUME))
    secondary = round(primary * SECONDARY_STAT_RATIO)
    result["primary"] = result.get("primary", 0) + primary
    if secondary > 0:
        result["secondary"] = result.get("secondary", 0) + secondary
    return result


def progress_overload(weight: float | None, sets: int, reps: int, step: float = DEFAULT_WEIGHT_STEP):
    """Return next-session (weight, sets, reps) for progressive overload."""
    if weight is not None:
        return (weight + (step or DEFAULT_WEIGHT_STEP), sets, reps)
    next_reps = reps + DEFAULT_REP_STEP
    if next_reps > REP_ROLLOVER_THRESHOLD:
        return (None, sets + 1, 8)
    return (None, sets, next_reps)


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------

def print_tuning_table() -> None:
    print(f"{'Rank':<10}{'Lv1 EXP':>12}{'Lv10 EXP':>12}{'Band Total':>14}")
    print("-" * 48)
    for rank in Rank:
        lv1 = exp_for_level(rank, 1)
        lv10 = exp_for_level(rank, LEVELS_PER_RANK)
        band = exp_for_rank_band(rank)
        print(f"{rank.label:<10}{lv1:>12,.0f}{lv10:>12,.0f}{band:>14,.0f}")


def simulate(daily_exp: float = 250.0, days: int = 120) -> None:
    p = RankProfile()
    print(f"Simulating {days} days @ {daily_exp:.0f} EXP/day\n")
    for day in range(1, days + 1):
        res = award(p, daily_exp)
        p = res.profile
        if res.ranks_gained or day % 15 == 0:
            flag = "  << RANK UP" if res.ranks_gained else ""
            print(
                f"Day {day:>3}: {p.rank.label:<10} Lv{p.level:<2} "
                f"EXP {p.current_exp:>7.0f}/{p.exp_to_next:<7.0f} "
                f"coins:{p.coins}{flag}"
            )


def main() -> None:
    parser = argparse.ArgumentParser(description="Project Monarch math engine reference")
    parser.add_argument("--simulate", action="store_true", help="run an EXP-over-time simulation")
    parser.add_argument("--daily", type=float, default=250.0, help="EXP per day for --simulate")
    parser.add_argument("--days", type=int, default=120, help="days to simulate")
    args = parser.parse_args()

    if args.simulate:
        simulate(args.daily, args.days)
    else:
        print_tuning_table()


if __name__ == "__main__":
    main()
