-- CONCORD: nomes públicos escolhidos pelos usuários (sem expor email ou metadados privados)
create table if not exists public.concord_public_profiles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null check (char_length(trim(display_name)) between 1 and 28),
  updated_at timestamptz not null default now()
);
alter table public.concord_public_profiles enable row level security;
drop policy if exists "Authenticated users can read public display names" on public.concord_public_profiles;
create policy "Authenticated users can read public display names"
on public.concord_public_profiles for select to authenticated using (true);
drop policy if exists "Users can create their own public profile" on public.concord_public_profiles;
create policy "Users can create their own public profile"
on public.concord_public_profiles for insert to authenticated with check ((select auth.uid()) = user_id);
drop policy if exists "Users can update their own public profile" on public.concord_public_profiles;
create policy "Users can update their own public profile"
on public.concord_public_profiles for update to authenticated
using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);
