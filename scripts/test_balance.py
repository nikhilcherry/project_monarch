#!/usr/bin/env python3
"""Executable balance tests for the v2 economy (GAME_DESIGN_V2).

These mirror the Dart balancing constants and, crucially, assert the
**soft-lock invariant**: at every rank the guaranteed daily Crystal income is at
least the cost of the cheapest frontier (Path I) node, so a zero-savings player
can always advance one map node per day and can never get permanently stuck.

Run:  python3 scripts/test_balance.py     # exits 0 on success
"""

from __future__ import annotations

import sys

RANKS = 9  # E … National  (tiers 0..8)

# --- Map (World Map region) -------------------------------------------------
PATH_MULT = [1.0, 1.5, 2.0, 3.0]  # Path I..IV


def r(tier: int) -> int:
    return tier + 1


def map_depth(tier: int) -> int:
    return 5 + 2 * tier


def node_cost(tier: int, path: int) -> int:
    return round(10 * r(tier) * PATH_MULT[path])


# --- Daily Quests -----------------------------------------------------------

def daily_guaranteed(tier: int) -> int:
    return 10 * r(tier)  # System Check-In alone


def daily_max(tier: int) -> int:
    return 30 * r(tier)  # all three quests


def streak_bonus(tier: int) -> int:
    return 50 * r(tier)


# --- Shop Realms ------------------------------------------------------------

def realm_length(tier: int) -> int:
    return 20 + 2 * tier


def realms_buyable(tier: int) -> int:
    return 4 + 2 * tier


def realm_cost(tier: int, index: int) -> int:
    return round(200 * r(tier) * (1 + 0.25 * index))


# ---------------------------------------------------------------------------
# Tests
# ---------------------------------------------------------------------------

def test_soft_lock_invariant():
    """The whole point: guaranteed daily income >= cheapest frontier node."""
    for t in range(RANKS):
        cheapest = min(node_cost(t, p) for p in range(4))
        assert cheapest == node_cost(t, 0), "Path I must be the cheapest path"
        assert daily_guaranteed(t) >= cheapest, (
            f"SOFT-LOCK at tier {t}: guaranteed {daily_guaranteed(t)} "
            f"< cheapest node {cheapest}"
        )


def test_rank_transition_is_safe():
    """Crossing into the next rank, income and Path I cost rise together."""
    for t in range(RANKS - 1):
        assert daily_guaranteed(t + 1) >= node_cost(t + 1, 0)


def test_path_costs_scale():
    for t in range(RANKS):
        costs = [node_cost(t, p) for p in range(4)]
        assert costs == sorted(costs)  # I <= II <= III <= IV
        assert costs[0] == 10 * r(t)


def test_map_depth():
    assert [map_depth(t) for t in range(RANKS)] == [5, 7, 9, 11, 13, 15, 17, 19, 21]


def test_daily_payouts():
    for t in range(RANKS):
        assert daily_max(t) == 3 * daily_guaranteed(t)
        assert streak_bonus(t) == 5 * daily_guaranteed(t)


def test_realm_availability_and_length():
    assert [realms_buyable(t) for t in range(RANKS)] == [4, 6, 8, 10, 12, 14, 16, 18, 20]
    assert [realm_length(t) for t in range(RANKS)] == [20, 22, 24, 26, 28, 30, 32, 34, 36]


def test_realm_cost_formula():
    assert realm_cost(0, 0) == 200
    assert realm_cost(0, 1) == 250
    assert realm_cost(0, 3) == 350
    assert realm_cost(1, 0) == 400  # 200 * 2


def _run() -> int:
    tests = [v for k, v in sorted(globals().items()) if k.startswith("test_")]
    failures = 0
    for t in tests:
        try:
            t()
            print(f"  PASS  {t.__name__}")
        except AssertionError as e:
            failures += 1
            print(f"  FAIL  {t.__name__}: {e}")
    print(f"\n{len(tests) - failures}/{len(tests)} passed.")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(_run())
