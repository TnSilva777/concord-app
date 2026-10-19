-- CONCORD: correcao das permissoes de acesso ao painel Amigos.
-- Executar no SQL Editor do projeto concord-app.
-- Nao remove tabelas, registros nem politicas RLS existentes.
grant usage on schema public to authenticated;
grant select, insert, delete on table public.concord_friend_requests to authenticated;
grant update (status) on table public.concord_friend_requests to authenticated;
grant select, insert, update on table public.concord_presence to authenticated;
grant select, insert, delete on table public.concord_voice_rooms to authenticated;
-- As politicas RLS continuam restringindo quem pode ler, inserir, atualizar ou excluir cada registro.
