-- Before running this script:
-- 1. In Supabase Dashboard > Authentication > Third-Party Auth, add your Firebase project.
-- 2. Deploy the Firebase callable function from functions/:
--      firebase deploy --only functions:ensureSupabaseRole --project campusmate-78a20
--    The dashboard calls it for the signed-in user and refreshes the Firebase ID token.
--    It sets role="authenticated" with the Firebase Admin SDK while preserving other claims.
--    Cloud Functions deployment requires the Firebase project to use the Blaze plan.
--    Alternatively, set this claim manually from a trusted Admin SDK environment:
--      const user = await getAuth().getUser(uid);
--      await getAuth().setCustomUserClaims(uid, {
--        ...user.customClaims,
--        role: 'authenticated',
--      });
-- 3. Run this SQL in the Supabase SQL Editor.
-- 4. This app stores files at users/<Firebase UID>/pdfs/<filename>.

insert into storage.buckets (id, name, public, file_size_limit)
values ('campusmate-files', 'campusmate-files', false, 10485760)
on conflict (id) do update
set public = false,
    file_size_limit = excluded.file_size_limit;

drop policy if exists "CampusMate users can read their files" on storage.objects;
create policy "CampusMate users can read their files"
on storage.objects
for select
to authenticated
using (
  bucket_id = 'campusmate-files'
  and (storage.foldername(name))[1] = 'users'
  and (storage.foldername(name))[2] = (select auth.jwt() ->> 'sub')
  and (storage.foldername(name))[3] = 'pdfs'
);

drop policy if exists "CampusMate users can upload their files" on storage.objects;
create policy "CampusMate users can upload their files"
on storage.objects
for insert
to authenticated
with check (
  bucket_id = 'campusmate-files'
  and (storage.foldername(name))[1] = 'users'
  and (storage.foldername(name))[2] = (select auth.jwt() ->> 'sub')
  and (storage.foldername(name))[3] = 'pdfs'
);

drop policy if exists "CampusMate users can delete their files" on storage.objects;
create policy "CampusMate users can delete their files"
on storage.objects
for delete
to authenticated
using (
  bucket_id = 'campusmate-files'
  and (storage.foldername(name))[1] = 'users'
  and (storage.foldername(name))[2] = (select auth.jwt() ->> 'sub')
  and (storage.foldername(name))[3] = 'pdfs'
);
