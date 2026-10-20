-- CONCORD: execute in Supabase SQL Editor after concord-public-profiles.sql.
-- Public avatars, but only the account owner may upload, overwrite or delete.
insert into storage.buckets (id,name,public,file_size_limit,allowed_mime_types)
values ('concord-avatars','concord-avatars',true,5242880,array['image/jpeg'])
on conflict (id) do update set public=true,file_size_limit=5242880,allowed_mime_types=array['image/jpeg'];

drop policy if exists "CONCORD avatar public read" on storage.objects;
create policy "CONCORD avatar public read"
on storage.objects for select to public
using (bucket_id='concord-avatars');

drop policy if exists "CONCORD avatar own insert" on storage.objects;
create policy "CONCORD avatar own insert"
on storage.objects for insert to authenticated
with check (
 bucket_id='concord-avatars'
 and (storage.foldername(name))[1]=(select auth.uid())::text
 and name=(select auth.uid())::text||'/avatar.jpg'
);

drop policy if exists "CONCORD avatar own update" on storage.objects;
create policy "CONCORD avatar own update"
on storage.objects for update to authenticated
using (bucket_id='concord-avatars' and name=(select auth.uid())::text||'/avatar.jpg')
with check (bucket_id='concord-avatars' and name=(select auth.uid())::text||'/avatar.jpg');

drop policy if exists "CONCORD avatar own delete" on storage.objects;
create policy "CONCORD avatar own delete"
on storage.objects for delete to authenticated
using (bucket_id='concord-avatars' and name=(select auth.uid())::text||'/avatar.jpg');
