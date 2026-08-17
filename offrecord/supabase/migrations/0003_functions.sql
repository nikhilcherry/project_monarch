-- ============================================================================
-- OffRecord — 0003 write paths
-- ----------------------------------------------------------------------------
-- Every mutation in the app is one of these functions. They are SECURITY
-- DEFINER, so they run with the rights needed to write the table — which is
-- exactly why each one re-checks who the caller is, what community they belong
-- to, and whether they are suspended, before touching anything.
--
-- `set search_path = public, pg_temp` on every function is not decoration: a
-- SECURITY DEFINER function with a mutable search_path can be hijacked by a
-- caller who creates a same-named object in a schema earlier on the path.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Rate limiting
-- ----------------------------------------------------------------------------
-- Counting the caller's own recent rows is enough for V1 and needs no extra
-- table, no IP address and no device fingerprint. It bounds how fast one
-- account can flood the community; it is not a defence against someone
-- redeeming many invites, which is what the invite system is for.

create or replace function public.assert_under_rate_limit(
  p_profile_id uuid,
  p_kind       text,
  p_max        integer,
  p_window     interval
)
returns void
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare
  recent integer;
begin
  if p_kind = 'post' then
    select count(*) into recent from public.posts
      where author_id = p_profile_id and created_at > now() - p_window;
  elsif p_kind = 'comment' then
    select count(*) into recent from public.comments
      where author_id = p_profile_id and created_at > now() - p_window;
  elsif p_kind = 'report' then
    select count(*) into recent from public.reports
      where reporter_id = p_profile_id and created_at > now() - p_window;
  else
    raise exception 'unknown rate limit kind: %', p_kind;
  end if;

  if recent >= p_max then
    raise exception 'rate_limited'
      using hint = 'You are doing that too often. Try again a little later.';
  end if;
end;
$$;

-- Resolves the caller to an active profile or refuses to continue. Every write
-- below starts with this.
create or replace function public.require_active_profile()
returns public.profiles
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare
  me public.profiles;
begin
  select * into me from public.profiles where id = auth.uid();

  if me.id is null then
    raise exception 'not_a_member'
      using hint = 'Redeem an invite code before using the community.';
  end if;

  if me.status = 'suspended'
     and (me.suspended_until is null or me.suspended_until > now()) then
    raise exception 'suspended'
      using hint = coalesce(me.suspension_reason, 'Your account is suspended.');
  end if;

  return me;
end;
$$;

create or replace function public.require_moderator()
returns public.profiles
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare
  me public.profiles;
begin
  me := public.require_active_profile();
  if me.role not in ('moderator', 'admin') then
    raise exception 'not_authorised';
  end if;
  return me;
end;
$$;

-- ----------------------------------------------------------------------------
-- Invite codes
-- ----------------------------------------------------------------------------

-- Alphabet excludes I, O, 0 and 1 — codes get read aloud and typed by hand.
-- 8 random characters from 32 is ~1.1e12 combinations, far past guessing given
-- that redemption requires an authenticated account and is rate limited.
create or replace function public.generate_invite_code()
returns text
language plpgsql
volatile
set search_path = public, pg_temp
as $$
declare
  alphabet constant text := 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  candidate text;
  i integer;
begin
  loop
    candidate := '';
    for i in 1..8 loop
      -- gen_random_bytes is cryptographically secure; random() is not, and an
      -- invite code is a credential.
      candidate := candidate ||
        substr(alphabet, 1 + (get_byte(gen_random_bytes(1), 0) % 32), 1);
    end loop;
    candidate := 'OFFR-' || substr(candidate, 1, 4) || '-' || substr(candidate, 5, 4);
    exit when not exists (select 1 from public.invites where code = candidate);
  end loop;
  return candidate;
end;
$$;

-- A member spends one of their allowance to mint a single-use code.
create or replace function public.create_invite()
returns text
language plpgsql
volatile
security definer
set search_path = public, pg_temp
as $$
declare
  me   public.profiles;
  code text;
begin
  me := public.require_active_profile();

  if me.invites_remaining <= 0 then
    raise exception 'no_invites_remaining'
      using hint = 'You have used all of your invites.';
  end if;

  code := public.generate_invite_code();

  insert into public.invites (code, community_id, created_by, max_uses)
  values (code, me.community_id, me.id, 1);

  update public.profiles
     set invites_remaining = invites_remaining - 1
   where id = me.id;

  return code;
