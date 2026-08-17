# OffRecord

A text-only, invite-only, pseudonymous community for students.

Next.js (App Router) + TypeScript. Supabase/Postgres is not wired up yet — see
*Status* below.

## Running it

```bash
cd offrecord
npm install
npm run dev          # http://localhost:3000
```

Other scripts: `npm run build`, `npm run start`, `npm run typecheck`.

Node 18.18+ is required (Next 15). No environment variables are needed yet.

## Status

| Step | State |
|------|-------|
| 1. Scaffold + theme foundation | **done** |
| 2. Supabase schema + RLS | not started |
| 3. Auth, invite redemption, pseudonym picker | not started |
| 4. Feed + post detail | not started |
| 5. Create post → pending | not started |
| 6. Admin console | not started |
| 7. Reactions + comments | not started |
| 8. Reports + moderation | not started |
| 9. Search | not started |
| 10. Profile, invites, settings | not started |

`/` is currently a **temporary theme preview**, not a real screen. It gets
deleted when the feed lands in step 4.

## Theming

Two themes, no more: **OLED black** (default) and **pure white**. Both are
defined in `src/styles/theme.css`.

To rebrand the entire app, change one line at the top of that file:

```css
:root {
  --brand: #9184d9;
}
```

Everything accent-colored derives from it via `color-mix()` — pulled lighter on
black and darker on white, so accent text keeps its contrast on both grounds.
There is no second accent and no per-user accent.

Rules for working in here:

- Never hard-code a hex, a radius, a shadow or a spacing value in a component.
  Take them from the tokens (`var(--color-*)`, `var(--space-*)`,
  `var(--radius-*)`, `var(--shadow-*)`).
- Interactive elements clear `var(--tap)` (44px). Many users are on a phone,
  sometimes a borrowed one.
- Text inputs stay at 16px. Anything smaller makes iOS Safari zoom the page on
  focus.

## Layout

```
offrecord/
├── src/
│   ├── app/              # App Router routes
│   ├── components/       # shared React components
│   ├── lib/              # framework-free helpers (categories, theme)
│   └── styles/
│       ├── theme.css     # tokens + the two themes  ← the brand lives here
│       └── base.css      # element styles + component classes
└── design-reference/     # the original Stitch export (not built, not run)
```

## CI

The repository root runs a Flutter release pipeline
(`.github/workflows/auto-version.yml`). It ignores `offrecord/**`, so web
commits do not build an APK or cut a release. There is no CI for this app yet.
