#!/usr/bin/env python3
"""Lumen — Reading Engine reference & tuning script.

Lumen is a minimalist, offline-first speed-reading + everyday reader app. This
module is the Python mirror of the pure Dart engines that will live in
`lib/lumen/services/`. Keeping a runnable reference here lets us tune the *feel*
of RSVP timing and sanity-check the ORP pivot + chapter splitting without a
Flutter SDK — the same pattern Project Monarch uses for its math engine.

The engines are deliberately pure (no I/O, no app state) and deterministic
(no AI): given the same text + settings they always produce the same stream.

Engines:
    OrpEngine        -> optimal recognition point (pivot letter) for a word
    TextTokenizer    -> split raw text into words / sentences
    RsvpScheduler    -> timed word stream (ms per word) from text + WPM
    ChapterSplitter  -> real headings -> heading detection -> auto-sections

Usage:
    python3 scripts/lumen/reading_engine.py            # demo a Boost stream
    python3 scripts/lumen/reading_engine.py --table    # WPM -> ms/word table
"""

from __future__ import annotations

import argparse
import re
from dataclasses import dataclass, field

# ---------------------------------------------------------------------------
# Tuning constants  (mirror of lib/lumen/core/constants/lumen_defaults.dart)
# ---------------------------------------------------------------------------

# Words-per-minute bounds and default (the user owns this number; per-book).
MIN_WPM = 100
MAX_WPM = 800
DEFAULT_WPM = 300
WPM_STEP = 25

# Smart-pause timing. All multipliers scale the base ms/word (= 60000 / wpm),
# so changing WPM keeps the *rhythm* intact. Smart pauses are an opt-in toggle;
# when off, every word uses the flat base duration.
LONG_WORD_LEN = 8            # words longer than this get a small extra hold
LONG_WORD_EXTRA_PER_CHAR = 0.04   # added multiplier per char beyond LONG_WORD_LEN
LONG_WORD_MAX_EXTRA = 0.6   # cap the long-word bonus

PAUSE_SOFT = 1.5            # , ; : —  (brief breath)
PAUSE_HARD = 2.2           # . ! ?     (end of thought)
PAUSE_PARAGRAPH = 2.6      # end of paragraph (blank line follows)
SHORT_WORD_LEN = 3         # very short words can flash a touch faster
SHORT_WORD_SCALE = 0.9

# Chapter auto-sectioning: when a text has no detectable structure, slice it
# into evenly sized blocks so the reader still gets reachable finish lines.
AUTO_SECTION_WORDS = 1000

_SOFT_PUNCT = set(",;:—–")
_HARD_PUNCT = set(".!?")


# ---------------------------------------------------------------------------
# OrpEngine — Optimal Recognition Point (the amber pivot letter)
# ---------------------------------------------------------------------------

class OrpEngine:
    """Picks the pivot letter index for RSVP, so the eye never moves.

    Based on the well-known Spritz heuristic: the recognition point sits a
    little left of center and shifts right as words get longer. Returning an
    index (not a pixel) keeps this pure — the UI aligns that letter to a fixed
    focal column and tints it the accent color.
    """

    @staticmethod
    def pivot_index(word: str) -> int:
        n = len(word)
        if n <= 1:
            return 0
        if n <= 5:
            return 1
        if n <= 9:
            return 2
        if n <= 13:
            return 3
        return 4

    @staticmethod
    def split(word: str) -> tuple[str, str, str]:
        """Split a word into (before, pivot, after) around the pivot letter."""
        i = OrpEngine.pivot_index(word)
        return word[:i], word[i:i + 1], word[i + 1:]


# ---------------------------------------------------------------------------
# TextTokenizer — words & sentence/paragraph boundaries
# ---------------------------------------------------------------------------

@dataclass
class Token:
    """One displayable word plus the punctuation context that follows it."""
    word: str                 # the visible word (letters/digits, no trailing space)
    trailing: str = ""       # punctuation immediately after the word, e.g. "," "."
    ends_paragraph: bool = False

    @property
    def ends_sentence(self) -> bool:
        return any(ch in _HARD_PUNCT for ch in self.trailing)


