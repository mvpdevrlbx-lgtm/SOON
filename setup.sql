-- NOCTA RP — setup complémentaire
-- À exécuter dans Supabase SQL Editor APRÈS ton schéma actuel.
-- Cette version ajoute le lien whitelist -> profil vérifié,
-- le système vidéo et la fonction admin sécurisée.

create table if not exists public.videos (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  title text not null,
  file_path text not null,
  public_url text not null,
  status text not null default 'pending' check (status in ('pending','approved','rejected')),
  created_at timestamptz not null default now()
);

alter table public.videos enable row level security;

drop policy if exists "videos_public_approved" on public.videos;
create policy "videos_public_approved"
on public.videos for select
to anon, authenticated
using (status = 'approved' or public.is_admin() or auth.uid() = user_id);

drop policy if exists "videos_insert_own" on public.videos;
create policy "videos_insert_own"
on public.videos for insert
to authenticated
with check (auth.uid() = user_id);

drop policy if exists "videos_admin_update" on public.videos;
create policy "videos_admin_update"
on public.videos for update
to authenticated
using (public.is_admin())
with check (public.is_admin());

drop policy if exists "videos_admin_delete" on public.videos;
create policy "videos_admin_delete"
on public.videos for delete
to authenticated
using (public.is_admin());

create or replace function public.admin_set_verification(p_id uuid, p_status text)
returns void
language plpgsql
security definer
set search_path=public
as $$
declare v_user uuid;
begin
  if not public.is_admin() then
    raise exception 'not authorized';
  end if;

  if p_status not in ('verified','rejected') then
    raise exception 'invalid status';
  end if;

  select user_id into v_user
  from public.verification_requests
  where id=p_id;

  if v_user is null then
    raise exception 'request not found';
  end if;

  update public.verification_requests
  set status=p_status,
      verified_at=case when p_status='verified' then now() else null end
  where id=p_id;

  update public.profiles
  set status=p_status,
      updated_at=now()
  where id=v_user;
end;
$$;

grant execute on function public.admin_set_verification(uuid,text) to authenticated;

-- Bucket vidéo :
-- Crée dans Supabase Storage un bucket PUBLIC nommé exactement : rp-videos
-- Puis ajoute ces policies Storage :

drop policy if exists "rp_videos_upload_own" on storage.objects;
create policy "rp_videos_upload_own"
on storage.objects for insert
to authenticated
with check (
  bucket_id = 'rp-videos'
  and (storage.foldername(name))[1] = auth.uid()::text
);

drop policy if exists "rp_videos_read_public" on storage.objects;
create policy "rp_videos_read_public"
on storage.objects for select
to public
using (bucket_id = 'rp-videos');

drop policy if exists "rp_videos_delete_admin" on storage.objects;
create policy "rp_videos_delete_admin"
on storage.objects for delete
to authenticated
using (bucket_id='rp-videos' and public.is_admin());