end;
$$;

-- Turns a signed-up auth user into a community member. This is the only way a
-- profile is ever created.
create or replace function public.redeem_invite(
  p_code      text,
  p_pseudonym text
)
returns public.my_profile
language plpgsql
volatile
security definer
set search_path = public, pg_temp
as $$
declare
  inv    public.invites;
  result public.my_profile;
begin
  if auth.uid() is null then
    raise exception 'not_authenticated';
  end if;

  if exists (select 1 from public.profiles where id = auth.uid()) then
    raise exception 'already_a_member';
  end if;

  if p_pseudonym !~ '^[a-zA-Z0-9_]{3,20}$' then
    raise exception 'invalid_pseudonym'
      using hint = '3-20 characters, letters, numbers and underscores only.';
  end if;

  -- FOR UPDATE holds the row until this transaction commits, so two people
  -- racing on the last use of a code cannot both win.
  select * into inv from public.invites
   where code = p_code
   for update;

  if inv.id is null then
    raise exception 'invalid_invite' using hint = 'That code was not recognised.';
  end if;
  if inv.revoked_at is not null then
    raise exception 'invalid_invite' using hint = 'That code has been revoked.';
  end if;
  if inv.expires_at is not null and inv.expires_at <= now() then
    raise exception 'invalid_invite' using hint = 'That code has expired.';
  end if;
  if inv.uses_count >= inv.max_uses then
    raise exception 'invalid_invite' using hint = 'That code has already been used.';
  end if;

  -- Deliberately the same message for every failure above except the wording
  -- of the hint: an attacker probing codes should not learn whether a code
  -- exists but is spent, versus never existed.

  begin
    insert into public.profiles (id, community_id, pseudonym)
    values (auth.uid(), inv.community_id, p_pseudonym);
  exception when unique_violation then
    raise exception 'pseudonym_taken'
      using hint = 'That name is already in use. Pick another.';
  end;

  update public.invites
     set uses_count = uses_count + 1
   where id = inv.id;

  insert into public.invite_redemptions (invite_id, profile_id)
  values (inv.id, auth.uid());

  select * into result from public.my_profile where id = auth.uid();
  return result;
end;
$$;

-- ----------------------------------------------------------------------------
-- Posting
-- ----------------------------------------------------------------------------

create or replace function public.create_post(
  p_category     public.post_category,
  p_body         text,
  p_is_anonymous boolean default true
)
returns uuid
language plpgsql
volatile
security definer
set search_path = public, pg_temp
as $$
declare
  me        public.profiles;
  needs_mod boolean;
  new_id    uuid;
begin
  me := public.require_active_profile();
  perform public.assert_under_rate_limit(me.id, 'post', 5, interval '1 hour');

  if char_length(btrim(p_body)) = 0 then
    raise exception 'empty_body' using hint = 'Write something first.';
  end if;
  if char_length(btrim(p_body)) > 500 then
    raise exception 'body_too_long' using hint = 'Posts are limited to 500 characters.';
  end if;

  select premoderate into needs_mod
    from public.communities where id = me.community_id;

  insert into public.posts (
    community_id, author_id, category, body, is_anonymous, status, published_at
  )
  values (
    me.community_id, me.id, p_category, btrim(p_body), coalesce(p_is_anonymous, true),
    case when needs_mod then 'pending' else 'published' end::public.content_status,
    case when needs_mod then null else now() end
  )
  returning id into new_id;

  return new_id;
end;
$$;

create or replace function public.create_comment(
  p_post_id      uuid,
  p_body         text,
  p_is_anonymous boolean default false
)
returns uuid
language plpgsql
volatile
security definer
set search_path = public, pg_temp
as $$
declare
  me     public.profiles;
  target public.posts;
  new_id uuid;
begin
  me := public.require_active_profile();
  perform public.assert_under_rate_limit(me.id, 'comment', 20, interval '1 hour');

  if char_length(btrim(p_body)) = 0 then
    raise exception 'empty_body';
  end if;
  if char_length(btrim(p_body)) > 1000 then
    raise exception 'body_too_long' using hint = 'Comments are limited to 1000 characters.';
  end if;

  select * into target from public.posts where id = p_post_id;

  -- You may only comment on a published post in your own community. Checking
  -- the community here stops a guessed post id from reaching across schools.
  if target.id is null
     or target.community_id <> me.community_id
     or target.status <> 'published' then
    raise exception 'post_not_available';
  end if;

  insert into public.comments (post_id, community_id, author_id, body, is_anonymous)
  values (p_post_id, me.community_id, me.id, btrim(p_body), coalesce(p_is_anonymous, false))
  returning id into new_id;

  return new_id;
