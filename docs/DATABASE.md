# Base de données — Photographes.ci

> **Liens rapides :** [README](../README.md) | [ARCHITECTURE](ARCHITECTURE.md) | [API](API.md) | [SETUP](SETUP.md) | [DEPLOYMENT](DEPLOYMENT.md) | [CONVENTIONS](CONVENTIONS.md) | [FEATURES](FEATURES.md)

## Table des matières

1. [Schéma ERD](#schéma-erd)
2. [Description des tables](#description-des-tables)
3. [Relations entre tables](#relations-entre-tables)
4. [Politiques RLS](#politiques-rls)
5. [Index](#index)
6. [Triggers](#triggers)
7. [Migrations](#migrations)
8. [Exemples de requêtes](#exemples-de-requêtes)

---

## Schéma ERD

```
auth.users (Supabase Auth)
    │
    │ 1:1
    ▼
┌──────────────────────────────────────────────────────┐
│ profiles                                              │
│ ─────────────────────────────────────────────────── │
│ id           UUID PK (FK auth.users)                 │
│ full_name    TEXT                                     │
│ avatar_url   TEXT                                     │
│ phone        TEXT UNIQUE                              │
│ role         TEXT ('client'|'photographer'|'admin')   │
│ created_at   TIMESTAMPTZ                              │
│ updated_at   TIMESTAMPTZ                              │
└──────┬──────────────────────────────────────────────┘
       │
       │ 1:1 (si role = 'photographer')
       ▼
┌──────────────────────────────────────────────────────┐
│ photographers                                         │
│ ─────────────────────────────────────────────────── │
│ id              UUID PK                               │
│ profile_id      UUID FK → profiles.id                 │
│ bio             TEXT                                  │
│ city            TEXT                                  │
│ commune         TEXT                                  │
│ specialties     TEXT[]                                │
│ price_per_hour  NUMERIC(10,2)                         │
│ is_available    BOOLEAN                               │
│ rating_avg      NUMERIC(3,2)                          │
│ rating_count    INTEGER                               │
│ portfolio_cover TEXT                                  │
│ created_at      TIMESTAMPTZ                           │
└──────┬──────────────┬──────────────┬─────────────────┘
       │              │              │
       │ 1:N          │ 1:N          │ 1:N
       ▼              ▼              ▼
┌──────────┐   ┌──────────────┐  ┌──────────────────┐
│ bookings │   │  portfolios  │  │    reviews        │
│ ─────── │   │ ──────────── │  │ ──────────────── │
│ id UUID  │   │ id UUID      │  │ id UUID           │
│ client_id│   │ photographer │  │ booking_id FK     │
│ photo_id │   │ _id FK       │  │ client_id FK      │
│ event_dt │   │ image_url    │  │ photographer_id FK│
│ duration │   │ thumb_url    │  │ rating SMALLINT   │
│ status   │   │ title        │  │ comment TEXT      │
│ price    │   │ category_id  │  │ created_at        │
│ notes    │   │ is_featured  │  └──────────────────┘
│ created  │   │ created_at   │
└──────────┘   └──────────────┘

┌──────────────────────────────────────────────────────┐
│ contacts                                              │
│ ─────────────────────────────────────────────────── │
│ id              UUID PK                               │
│ client_id       UUID FK → profiles.id                 │
│ photographer_id UUID FK → photographers.id            │
│ message         TEXT                                  │
│ status          TEXT ('pending'|'accepted'|'refused'  │
│                      |'expired'|'refunded')           │
│ payment_ref     TEXT                                  │
│ amount          NUMERIC(10,2)                         │
│ refund_at       TIMESTAMPTZ                           │
│ created_at      TIMESTAMPTZ                           │
│ expires_at      TIMESTAMPTZ                           │
└──────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────┐
│ categories                                            │
│ ─────────────────────────────────────────────────── │
│ id    UUID PK                                         │
│ slug  TEXT UNIQUE                                     │
│ label TEXT                                            │
│ icon  TEXT                                            │
└──────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────┐
│ app_settings                                          │
│ ─────────────────────────────────────────────────── │
│ key        TEXT PK                                    │
│ value      TEXT                                       │
│ is_public  BOOLEAN                                    │
│ description TEXT                                      │
│ updated_at TIMESTAMPTZ                                │
└──────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────┐
│ payment_providers                                     │
│ ─────────────────────────────────────────────────── │
│ id          UUID PK                                   │
│ name        TEXT                                      │
│ slug        TEXT UNIQUE                               │
│ api_url     TEXT                                      │
│ api_key_enc TEXT (chiffré)                            │
│ is_active   BOOLEAN                                   │
│ config      JSONB                                     │
│ created_at  TIMESTAMPTZ                               │
└──────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────┐
│ otp_codes                                             │
│ ─────────────────────────────────────────────────── │
│ id         UUID PK                                    │
│ phone      TEXT                                       │
│ code       TEXT                                       │
│ used       BOOLEAN                                    │
│ expires_at TIMESTAMPTZ                                │
│ created_at TIMESTAMPTZ                                │
└──────────────────────────────────────────────────────┘
```

---

## Description des tables

### `profiles`

Table centrale des utilisateurs. Liée à `auth.users` de Supabase Auth via l'`id`.

| Colonne | Type | Contrainte | Description |
|---------|------|------------|-------------|
| `id` | `UUID` | PK, FK → `auth.users.id` ON DELETE CASCADE | Identifiant unique (= Supabase Auth UID) |
| `full_name` | `TEXT` | NULL | Nom complet de l'utilisateur |
| `avatar_url` | `TEXT` | NULL | URL de l'avatar (Supabase Storage) |
| `phone` | `TEXT` | UNIQUE, NULL | Numéro de téléphone (format international) |
| `role` | `TEXT` | NOT NULL, DEFAULT 'client' | Rôle : `client`, `photographer`, `admin` |
| `created_at` | `TIMESTAMPTZ` | NOT NULL, DEFAULT now() | Date de création |
| `updated_at` | `TIMESTAMPTZ` | NOT NULL, DEFAULT now() | Date de dernière modification |

### `photographers`

Profil étendu d'un photographe. Un photographe a obligatoirement un profil avec `role = 'photographer'`.

| Colonne | Type | Contrainte | Description |
|---------|------|------------|-------------|
| `id` | `UUID` | PK, DEFAULT gen_random_uuid() | Identifiant unique |
| `profile_id` | `UUID` | FK → `profiles.id` ON DELETE CASCADE, UNIQUE | Profil associé |
| `bio` | `TEXT` | NULL | Biographie |
| `city` | `TEXT` | NULL | Ville principale |
| `commune` | `TEXT` | NULL | Commune (arrondissement) |
| `specialties` | `TEXT[]` | NULL | Spécialités (ex: `['mariage', 'portrait']`) |
| `price_per_hour` | `NUMERIC(10,2)` | NULL | Tarif horaire en XOF |
| `is_available` | `BOOLEAN` | NOT NULL, DEFAULT true | Disponible pour nouvelles réservations |
| `rating_avg` | `NUMERIC(3,2)` | NULL | Note moyenne (calculée par trigger) |
| `rating_count` | `INTEGER` | DEFAULT 0 | Nombre d'avis |
| `portfolio_cover` | `TEXT` | NULL | URL de l'image de couverture |
| `created_at` | `TIMESTAMPTZ` | NOT NULL, DEFAULT now() | Date de création |

### `bookings`

Réservations entre clients et photographes.

| Colonne | Type | Contrainte | Description |
|---------|------|------------|-------------|
| `id` | `UUID` | PK, DEFAULT gen_random_uuid() | Identifiant unique |
| `client_id` | `UUID` | FK → `profiles.id` ON DELETE SET NULL | Client ayant réservé |
| `photographer_id` | `UUID` | FK → `photographers.id` ON DELETE SET NULL | Photographe réservé |
| `event_date` | `DATE` | NOT NULL | Date de l'événement |
| `duration_hours` | `NUMERIC(4,1)` | NOT NULL | Durée en heures |
| `status` | `TEXT` | NOT NULL, DEFAULT 'pending' | Statut : `pending`, `confirmed`, `cancelled`, `completed` |
| `total_price` | `NUMERIC(10,2)` | NULL | Prix total en XOF |
| `notes` | `TEXT` | NULL | Notes/instructions |
| `created_at` | `TIMESTAMPTZ` | NOT NULL, DEFAULT now() | Date de création |

### `contacts`

Demandes de contact avec paiement (système "pay to contact").

| Colonne | Type | Contrainte | Description |
|---------|------|------------|-------------|
| `id` | `UUID` | PK | Identifiant unique |
| `client_id` | `UUID` | FK → `profiles.id` | Client demandeur |
| `photographer_id` | `UUID` | FK → `photographers.id` | Photographe ciblé |
| `message` | `TEXT` | NULL | Message initial |
| `status` | `TEXT` | NOT NULL, DEFAULT 'pending' | `pending`, `accepted`, `refused`, `expired`, `refunded` |
| `payment_ref` | `TEXT` | NULL | Référence de paiement externe |
| `amount` | `NUMERIC(10,2)` | NULL | Montant payé en XOF |
| `refund_at` | `TIMESTAMPTZ` | NULL | Date de remboursement |
| `expires_at` | `TIMESTAMPTZ` | NOT NULL | Date d'expiration (72h après création) |
| `created_at` | `TIMESTAMPTZ` | NOT NULL, DEFAULT now() | Date de création |

### `portfolios`

Images du portfolio d'un photographe.

| Colonne | Type | Contrainte | Description |
|---------|------|------------|-------------|
| `id` | `UUID` | PK | Identifiant unique |
| `photographer_id` | `UUID` | FK → `photographers.id` ON DELETE CASCADE | Photographe propriétaire |
| `image_url` | `TEXT` | NOT NULL | URL de l'image originale (R2) |
| `thumb_url` | `TEXT` | NULL | URL du thumbnail 400px (R2) |
| `title` | `TEXT` | NULL | Titre de la photo |
| `category_id` | `UUID` | FK → `categories.id` ON DELETE SET NULL | Catégorie |
| `is_featured` | `BOOLEAN` | DEFAULT false | Mise en avant sur le profil |
| `sort_order` | `INTEGER` | DEFAULT 0 | Ordre d'affichage |
| `created_at` | `TIMESTAMPTZ` | NOT NULL, DEFAULT now() | Date d'upload |

### `reviews`

Avis laissés par les clients après une réservation.

| Colonne | Type | Contrainte | Description |
|---------|------|------------|-------------|
| `id` | `UUID` | PK | Identifiant unique |
| `booking_id` | `UUID` | FK → `bookings.id`, UNIQUE | Réservation associée (1 avis/réservation) |
| `client_id` | `UUID` | FK → `profiles.id` | Client auteur |
| `photographer_id` | `UUID` | FK → `photographers.id` | Photographe évalué |
| `rating` | `SMALLINT` | NOT NULL, CHECK (1..5) | Note de 1 à 5 |
| `comment` | `TEXT` | NULL | Commentaire |
| `created_at` | `TIMESTAMPTZ` | NOT NULL, DEFAULT now() | Date de l'avis |

### `categories`

Référentiel des catégories de photographie.

| Colonne | Type | Contrainte | Description |
|---------|------|------------|-------------|
| `id` | `UUID` | PK | Identifiant unique |
| `slug` | `TEXT` | UNIQUE, NOT NULL | Identifiant URL (ex: `mariage`) |
| `label` | `TEXT` | NOT NULL | Libellé affiché (ex: `Mariage`) |
| `icon` | `TEXT` | NULL | Icône (emoji ou nom lucide) |

### `app_settings`

Constantes dynamiques de l'application, configurables depuis l'admin.

| Colonne | Type | Contrainte | Description |
|---------|------|------------|-------------|
| `key` | `TEXT` | PK | Clé de la constante (ex: `contact_price_xof`) |
| `value` | `TEXT` | NOT NULL | Valeur (toujours TEXT, castée côté app) |
| `is_public` | `BOOLEAN` | DEFAULT false | Si `true`, accessible sans auth via `sync-settings` |
| `description` | `TEXT` | NULL | Description à destination des admins |
| `updated_at` | `TIMESTAMPTZ` | DEFAULT now() | Date de dernière modification |

**Exemples de clés :**

| Clé | Valeur | Description |
|-----|--------|-------------|
| `contact_price_xof` | `2000` | Prix d'un contact en XOF |
| `contact_expiry_hours` | `72` | Durée d'expiration d'un contact |
| `wasender_api_key` | `***` | Clé API WasenderAPI (non publique) |
| `r2_bucket_name` | `photographes` | Nom du bucket R2 |
| `max_portfolio_images` | `30` | Quota images portfolio |
| `otp_expiry_minutes` | `5` | Durée validité OTP |

### `payment_providers`

Configuration des prestataires de paiement (Mobile Money).

| Colonne | Type | Contrainte | Description |
|---------|------|------------|-------------|
| `id` | `UUID` | PK | Identifiant unique |
| `name` | `TEXT` | NOT NULL | Nom affiché (ex: `Orange Money CI`) |
| `slug` | `TEXT` | UNIQUE, NOT NULL | Identifiant technique (ex: `orange-money`) |
| `api_url` | `TEXT` | NOT NULL | URL de l'API de paiement |
| `api_key_enc` | `TEXT` | NULL | Clé API chiffrée (AES-256) |
| `is_active` | `BOOLEAN` | DEFAULT true | Provider actif/inactif |
| `config` | `JSONB` | DEFAULT '{}' | Configuration additionnelle |
| `created_at` | `TIMESTAMPTZ` | DEFAULT now() | Date de création |

### `otp_codes`

Codes OTP générés pour l'authentification WhatsApp.

| Colonne | Type | Contrainte | Description |
|---------|------|------------|-------------|
| `id` | `UUID` | PK | Identifiant unique |
| `phone` | `TEXT` | NOT NULL | Numéro de téléphone |
| `code` | `TEXT` | NOT NULL | Code OTP (6 chiffres, haché en SHA-256) |
| `used` | `BOOLEAN` | DEFAULT false | OTP déjà utilisé |
| `expires_at` | `TIMESTAMPTZ` | NOT NULL | Date d'expiration (5 min) |
| `created_at` | `TIMESTAMPTZ` | DEFAULT now() | Date de génération |

---

## Relations entre tables

```
auth.users ──1:1──► profiles
profiles ──1:1──► photographers
profiles ──1:N──► bookings (via client_id)
profiles ──1:N──► contacts (via client_id)
profiles ──1:N──► reviews (via client_id)
photographers ──1:N──► bookings (via photographer_id)
photographers ──1:N──► contacts (via photographer_id)
photographers ──1:N──► portfolios
photographers ──1:N──► reviews
bookings ──1:1──► reviews
categories ──1:N──► portfolios
```

---

## Politiques RLS

Toutes les tables ont le Row Level Security activé. Voici les politiques par table :

### `profiles`

```sql
-- Tout utilisateur authentifié voit son propre profil
CREATE POLICY "profiles_select_own"
  ON public.profiles FOR SELECT
  USING (auth.uid() = id);

-- Les photographes sont visibles publiquement (pour le feed)
CREATE POLICY "profiles_select_photographers"
  ON public.profiles FOR SELECT
  USING (role = 'photographer');

-- L'utilisateur modifie uniquement son propre profil
CREATE POLICY "profiles_update_own"
  ON public.profiles FOR UPDATE
  USING (auth.uid() = id);

-- Insertion automatique via trigger on auth.users
CREATE POLICY "profiles_insert_trigger"
  ON public.profiles FOR INSERT
  WITH CHECK (auth.uid() = id);

-- Admins voient tous les profils
CREATE POLICY "profiles_select_admin"
  ON public.profiles FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );
```

### `photographers`

```sql
-- Lecture publique (liste et détail)
CREATE POLICY "photographers_select_public"
  ON public.photographers FOR SELECT
  USING (true);

-- Un photographe modifie son propre profil
CREATE POLICY "photographers_update_own"
  ON public.photographers FOR UPDATE
  USING (
    profile_id = auth.uid()
  );

-- Insertion par le propriétaire
CREATE POLICY "photographers_insert_own"
  ON public.photographers FOR INSERT
  WITH CHECK (profile_id = auth.uid());

-- Admin peut tout faire
CREATE POLICY "photographers_all_admin"
  ON public.photographers FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );
```

### `bookings`

```sql
-- Le client voit ses propres réservations
CREATE POLICY "bookings_select_client"
  ON public.bookings FOR SELECT
  USING (client_id = auth.uid());

-- Le photographe voit les réservations qui le concernent
CREATE POLICY "bookings_select_photographer"
  ON public.bookings FOR SELECT
  USING (
    photographer_id IN (
      SELECT id FROM public.photographers WHERE profile_id = auth.uid()
    )
  );

-- Le client crée une réservation
CREATE POLICY "bookings_insert_client"
  ON public.bookings FOR INSERT
  WITH CHECK (client_id = auth.uid());

-- Le client ou le photographe peut modifier (ex: annuler)
CREATE POLICY "bookings_update_owner"
  ON public.bookings FOR UPDATE
  USING (
    client_id = auth.uid()
    OR photographer_id IN (
      SELECT id FROM public.photographers WHERE profile_id = auth.uid()
    )
  );
```

### `contacts`

```sql
-- Le client voit ses contacts
CREATE POLICY "contacts_select_client"
  ON public.contacts FOR SELECT
  USING (client_id = auth.uid());

-- Le photographe voit les contacts reçus
CREATE POLICY "contacts_select_photographer"
  ON public.contacts FOR SELECT
  USING (
    photographer_id IN (
      SELECT id FROM public.photographers WHERE profile_id = auth.uid()
    )
  );

-- Le client crée un contact
CREATE POLICY "contacts_insert_client"
  ON public.contacts FOR INSERT
  WITH CHECK (client_id = auth.uid());
```

### `portfolios`

```sql
-- Lecture publique
CREATE POLICY "portfolios_select_public"
  ON public.portfolios FOR SELECT
  USING (true);

-- Le photographe gère son portfolio
CREATE POLICY "portfolios_manage_own"
  ON public.portfolios FOR ALL
  USING (
    photographer_id IN (
      SELECT id FROM public.photographers WHERE profile_id = auth.uid()
    )
  );
```

### `app_settings`

```sql
-- Lecture des settings publics (sans auth)
CREATE POLICY "settings_select_public"
  ON public.app_settings FOR SELECT
  USING (is_public = true);

-- Admin voit et modifie tout
CREATE POLICY "settings_all_admin"
  ON public.app_settings FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );
```

---

## Index

```sql
-- Performance du feed photographes
CREATE INDEX idx_photographers_city ON public.photographers (city);
CREATE INDEX idx_photographers_available ON public.photographers (is_available);
CREATE INDEX idx_photographers_rating ON public.photographers (rating_avg DESC NULLS LAST);

-- Filtre par catégorie dans les portfolios
CREATE INDEX idx_portfolios_photographer ON public.portfolios (photographer_id);
CREATE INDEX idx_portfolios_category ON public.portfolios (category_id);
CREATE INDEX idx_portfolios_featured ON public.portfolios (is_featured) WHERE is_featured = true;

-- Réservations par statut et date
CREATE INDEX idx_bookings_client ON public.bookings (client_id);
CREATE INDEX idx_bookings_photographer ON public.bookings (photographer_id);
CREATE INDEX idx_bookings_status ON public.bookings (status);
CREATE INDEX idx_bookings_event_date ON public.bookings (event_date);

-- Contacts expirés (pour le job auto-refund)
CREATE INDEX idx_contacts_expires_at ON public.contacts (expires_at)
  WHERE status = 'pending';

-- OTP par téléphone (pour verify-otp)
CREATE INDEX idx_otp_phone ON public.otp_codes (phone, expires_at)
  WHERE used = false;

-- Recherche full-text sur bio et ville
CREATE INDEX idx_photographers_search ON public.photographers
  USING gin(to_tsvector('french', coalesce(bio, '') || ' ' || coalesce(city, '')));
```

---

## Triggers

### Trigger : création automatique du profil

Lors de l'inscription via Supabase Auth, un profil est automatiquement créé dans `profiles`.

```sql
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, full_name, avatar_url, role)
  VALUES (
    NEW.id,
    NEW.raw_user_meta_data->>'full_name',
    NEW.raw_user_meta_data->>'avatar_url',
    COALESCE(NEW.raw_user_meta_data->>'role', 'client')
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();
```

### Trigger : mise à jour automatique de `updated_at`

```sql
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER profiles_updated_at
  BEFORE UPDATE ON public.profiles
  FOR EACH ROW EXECUTE PROCEDURE public.handle_updated_at();

CREATE TRIGGER settings_updated_at
  BEFORE UPDATE ON public.app_settings
  FOR EACH ROW EXECUTE PROCEDURE public.handle_updated_at();
```

### Trigger : calcul automatique de la note moyenne

Après l'insertion ou la modification d'un avis, la note moyenne du photographe est recalculée.

```sql
CREATE OR REPLACE FUNCTION public.update_photographer_rating()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE public.photographers
  SET
    rating_avg = (
      SELECT AVG(rating)::NUMERIC(3,2)
      FROM public.reviews
      WHERE photographer_id = NEW.photographer_id
    ),
    rating_count = (
      SELECT COUNT(*)
      FROM public.reviews
      WHERE photographer_id = NEW.photographer_id
    )
  WHERE id = NEW.photographer_id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER reviews_update_rating
  AFTER INSERT OR UPDATE ON public.reviews
  FOR EACH ROW EXECUTE PROCEDURE public.update_photographer_rating();
```

### Trigger : expiration automatique des contacts

```sql
CREATE OR REPLACE FUNCTION public.set_contact_expiry()
RETURNS TRIGGER AS $$
DECLARE
  expiry_hours INTEGER;
BEGIN
  SELECT value::INTEGER INTO expiry_hours
  FROM public.app_settings
  WHERE key = 'contact_expiry_hours';

  NEW.expires_at = now() + (COALESCE(expiry_hours, 72) || ' hours')::INTERVAL;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER contacts_set_expiry
  BEFORE INSERT ON public.contacts
  FOR EACH ROW EXECUTE PROCEDURE public.set_contact_expiry();
```

---

## Migrations

Les migrations sont stockées dans `supabase/migrations/` et nommées avec un timestamp :

```
supabase/migrations/
├── 20260304000000_init.sql              # Tables initiales + RLS
├── 20260304000001_contacts.sql          # Table contacts + trigger expiry
├── 20260304000002_portfolios.sql        # Table portfolios + index
├── 20260304000003_reviews.sql           # Table reviews + trigger rating
├── 20260304000004_categories.sql        # Table categories
├── 20260304000005_app_settings.sql      # Table app_settings
├── 20260304000006_payment_providers.sql # Table payment_providers
├── 20260304000007_otp_codes.sql         # Table otp_codes
└── 20260304000008_indexes.sql           # Index de performance
```

### Commandes de migration

```bash
# Appliquer les migrations en local
supabase db reset

# Créer une nouvelle migration
supabase migration new <nom_migration>

# Vérifier les migrations en attente
supabase db diff

# Pousser vers production
supabase db push --project-ref <PROJECT_REF>
```

---

## Exemples de requêtes

### Feed photographes avec filtres

```typescript
const { data, error } = await supabase
  .from('photographers')
  .select(`
    id,
    city,
    commune,
    specialties,
    price_per_hour,
    rating_avg,
    rating_count,
    is_available,
    portfolio_cover,
    profiles!profile_id (
      full_name,
      avatar_url
    )
  `)
  .eq('is_available', true)
  .eq('city', 'Abidjan')
  .containedBy('specialties', ['mariage'])
  .gte('rating_avg', 4.0)
  .lte('price_per_hour', 50000)
  .order('rating_avg', { ascending: false })
  .range(0, 11); // 12 résultats par page
```

### Profil public d'un photographe

```typescript
const { data } = await supabase
  .from('photographers')
  .select(`
    *,
    profiles!profile_id (full_name, avatar_url),
    portfolios (
      id, image_url, thumb_url, title, is_featured,
      categories!category_id (slug, label)
    ),
    reviews (
      rating, comment, created_at,
      profiles!client_id (full_name, avatar_url)
    )
  `)
  .eq('id', photographerId)
  .single();
```

### Créer un contact (client → photographe)

```typescript
const { data, error } = await supabase
  .from('contacts')
  .insert({
    client_id: user.id,
    photographer_id: photographerId,
    message: 'Bonjour, je cherche un photographe pour mon mariage...',
    amount: contactPrice,
    payment_ref: paymentRef,
  })
  .select()
  .single();
```

### Récupérer les settings publics

```typescript
const { data } = await supabase
  .from('app_settings')
  .select('key, value')
  .eq('is_public', true);

const settings = Object.fromEntries(data.map(s => [s.key, s.value]));
```
