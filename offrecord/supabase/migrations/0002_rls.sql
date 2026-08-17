-- ============================================================================
-- OffRecord — 0002 row-level security, grants and read views
-- ----------------------------------------------------------------------------
-- The security model, in one paragraph:
--
--   Clients never touch base tables. Every table has RLS enabled with policies
--   that express the real rule, AND the `authenticated` role is granted nothing
--   on those tables. Reads go through the views at the bottom of this file,
--   which omit author_id entirely; writes go through the SECURITY DEFINER
--   functions in 0003, which validate first. So there are two independent
--   layers: if a grant is ever widened by accident, the policies still hold; if
--   a policy is ever written wrong, the missing grant still holds.
--
-- Why not let clients query tables directly, the usual Supabase way? Because
-- anonymity is the product. `posts.author_id` must exist for moderation and
-- must never reach another student's browser. A SELECT policy cannot hide a
-- column — it filters rows. Removing the grant is what actually hides it.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Helpers
-- ----------------------------------------------------------------------------
-- These are SECURITY DEFINER on purpose. A policy on `profiles` that queries
-- `profiles` re-enters the same policy and Postgres raises "infinite recursion
-- detected in policy". Reading through a definer function breaks the cycle.
-- They are STABLE so the planner calls them once per statement, not per row.

create or replace function public.current_profile_id()
returns uuid
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select id from public.profiles where id = auth.uid();
$$;

create or replace function public.current_community_id()
returns uuid
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select community_id from public.profiles where id = auth.uid();
$$;

-- Active means: has a profile, and is not currently serving a suspension.
-- A suspension with a past suspended_until has simply expired — no cron job
-- needed to reinstate anyone.
create or replace function public.is_active_member()
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select exists (
    select 1 from public.profiles p
    where p.id = auth.uid()
      and (
        p.status = 'active'
        or (p.suspended_until is not null and p.suspended_until <= now())
      )
  );
$$;

create or replace function public.is_moderator()
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select exists (
    select 1 from public.profiles p
    where p.id = auth.uid()
      and p.role in ('moderator', 'admin')
      and p.status = 'active'
  );
$$;

create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select exists (
    select 1 from public.profiles p
    where p.id = auth.uid() and p.role = 'admin' and p.status = 'active'
  );
$$;

-- ----------------------------------------------------------------------------
-- Enable RLS everywhere
-- ----------------------------------------------------------------------------
-- FORCE also applies policies to the table owner, so a SECURITY DEFINER
-- function cannot accidentally read past them unless it means to.

alter table public.communities        enable row level security;
alter table public.profiles           enable row level security;
alter table public.invites            enable row level security;
alter table public.invite_redemptions enable row level security;
alter table public.posts              enable row level security;
alter table public.comments           enable row level security;
alter table public.post_reactions     enable row level security;
alter table public.comment_reactions  enable row level security;
alter table public.reports            enable row level security;
alter table public.moderation_actions enable row level security;

-- ----------------------------------------------------------------------------
-- Revoke the default grants
-- ----------------------------------------------------------------------------
-- Supabase grants ALL on new public tables to anon and authenticated by
-- default. That default is wrong for this project, so it is taken back
-- explicitly. Nothing below re-grants table access; only views and functions
-- are granted.

revoke all on all tables in schema public from anon, authenticated;
revoke all on all sequences in schema public from anon, authenticated;
-- Functions are granted individually in 0003.
revoke all on all functions in schema public from anon, authenticated;

-- ----------------------------------------------------------------------------
-- Policies — communities
-- ----------------------------------------------------------------------------

create policy communities_read_own
  on public.communities for select
  to authenticated
  using (id = public.current_community_id());

-- ----------------------------------------------------------------------------
-- Policies — profiles
-- ----------------------------------------------------------------------------

-- A member may read their own profile row in full.
create policy profiles_read_self
  on public.profiles for select
  to authenticated
  using (id = auth.uid());

-- Moderators may read profiles in their own community, and only their own:
-- a moderator at one school has no business reading another school's members.
create policy profiles_read_as_moderator
  on public.profiles for select
  to authenticated
  using (public.is_moderator() and community_id = public.current_community_id());

