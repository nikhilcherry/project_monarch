-- ============================================================================
-- OffRecord — 0004 bootstrap
-- ----------------------------------------------------------------------------
-- Creates the first community and its founding invite codes. Safe to run more
-- than once: the insert is a no-op if the community already exists.
--
-- Edit the two values below before running.
-- ============================================================================

do $$
declare
  -- CHANGE THESE ------------------------------------------------------------
  v_slug constant text := 'northwood';          -- url-safe id, lowercase
  v_name constant text := 'Northwood High';     -- shown in the UI
  ---------------------------------------------------------------------------
  v_community_id uuid;
  v_code         text;
  i              integer;
begin
  insert into public.communities (slug, name, premoderate)
  values (v_slug, v_name, true)
  on conflict (slug) do nothing;

  select id into v_community_id from public.communities where slug = v_slug;

  -- Ten founding codes, owned by nobody. These are how the first people get
  -- in; after that, members mint their own from their allowance.
  if not exists (
    select 1 from public.invites
    where community_id = v_community_id and created_by is null
  ) then
    for i in 1..10 loop
      v_code := public.generate_invite_code();
      insert into public.invites (code, community_id, created_by, max_uses)
      values (v_code, v_community_id, null, 1);
    end loop;
  end if;
end;
$$;

-- Read your founding codes:
--
--   select code from public.invites where created_by is null order by created_at;
--
-- Treat them as passwords. Each one admits exactly one person.

-- ----------------------------------------------------------------------------
-- Making yourself an admin
-- ----------------------------------------------------------------------------
-- There is deliberately no way to create an admin from the app: a self-service
-- path to the role would be the single worst bug this project could ship. So
-- the first admin is made by hand, once, from the SQL editor.
--
-- 1. Sign up in the app and redeem one of the codes above.
-- 2. Find your profile:
--
--      select id, pseudonym, role from public.profiles;
--
-- 3. Promote it, using your own pseudonym:
--
--      update public.profiles set role = 'admin' where pseudonym = 'your_name';
--
-- Later moderators can be promoted the same way. Keep the admin count small.
