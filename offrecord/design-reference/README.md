# Design reference — do not run, do not edit

The original Stitch export. It is the **source of truth for the visual design**
and is kept here purely to check ported screens against.

- `OffRecord.dc.html` — the student app: onboarding, feed, search, create,
  post detail, profile, settings, report dialog.
- `OffRecord Admin.dc.html` — the moderation console: pending queue, reports.
- `_ds/styles.css`, `_ds/readme.md` — the Nocturne design system these were
  built on.

These files are **not part of the build**. They are a proprietary Stitch
template format (`<x-dc>`, `<sc-if>`, `<sc-for>`, `class Component extends
DCLogic`) that only renders inside Stitch's own preview host, and the runtime
they need (`support.js`) is deliberately not vendored.

The live app re-implements this design in `../src`. Two deliberate departures
from the original, both requested:

1. **Themes** — the original had one ground (`#161826`). The app ships OLED
   black and pure white only. Nocturne's shadow tokens were retuned because a
   drop shadow is invisible on `#000000`; elevation there is a hairline border.
2. **Accent** — the original hard-coded a nine-step accent ramp. The app
   derives the whole ramp from a single `--brand` token in
   `../src/styles/theme.css`.

Layout, spacing rhythm, component anatomy, copy and interaction behavior
should still match this reference. If a ported screen disagrees with it,
the reference wins unless the change was explicitly asked for.
