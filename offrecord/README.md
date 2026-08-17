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

## Deploying (Vercel)

This app lives in a subdirectory of a repo whose root is a Flutter project, so
**Vercel must be told where the app is** or the build fails immediately with
"no package.json found":

1. Import `nikhilcherry/project_monarch` in Vercel.
2. Set **Root Directory** to `offrecord`. Everything else (framework preset,
   build command, output) is detected correctly once that's set.
3. Under **Settings → Git**, restrict production deploys to the branches you
   actually want live — otherwise every Flutter commit on `main` triggers a
   redundant web build.

Nothing else is needed today: there are no environment variables yet. When
Supabase lands in step 2, its URL and publishable key go in Vercel's
environment variables. The service-role key never goes in this project — it
belongs only to server-side code, never to anything the browser can read.

Vercel's Hobby plan is free for non-commercial projects, which OffRecord is as
long as it carries no ads or paid features.

## CI

The repository root runs a Flutter release pipeline
(`.github/workflows/auto-version.yml`). It ignores `offrecord/**`, so web
commits do not build an APK or cut a release. There is no CI for this app yet.