-- Nobody updates a profile directly — not even their own. Role, status and
-- invites_remaining are all privilege-bearing, and pseudonym uniqueness needs
-- validation. Those changes go through 0003's functions.

-- ----------------------------------------------------------------------------
-- Policies — invites
-- ----------------------------------------------------------------------------

-- You can see the codes you own, and nothing else. Reading someone else's
-- unused code would let you spend it.
create policy invites_read_own
  on public.invites for select
  to authenticated
  using (created_by = auth.uid());

create policy invites_read_as_admin
  on public.invites for select
  to authenticated
  using (public.is_admin() and community_id = public.current_community_id());

create policy invite_redemptions_read_as_admin
  on public.invite_redemptions for select
  to authenticated
  using (
    public.is_admin()
    and exists (
      select 1 from public.invites i
      where i.id = invite_id and i.community_id = public.current_community_id()
    )
  );

-- ----------------------------------------------------------------------------
-- Policies — posts
-- ----------------------------------------------------------------------------

-- Published posts, to active members of the same community.
create policy posts_read_published
  on public.posts for select
  to authenticated
  using (
    status = 'published'
    and community_id = public.current_community_id()
    and public.is_active_member()
  );

-- Your own posts whatever their state, so you can see yours awaiting review.
create policy posts_read_own
  on public.posts for select
  to authenticated
  using (author_id = auth.uid());

-- Moderators see everything in their community, including the pending queue
-- and removed posts.
create policy posts_read_as_moderator
  on public.posts for select
  to authenticated
  using (public.is_moderator() and community_id = public.current_community_id());

-- ----------------------------------------------------------------------------
-- Policies — comments
-- ----------------------------------------------------------------------------

create policy comments_read_published
  on public.comments for select
  to authenticated
  using (
    status = 'published'
    and community_id = public.current_community_id()
    and public.is_active_member()
  );

create policy comments_read_own
  on public.comments for select
  to authenticated
  using (author_id = auth.uid());

create policy comments_read_as_moderator
  on public.comments for select
  to authenticated
  using (public.is_moderator() and community_id = public.current_community_id());

-- ----------------------------------------------------------------------------
-- Policies — reactions
-- ----------------------------------------------------------------------------
-- Who reacted to what is private: knowing that `quietkoala82` hearted a
-- particular confession is exactly the kind of link this platform exists to
-- prevent. You may read only your own reactions — enough to draw the heart
-- filled in. Totals come from the denormalised counters.

create policy post_reactions_read_own
  on public.post_reactions for select
  to authenticated
  using (profile_id = auth.uid());

create policy comment_reactions_read_own
  on public.comment_reactions for select
  to authenticated
  using (profile_id = auth.uid());

-- ----------------------------------------------------------------------------
-- Policies — reports
-- ----------------------------------------------------------------------------

