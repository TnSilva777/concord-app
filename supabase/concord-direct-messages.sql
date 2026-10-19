-- CONCORD: mensagens diretas entre amigos aceitos.
-- Executar no SQL Editor do Supabase antes de usar a aba Conversas privadas.
create table if not exists public.concord_direct_messages (
 id uuid primary key default gen_random_uuid(),
 sender_id uuid not null references auth.users(id) on delete cascade,
 recipient_id uuid not null references auth.users(id) on delete cascade,
 body text not null check (char_length(trim(body)) between 1 and 2000),
 created_at timestamptz not null default now(),
 check (sender_id <> recipient_id)
);
create index if not exists concord_dm_sender_idx on public.concord_direct_messages(sender_id,recipient_id,created_at desc);
create index if not exists concord_dm_recipient_idx on public.concord_direct_messages(recipient_id,sender_id,created_at desc);
alter table public.concord_direct_messages enable row level security;
drop policy if exists "dm read accepted friends" on public.concord_direct_messages;
create policy "dm read accepted friends" on public.concord_direct_messages for select to authenticated
using (
 (sender_id=auth.uid() or recipient_id=auth.uid())
 and exists (
  select 1 from public.concord_friend_requests f
  where f.status='accepted'
  and ((f.requester_id=sender_id and f.recipient_id=recipient_id)
    or (f.requester_id=recipient_id and f.recipient_id=sender_id))
 )
);
drop policy if exists "dm send accepted friends" on public.concord_direct_messages;
create policy "dm send accepted friends" on public.concord_direct_messages for insert to authenticated
with check (
 sender_id=auth.uid()
 and exists (
  select 1 from public.concord_friend_requests f
  where f.status='accepted'
  and ((f.requester_id=sender_id and f.recipient_id=recipient_id)
    or (f.requester_id=recipient_id and f.recipient_id=sender_id))
 )
);
grant select, insert on public.concord_direct_messages to authenticated;
-- Sem politicas de UPDATE ou DELETE: mensagens nao podem ser editadas/apagadas pelo cliente nesta fase.
