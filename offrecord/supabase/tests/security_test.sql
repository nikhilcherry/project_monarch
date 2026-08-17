-- ============================================================================
-- OffRecord — security regression tests
-- ----------------------------------------------------------------------------
-- Run against a scratch database, never against production. Each block asserts
-- something the platform promises its users. A failure here is a privacy bug,
-- not a style problem.
--
--   psql -d offrecord_test -v ON_ERROR_STOP=1 -f supabase/tests/security_test.sql
-- ============================================================================

\set ON_ERROR_STOP on

create or replace function assert(cond boolean, label text)
returns void language plpgsql as $$
begin
  if cond then
    raise notice 'PASS  %', label;
  else
    raise exception 'FAIL  %', label;
  end if;
end;
$$;

-- Runs a statement as a signed-in member and reports whether it was refused.
create or replace function refused(sql text)
returns boolean language plpgsql as $$
begin
  execute sql;
  return false;
exception when others then
  return true;
end;
$$;

-- ----------------------------------------------------------------------------
-- Fixtures
-- ----------------------------------------------------------------------------

truncate table public.moderation_actions, public.reports, public.comment_reactions,
  public.post_reactions, public.comments, public.posts, public.invite_redemptions,
  public.invites, public.profiles, public.communities cascade;
delete from auth.users;

insert into public.communities (id, slug, name)
values ('11111111-1111-1111-1111-111111111111', 'northwood', 'Northwood High');
insert into public.communities (id, slug, name)
values ('22222222-2222-2222-2222-222222222222', 'southvale', 'Southvale High');

insert into auth.users (id) values
  ('aaaaaaaa-0000-0000-0000-000000000001'),  -- alice, member
  ('bbbbbbbb-0000-0000-0000-000000000002'),  -- bob, member
  ('cccccccc-0000-0000-0000-000000000003'),  -- carol, moderator
  ('dddddddd-0000-0000-0000-000000000004'),  -- dave, other community
  ('eeeeeeee-0000-0000-0000-000000000005');  -- erin, unredeemed

insert into public.profiles (id, community_id, pseudonym, role) values
  ('cccccccc-0000-0000-0000-000000000003', '11111111-1111-1111-1111-111111111111', 'modcarol', 'moderator'),
  ('dddddddd-0000-0000-0000-000000000004', '22222222-2222-2222-2222-222222222222', 'davesouth', 'member');

insert into public.invites (code, community_id, created_by, max_uses) values
  ('OFFR-TEST-0001', '11111111-1111-1111-1111-111111111111', null, 1),
  ('OFFR-TEST-0002', '11111111-1111-1111-1111-111111111111', null, 1),
  ('OFFR-TEST-DEAD', '11111111-1111-1111-1111-111111111111', null, 1);
update public.invites set revoked_at = now() where code = 'OFFR-TEST-DEAD';

-- Helper: become a given user in the `authenticated` role.
create or replace function login(uid uuid)
returns void language plpgsql as $$
begin
  perform set_config('request.jwt.claim.sub', uid::text, false);
end;
$$;

-- ============================================================================
-- 1. Invites
-- ============================================================================

select login('aaaaaaaa-0000-0000-0000-000000000001');
select public.redeem_invite('OFFR-TEST-0001', 'alicepseudo');
select assert(
  exists (select 1 from public.profiles where id = 'aaaaaaaa-0000-0000-0000-000000000001'),
  'invite redemption creates a profile');

select login('bbbbbbbb-0000-0000-0000-000000000002');
select assert(
  refused($$select public.redeem_invite('OFFR-TEST-0001', 'bobpseudo')$$),
  'a single-use invite cannot be redeemed twice');

select assert(
  refused($$select public.redeem_invite('OFFR-TEST-DEAD', 'bobpseudo')$$),
  'a revoked invite is refused');

select assert(
  refused($$select public.redeem_invite('OFFR-NOPE-NOPE', 'bobpseudo')$$),
  'an unknown invite code is refused');

select assert(
  refused($$select public.redeem_invite('OFFR-TEST-0002', 'ALICEPSEUDO')$$),
  'pseudonyms are unique case-insensitively');

select assert(
  refused($$select public.redeem_invite('OFFR-TEST-0002', 'bad name!')$$),
  'a pseudonym with illegal characters is refused');

select public.redeem_invite('OFFR-TEST-0002', 'bobpseudo');
select assert(
  refused($$select public.redeem_invite('OFFR-TEST-0002', 'bobagain')$$),
  'an existing member cannot redeem another code');

-- ============================================================================
-- 2. Anonymity — the core promise
-- ============================================================================

select login('aaaaaaaa-0000-0000-0000-000000000001');
select public.create_post('confession', 'I have never once done the reading.', true) as anon_post \gset
select public.create_post('advice', 'Signed, with my name on it.', false) as named_post \gset

-- Publish them so they are visible in the feed.
select login('cccccccc-0000-0000-0000-000000000003');
select public.mod_approve_post(:'anon_post');
select public.mod_approve_post(:'named_post');