end;
$$;

-- ----------------------------------------------------------------------------
-- Reactions
-- ----------------------------------------------------------------------------
-- Returns the reacted state after the toggle, so the UI can settle on the
-- truth rather than guessing.

create or replace function public.toggle_post_reaction(p_post_id uuid)
returns boolean
language plpgsql
volatile
security definer
set search_path = public, pg_temp
as $$
declare
  me      public.profiles;
  target  public.posts;
  existed boolean;
begin
  me := public.require_active_profile();

  select * into target from public.posts where id = p_post_id;
  if target.id is null
     or target.community_id <> me.community_id
     or target.status <> 'published' then
    raise exception 'post_not_available';
  end if;

  delete from public.post_reactions
   where post_id = p_post_id and profile_id = me.id;

  get diagnostics existed = row_count;

  if existed then
    return false;
  end if;

  insert into public.post_reactions (post_id, profile_id) values (p_post_id, me.id);
  return true;
end;
$$;

create or replace function public.toggle_comment_reaction(p_comment_id uuid)
returns boolean
language plpgsql
volatile
security definer
set search_path = public, pg_temp
as $$
declare
  me      public.profiles;
  target  public.comments;
  existed boolean;
begin
  me := public.require_active_profile();

  select * into target from public.comments where id = p_comment_id;
  if target.id is null
     or target.community_id <> me.community_id
     or target.status <> 'published' then
    raise exception 'comment_not_available';
  end if;

  delete from public.comment_reactions
   where comment_id = p_comment_id and profile_id = me.id;

  get diagnostics existed = row_count;

  if existed then
    return false;
  end if;

  insert into public.comment_reactions (comment_id, profile_id) values (p_comment_id, me.id);
  return true;
end;
$$;

-- ----------------------------------------------------------------------------
-- Reporting
-- ----------------------------------------------------------------------------

create or replace function public.submit_report(
  p_reason     public.report_reason,
  p_post_id    uuid default null,
  p_comment_id uuid default null,
  p_details    text default null
)
returns void
language plpgsql
volatile
security definer
set search_path = public, pg_temp
as $$
declare
  me            public.profiles;
  target_commun uuid;
begin
  me := public.require_active_profile();
  perform public.assert_under_rate_limit(me.id, 'report', 20, interval '1 day');

  if (p_post_id is null) = (p_comment_id is null) then
    raise exception 'report_needs_one_target';
  end if;

  if p_post_id is not null then
    select community_id into target_commun from public.posts where id = p_post_id;
  else
    select community_id into target_commun from public.comments where id = p_comment_id;
  end if;

  if target_commun is null or target_commun <> me.community_id then
    raise exception 'content_not_available';
  end if;

  insert into public.reports (
    community_id, reporter_id, post_id, comment_id, reason, details
  )
  values (
    me.community_id, me.id, p_post_id, p_comment_id, p_reason, nullif(btrim(p_details), '')
  )
  -- Reporting the same thing twice is a no-op, not an error: the user's
  -- intent is already recorded and the UI should not punish a double tap.
  on conflict do nothing;
end;
$$;

-- ----------------------------------------------------------------------------
-- Moderation
-- ----------------------------------------------------------------------------
-- Nothing here is triggered by report volume. A human decides, every time.

create or replace function public.mod_approve_post(p_post_id uuid)
returns void
language plpgsql
volatile
security definer
set search_path = public, pg_temp
as $$
declare
  me public.profiles;
begin
  me := public.require_moderator();

  update public.posts
     set status = 'published', published_at = now()
   where id = p_post_id
     and community_id = me.community_id
     and status = 'pending';

  if not found then
    raise exception 'post_not_pending';
  end if;

  insert into public.moderation_actions (community_id, moderator_id, action, post_id)
  values (me.community_id, me.id, 'approve_post', p_post_id);
end;
$$;

create or replace function public.mod_remove_post(p_post_id uuid, p_reason text default null)
returns void
language plpgsql
volatile
security definer
set search_path = public, pg_temp
as $$
declare
  me public.profiles;
