#!/usr/bin/env python3
"""Executable tests for the Python math-engine reference.

Because `scripts/math_engine.py` mirrors the Dart engines 1:1, validating the
algorithm here gives real confidence in the shared EXP/overload/stat math even
when no Dart/Flutter SDK is available. Run with:

    python3 scripts/test_math_engine.py        # plain asserts, exit 0 on pass
    pytest scripts/test_math_engine.py         # if pytest is installed
"""

from __future__ import annotations

import math
import sys

import math_engine as m


# ---------------------------------------------------------------------------
# expForLevel / curve shape
# ---------------------------------------------------------------------------

def test_first_level_equals_base_exp():
    assert math.isclose(m.exp_for_level(m.Rank.E, 1), m.BASE_EXP)


def test_level_threshold_grows_within_rank():
    l1 = m.exp_for_level(m.Rank.E, 1)
    l2 = m.exp_for_level(m.Rank.E, 2)
    l3 = m.exp_for_level(m.Rank.E, 3)
    assert l1 < l2 < l3


def test_rank_scaling_is_exponential():
    e = m.exp_for_level(m.Rank.E, 1)
    d = m.exp_for_level(m.Rank.D, 1)
    assert math.isclose(d / e, 2 ** m.RANK_EXPONENT, rel_tol=1e-6)


# ---------------------------------------------------------------------------
# award
# ---------------------------------------------------------------------------

def test_single_level_up():
    p = m.RankProfile()
    res = m.award(p, m.BASE_EXP)
    assert res.levels_gained == 1
    assert res.ranks_gained == 0
    assert res.profile.level == 2
    assert math.isclose(res.profile.current_exp, 0.0, abs_tol=1e-6)


def test_coins_scale_with_exp():
    p = m.RankProfile()
    res = m.award(p, 200)
    assert res.coins_gained == int(2 * m.COINS_PER_HUNDRED_EXP)


def test_multi_level_cascade():
    p = m.RankProfile()
    res = m.award(p, 1000)
    assert res.levels_gained > 1


def test_rank_up_at_cap():
    p = m.RankProfile(rank=m.Rank.E, level=m.LEVELS_PER_RANK, current_exp=0.0)
    threshold = m.exp_for_level(m.Rank.E, m.LEVELS_PER_RANK)
    res = m.award(p, threshold)
    assert res.ranks_gained == 1
    assert res.profile.rank == m.Rank.D
    assert res.profile.level == 1


def test_penalty_clamps_and_no_delevel():
    p = m.RankProfile(rank=m.Rank.C, level=3, current_exp=20.0)
    res = m.award(p, m.PENALTY_EXP)
    assert res.profile.current_exp == 0.0
    assert res.profile.level == 3
    assert res.profile.rank == m.Rank.C
    assert res.levels_gained == 0
    assert res.coins_gained == 0


def test_max_rank_parks():
    p = m.RankProfile(rank=m.Rank.NATIONAL, level=m.LEVELS_PER_RANK)
    res = m.award(p, 999999)
    assert res.profile.rank == m.Rank.NATIONAL
    assert res.profile.level == m.LEVELS_PER_RANK
    assert res.ranks_gained == 0


def test_lifetime_ignores_penalties():
    p = m.RankProfile()
    p = m.award(p, 50).profile
    p = m.award(p, -30).profile
    p = m.award(p, 50).profile
    assert math.isclose(p.lifetime_exp, 100.0, abs_tol=1e-6)


# ---------------------------------------------------------------------------
# overload
# ---------------------------------------------------------------------------

def test_weighted_overload_adds_load():
    w, sets, reps = m.progress_overload(60.0, 3, 8, step=2.5)
    assert w == 62.5 and sets == 3 and reps == 8


def test_bodyweight_overload_adds_reps():
    w, sets, reps = m.progress_overload(None, 3, 10)
    assert w is None and sets == 3 and reps == 10 + m.DEFAULT_REP_STEP


def test_rep_rollover_into_set():
    w, sets, reps = m.progress_overload(None, 3, m.REP_ROLLOVER_THRESHOLD)
    assert w is None and sets == 4 and reps == 8


# ---------------------------------------------------------------------------
# stat distribution
# ---------------------------------------------------------------------------

def test_min_primary_stat_gain():
    dist = m.distribute_stats(total_volume=1)
    assert dist["primary"] >= m.MIN_PRIMARY_STAT_GAIN


def test_volume_increases_primary():
    low = m.distribute_stats(total_volume=50)["primary"]
    high = m.distribute_stats(total_volume=5000)["primary"]
    assert high > low


def test_designer_rewards_preserved():
    dist = m.distribute_stats(total_volume=100, base_rewards={"vit": 5})
    assert dist["vit"] == 5
    assert dist["primary"] >= 1


# ---------------------------------------------------------------------------
# runner
# ---------------------------------------------------------------------------

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
