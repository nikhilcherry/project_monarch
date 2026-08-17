-- ============================================================================
-- OffRecord — 0001 schema
-- ----------------------------------------------------------------------------
-- Tables, types, indexes and counter triggers. No security in this file;
-- row-level security lives in 0002_rls.sql and the write paths in
-- 0003_functions.sql.
--
-- Two decisions shape everything here:
--
-- 1. MULTI-COMMUNITY FROM DAY ONE. Every row that belongs to a school carries
--    community_id, even though V1 runs a single community. Adding this column
--    later would mean backfilling every table and rewriting every security
--    policy; carrying it now costs one column and one index.
--
-- 2. ANONYMITY IS ENFORCED IN THE DATABASE, NOT THE UI. posts.author_id always
--    holds the real author — the platform needs it for moderation — but no
--    client is ever granted permission to read that column (see 0002). What a
--    reader gets is the display_name computed by the feed views: the author's
--    pseudonym, or the literal 'Anonymous'.
-- ============================================================================

create extension if not exists "pgcrypto";   -- gen_random_uuid(), gen_random_bytes()
create extension if not exists "citext";     -- case-insensitive invite codes

-- ----------------------------------------------------------------------------
-- Types
-- ----------------------------------------------------------------------------

create type public.community_role as enum ('member', 'moderator', 'admin');

create type public.profile_status as enum ('active', 'suspended');

-- Stored as stable ids. The label a user sees lives in the app
-- (src/lib/categories.ts) so wording can change without touching data.
create type public.post_category as enum (
  'confession', 'question', 'rant', 'funny', 'advice', 'other'
);

-- 'pending'   — awaiting moderator approval, visible only to its author
-- 'published' — publicly visible inside the community
-- 'removed'   — taken down by a moderator; kept, never hard-deleted, so an
--               appeal or an abuse investigation still has the evidence
create type public.content_status as enum ('pending', 'published', 'removed');

create type public.report_reason as enum (
  'harassment', 'spam', 'personal_information', 'threatening', 'other'
);

create type public.report_status as enum ('open', 'dismissed', 'actioned');

-- ----------------------------------------------------------------------------
-- communities
-- ----------------------------------------------------------------------------

create table public.communities (
  id           uuid primary key default gen_random_uuid(),
  slug         text not null unique check (slug ~ '^[a-z0-9-]{2,40}$'),
  name         text not null check (char_length(name) between 1 and 80),
  -- Posts land in 'pending' and need approval when true. A community can turn
  -- this off later without a schema change.
  premoderate  boolean not null default true,
  is_active    boolean not null default true,
  created_at   timestamptz not null default now()
);

comment on table public.communities is
  'One school / community. V1 runs a single row; the column exists so a second never requires a rebuild.';

-- ----------------------------------------------------------------------------
-- profiles
-- ----------------------------------------------------------------------------
-- Deliberately holds NO personal information: no real name, no email, no phone,
-- no IP, no device identifiers. The email address a user signed up with stays
-- in auth.users, which is Supabase-managed and unreadable from the API.

create table public.profiles (
  id                uuid primary key references auth.users (id) on delete cascade,
  community_id      uuid not null references public.communities (id) on delete restrict,
  pseudonym         text not null check (pseudonym ~ '^[a-zA-Z0-9_]{3,20}$'),
  role              public.community_role not null default 'member',
  status            public.profile_status not null default 'active',
  -- NULL while suspended means an indefinite suspension.
  suspended_until   timestamptz,
  suspension_reason text,
  -- Ordinary members get a small, fixed allowance. Not a referral tree — an
  -- invite records who made it and nothing more.
  invites_remaining integer not null default 3 check (invites_remaining >= 0),
  created_at        timestamptz not null default now()
);

-- Pseudonyms are unique per community, case-insensitively: 'QuietKoala' and
-- 'quietkoala' must not be able to impersonate each other.
create unique index profiles_community_pseudonym_key
  on public.profiles (community_id, lower(pseudonym));

create index profiles_community_idx on public.profiles (community_id);

comment on column public.profiles.pseudonym is
  'Public display name. Must not contain real-world identity; validated in 0003.';

-- ----------------------------------------------------------------------------
-- invites
-- ----------------------------------------------------------------------------

create table public.invites (
  id           uuid primary key default gen_random_uuid(),
  code         citext not null unique,
  community_id uuid not null references public.communities (id) on delete cascade,
  -- NULL for the founding codes an admin generates before anyone exists.
  created_by   uuid references public.profiles (id) on delete set null,
  max_uses     integer not null default 1 check (max_uses > 0),
  uses_count   integer not null default 0 check (uses_count >= 0),
  revoked_at   timestamptz,
  expires_at   timestamptz,
  created_at   timestamptz not null default now(),
  constraint invites_not_overused check (uses_count <= max_uses)
);