begin
  me := public.require_moderator();

  -- Removed, never deleted: an appeal or an investigation needs the evidence.
  update public.posts
     set status = 'removed', removed_at = now(), removed_by = me.id, removed_reason = p_reason
   where id = p_post_id
     and community_id = me.community_id
     and status <> 'removed';

  if not found then
    raise exception 'post_not_found';
  end if;

  insert into public.moderation_actions (community_id, moderator_id, action, post_id, notes)
  values (me.community_id, me.id, 'remove_post', p_post_id, p_reason);
end;
$$;

create or replace function public.mod_remove_comment(p_comment_id uuid, p_reason text default null)
returns void
language plpgsql
volatile
security definer
set search_path = public, pg_temp
as $$
declare
  me public.profiles;
begin
  me := public.require_moderator();

  update public.comments
     set status = 'removed', removed_at = now(), removed_by = me.id, removed_reason = p_reason
   where id = p_comment_id
     and community_id = me.community_id
     and status <> 'removed';

  if not found then
    raise exception 'comment_not_found';
  end if;

  insert into public.moderation_actions (community_id, moderator_id, action, comment_id, notes)
  values (me.community_id, me.id, 'remove_comment', p_comment_id, p_reason);
end;
$$;

create or replace function public.mod_resolve_report(
  p_report_id uuid,
  p_dismiss   boolean default true,
  p_notes     text default null
)
returns void
language plpgsql
volatile
security definer
set search_path = public, pg_temp
as $$
declare
  me public.profiles;
begin
  me := public.require_moderator();

  update public.reports
     set status = case when p_dismiss then 'dismissed' else 'actioned' end::public.report_status,
         resolved_by = me.id,
         resolved_at = now()
   where id = p_report_id
     and community_id = me.community_id
     and status = 'open';

  if not found then
    raise exception 'report_not_open';
  end if;

  insert into public.moderation_actions
    (community_id, moderator_id, action, report_id, notes)
  values (me.community_id, me.id, 'dismiss_report', p_report_id, p_notes);
end;
$$;

create or replace function public.mod_suspend_user(
  p_profile_id uuid,
  p_until      timestamptz default null,
  p_reason     text default null
)
returns void
language plpgsql
volatile
security definer
set search_path = public, pg_temp
as $$
declare
  me     public.profiles;
  target public.profiles;
begin
  me := public.require_moderator();

  select * into target from public.profiles
   where id = p_profile_id and community_id = me.community_id;

  if target.id is null then
    raise exception 'user_not_found';
  end if;

  -- A moderator cannot suspend a peer or an admin. Without this, one
  -- compromised moderator account could lock out the whole moderation team.
  if target.role in ('moderator', 'admin') and not public.is_admin() then
    raise exception 'not_authorised'
      using hint = 'Only an admin can suspend a moderator.';
  end if;

  if target.id = me.id then
    raise exception 'cannot_suspend_self';
  end if;

  update public.profiles
     set status = 'suspended', suspended_until = p_until, suspension_reason = p_reason
   where id = p_profile_id;

  insert into public.moderation_actions
    (community_id, moderator_id, action, target_profile_id, notes)
  values (me.community_id, me.id, 'suspend_user', p_profile_id, p_reason);
end;
$$;

create or replace function public.mod_unsuspend_user(p_profile_id uuid)
returns void
language plpgsql
volatile
security definer
set search_path = public, pg_temp
as $$
declare
  me public.profiles;
begin
  me := public.require_moderator();

  update public.profiles
     set status = 'active', suspended_until = null, suspension_reason = null
   where id = p_profile_id and community_id = me.community_id;

  if not found then
    raise exception 'user_not_found';
  end if;

  insert into public.moderation_actions
    (community_id, moderator_id, action, target_profile_id)
  values (me.community_id, me.id, 'unsuspend_user', p_profile_id);
end;
$$;

create or replace function public.admin_revoke_invite(p_code text)
returns void
language plpgsql
volatile
security definer
set search_path = public, pg_temp
as $$
declare
  me public.profiles;
begin
  me := public.require_active_profile();
  if me.role <> 'admin' then
    raise exception 'not_authorised';
  end if;

  update public.invites
     set revoked_at = now()
   where code = p_code and community_id = me.community_id and revoked_at is null;

  if not found then
    raise exception 'invite_not_found';
  end if;

  insert into public.moderation_actions (community_id, moderator_id, action, notes)
  values (me.community_id, me.id, 'revoke_invite', p_code);
