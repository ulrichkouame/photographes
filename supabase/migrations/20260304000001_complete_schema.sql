-- Migration : schéma complet Photographes.ci
-- Tables manquantes + colonnes étendues + RLS complet
-- Créée le 2026-03-04

-- ─────────────────────────────────────────────────────────────────────────────
-- 1. Mise à jour table bookings (aligner sur le modèle Flutter BookingModel)
-- ─────────────────────────────────────────────────────────────────────────────
alter table public.bookings
  add column if not exists service_type  text,
  add column if not exists location      text,
  add column if not exists message       text,
  add column if not exists contact_cost  numeric(10, 2) not null default 0,
  add column if not exists updated_at    timestamptz not null default now();

-- Mettre à jour la contrainte de statut pour les statuts français
alter table public.bookings
  drop constraint if exists bookings_status_check;
alter table public.bookings
  add constraint bookings_status_check
  check (status in ('en_attente', 'accepte', 'refuse', 'termine', 'annule', 'pending', 'confirmed', 'cancelled', 'completed'));

-- ─────────────────────────────────────────────────────────────────────────────
-- 2. Table portfolio_photos
-- ─────────────────────────────────────────────────────────────────────────────
create table if not exists public.portfolio_photos (
  id               uuid primary key default uuid_generate_v4(),
  photographer_id  uuid references public.photographers(id) on delete cascade not null,
  url              text not null,
  caption          text,
  category         text,
  is_cover         boolean not null default false,
  sort_order       int not null default 0,
  created_at       timestamptz not null default now()
);

alter table public.portfolio_photos enable row level security;

create policy "Les photos de portfolio sont publiques"
  on public.portfolio_photos for select using (true);

create policy "Le photographe gère ses photos"
  on public.portfolio_photos for all
  using (
    auth.uid() = (
      select profile_id from public.photographers where id = photographer_id
    )
  );

-- ─────────────────────────────────────────────────────────────────────────────
-- 3. Table reviews (avis clients)
-- ─────────────────────────────────────────────────────────────────────────────
create table if not exists public.reviews (
  id               uuid primary key default uuid_generate_v4(),
  booking_id       uuid references public.bookings(id) on delete cascade not null,
  client_id        uuid references public.profiles(id) on delete cascade not null,
  photographer_id  uuid references public.photographers(id) on delete cascade not null,
  rating           numeric(2, 1) not null check (rating >= 1 and rating <= 5),
  comment          text,
  created_at       timestamptz not null default now(),
  unique (booking_id)
);

alter table public.reviews enable row level security;

create policy "Les avis sont publics"
  on public.reviews for select using (true);

create policy "Les clients publient leurs avis"
  on public.reviews for insert
  with check (auth.uid() = client_id);

create policy "Les clients modifient leurs avis"
  on public.reviews for update
  using (auth.uid() = client_id);

-- ─────────────────────────────────────────────────────────────────────────────
-- 4. Table chat_rooms (conversations)
-- ─────────────────────────────────────────────────────────────────────────────
create table if not exists public.chat_rooms (
  id               uuid primary key default uuid_generate_v4(),
  booking_id       uuid references public.bookings(id) on delete cascade,
  client_id        uuid references public.profiles(id) on delete cascade not null,
  photographer_id  uuid references public.profiles(id) on delete cascade not null,
  created_at       timestamptz not null default now(),
  unique (client_id, photographer_id)
);

alter table public.chat_rooms enable row level security;

create policy "Les participants voient la salle"
  on public.chat_rooms for select
  using (auth.uid() = client_id or auth.uid() = photographer_id);

-- ─────────────────────────────────────────────────────────────────────────────
-- 5. Table messages (chat temps réel)
-- ─────────────────────────────────────────────────────────────────────────────
create table if not exists public.messages (
  id          uuid primary key default uuid_generate_v4(),
  room_id     uuid references public.chat_rooms(id) on delete cascade not null,
  sender_id   uuid references public.profiles(id) on delete cascade not null,
  content     text not null,
  is_read     boolean not null default false,
  created_at  timestamptz not null default now()
);

alter table public.messages enable row level security;

create policy "Les participants lisent les messages"
  on public.messages for select
  using (
    auth.uid() in (
      select client_id from public.chat_rooms where id = room_id
      union
      select photographer_id from public.chat_rooms where id = room_id
    )
  );

create policy "L'expéditeur envoie les messages"
  on public.messages for insert
  with check (auth.uid() = sender_id);

create policy "L'expéditeur marque comme lu"
  on public.messages for update
  using (
    auth.uid() in (
      select client_id from public.chat_rooms where id = room_id
      union
      select photographer_id from public.chat_rooms where id = room_id
    )
  );

-- Activer realtime sur messages
alter publication supabase_realtime add table public.messages;