select login('bbbbbbbb-0000-0000-0000-000000000002');

select assert(
  (select display_name from public.feed_posts where id = :'anon_post') = 'Anonymous',
  'an anonymous post shows as Anonymous to another member');

select assert(
  (select display_name from public.feed_posts where id = :'named_post') = 'alicepseudo',
  'a pseudonymous post shows the pseudonym');

select assert(
  not exists (
    select 1 from information_schema.columns
    where table_name = 'feed_posts' and column_name = 'author_id'
  ),
  'the feed view has no author_id column at all');

set role authenticated;
select assert(
  refused($$select author_id from public.posts$$),
  'a member cannot read posts.author_id directly');
select assert(
  refused($$select * from public.posts$$),
  'a member cannot select from the posts table at all');
select assert(
  refused($$select * from public.profiles$$),
  'a member cannot select from the profiles table directly');
select assert(
  refused($$update public.posts set body = 'hacked'$$),
  'a member cannot update posts directly');
select assert(
  refused($$insert into public.posts (community_id, author_id, category, body)
            values ('11111111-1111-1111-1111-111111111111',
                    'bbbbbbbb-0000-0000-0000-000000000002', 'rant', 'direct insert')$$),
  'a member cannot insert a post directly, bypassing moderation');
select assert(
  refused($$update public.profiles set role = 'admin' where id = auth.uid()$$),
  'a member cannot promote themselves to admin');
select assert(
  refused($$update public.invites set uses_count = 0$$),
  'a member cannot reset an invite for reuse');
reset role;

-- ============================================================================
-- 3. Moderation state
-- ============================================================================

select login('aaaaaaaa-0000-0000-0000-000000000001');
select public.create_post('rant', 'This one is still waiting for review.', true) as pending_post \gset

select assert(
  exists (select 1 from public.feed_posts where id = :'pending_post'),
  'an author sees their own pending post');

select login('bbbbbbbb-0000-0000-0000-000000000002');
select assert(
  not exists (select 1 from public.feed_posts where id = :'pending_post'),
  'another member cannot see a pending post');

select assert(
  refused($$select public.mod_approve_post('$$ || :'pending_post' || $$')$$),
  'an ordinary member cannot approve a post');
select assert(
  refused($$select public.mod_remove_post('$$ || :'anon_post' || $$')$$),
  'an ordinary member cannot remove a post');
select assert(
  refused($$select public.mod_suspend_user('aaaaaaaa-0000-0000-0000-000000000001')$$),
  'an ordinary member cannot suspend anyone');
select assert(
  refused($$select public.admin_revoke_invite('OFFR-TEST-0001')$$),
  'a member cannot revoke invites');

select assert(
  not exists (select 1 from public.mod_pending_posts),
  'the moderator queue is empty for a non-moderator');

select login('cccccccc-0000-0000-0000-000000000003');
select assert(
  exists (select 1 from public.mod_pending_posts where id = :'pending_post'),
  'a moderator sees the pending queue');

-- A moderator cannot suspend another moderator.
select assert(
  refused($$select public.mod_suspend_user('cccccccc-0000-0000-0000-000000000003')$$),
  'a moderator cannot suspend themselves');

-- ============================================================================
-- 4. Cross-community isolation
-- ============================================================================

select login('dddddddd-0000-0000-0000-000000000004');
select assert(
  not exists (select 1 from public.feed_posts),
  'a member of another school sees none of this school''s posts');
select assert(
  not exists (select 1 from public.community_members where pseudonym = 'alicepseudo'),
  'member search does not cross communities');
select assert(
  refused($$select public.create_comment('$$ || :'anon_post' || $$', 'from another school')$$),
  'a member of another school cannot comment here');
select assert(
  refused($$select public.toggle_post_reaction('$$ || :'anon_post' || $$')$$),
  'a member of another school cannot react here');

-- ============================================================================
-- 5. Reactions are private
-- ============================================================================

select login('bbbbbbbb-0000-0000-0000-000000000002');
select public.toggle_post_reaction(:'anon_post');
select assert(
  (select reaction_count from public.feed_posts where id = :'anon_post') = 1,
  'reacting increments the counter');
select assert(
  (select has_reacted from public.feed_posts where id = :'anon_post'),
  'the reactor sees their own reaction');

select login('aaaaaaaa-0000-0000-0000-000000000001');
select assert(
  not (select has_reacted from public.feed_posts where id = :'anon_post'),
  'someone else''s reaction does not show as mine');

set role authenticated;
select assert(
  refused($$select * from public.post_reactions$$),
  'the reactions table is not readable — who liked what stays private');
reset role;

select login('bbbbbbbb-0000-0000-0000-000000000002');
select public.toggle_post_reaction(:'anon_post');
select assert(
  (select reaction_count from public.feed_posts where id = :'anon_post') = 0,
  'un-reacting decrements the counter');

-- ============================================================================
-- 6. Suspension
-- ============================================================================