create index invites_created_by_idx on public.invites (created_by);
create index invites_community_idx on public.invites (community_id);

comment on column public.invites.max_uses is
  'Single-use by default. A higher value is an explicit admin choice, never the default.';

-- Who redeemed what. Two columns of audit trail so an admin can trace an abuse
-- wave back to the code that let it in — not a referral graph.
create table public.invite_redemptions (
  id          uuid primary key default gen_random_uuid(),
  invite_id   uuid not null references public.invites (id) on delete cascade,
  profile_id  uuid not null references public.profiles (id) on delete cascade,
  redeemed_at timestamptz not null default now(),
  unique (invite_id, profile_id)
);

create index invite_redemptions_profile_idx on public.invite_redemptions (profile_id);

-- ----------------------------------------------------------------------------
-- posts
-- ----------------------------------------------------------------------------

create table public.posts (
  id             uuid primary key default gen_random_uuid(),
  community_id   uuid not null references public.communities (id) on delete cascade,
  author_id      uuid not null references public.profiles (id) on delete cascade,
  category       public.post_category not null,
  -- 500 characters matches the composer's counter. Enforced here too: a client
  -- limit is a hint, this is the rule.
  body           text not null check (char_length(btrim(body)) between 1 and 500),
  is_anonymous   boolean not null default true,
  status         public.content_status not null default 'pending',
  created_at     timestamptz not null default now(),
  published_at   timestamptz,
  removed_at     timestamptz,
  removed_by     uuid references public.profiles (id) on delete set null,
  removed_reason text,
  -- Denormalised so the feed never needs a count(*) over reactions. Kept
  -- honest by triggers below, never written by clients.
  reaction_count integer not null default 0 check (reaction_count >= 0),
  comment_count  integer not null default 0 check (comment_count >= 0),
  search_tsv     tsvector generated always as (to_tsvector('english', body)) stored
);

-- The feed query: one community, published only, newest first.
create index posts_feed_idx
  on public.posts (community_id, status, created_at desc);

-- The same feed sorted by reactions ("Trending") and comments ("Discussed").
create index posts_trending_idx
  on public.posts (community_id, status, reaction_count desc, created_at desc);
create index posts_discussed_idx
  on public.posts (community_id, status, comment_count desc, created_at desc);

-- "Your posts", and the rate-limit lookup in 0003.
create index posts_author_idx on public.posts (author_id, created_at desc);

-- The moderation queue.
create index posts_pending_idx
  on public.posts (community_id, created_at)
  where status = 'pending';

create index posts_search_idx on public.posts using gin (search_tsv);

-- ----------------------------------------------------------------------------
-- comments
-- ----------------------------------------------------------------------------

create table public.comments (
  id             uuid primary key default gen_random_uuid(),
  post_id        uuid not null references public.posts (id) on delete cascade,
  -- Denormalised from the post so security policies can filter by community
  -- without joining posts on every row.
  community_id   uuid not null references public.communities (id) on delete cascade,
  author_id      uuid not null references public.profiles (id) on delete cascade,
  body           text not null check (char_length(btrim(body)) between 1 and 1000),
  is_anonymous   boolean not null default false,
  -- Comments publish immediately; pre-moderating replies would make
  -- conversation impossible. They are still reportable and removable.
  status         public.content_status not null default 'published',
  created_at     timestamptz not null default now(),
  removed_at     timestamptz,
  removed_by     uuid references public.profiles (id) on delete set null,
  removed_reason text,
  reaction_count integer not null default 0 check (reaction_count >= 0)
);

create index comments_post_idx on public.comments (post_id, created_at);
create index comments_author_idx on public.comments (author_id, created_at desc);

-- ----------------------------------------------------------------------------
-- reactions
-- ----------------------------------------------------------------------------
-- Two tables rather than one polymorphic table: real foreign keys, real
-- cascades, and a primary key that makes double-reacting impossible.

