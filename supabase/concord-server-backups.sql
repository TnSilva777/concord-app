-- CONCORD: backup privado de servidores por conta.
-- Execute no SQL Editor do Supabase uma única vez.
create table if not exists public.concord_server_backups (
  user_id uuid primary key references auth.users(id) on delete cascade,
  communities jsonb not null default '[]'::jsonb,
  updated_at timestamptz not null default now(),
  constraint concord_server_backups_array check (jsonb_typeof(communities) = 'array'),
  constraint concord_server_backups_size check (octet_length(communities::text) <= 500000)
);
alter table public.concord_server_backups enable row level security;
revoke all on public.concord_server_backups from anon;
grant select, insert, update on public.concord_server_backups to authenticated;
drop policy if exists "read own server backup" on public.concord_server_backups;
create policy "read own server backup" on public.concord_server_backups for select to authenticated using (user_id = (select auth.uid()));
drop policy if exists "insert own server backup" on public.concord_server_backups;
create policy "insert own server backup" on public.concord_server_backups for insert to authenticated with check (user_id = (select auth.uid()));
drop policy if exists "update own server backup" on public.concord_server_backups;
create policy "update own server backup" on public.concord_server_backups for update to authenticated using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));
-- Não compartilha servidores com amigos; apenas preserva os seus servidores entre dispositivos.