select login('cccccccc-0000-0000-0000-000000000003');
select public.mod_suspend_user('bbbbbbbb-0000-0000-0000-000000000002', null, 'testing');

select login('bbbbbbbb-0000-0000-0000-000000000002');
select assert(
  refused($$select public.create_post('rant', 'let me back in')$$),
  'a suspended member cannot post');
select assert(
  refused($$select public.create_comment('$$ || :'anon_post' || $$', 'still here')$$),
  'a suspended member cannot comment');
select assert(
  refused($$select public.toggle_post_reaction('$$ || :'anon_post' || $$')$$),
  'a suspended member cannot react');

select login('cccccccc-0000-0000-0000-000000000003');
select public.mod_unsuspend_user('bbbbbbbb-0000-0000-0000-000000000002');
select login('bbbbbbbb-0000-0000-0000-000000000002');
select assert(
  not refused($$select public.create_post('rant', 'back again')$$),
  'an unsuspended member can post again');

-- ============================================================================
-- 7. Input validation and rate limits
-- ============================================================================

select login('aaaaaaaa-0000-0000-0000-000000000001');
select assert(
  refused($$select public.create_post('rant', '   ')$$),
  'a whitespace-only post is refused');
select assert(
  refused($$select public.create_post('rant', repeat('x', 501))$$),
  'a post over 500 characters is refused');

-- Alice has posted 3 times already; the limit is 5 an hour.
select public.create_post('other', 'four');
select public.create_post('other', 'five');
select assert(
  refused($$select public.create_post('other', 'six')$$),
  'posting is rate limited');

-- ============================================================================
-- 8. Reports
-- ============================================================================

select login('bbbbbbbb-0000-0000-0000-000000000002');
select public.submit_report('harassment', :'anon_post', null, 'not ok');
select assert(
  (select count(*) from public.reports where post_id = :'anon_post') = 1,
  'a report is recorded');

-- Reporting twice must not create a second row, and must not error.
select public.submit_report('spam', :'anon_post', null, null);
select assert(
  (select count(*) from public.reports where post_id = :'anon_post') = 1,
  'reporting the same post twice is a no-op');

select assert(
  refused($$select public.submit_report('spam', null, null)$$),
  'a report must name a target');

select assert(
  (select status from public.posts where id = :'anon_post') = 'published',
  'a reported post is NOT auto-removed');

select assert(
  not exists (select 1 from public.mod_reports),
  'a member cannot read the report queue');

select login('cccccccc-0000-0000-0000-000000000003');
select assert(
  (select count(*) from public.mod_reports) = 1,
  'a moderator sees the report queue');

select id from public.reports limit 1 \gset report_
select public.mod_resolve_report(:'report_id', true, 'reviewed, no action');
select assert(
  (select status from public.reports where id = :'report_id') = 'dismissed',
  'a moderator can dismiss a report');

-- ============================================================================
-- 9. Non-members
-- ============================================================================

select login('eeeeeeee-0000-0000-0000-000000000005');
select assert(
  not exists (select 1 from public.feed_posts),
  'a signed-up user who has not redeemed an invite sees nothing');
select assert(
  refused($$select public.create_post('rant', 'hello')$$),
  'a user without a profile cannot post');

-- ============================================================================
-- 10. Invite allowance
-- ============================================================================

select login('aaaaaaaa-0000-0000-0000-000000000001');
select assert(
  (select invites_remaining from public.my_profile) = 3,
  'a new member starts with three invites');
select public.create_invite();
select assert(
  (select invites_remaining from public.my_profile) = 2,
  'creating an invite spends one of the allowance');
select assert(
  (select code from public.invites where created_by = auth.uid()) ~ '^OFFR-[A-Z2-9]{4}-[A-Z2-9]{4}$',
  'generated codes match the expected format');

update public.profiles set invites_remaining = 0 where id = auth.uid();
select assert(
  refused($$select public.create_invite()$$),
  'a member out of invites cannot create more');

-- ============================================================================
-- 11. Internal helpers are not reachable from a client
-- ============================================================================
-- assert_under_rate_limit accepts any profile id and raises only when that
-- profile is over the limit. If a member could call it, it would answer
-- "has this person posted recently?" about anyone.

select assert(
  not has_function_privilege('authenticated',
    'public.assert_under_rate_limit(uuid, text, integer, interval)', 'EXECUTE'),
  'the rate-limit helper is not callable by members (no activity oracle)');

select assert(
  not has_function_privilege('authenticated', 'public.require_active_profile()', 'EXECUTE'),
  'require_active_profile is not callable by members');
select assert(
  not has_function_privilege('authenticated', 'public.generate_invite_code()', 'EXECUTE'),
  'generate_invite_code is not callable by members');

-- These must stay callable: RLS policies evaluate them as the querying user.
select assert(
  has_function_privilege('authenticated', 'public.is_moderator()', 'EXECUTE'),
  'policy helpers remain callable, or members could read nothing at all');

select 'ALL SECURITY TESTS PASSED' as result;