class TextTokenizer:
    """Splits raw text into Tokens. Pure, Unicode-friendly enough for prose."""

    _WORD_RE = re.compile(r"\S+")

    @staticmethod
    def tokenize(text: str) -> list[Token]:
        tokens: list[Token] = []
        paragraphs = re.split(r"\n\s*\n", text.strip())
        for p_idx, para in enumerate(paragraphs):
            raw_words = TextTokenizer._WORD_RE.findall(para)
            for w_idx, raw in enumerate(raw_words):
                # Peel trailing punctuation off the word for clean display.
                m = re.match(r"^(.*?)([^\w'’\-]*)$", raw, re.UNICODE)
                word = m.group(1) if m and m.group(1) else raw
                trailing = m.group(2) if m else ""
                last_in_para = w_idx == len(raw_words) - 1
                tokens.append(Token(
                    word=word or raw,
                    trailing=trailing,
                    ends_paragraph=last_in_para and p_idx < len(paragraphs),
                ))
        return tokens

    @staticmethod
    def word_count(text: str) -> int:
        return len(TextTokenizer._WORD_RE.findall(text))


# ---------------------------------------------------------------------------
# RsvpScheduler — the timed word stream that drives Boost
# ---------------------------------------------------------------------------

@dataclass
class Frame:
    """A single RSVP frame: the word, its pivot, and how long to show it."""
    word: str
    pivot_index: int
    duration_ms: int
    ends_sentence: bool = False


class RsvpScheduler:
    """Turns tokens + a WPM into a list of timed frames.

    `smart_pauses=False` -> every frame is the flat base duration (purest).
    `smart_pauses=True`  -> deterministic rule scales the base by word length
                            and trailing punctuation, so dense text reads
                            naturally instead of like a metronome. No AI.
    """

    @staticmethod
    def base_ms(wpm: int) -> float:
        wpm = max(MIN_WPM, min(MAX_WPM, wpm))
        return 60000.0 / wpm

    @staticmethod
    def _multiplier(token: Token) -> float:
        mult = 1.0
        n = len(token.word)
        if n <= SHORT_WORD_LEN:
            mult *= SHORT_WORD_SCALE
        elif n > LONG_WORD_LEN:
            extra = (n - LONG_WORD_LEN) * LONG_WORD_EXTRA_PER_CHAR
            mult += min(extra, LONG_WORD_MAX_EXTRA)
        # Punctuation pause stacks on top (use the strongest applicable).
        if token.ends_paragraph:
            mult = max(mult, PAUSE_PARAGRAPH)
        elif any(ch in _HARD_PUNCT for ch in token.trailing):
            mult = max(mult, PAUSE_HARD)
        elif any(ch in _SOFT_PUNCT for ch in token.trailing):
            mult = max(mult, PAUSE_SOFT)
        return mult

    @staticmethod
    def schedule(text: str, wpm: int, smart_pauses: bool = False) -> list[Frame]:
        base = RsvpScheduler.base_ms(wpm)
        frames: list[Frame] = []
        for tok in TextTokenizer.tokenize(text):
            display = tok.word + tok.trailing
            mult = RsvpScheduler._multiplier(tok) if smart_pauses else 1.0
            frames.append(Frame(
                word=display,
                pivot_index=OrpEngine.pivot_index(tok.word),
                duration_ms=round(base * mult),
                ends_sentence=tok.ends_sentence,
            ))
        return frames

    @staticmethod
    def total_ms(frames: list[Frame]) -> int:
        return sum(f.duration_ms for f in frames)

    @staticmethod
    def estimate_minutes(text: str, wpm: int, smart_pauses: bool = False) -> float:
        return RsvpScheduler.total_ms(
            RsvpScheduler.schedule(text, wpm, smart_pauses)) / 60000.0


# ---------------------------------------------------------------------------
# ChapterSplitter — real TOC -> heading detection -> auto-sections
# ---------------------------------------------------------------------------

@dataclass
class Chapter:
    title: str
    text: str
    synthetic: bool = False   # True when we invented the boundary (auto-section)
    word_count: int = field(default=0)

    def __post_init__(self):
        if not self.word_count:
            self.word_count = TextTokenizer.word_count(self.text)


