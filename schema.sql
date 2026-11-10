-- LynxHub schema (v2). Paste ALL of this into Supabase > SQL Editor > Run. Safe to run on a fresh project.
create extension if not exists pg_trgm;

create table profiles(
  id uuid primary key references auth.users on delete cascade,
  email text, name text,
  role text not null default 'vendor' check (role in ('vendor','pro','admin')),
  pro_code text unique, referred_by text,
  created_at timestamptz default now());

create table listings(
  id uuid primary key default gen_random_uuid(),
  vendor_id uuid, pro_id uuid,
  title text not null, brand text not null, cat text not null,
  hub text not null check (hub in ('tech','micro')),
  price numeric not null check (price > 0), cond text, neg boolean default false,
  status text not null default 'live' check (status in ('live','sold','removed')),
  spot text, img text, clicks int not null default 0, ts timestamptz default now());
alter table listings add column vendor uuid generated always as (vendor_id) stored;
alter table listings add column pro    uuid generated always as (pro_id)    stored;

create table listing_contacts(listing_id uuid primary key references listings on delete cascade, wa text not null);
create table settings(key text primary key, value jsonb not null);

create index on listings (hub, status, cat, ts desc);
create index on listings (brand);
create index on listings (price);
create index on listings using gin (lower(title) gin_trgm_ops);
create index on profiles (referred_by);

-- helper functions (security definer = no RLS recursion)
create function my_role() returns text language sql stable security definer set search_path=public as $$ select role from profiles where id=auth.uid() $$;
create function my_code() returns text language sql stable security definer set search_path=public as $$ select pro_code from profiles where id=auth.uid() $$;
create function is_staff() returns boolean language sql stable security definer set search_path=public as $$ select coalesce(my_role() in ('pro','admin'),false) $$;
create function is_admin() returns boolean language sql stable security definer set search_path=public as $$ select coalesce(my_role()='admin',false) $$;

create function new_user() returns trigger language plpgsql security definer set search_path=public as $$
begin insert into profiles(id,email,name,pro_code)
  values(new.id,new.email,coalesce(new.raw_user_meta_data->>'full_name',new.email),upper(substr(md5(new.id::text),1,6)));
  return new; end $$;
create trigger on_signup after insert on auth.users for each row execute function new_user();

-- buyer taps WhatsApp: returns the number and counts the click
create function contact_listing(lid uuid) returns text language plpgsql security definer set search_path=public as $$
declare n text; begin
  select wa into n from listing_contacts where listing_id=lid;
  update listings set clicks=clicks+1 where id=lid and status='live'; return n; end $$;

create function make_pro(p_email text) returns boolean language plpgsql security definer set search_path=public as $$
begin if not is_admin() then raise exception 'Admins only'; end if;
  update profiles set role='pro' where lower(email)=lower(p_email); return found; end $$;

alter table profiles enable row level security;
alter table listings enable row level security;
alter table listing_contacts enable row level security;
alter table settings enable row level security;

create policy "see profiles" on profiles for select using (id=auth.uid() or is_admin() or (is_staff() and referred_by=my_code()));
create policy "edit own profile" on profiles for update using (id=auth.uid()) with check (role=my_role());
create policy "browse" on listings for select using (status<>'removed' or vendor_id=auth.uid() or is_staff());
create policy "post" on listings for insert with check (auth.uid() is not null and (vendor_id=auth.uid() or pro_id=auth.uid()));
create policy "manage" on listings for update using (vendor_id=auth.uid() or is_staff());
create policy "add contact" on listing_contacts for insert with check (exists(select 1 from listings l where l.id=listing_id and (l.vendor_id=auth.uid() or l.pro_id=auth.uid())));
create policy "read contact" on listing_contacts for select using (is_staff() or exists(select 1 from listings l where l.id=listing_id and l.vendor_id=auth.uid()));
create policy "site read" on settings for select using (true);
create policy "site write" on settings for insert with check (is_admin());
create policy "site edit" on settings for update using (is_admin());

-- photo bucket (public read) + upload only into your own folder
insert into storage.buckets(id,name,public) values('listings','listings',true) on conflict do nothing;
create policy "upload own" on storage.objects for insert to authenticated
  with check (bucket_id='listings' and (storage.foldername(name))[1]=auth.uid()::text);

-- AFTER your first Google sign-in, make yourself CEO (use your email):
-- update profiles set role='admin' where email='you@gmail.com';
