-- CONCORD: canais públicos oficiais (visíveis a todos os usuários autenticados).
-- Não inclui comunidades privadas; estas precisarão de políticas por membro.
create table if not exists public.concord_public_messages (
  id uuid primary key default gen_random_uuid(),
  channel text not null check (channel in ('geral','regras','anuncios','jogos','tecnologia','memes')),
  author_id uuid not null references auth.users(id) on delete cascade,
  author_name text not null check (char_length(author_name) between 1 and 60),
  body text not null check (char_length(trim(body)) between 1 and 2000),
  created_at timestamptz not null default now()
);
create index if not exists concord_public_messages_channel_time_idx on public.concord_public_messages(channel,created_at desc);
alter table public.concord_public_messages enable row level security;
drop policy if exists "public channels read" on public.concord_public_messages;
create policy "public channels read" on public.concord_public_messages for select to authenticated using (true);
drop policy if exists "public channels send own" on public.concord_public_messages;
create policy "public channels send own" on public.concord_public_messages for insert to authenticated with check (author_id=auth.uid());
grant select, insert on public.concord_public_messages to authenticated;
-- Não conceder UPDATE/DELETE ao cliente nesta fase.
