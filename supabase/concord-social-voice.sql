-- Execute no SQL Editor do Supabase ANTES de ativar os recursos compartilhados.
-- Salas de voz globais (fase de testes); apenas o criador pode remover sua sala.
create table if not exists public.concord_voice_rooms (
 id uuid primary key default gen_random_uuid(),
 name text not null unique check (char_length(name) between 1 and 24),
 owner_id uuid not null references auth.users(id) on delete cascade,
 created_at timestamptz not null default now()
);
alter table public.concord_voice_rooms enable row level security;
drop policy if exists "voice rooms read" on public.concord_voice_rooms;
create policy "voice rooms read" on public.concord_voice_rooms for select to authenticated using (true);
drop policy if exists "voice rooms create" on public.concord_voice_rooms;
create policy "voice rooms create" on public.concord_voice_rooms for insert to authenticated with check (owner_id=auth.uid());
drop policy if exists "voice rooms delete own" on public.concord_voice_rooms;
create policy "voice rooms delete own" on public.concord_voice_rooms for delete to authenticated using (owner_id=auth.uid());

-- Pedidos de amizade por ID de usuário; presença só é consultável por amizades aceitas.
create table if not exists public.concord_friend_requests (
 id uuid primary key default gen_random_uuid(),
 requester_id uuid not null references auth.users(id) on delete cascade,
 recipient_id uuid not null references auth.users(id) on delete cascade,
 status text not null default 'pending' check (status in ('pending','accepted')),
 created_at timestamptz not null default now(),
 check (requester_id<>recipient_id),
 unique(requester_id,recipient_id)
);
alter table public.concord_friend_requests enable row level security;
drop policy if exists "friends view own" on public.concord_friend_requests;
create policy "friends view own" on public.concord_friend_requests for select to authenticated using (requester_id=auth.uid() or recipient_id=auth.uid());
drop policy if exists "friends request" on public.concord_friend_requests;
create policy "friends request" on public.concord_friend_requests for insert to authenticated with check (requester_id=auth.uid() and status='pending');
drop policy if exists "friends accept" on public.concord_friend_requests;
create policy "friends accept" on public.concord_friend_requests for update to authenticated using (recipient_id=auth.uid() and status='pending') with check (recipient_id=auth.uid() and status='accepted');
drop policy if exists "friends remove" on public.concord_friend_requests;
create policy "friends remove" on public.concord_friend_requests for delete to authenticated using (requester_id=auth.uid() or recipient_id=auth.uid());

create table if not exists public.concord_presence (
 user_id uuid primary key references auth.users(id) on delete cascade,
 last_seen timestamptz not null default now()
);
alter table public.concord_presence enable row level security;
drop policy if exists "presence update own" on public.concord_presence;
create policy "presence update own" on public.concord_presence for insert to authenticated with check (user_id=auth.uid());
drop policy if exists "presence refresh own" on public.concord_presence;
create policy "presence refresh own" on public.concord_presence for update to authenticated using (user_id=auth.uid()) with check (user_id=auth.uid());
drop policy if exists "presence read friends" on public.concord_presence;
create policy "presence read friends" on public.concord_presence for select to authenticated using (
 user_id=auth.uid() or exists(
 select 1 from public.concord_friend_requests f
 where f.status='accepted' and
 ((f.requester_id=auth.uid() and f.recipient_id=user_id) or (f.recipient_id=auth.uid() and f.requester_id=user_id))
 )
);
-- Nota: executar apenas uma vez; a interface consulta por polling, sem publicacao Realtime.

-- Evita que o destinatario altere requester_id/recipient_id durante a aceitacao.
revoke update on public.concord_friend_requests from authenticated;
grant update (status) on public.concord_friend_requests to authenticated;
