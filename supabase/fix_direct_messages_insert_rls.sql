-- CONCORD: ajuste seguro de INSERT para mensagens privadas.
-- Execute no SQL Editor do Supabase do projeto correto.
-- Esta migração NÃO desativa RLS e não concede acesso público.
-- Remetente deve ser o usuário autenticado e destinatário deve ser amigo aceito.
begin;
alter table public.concord_direct_messages enable row level security;
drop policy if exists "concord_dm_insert_accepted_friends" on public.concord_direct_messages;
create policy "concord_dm_insert_accepted_friends"
on public.concord_direct_messages
for insert
to authenticated
with check (
  sender_id = (select auth.uid())
  and recipient_id <> (select auth.uid())
  and exists (
    select 1
    from public.concord_friend_requests f
    where f.status = 'accepted'
      and (
        (f.requester_id = sender_id and f.recipient_id = recipient_id)
        or
        (f.recipient_id = sender_id and f.requester_id = recipient_id)
      )
  )
);
commit;
-- Caso continue bloqueado, confira o UID da sessão e as policies existentes.
-- Não use USING(true), WITH CHECK(true) nem desative RLS.
