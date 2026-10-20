-- CONCORD: recover missing public display names from existing Auth metadata.
-- Run AFTER concord-public-profiles.sql in the Supabase SQL Editor.
-- Never derives a public name from email; existing chosen public names are preserved.
insert into public.concord_public_profiles (user_id, display_name, updated_at)
select u.id, left(names.chosen_name,28), now()
from auth.users u
cross join lateral (
 select coalesce(
   nullif(btrim(u.raw_user_meta_data->'concord_profile'->>'name'),''),
   nullif(btrim(u.raw_user_meta_data->>'display_name'),''),
   nullif(btrim(u.raw_user_meta_data->>'full_name'),''),
   nullif(btrim(u.raw_user_meta_data->>'name'),'')
 ) as chosen_name
) names
where names.chosen_name is not null
  and char_length(btrim(names.chosen_name))>0
on conflict (user_id) do nothing;

-- Aggregated diagnostics, no emails or user identifiers.
select
 (select count(*) from auth.users) as total_accounts,
 (select count(*) from public.concord_public_profiles) as public_names,
 (select count(*) from storage.objects where bucket_id='concord-avatars') as uploaded_avatars,
 (select count(*) from auth.users u where not exists (
    select 1 from public.concord_public_profiles p where p.user_id=u.id
 )) as accounts_missing_public_name;
