# Database

Postgres schema, row-level security and write paths for OffRecord.

## Applying the migrations

In the Supabase dashboard → **SQL Editor**, run these **in order**, one at a
time, checking each succeeds before the next:

| File | What it does |
|------|--------------|
| `migrations/0001_schema.sql` | Types, tables, indexes, counter triggers |
| `migrations/0002_rls.sql` | RLS policies, grants, the read views |
| `migrations/0003_functions.sql` | Every write path, as validated functions |
| `migrations/0004_seed.sql` | Your community + 10 founding invite codes |

**Edit `0004_seed.sql` first** — the community slug and name are at the top.

Then read your founding codes, and keep them somewhere safe:

```sql
select code from public.invites where created_by is null order by created_at;
```

Each admits exactly one person. Treat them like passwords.

### Becoming an admin

Deliberately manual — there is no in-app path to the admin role, because a
self-service one would be the worst possible bug to ship. Sign up, redeem a
code, then run once:

```sql
update public.profiles set role = 'admin' where pseudonym = 'your_name';
```

## How the security model works

The short version: **clients never touch base tables.**

- Every table has RLS enabled, with policies stating the real rule.
- The `authenticated` role is granted *nothing* on those tables.
- Reads go through views (`feed_posts`, `feed_comments`, `community_members`,
  `my_profile`, and the two `mod_*` views).
- Writes go through `SECURITY DEFINER` functions that validate first.

That is two independent layers. If a grant is widened by accident, the policies
still hold. If a policy is written wrong, the missing grant still holds.

### Why not query tables directly, the usual Supabase way?

Because anonymity is the product. `posts.author_id` has to exist — moderation
is impossible without it — and must never reach another student's browser. **A
SELECT policy cannot hide a column**; it filters rows. Removing the grant is
what actually hides it. `feed_posts` has no `author_id` column at all, so there
is nothing for a client to ask for.

### What each role can see

| | member | moderator | admin |
|---|---|---|---|
| Published posts in their community | yes | yes | yes |
| Their own pending posts | yes | yes | yes |
| Anyone else's pending posts | no | yes | yes |
| Author of an anonymous post | **never** | pseudonym only | pseudonym only |
| Who reacted to what | own only | own only | own only |
| Report queue | own reports | yes | yes |
| Other communities | no | no | no |
| Real names, emails, IPs | not stored anywhere | | |

Moderators see author *pseudonyms*, because reviewing a harassment campaign
without knowing whether one account is behind it is not moderation. They never
see an email or any real-world identifier — the database does not store one.

## Running the tests

The suite tries to break the guarantees above: reading `author_id`, seeing
another school's posts, self-promoting to admin, auto-removing a reported post,
and so on. It needs a scratch Postgres — **never run it against production**,
it truncates every table.

```bash
createdb offrecord_test
psql -d offrecord_test -f tests/supabase_shim.sql          # fake auth.users + roles
psql -d offrecord_test -v ON_ERROR_STOP=1 -f migrations/0001_schema.sql
psql -d offrecord_test -v ON_ERROR_STOP=1 -f migrations/0002_rls.sql
psql -d offrecord_test -v ON_ERROR_STOP=1 -f migrations/0003_functions.sql
psql -d offrecord_test -v ON_ERROR_STOP=1 -f tests/security_test.sql
```

59 assertions; the last line should read `ALL SECURITY TESTS PASSED`.

## Things worth knowing

**Nothing is auto-removed by report count.** Reports are a request for human
review. One report and fifty reports do the same thing: put an item in the
queue. `reports` has a unique index per (reporter, item) so one person cannot
inflate a count anyway.

**Removed, never deleted.** A removed post keeps its row with
`status = 'removed'`. An appeal or an abuse investigation needs the evidence.

**Suspensions expire on their own.** `suspended_until` in the past reads as
active — no cron job reinstates anyone. A NULL means indefinite.

**Rate limits** are 5 posts/hour, 20 comments/hour, 20 reports/day, counted
from the user's own rows. No IP addresses, no device fingerprints — those would
break the privacy promise, and the invite system is the real defence against
mass signup.

**Multi-community is already wired.** Every table carries `community_id` and
every policy filters on it. A second school is a row in `communities`, not a
migration.

## What is deliberately missing

- **No `updated_at`/edit path for posts.** V1 has no edit feature; adding the
  column when editing ships is trivial, guessing the semantics now is not.
- **No notifications table.** The UI's bell is empty by design in V1.
- **No soft-delete for profiles.** Account deletion cascades from
  `auth.users`, which is the one place a real identity exists.
