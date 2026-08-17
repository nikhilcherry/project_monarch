-- Minimal stand-in for the parts of Supabase the migrations depend on, so the
-- schema can be validated locally. NOT shipped.
create schema if not exists auth;

create table auth.users (
  id uuid primary key default gen_random_uuid(),
  email text
);

-- Supabase sets request.jwt.claims per request; auth.uid() reads it.
create or replace function auth.uid()
returns uuid
language sql
stable
as $$
  select nullif(current_setting('request.jwt.claim.sub', true), '')::uuid;
$$;

do $$ begin
  create role anon nologin;
exception when duplicate_object then null; end $$;
do $$ begin
  create role authenticated nologin;
exception when duplicate_object then null; end $$;
do $$ begin
  create role service_role nologin bypassrls;
exception when duplicate_object then null; end $$;

grant usage on schema public to anon, authenticated, service_role;

-- Mirror Supabase's default grants, so the REVOKE in 0002 has something real
-- to take back.
alter default privileges in schema public grant all on tables to anon, authenticated;
alter default privileges in schema public grant all on functions to anon, authenticated;
alter default privileges in schema public grant all on sequences to anon, authenticated;
