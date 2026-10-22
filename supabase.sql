-- =====================================================================
--  Zero X Sient · Pago Fácil — Esquema de Supabase
--  Pegar TODO esto en: Supabase → SQL Editor → New query → Run
-- =====================================================================

-- ---------- TABLAS ----------

create table if not exists public.profiles (
  id          uuid primary key references auth.users(id) on delete cascade,
  dni         text unique not null,
  nombre      text,
  is_admin    boolean not null default false,
  created_at  timestamptz not null default now()
);

create table if not exists public.tramites (
  id          uuid primary key default gen_random_uuid(),
  nombre      text not null,
  descripcion text,
  imagen_url  text,
  activo      boolean not null default true,
  orden       int not null default 0,
  created_at  timestamptz not null default now()
);

create table if not exists public.carpetas (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null default auth.uid() references auth.users(id) on delete cascade,
  empresa     text not null,
  created_at  timestamptz not null default now()
);

create table if not exists public.carpeta_datos (
  id          uuid primary key default gen_random_uuid(),
  carpeta_id  uuid not null references public.carpetas(id) on delete cascade,
  user_id     uuid not null default auth.uid() references auth.users(id) on delete cascade,
  etiqueta    text not null,
  valor       text not null default '',
  created_at  timestamptz not null default now()
);

create index if not exists carpetas_user_idx       on public.carpetas(user_id);
create index if not exists carpeta_datos_carp_idx  on public.carpeta_datos(carpeta_id);

-- ---------- FUNCIÓN: ¿es admin? ----------

create or replace function public.is_admin()
returns boolean
language sql
security definer
set search_path = public
stable
as $$
  select coalesce((select is_admin from public.profiles where id = auth.uid()), false);
$$;

-- ---------- TRIGGER: crear perfil al registrarse ----------

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, dni, nombre)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'dni', split_part(new.email, '@', 1)),
    new.raw_user_meta_data->>'nombre'
  );
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ---------- RLS (seguridad por fila) ----------

alter table public.profiles       enable row level security;
alter table public.tramites       enable row level security;
alter table public.carpetas       enable row level security;
alter table public.carpeta_datos  enable row level security;

-- profiles: cada uno ve el suyo; admins ven todos. Nadie edita is_admin desde la web.
drop policy if exists "profiles_select" on public.profiles;
create policy "profiles_select" on public.profiles
  for select using (id = auth.uid() or public.is_admin());

-- tramites: cualquiera ve los activos (landing pública); admins ven y gestionan todos
drop policy if exists "tramites_select" on public.tramites;
create policy "tramites_select" on public.tramites
  for select using (activo = true or public.is_admin());

drop policy if exists "tramites_admin_insert" on public.tramites;
create policy "tramites_admin_insert" on public.tramites
  for insert with check (public.is_admin());

drop policy if exists "tramites_admin_update" on public.tramites;
create policy "tramites_admin_update" on public.tramites
  for update using (public.is_admin()) with check (public.is_admin());

drop policy if exists "tramites_admin_delete" on public.tramites;
create policy "tramites_admin_delete" on public.tramites
  for delete using (public.is_admin());

-- carpetas: solo el dueño
drop policy if exists "carpetas_owner" on public.carpetas;
create policy "carpetas_owner" on public.carpetas
  for all using (user_id = auth.uid()) with check (user_id = auth.uid());

-- carpeta_datos: solo el dueño
drop policy if exists "carpeta_datos_owner" on public.carpeta_datos;
create policy "carpeta_datos_owner" on public.carpeta_datos
  for all using (user_id = auth.uid()) with check (user_id = auth.uid());

-- ---------- STORAGE: imágenes de trámites ----------

insert into storage.buckets (id, name, public)
values ('tramites', 'tramites', true)
on conflict (id) do nothing;

drop policy if exists "tramites_img_read" on storage.objects;
create policy "tramites_img_read" on storage.objects
  for select using (bucket_id = 'tramites');

drop policy if exists "tramites_img_admin_insert" on storage.objects;
create policy "tramites_img_admin_insert" on storage.objects
  for insert with check (bucket_id = 'tramites' and public.is_admin());

drop policy if exists "tramites_img_admin_update" on storage.objects;
create policy "tramites_img_admin_update" on storage.objects
  for update using (bucket_id = 'tramites' and public.is_admin());

drop policy if exists "tramites_img_admin_delete" on storage.objects;
create policy "tramites_img_admin_delete" on storage.objects
  for delete using (bucket_id = 'tramites' and public.is_admin());

-- ---------- TRÁMITES DE EJEMPLO (opcional, podés borrarlos desde el panel) ----------

insert into public.tramites (nombre, descripcion, orden) values
  ('Luz (EDEN)',               'Pago de facturas de energía eléctrica', 1),
  ('Gas (Litoral Gas)',        'Pago de facturas de gas natural',       2),
  ('Tasas municipales',        'Municipalidad de San Nicolás',          3),
  ('ARBA',                     'Impuesto inmobiliario y automotor',     4),
  ('Recargas',                 'Celular y SUBE',                        5),
  ('Cobro de servicios',       'Cable, internet, seguros y más',        6)
on conflict do nothing;

-- =====================================================================
--  DESPUÉS DE REGISTRARTE EN LA APP CON TU DNI, hacete admin con esto
--  (reemplazá 12345678 por tu DNI):
--
--    update public.profiles set is_admin = true where dni = '12345678';
--
-- =====================================================================