create table public.post_reactions (
  post_id    uuid not null references public.posts (id) on delete cascade,
  profile_id uuid not null references public.profiles (id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (post_id, profile_id)
);

create index post_reactions_profile_idx on public.post_reactions (profile_id);

create table public.comment_reactions (
  comment_id uuid not null references public.comments (id) on delete cascade,
  profile_id uuid not null references public.profiles (id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (comment_id, profile_id)
);

create index comment_reactions_profile_idx on public.comment_reactions (profile_id);

-- ----------------------------------------------------------------------------
-- reports
-- ----------------------------------------------------------------------------

create table public.reports (
  id           uuid primary key default gen_random_uuid(),
  community_id uuid not null references public.communities (id) on delete cascade,
  reporter_id  uuid not null references public.profiles (id) on delete cascade,
  post_id      uuid references public.posts (id) on delete cascade,
  comment_id   uuid references public.comments (id) on delete cascade,
  reason       public.report_reason not null,
  details      text check (details is null or char_length(details) <= 500),
  status       public.report_status not null default 'open',
  resolved_by  uuid references public.profiles (id) on delete set null,
  resolved_at  timestamptz,
  created_at   timestamptz not null default now(),
  -- Exactly one target.
  constraint reports_one_target check (
    (post_id is not null and comment_id is null) or
    (post_id is null and comment_id is not null)
  )
);

-- One report per person per item. Stops a single user inflating the queue, and
-- with it any temptation to auto-remove on report count.
create unique index reports_unique_post_reporter
  on public.reports (reporter_id, post_id) where post_id is not null;
create unique index reports_unique_comment_reporter
  on public.reports (reporter_id, comment_id) where comment_id is not null;

-- The moderator queue: open reports, oldest first.
create index reports_open_idx
  on public.reports (community_id, created_at)
  where status = 'open';

comment on table public.reports is
  'A report is a request for review. Nothing is ever removed automatically by report count.';

-- ----------------------------------------------------------------------------
-- moderation_actions — an append-only record of what moderators did
-- ----------------------------------------------------------------------------

create table public.moderation_actions (
  id                uuid primary key default gen_random_uuid(),
  community_id      uuid not null references public.communities (id) on delete cascade,
  moderator_id      uuid references public.profiles (id) on delete set null,
  action            text not null check (action in (
                      'approve_post', 'remove_post', 'remove_comment',
                      'dismiss_report', 'suspend_user', 'unsuspend_user',
                      'revoke_invite'
                    )),
  post_id           uuid references public.posts (id) on delete set null,
  comment_id        uuid references public.comments (id) on delete set null,
  target_profile_id uuid references public.profiles (id) on delete set null,
  report_id         uuid references public.reports (id) on delete set null,
  notes             text,
  created_at        timestamptz not null default now()
);

create index moderation_actions_community_idx
  on public.moderation_actions (community_id, created_at desc);

-- ============================================================================
-- Counter triggers
-- ----------------------------------------------------------------------------
-- reaction_count and comment_count are maintained here so clients can never
-- write them and can never disagree with reality.
-- ============================================================================

create or replace function public.tg_post_reaction_count()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  if tg_op = 'INSERT' then
    update public.posts set reaction_count = reaction_count + 1 where id = new.post_id;
  elsif tg_op = 'DELETE' then
    update public.posts set reaction_count = greatest(reaction_count - 1, 0) where id = old.post_id;
  end if;
  return null;
end;
$$;

create trigger post_reactions_count
  after insert or delete on public.post_reactions
  for each row execute function public.tg_post_reaction_count();

create or replace function public.tg_comment_reaction_count()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  if tg_op = 'INSERT' then
    update public.comments set reaction_count = reaction_count + 1 where id = new.comment_id;
  elsif tg_op = 'DELETE' then
    update public.comments set reaction_count = greatest(reaction_count - 1, 0) where id = old.comment_id;
  end if;
  return null;
end;
$$;

create trigger comment_reactions_count
  after insert or delete on public.comment_reactions
  for each row execute function public.tg_comment_reaction_count();

-- Only visible comments count toward a post's comment_count, so removing a
-- comment corrects the number the feed shows.
create or replace function public.tg_post_comment_count()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  if tg_op = 'INSERT' then
    if new.status = 'published' then
      update public.posts set comment_count = comment_count + 1 where id = new.post_id;
    end if;
  elsif tg_op = 'DELETE' then
    if old.status = 'published' then
      update public.posts set comment_count = greatest(comment_count - 1, 0) where id = old.post_id;
    end if;
  elsif tg_op = 'UPDATE' and old.status is distinct from new.status then
    if new.status = 'published' then
      update public.posts set comment_count = comment_count + 1 where id = new.post_id;
    elsif old.status = 'published' then
      update public.posts set comment_count = greatest(comment_count - 1, 0) where id = old.post_id;
    end if;
  end if;
  return null;
end;
$$;

create trigger comments_count
  after insert or delete or update of status on public.comments
  for each row execute function public.tg_post_comment_count();
