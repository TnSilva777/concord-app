-- CONCORD: armazenamento de fotos de perfil.
-- Execute uma vez no SQL Editor do Supabase.
insert into storage.buckets (id,name,public,file_size_limit,allowed_mime_types)
values ('concord-avatars','concord-avatars',true,1048576,array['image/jpeg'])
on conflict (id) do update set public=true,file_size_limit=1048576,allowed_mime_types=array['image/jpeg'];
drop policy if exists "concord avatars upload own" on storage.objects;
create policy "concord avatars upload own" on storage.objects for insert to authenticated
with check (bucket_id='concord-avatars' and name=auth.uid()::text||'/avatar.jpg');
drop policy if exists "concord avatars update own" on storage.objects;
create policy "concord avatars update own" on storage.objects for update to authenticated
using (bucket_id='concord-avatars' and name=auth.uid()::text||'/avatar.jpg')
with check (bucket_id='concord-avatars' and name=auth.uid()::text||'/avatar.jpg');
drop policy if exists "concord avatars delete own" on storage.objects;
create policy "concord avatars delete own" on storage.objects for delete to authenticated
using (bucket_id='concord-avatars' and name=auth.uid()::text||'/avatar.jpg');
-- Bucket publico: fotos acessiveis por URL, nunca envie imagens confidenciais.