-- Reporters may see the reports they filed (so the UI can say "already
-- reported") but never who else reported the same thing.
create policy reports_read_own
  on public.reports for select
  to authenticated
  using (reporter_id = auth.uid());

create policy reports_read_as_moderator
  on public.reports for select
  to authenticated
  using (public.is_moderator() and community_id = public.current_community_id());

-- ----------------------------------------------------------------------------
-- Policies — moderation_actions
-- ----------------------------------------------------------------------------

create policy moderation_actions_read_as_moderator
  on public.moderation_actions for select
  to authenticated
  using (public.is_moderator() and community_id = public.current_community_id());

-- Note there is no INSERT, UPDATE or DELETE policy anywhere in this file. All
-- writes go through 0003. A missing policy denies by default, which is the
-- behaviour we want if someone later grants table access by mistake.

-- ============================================================================
-- Read views — the only thing clients SELECT from
-- ----------------------------------------------------------------------------
-- These run with the view owner's rights (security_invoker is left off), so
-- they see past RLS. That means every visibility rule must be written into the
-- view's own WHERE clause — which is done below, and is the reason each view
-- repeats the community and status checks.
-- ============================================================================

-- The feed and post detail. author_id is absent by construction: there is no
-- column for a client to ask for.
create view public.feed_posts as
select
  p.id,
  p.community_id,
  p.category,
  p.body,
  p.status,
  p.created_at,
  p.published_at,
  p.reaction_count,
  p.comment_count,
  case when p.is_anonymous then 'Anonymous' else author.pseudonym end as display_name,
  -- Lets the UI show "your post" and a pending badge without exposing who
  -- wrote anything else.
  (p.author_id = auth.uid()) as is_mine,
  exists (
    select 1 from public.post_reactions r
    where r.post_id = p.id and r.profile_id = auth.uid()
  ) as has_reacted
from public.posts p
join public.profiles author on author.id = p.author_id
where p.community_id = public.current_community_id()
  and public.is_active_member()
  and (
    p.status = 'published'
    or (p.status = 'pending' and p.author_id = auth.uid())
  );

comment on view public.feed_posts is
  'The only post read path for members. Exposes display_name, never author_id.';

create view public.feed_comments as
select
  c.id,
  c.post_id,
  c.body,
  c.created_at,
  c.reaction_count,
  case when c.is_anonymous then 'Anonymous' else author.pseudonym end as display_name,
  (c.author_id = auth.uid()) as is_mine,
  exists (
    select 1 from public.comment_reactions r
    where r.comment_id = c.id and r.profile_id = auth.uid()
  ) as has_reacted
from public.comments c
join public.profiles author on author.id = c.author_id
where c.community_id = public.current_community_id()
  and public.is_active_member()
  and c.status = 'published';

-- Pseudonym search. Returns display names only — no join back to posts, so
-- searching a name cannot reveal which anonymous posts belong to it.
create view public.community_members as
select
  p.id,
  p.pseudonym,
  p.created_at
from public.profiles p
where p.community_id = public.current_community_id()
  and p.status = 'active'
  and public.is_active_member();

-- What the logged-in user needs about themselves.
create view public.my_profile as
select
  p.id,
  p.community_id,
  p.pseudonym,
  p.role,
  p.status,
  p.suspended_until,
  p.suspension_reason,
  p.invites_remaining,
  p.created_at,
  (select count(*) from public.posts x
    where x.author_id = p.id and x.status = 'published') as published_post_count
from public.profiles p
where p.id = auth.uid();

-- ----------------------------------------------------------------------------
-- Moderator views
-- ----------------------------------------------------------------------------
-- Moderators DO see author pseudonyms — reviewing content without knowing
-- whether one account is behind a harassment campaign is not moderation. They
-- still never see an email or any real-world identifier, because the database
-- does not store one.

create view public.mod_pending_posts as
select
  p.id,
  p.category,
  p.body,
  p.created_at,
  p.is_anonymous,
  author.pseudonym as author_pseudonym,
  p.author_id
from public.posts p
join public.profiles author on author.id = p.author_id
where p.status = 'pending'
  and p.community_id = public.current_community_id()
  and public.is_moderator();

create view public.mod_reports as
select
  r.id,
  r.reason,
  r.details,
  r.status,
  r.created_at,
  case when r.post_id is not null then 'post' else 'comment' end as target_kind,
  r.post_id,
  r.comment_id,
  coalesce(p.body, c.body) as content_body,
  coalesce(p.status, c.status) as content_status,
  coalesce(pa.pseudonym, ca.pseudonym) as author_pseudonym,
  coalesce(p.author_id, c.author_id) as author_id,
  reporter.pseudonym as reporter_pseudonym
from public.reports r
left join public.posts p on p.id = r.post_id
left join public.profiles pa on pa.id = p.author_id
left join public.comments c on c.id = r.comment_id
left join public.profiles ca on ca.id = c.author_id
join public.profiles reporter on reporter.id = r.reporter_id
where r.community_id = public.current_community_id()
  and public.is_moderator();

-- ----------------------------------------------------------------------------
-- View grants
-- ----------------------------------------------------------------------------

grant select on public.feed_posts        to authenticated;
grant select on public.feed_comments     to authenticated;
grant select on public.community_members to authenticated;
grant select on public.my_profile        to authenticated;
grant select on public.mod_pending_posts to authenticated;
grant select on public.mod_reports       to authenticated;

-- The anonymous role gets nothing at all. Signed-out visitors see no content:
-- this is a closed, invite-only community, not a public forum.