-- ─────────────────────────────────────────────────────────────────────────────
-- 6. Table payments (paiements via Orange Money / MTN MoMo)
-- ─────────────────────────────────────────────────────────────────────────────
create table if not exists public.payments (
  id              uuid primary key default uuid_generate_v4(),
  booking_id      uuid references public.bookings(id) on delete set null,
  client_id       uuid references public.profiles(id) on delete set null,
  amount          numeric(12, 2) not null,
  currency        text not null default 'XOF',
  operator        text not null check (operator in ('orange_money', 'mtn_momo', 'wave', 'cinetpay', 'card')),
  phone_number    text,
  status          text not null default 'pending' check (status in ('pending', 'processing', 'completed', 'failed', 'refunded')),
  transaction_id  text,
  provider_ref    text,
  metadata        jsonb,
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now()
);

alter table public.payments enable row level security;

create policy "Les clients voient leurs paiements"
  on public.payments for select
  using (auth.uid() = client_id);

create policy "Service role gère les paiements"
  on public.payments for all
  using (auth.role() = 'service_role');

-- ─────────────────────────────────────────────────────────────────────────────
-- 7. Table services (offres des photographes)
-- ─────────────────────────────────────────────────────────────────────────────
create table if not exists public.services (
  id               uuid primary key default uuid_generate_v4(),
  photographer_id  uuid references public.photographers(id) on delete cascade not null,
  name             text not null,
  description      text,
  price            numeric(10, 2) not null,
  duration_hours   numeric(4, 1),
  is_active        boolean not null default true,
  created_at       timestamptz not null default now(),
  updated_at       timestamptz not null default now()
);

alter table public.services enable row level security;

create policy "Les services actifs sont publics"
  on public.services for select using (is_active = true);

create policy "Le photographe gère ses services"
  on public.services for all
  using (
    auth.uid() = (
      select profile_id from public.photographers where id = photographer_id
    )
  );

-- ─────────────────────────────────────────────────────────────────────────────
-- 8. Table subscriptions (abonnements photographes)
-- ─────────────────────────────────────────────────────────────────────────────
create table if not exists public.subscriptions (
  id               uuid primary key default uuid_generate_v4(),
  photographer_id  uuid references public.photographers(id) on delete cascade not null,
  plan             text not null default 'free' check (plan in ('free', 'starter', 'pro', 'premium')),
  status           text not null default 'active' check (status in ('active', 'expired', 'cancelled')),
  started_at       timestamptz not null default now(),
  expires_at       timestamptz,
  monthly_price    numeric(10, 2) not null default 0,
  features         jsonb not null default '{}',
  payment_id       uuid references public.payments(id) on delete set null,
  created_at       timestamptz not null default now()
);

alter table public.subscriptions enable row level security;

create policy "Le photographe voit son abonnement"
  on public.subscriptions for select
  using (
    auth.uid() = (
      select profile_id from public.photographers where id = photographer_id
    )
  );

-- ─────────────────────────────────────────────────────────────────────────────
-- 9. Table notifications
-- ─────────────────────────────────────────────────────────────────────────────
create table if not exists public.notifications (
  id         uuid primary key default uuid_generate_v4(),
  user_id    uuid references public.profiles(id) on delete cascade not null,
  type       text not null,               -- 'booking_request', 'booking_accepted', 'message', 'payment', 'review'
  title      text not null,
  body       text,
  data       jsonb,
  is_read    boolean not null default false,
  created_at timestamptz not null default now()
);

alter table public.notifications enable row level security;

create policy "L'utilisateur voit ses notifications"
  on public.notifications for select
  using (auth.uid() = user_id);

create policy "L'utilisateur marque ses notifications lues"
  on public.notifications for update
  using (auth.uid() = user_id);

-- Activer realtime sur notifications
alter publication supabase_realtime add table public.notifications;

