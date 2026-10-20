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

-- Keep public names synchronized from account creation and profile edits.
-- Run this migration in the Supabase SQL Editor; committing SQL alone does not apply it.
create or replace function public.concord_sync_auth_display_name()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare chosen_name text;
begin
  chosen_name := coalesce(
    nullif(btrim(new.raw_user_meta_data->'concord_profile'->>'name'),''),
    nullif(btrim(new.raw_user_meta_data->>'display_name'),''),
    nullif(btrim(new.raw_user_meta_data->>'full_name'),''),
    nullif(btrim(new.raw_user_meta_data->>'name'),'')
  );
  if chosen_name is not null then
    insert into public.concord_public_profiles(user_id,display_name,updated_at)
    values(new.id,left(chosen_name,28),now())
    on conflict(user_id) do update
      set display_name=excluded.display_name,updated_at=excluded.updated_at
      where public.concord_public_profiles.display_name is distinct from excluded.display_name;
  end if;
  return new;
end;
$$;
drop trigger if exists concord_sync_auth_display_name_trigger on auth.users;
create trigger concord_sync_auth_display_name_trigger
after insert or update of raw_user_meta_data on auth.users
for each row execute function public.concord_sync_auth_display_name();

-- Backfill accounts created before the trigger existed.
insert into public.concord_public_profiles(user_id,display_name,updated_at)
select id,left(coalesce(
 nullif(btrim(raw_user_meta_data->'concord_profile'->>'name'),''),
 nullif(btrim(raw_user_meta_data->>'display_name'),''),
 nullif(btrim(raw_user_meta_data->>'full_name'),''),
 nullif(btrim(raw_user_meta_data->>'name'),'')
),28),now()
from auth.users
where coalesce(
 nullif(btrim(raw_user_meta_data->'concord_profile'->>'name'),''),
 nullif(btrim(raw_user_meta_data->>'display_name'),''),
 nullif(btrim(raw_user_meta_data->>'full_name'),''),
 nullif(btrim(raw_user_meta_data->>'name'),'')
) is not null
on conflict(user_id) do nothing;

-- Existing accounts: after applying this migration, users without a saved name
-- must sign in and save their chosen profile name. Do not expose email addresses
-- or generate a public name from an email address without consent.