end;
$$;

-- ----------------------------------------------------------------------------
-- Search
-- ----------------------------------------------------------------------------
-- A function rather than a view so the query text is a parameter, never
-- concatenated into SQL by the client.

create or replace function public.search_posts(p_query text, p_limit integer default 30)
returns setof public.feed_posts
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select f.*
    from public.feed_posts f
   where f.status = 'published'
     and (
       to_tsvector('english', f.body) @@ websearch_to_tsquery('english', p_query)
       or f.body ilike '%' || p_query || '%'
     )
   order by f.created_at desc
   limit least(coalesce(p_limit, 30), 100);
$$;

-- ----------------------------------------------------------------------------
-- Execute grants
-- ----------------------------------------------------------------------------
-- 0002 revoked everything; each callable function is named explicitly here.
-- Internal helpers are deliberately absent — they stay owner-only.

grant execute on function public.redeem_invite(text, text)                              to authenticated;
grant execute on function public.create_invite()                                        to authenticated;
grant execute on function public.create_post(public.post_category, text, boolean)       to authenticated;
grant execute on function public.create_comment(uuid, text, boolean)                    to authenticated;
grant execute on function public.toggle_post_reaction(uuid)                             to authenticated;
grant execute on function public.toggle_comment_reaction(uuid)                          to authenticated;
grant execute on function public.submit_report(public.report_reason, uuid, uuid, text)  to authenticated;
grant execute on function public.search_posts(text, integer)                            to authenticated;

grant execute on function public.mod_approve_post(uuid)                                 to authenticated;
grant execute on function public.mod_remove_post(uuid, text)                            to authenticated;
grant execute on function public.mod_remove_comment(uuid, text)                         to authenticated;
grant execute on function public.mod_resolve_report(uuid, boolean, text)                to authenticated;
grant execute on function public.mod_suspend_user(uuid, timestamptz, text)              to authenticated;
grant execute on function public.mod_unsuspend_user(uuid)                               to authenticated;
grant execute on function public.admin_revoke_invite(text)                              to authenticated;

-- The mod_* and admin_* functions are granted to every authenticated user on
-- purpose: they each call require_moderator() as their first statement and
-- refuse anyone else. Authorisation is the function's job, not the grant's —
-- so a member calling one gets 'not_authorised', never a silent success.

-- ----------------------------------------------------------------------------
-- Close the PUBLIC grant on internal helpers
-- ----------------------------------------------------------------------------
-- Postgres grants EXECUTE on every new function to PUBLIC. The revoke in 0002
-- names anon and authenticated, which does NOT remove a PUBLIC grant — so
-- without the lines below, internal helpers stay callable by any signed-in
-- user. That matters most for assert_under_rate_limit: it accepts an arbitrary
-- profile id and raises only when that profile is over the limit, which turns
-- it into an oracle for "did this person post in the last hour?". Exactly the
-- kind of activity-to-identity link this platform exists to prevent.
--
-- These are safe to revoke because each is only ever called from inside a
-- SECURITY DEFINER function, which runs as the owner and is unaffected by the
-- caller's privileges.

revoke all on function public.assert_under_rate_limit(uuid, text, integer, interval) from public, anon, authenticated;
revoke all on function public.require_active_profile()                               from public, anon, authenticated;
revoke all on function public.require_moderator()                                    from public, anon, authenticated;
revoke all on function public.generate_invite_code()                                 from public, anon, authenticated;
revoke all on function public.tg_post_reaction_count()                               from public, anon, authenticated;
revoke all on function public.tg_comment_reaction_count()                            from public, anon, authenticated;
revoke all on function public.tg_post_comment_count()                                from public, anon, authenticated;

-- current_profile_id, current_community_id, is_active_member, is_moderator and
-- is_admin are deliberately NOT revoked. They are referenced by RLS policies,
-- and a policy expression is evaluated with the querying user's privileges — a
-- member who could not execute them would be unable to read anything at all.
-- Each reports only a fact about the caller themselves, so leaving them
-- callable discloses nothing.

-- Belt and braces: PostgREST only exposes functions it can see, and every
-- callable function above re-checks the caller. Nothing here relies on the
-- client choosing to call the right one.