class ChapterSplitter:
    """Breaks a book into chapters so progress feels reachable.

    Order of preference:
      1. Caller passes real chapters from the EPUB/PDF TOC -> use them as-is.
      2. No TOC: detect heading lines ("Chapter 3", "IV.", numbered/ALL-CAPS).
      3. Nothing detectable: slice into even ~AUTO_SECTION_WORDS blocks.
    """

    _HEADING_PATTERNS = [
        re.compile(r"^\s*chapter\s+([0-9]+|[ivxlcdm]+|[a-z]+)\b", re.IGNORECASE),
        re.compile(r"^\s*([0-9]{1,3})[\.\)]\s+\S"),          # "12. Title"
        re.compile(r"^\s*([IVXLCDM]{1,7})[\.\)]\s+\S"),       # "IV. Title"
        re.compile(r"^\s*(part|book|section)\s+\S+", re.IGNORECASE),
    ]

    @staticmethod
    def _is_heading(line: str) -> bool:
        s = line.strip()
        if not s or len(s) > 80:
            return False
        for pat in ChapterSplitter._HEADING_PATTERNS:
            if pat.match(s):
                return True
        # Short ALL-CAPS line with no terminal punctuation reads as a heading.
        if (len(s) <= 48 and s.upper() == s and any(c.isalpha() for c in s)
                and s[-1] not in ".!?,;:"):
            return True
        return False

    @staticmethod
    def detect(text: str) -> list[Chapter]:
        lines = text.splitlines()
        heading_idxs = [i for i, ln in enumerate(lines)
                        if ChapterSplitter._is_heading(ln)]
        if len(heading_idxs) >= 2:
            chapters: list[Chapter] = []
            bounds = heading_idxs + [len(lines)]
            for j in range(len(heading_idxs)):
                start, end = bounds[j], bounds[j + 1]
                title = lines[start].strip()
                body = "\n".join(lines[start + 1:end]).strip()
                if body:
                    chapters.append(Chapter(title=title, text=body))
            if chapters:
                return chapters
        return ChapterSplitter.auto_section(text)

    @staticmethod
    def auto_section(text: str, words_per: int = AUTO_SECTION_WORDS) -> list[Chapter]:
        words = TextTokenizer._WORD_RE.findall(text)
        if not words:
            return [Chapter(title="Section 1", text=text.strip(), synthetic=True)]
        chapters: list[Chapter] = []
        for idx in range(0, len(words), words_per):
            chunk = " ".join(words[idx:idx + words_per])
            n = idx // words_per + 1
            chapters.append(Chapter(title=f"Section {n}", text=chunk, synthetic=True))
        return chapters

    @staticmethod
    def from_toc(toc: list[tuple[str, str]]) -> list[Chapter]:
        """Build chapters from an explicit (title, body) TOC, e.g. EPUB spine."""
        return [Chapter(title=t, text=b) for t, b in toc]


# ---------------------------------------------------------------------------
# CLI demo / tuning helpers
# ---------------------------------------------------------------------------

_SAMPLE = (
    "The System awakened before dawn. A pale blue window hovered in the dark, "
    "patient and exact. It asked nothing and promised everything.\n\n"
    "He read the first line twice, then a third time, faster — and the words "
    "stopped resisting him."
)


def _print_wpm_table() -> None:
    print(f"{'WPM':>5} | {'ms/word':>8} | {'words/sec':>9}")
    print("-" * 30)
    for wpm in range(MIN_WPM, MAX_WPM + 1, WPM_STEP):
        ms = RsvpScheduler.base_ms(wpm)
        print(f"{wpm:>5} | {ms:>8.1f} | {1000 / ms:>9.2f}")


def _demo(wpm: int, smart: bool) -> None:
    frames = RsvpScheduler.schedule(_SAMPLE, wpm, smart_pauses=smart)
    print(f"Boost demo @ {wpm} WPM  (smart_pauses={smart})")
    print(f"  frames: {len(frames)}   "
          f"est: {RsvpScheduler.estimate_minutes(_SAMPLE, wpm, smart):.2f} min\n")
    for f in frames[:14]:
        b, p, a = OrpEngine.split(f.word)
        print(f"  {f.duration_ms:>4}ms  {b}[{p}]{a}")
    print("  ...")


def main() -> None:
    ap = argparse.ArgumentParser(description="Lumen reading engine reference")
    ap.add_argument("--table", action="store_true", help="print WPM->ms table")
    ap.add_argument("--wpm", type=int, default=DEFAULT_WPM)
    ap.add_argument("--smart", action="store_true", help="enable smart pauses")
    args = ap.parse_args()
    if args.table:
        _print_wpm_table()
    else:
        _demo(args.wpm, args.smart)


if __name__ == "__main__":
    main()