-- ─────────────────────────────────────────────────────────────────────────────
-- 10. Table app_settings (paramètres de l'app par utilisateur)
-- ─────────────────────────────────────────────────────────────────────────────
create table if not exists public.app_settings (
  user_id             uuid references public.profiles(id) on delete cascade primary key,
  language            text not null default 'fr',
  dark_mode           boolean not null default false,
  notifications_push  boolean not null default true,
  notifications_email boolean not null default true,
  notifications_sms   boolean not null default false,
  currency            text not null default 'XOF',
  updated_at          timestamptz not null default now()
);

alter table public.app_settings enable row level security;

create policy "L'utilisateur gère ses paramètres"
  on public.app_settings for all
  using (auth.uid() = user_id);

-- ─────────────────────────────────────────────────────────────────────────────
-- 11. Table availability (disponibilités photographes)
-- ─────────────────────────────────────────────────────────────────────────────
create table if not exists public.availability (
  id               uuid primary key default uuid_generate_v4(),
  photographer_id  uuid references public.photographers(id) on delete cascade not null,
  date             date not null,
  is_available     boolean not null default true,
  slots_remaining  int not null default 1 check (slots_remaining >= 0),
  note             text,
  unique (photographer_id, date)
);

alter table public.availability enable row level security;

create policy "Les disponibilités sont publiques"
  on public.availability for select using (true);

create policy "Le photographe gère ses disponibilités"
  on public.availability for all
  using (
    auth.uid() = (
      select profile_id from public.photographers where id = photographer_id
    )
  );

-- ─────────────────────────────────────────────────────────────────────────────
-- 12. Table otp_verifications (vérification OTP WhatsApp)
-- ─────────────────────────────────────────────────────────────────────────────
create table if not exists public.otp_verifications (
  id           uuid primary key default uuid_generate_v4(),
  phone        text not null,
  otp_hash     text not null,
  attempts     int not null default 0,
  verified     boolean not null default false,
  expires_at   timestamptz not null,
  created_at   timestamptz not null default now()
);

alter table public.otp_verifications enable row level security;

create policy "Service role gère les OTP"
  on public.otp_verifications for all
  using (auth.role() = 'service_role');

-- ─────────────────────────────────────────────────────────────────────────────
-- 13. Triggers updated_at automatiques
-- ─────────────────────────────────────────────────────────────────────────────
create or replace function public.handle_updated_at()
  returns trigger language plpgsql as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

create trigger on_bookings_updated
  before update on public.bookings
  for each row execute function public.handle_updated_at();

create trigger on_payments_updated
  before update on public.payments
  for each row execute function public.handle_updated_at();

create trigger on_services_updated
  before update on public.services
  for each row execute function public.handle_updated_at();

create trigger on_settings_updated
  before update on public.app_settings
  for each row execute function public.handle_updated_at();

-- ─────────────────────────────────────────────────────────────────────────────
-- 14. Trigger : créer les settings par défaut à l'inscription
-- ─────────────────────────────────────────────────────────────────────────────
create or replace function public.handle_new_user()
  returns trigger language plpgsql security definer as $$
begin
  insert into public.profiles (id, full_name, avatar_url)
  values (
    new.id,
    new.raw_user_meta_data->>'full_name',
    new.raw_user_meta_data->>'avatar_url'
  )
  on conflict (id) do nothing;

  insert into public.app_settings (user_id)
  values (new.id)
  on conflict (user_id) do nothing;

  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ─────────────────────────────────────────────────────────────────────────────
-- 15. Index pour les performances
-- ─────────────────────────────────────────────────────────────────────────────
create index if not exists idx_bookings_client_id        on public.bookings(client_id);
create index if not exists idx_bookings_photographer_id  on public.bookings(photographer_id);
create index if not exists idx_bookings_status           on public.bookings(status);
create index if not exists idx_bookings_date             on public.bookings(event_date);
create index if not exists idx_photographers_city        on public.photographers(city);
create index if not exists idx_photographers_available   on public.photographers(is_available);
create index if not exists idx_portfolio_photographer    on public.portfolio_photos(photographer_id);
create index if not exists idx_reviews_photographer      on public.reviews(photographer_id);
create index if not exists idx_messages_room_id          on public.messages(room_id);
create index if not exists idx_messages_sender_id        on public.messages(sender_id);
create index if not exists idx_messages_created_at       on public.messages(created_at desc);
create index if not exists idx_notifications_user_id     on public.notifications(user_id);
create index if not exists idx_notifications_unread      on public.notifications(user_id) where is_read = false;
create index if not exists idx_availability_photographer on public.availability(photographer_id);
create index if not exists idx_availability_date         on public.availability(date);
create index if not exists idx_services_photographer     on public.services(photographer_id);
create index if not exists idx_payments_booking_id       on public.payments(booking_id);
create index if not exists idx_payments_client_id        on public.payments(client_id);

-- ─────────────────────────────────────────────────────────────────────────────
-- 16. Vue agrégée : profil complet photographe
-- ─────────────────────────────────────────────────────────────────────────────
create or replace view public.photographer_profiles as
  select
    p.id,
    p.profile_id,
    pr.full_name,
    pr.avatar_url,
    p.bio,
    p.city,
    p.specialties,
    p.price_per_hour,
    p.is_available,
    coalesce(round(avg(r.rating), 1), 0) as average_rating,
    count(distinct r.id)                 as review_count,
    count(distinct pp.id)                as portfolio_count,
    p.created_at
  from public.photographers p
  left join public.profiles pr          on pr.id = p.profile_id
  left join public.reviews r            on r.photographer_id = p.id
  left join public.portfolio_photos pp  on pp.photographer_id = p.id
  group by p.id, p.profile_id, pr.full_name, pr.avatar_url, p.bio, p.city,
           p.specialties, p.price_per_hour, p.is_available, p.created_at;
