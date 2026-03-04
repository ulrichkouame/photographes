-- Migration initiale : tables principales de Photographes.ci
-- Créée le 2026-03-04

-- Extension UUID
create extension if not exists "uuid-ossp";

-- Table des profils utilisateurs
create table if not exists public.photographes_profiles (
  id uuid references auth.users on delete cascade primary key,
  full_name text,
  avatar_url text,
  role text not null default 'client' check (role in ('client', 'photographer', 'admin')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Table des photographes
create table if not exists public.photographes_photographers (
  id uuid primary key default uuid_generate_v4(),
  profile_id uuid references public.photographes_profiles(id) on delete cascade not null,
  bio text,
  city text,
  specialties text[],
  price_per_hour numeric(10, 2),
  is_available boolean not null default true,
  created_at timestamptz not null default now()
);

-- Table des réservations
create table if not exists public.photographes_bookings (
  id uuid primary key default uuid_generate_v4(),
  client_id uuid references public.photographes_profiles(id) on delete set null,
  photographer_id uuid references public.photographes_photographers(id) on delete set null,
  event_date date not null,
  duration_hours numeric(4, 1) not null,
  status text not null default 'pending' check (status in ('pending', 'confirmed', 'cancelled', 'completed')),
  total_price numeric(10, 2),
  notes text,
  created_at timestamptz not null default now()
);

-- RLS
alter table public.photographes_profiles enable row level security;
alter table public.photographes_photographers enable row level security;
alter table public.photographes_bookings enable row level security;

-- Politiques RLS basiques
create policy "Les utilisateurs voient leur propre profil"
  on public.photographes_profiles for select using (auth.uid() = id);

create policy "Les utilisateurs modifient leur propre profil"
  on public.photographes_profiles for update using (auth.uid() = id);

create policy "Les photographes sont publics"
  on public.photographes_photographers for select using (true);

create policy "Les réservations appartiennent au client"
  on public.photographes_bookings for all using (auth.uid() = client_id);
