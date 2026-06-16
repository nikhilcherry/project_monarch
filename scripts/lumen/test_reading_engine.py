#!/usr/bin/env python3
"""Executable reference tests for the Lumen reading engine.

Mirrors the Dart unit tests in `test/lumen/` 1:1 and is the quickest way to
verify ORP pivots, RSVP timing and chapter splitting without a Flutter SDK.

Run:
    python3 scripts/lumen/test_reading_engine.py
"""

from __future__ import annotations

import sys

from reading_engine import (
    AUTO_SECTION_WORDS,
    DEFAULT_WPM,
    MAX_WPM,
    MIN_WPM,
    Chapter,
    ChapterSplitter,
    OrpEngine,
    RsvpScheduler,
    TextTokenizer,
)

_passed = 0
_failed = 0


def check(name: str, cond: bool, detail: str = "") -> None:
    global _passed, _failed
    if cond:
        _passed += 1
        print(f"  ok   {name}")
    else:
        _failed += 1
        print(f"  FAIL {name}  {detail}")


# ---------------------------------------------------------------------------
# OrpEngine
# ---------------------------------------------------------------------------

def test_orp() -> None:
    print("OrpEngine")
    check("single char pivots at 0", OrpEngine.pivot_index("a") == 0)
    check("short word pivots at 1", OrpEngine.pivot_index("read") == 1)
    check("medium word pivots at 2", OrpEngine.pivot_index("reading") == 2)
    check("long word pivots at 3", OrpEngine.pivot_index("comprehend") == 3)
    check("very long word pivots at 4",
          OrpEngine.pivot_index("internationalization") == 4)
    b, p, a = OrpEngine.split("reading")
    check("split reassembles", b + p + a == "reading", f"{b}|{p}|{a}")
    check("split pivot is single char", len(p) == 1)
    check("empty word is safe", OrpEngine.pivot_index("") == 0)


# ---------------------------------------------------------------------------
# TextTokenizer
# ---------------------------------------------------------------------------

def test_tokenizer() -> None:
    print("TextTokenizer")
    toks = TextTokenizer.tokenize("Hello, world. Fast!")
    check("tokenizes word count", len(toks) == 3, str(len(toks)))
    check("strips trailing comma", toks[0].word == "Hello", toks[0].word)
    check("captures soft punctuation", toks[0].trailing == ",", toks[0].trailing)
    check("detects sentence end", toks[1].ends_sentence is True)
    check("non-terminal word not sentence end", toks[0].ends_sentence is False)

    para = "One two three.\n\nFour five."
    ptoks = TextTokenizer.tokenize(para)
    check("paragraph boundary flagged",
          any(t.ends_paragraph for t in ptoks))
    check("word_count counts whitespace runs",
          TextTokenizer.word_count("a  b\tc\nd") == 4)

    # Words with internal apostrophes/hyphens stay intact.
    apo = TextTokenizer.tokenize("don't well-read")
    check("keeps apostrophe word", apo[0].word == "don't", apo[0].word)
    check("keeps hyphenated word", apo[1].word == "well-read", apo[1].word)


# ---------------------------------------------------------------------------
# RsvpScheduler
# ---------------------------------------------------------------------------

def test_scheduler() -> None:
    print("RsvpScheduler")
    check("base ms at 300 wpm == 200", RsvpScheduler.base_ms(300) == 200.0,
          str(RsvpScheduler.base_ms(300)))
    check("base ms at 600 wpm == 100", RsvpScheduler.base_ms(600) == 100.0)
    check("wpm clamps low", RsvpScheduler.base_ms(10) == RsvpScheduler.base_ms(MIN_WPM))
    check("wpm clamps high", RsvpScheduler.base_ms(9999) == RsvpScheduler.base_ms(MAX_WPM))

    text = "The quick brown fox jumps."
    flat = RsvpScheduler.schedule(text, 300, smart_pauses=False)
    check("flat frames all equal",
          len({f.duration_ms for f in flat}) == 1,
          str({f.duration_ms for f in flat}))
    check("flat frame count matches words", len(flat) == 5, str(len(flat)))

    smart = RsvpScheduler.schedule(text, 300, smart_pauses=True)
    check("smart pauses lengthen total",
          RsvpScheduler.total_ms(smart) > RsvpScheduler.total_ms(flat))
    # Last word ends the sentence -> should hold longer than the base.
    check("sentence-final word held longer",
          smart[-1].duration_ms > flat[-1].duration_ms,
          f"{smart[-1].duration_ms} vs {flat[-1].duration_ms}")

    # A pivot index is always within the displayed word.
    check("pivot within bounds",
          all(0 <= f.pivot_index < max(1, len(f.word)) for f in flat))

    mins = RsvpScheduler.estimate_minutes("word " * 300, 300, smart_pauses=False)
    check("300 words @ 300 wpm ~= 1 min", abs(mins - 1.0) < 0.01, f"{mins:.3f}")


# ---------------------------------------------------------------------------
# ChapterSplitter
# ---------------------------------------------------------------------------

def test_chapters() -> None:
    print("ChapterSplitter")
    book = (
        "Chapter 1\nThe beginning of it all was quiet.\n\n"
        "Chapter 2\nThen everything changed at once.\n\n"
        "Chapter 3\nAnd in the end, calm returned."
    )
    chs = ChapterSplitter.detect(book)
    check("detects three chapters", len(chs) == 3, str(len(chs)))
    check("chapter titles preserved", chs[0].title == "Chapter 1", chs[0].title)
    check("chapter body excludes heading",
          "Chapter 1" not in chs[0].text, chs[0].text)
    check("detected chapters not synthetic",
          all(not c.synthetic for c in chs))

    plain = " ".join(f"w{i}" for i in range(2500))
    auto = ChapterSplitter.detect(plain)
    check("auto-sections long unstructured text",
          len(auto) == 3, str(len(auto)))
    check("auto-sections flagged synthetic", all(c.synthetic for c in auto))
    check("auto-section size respects cap",
          auto[0].word_count == AUTO_SECTION_WORDS, str(auto[0].word_count))
    check("auto-section titles are neutral",
          auto[0].title == "Section 1", auto[0].title)

    short = ChapterSplitter.detect("just a few plain words here")
    check("short text stays one section", len(short) == 1, str(len(short)))

    toc = ChapterSplitter.from_toc([("Intro", "hi"), ("Outro", "bye")])
    check("from_toc keeps order + count",
          [c.title for c in toc] == ["Intro", "Outro"])
    check("from_toc not synthetic", all(not c.synthetic for c in toc))


def main() -> int:
    print(f"Lumen reading-engine tests  (default WPM={DEFAULT_WPM})\n")
    test_orp()
    test_tokenizer()
    test_scheduler()
    test_chapters()
    print(f"\n{_passed} passed, {_failed} failed")
    return 1 if _failed else 0


if __name__ == "__main__":
    sys.exit(main())
