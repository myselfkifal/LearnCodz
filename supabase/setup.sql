-- LearnCodz private per-account backup. Run once in Supabase SQL Editor.
begin;
create table if not exists public.learncodz_backups (
  user_id uuid primary key references auth.users(id) on delete cascade,
  state jsonb not null default '{}'::jsonb,
  revision bigint not null default 1,
  updated_at timestamptz not null default now(),
  constraint learncodz_state_object check (jsonb_typeof(state) = 'object'),
  constraint learncodz_state_size check (octet_length(state::text) <= 1048576)
);
alter table public.learncodz_backups enable row level security;
revoke all on public.learncodz_backups from anon;
grant select, insert, update, delete on public.learncodz_backups to authenticated;
drop policy if exists learncodz_read_own on public.learncodz_backups;
create policy learncodz_read_own on public.learncodz_backups for select to authenticated using ((select auth.uid()) = user_id);
drop policy if exists learncodz_insert_own on public.learncodz_backups;
create policy learncodz_insert_own on public.learncodz_backups for insert to authenticated with check ((select auth.uid()) = user_id);
drop policy if exists learncodz_update_own on public.learncodz_backups;
create policy learncodz_update_own on public.learncodz_backups for update to authenticated using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);
drop policy if exists learncodz_delete_own on public.learncodz_backups;
create policy learncodz_delete_own on public.learncodz_backups for delete to authenticated using ((select auth.uid()) = user_id);
commit;
-- Verify configuration (no user data returned).
select tablename, rowsecurity from pg_tables where schemaname='public' and tablename='learncodz_backups';
select policyname, cmd from pg_policies where schemaname='public' and tablename='learncodz_backups';
