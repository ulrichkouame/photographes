# Features & Écrans — Photographes.ci

> **Liens rapides :** [README](../README.md) | [ARCHITECTURE](ARCHITECTURE.md) | [DATABASE](DATABASE.md) | [API](API.md) | [SETUP](SETUP.md) | [DEPLOYMENT](DEPLOYMENT.md) | [CONVENTIONS](CONVENTIONS.md)

## Table des matières

1. [Vue d'ensemble](#vue-densemble)
2. [Application Web (Next.js)](#application-web-nextjs)
   - [Interface publique](#interface-publique)
   - [Espace client](#espace-client)
   - [Dashboard admin](#dashboard-admin)
3. [Application Mobile (Flutter)](#application-mobile-flutter)
4. [Mapping données / state](#mapping-données--state)
5. [Statuts d'implémentation](#statuts-dimplémentation)

---

## Vue d'ensemble

Légende des statuts :
- ✅ Implémenté et testé
- 🚧 En cours d'implémentation
- 📋 Planifié (non démarré)
- ❌ Hors scope

---

## Application Web (Next.js)

### Interface publique

#### 🏠 Landing Page (`/`)

| Élément | Données | State | Statut |
|---------|---------|-------|--------|
| Hero section | Statique | - | 🚧 |
| Compteurs (photographes, clients, avis) | `COUNT(photographers)`, `COUNT(profiles)`, `COUNT(reviews)` | SSR | 🚧 |
| Section "Catégories populaires" | `categories` | SSG (revalidate: 3600) | 📋 |
| Section "Photographes en vedette" | `photographers` WHERE `is_featured = true` | ISR (revalidate: 60) | 📋 |
| Témoignages | `reviews` ORDER BY `created_at DESC` LIMIT 6 | ISR | 📋 |
| Section "Comment ça marche" | Statique | - | 📋 |
| Footer avec liens | Statique | - | 📋 |
| SEO : title, description, OpenGraph | `metadata` Next.js | - | 📋 |
| Sitemap (`/sitemap.xml`) | Toutes les routes statiques | - | 📋 |

#### 📸 Feed photographes (`/photographes`)

| Élément | Données | State | Statut |
|---------|---------|-------|--------|
| Liste des photographes | `photographers` JOIN `profiles` | Server Component + filtres client | 📋 |
| Filtre par ville | `DISTINCT city FROM photographers` | URL params | 📋 |
| Filtre par catégorie | `categories` | URL params | 📋 |
| Filtre par budget | `price_per_hour` lte/gte | URL params | 📋 |
| Filtre par note min | `rating_avg` gte | URL params | 📋 |
| Filtre "disponible" | `is_available = true` | URL params | 📋 |
| Tri (note, prix, récents) | `order` Supabase | URL params | 📋 |
| Pagination (cursor-based) | `range(offset, limit)` | URL params | 📋 |
| Carte Photographe | `photographers.*, profiles.*` | - | 📋 |
| Nombre de résultats | `count: 'exact'` | - | 📋 |
| État "aucun résultat" | - | UI | 📋 |
| Skeleton loading | - | `loading` state | 📋 |

#### 👤 Profil public photographe (`/photographes/[id]`)

| Élément | Données | State | Statut |
|---------|---------|-------|--------|
| Informations profil | `photographers JOIN profiles` | SSR | 📋 |
| Galerie portfolio (3 colonnes) | `portfolios WHERE photographer_id = id` | Client Component | 📋 |
| Photos "featured" en premier | `ORDER BY is_featured DESC, sort_order ASC` | - | 📋 |
| Note et avis | `reviews WHERE photographer_id = id` | ISR | 📋 |
| Spécialités / tags | `specialties[]` | - | 📋 |
| Prix à l'heure | `price_per_hour` | - | 📋 |
| Disponibilité | `is_available` | - | 📋 |
| Bouton "Contacter" | - | Auth check | 📋 |
| Bouton "Réserver" | - | Auth check | 📋 |
| SEO : title dynamique, OpenGraph image | `full_name`, `portfolio_cover` | - | 📋 |
| Page 404 si photographe inexistant | - | `notFound()` | 📋 |

#### 🔐 Authentification (`/connexion`)

| Élément | Données | State | Statut |
|---------|---------|-------|--------|
| Saisie numéro de téléphone | - | `useState` | 📋 |
| Envoi OTP (Edge Function `send-otp`) | `otp_codes` | `loading` | 📋 |
| Saisie code OTP (6 chiffres) | - | `useState` | 📋 |
| Vérification OTP (Edge Function `verify-otp`) | `otp_codes`, session JWT | `loading` | 📋 |
| Redirect après connexion | - | `router.push` | 📋 |
| Gestion erreurs (OTP invalide, expiré) | - | `error` state | 📋 |
| Countdown OTP (5 min) | - | `useInterval` | 📋 |
| Renvoi OTP | - | Rate limit check | 📋 |

---

### Espace client

#### 📅 Mes réservations (`/espace/reservations`)

| Élément | Données | State | Statut |
|---------|---------|-------|--------|
| Liste des réservations | `bookings WHERE client_id = auth.uid()` | SSR | 📋 |
| Filtre par statut | `status` | URL params | 📋 |
| Détail réservation | `bookings JOIN photographers JOIN profiles` | SSR | 📋 |
| Annuler réservation | `UPDATE bookings SET status = 'cancelled'` | Mutation | 📋 |
| Laisser un avis (après completion) | `INSERT INTO reviews` | Form | 📋 |

#### 💬 Mes contacts (`/espace/contacts`)

| Élément | Données | State | Statut |
|---------|---------|-------|--------|
| Liste des contacts | `contacts WHERE client_id = auth.uid()` | SSR | 📋 |
| Statut du contact | `contacts.status` | - | 📋 |
| Timer d'expiration | `contacts.expires_at` | `useInterval` | 📋 |
| Initier un paiement | Edge Function `process-payment` | `loading` | 📋 |
| Remboursement auto visible | `contacts.status = 'refunded'` | - | 📋 |

#### 👤 Mon profil (`/espace/profil`)

| Élément | Données | State | Statut |
|---------|---------|-------|--------|
| Formulaire de profil | `profiles WHERE id = auth.uid()` | React Hook Form | 📋 |
| Upload avatar | Supabase Storage `avatars/` | File upload | 📋 |
| Modification nom | `UPDATE profiles SET full_name` | Mutation | 📋 |

---

### Dashboard admin

#### 📊 Vue d'ensemble (`/admin`)

| Élément | Données | State | Statut |
|---------|---------|-------|--------|
| KPI : total photographes | `COUNT(photographers)` | SSR | 📋 |
| KPI : total clients | `COUNT(profiles WHERE role='client')` | SSR | 📋 |
| KPI : réservations du mois | `COUNT(bookings WHERE created_at >= month_start)` | SSR | 📋 |
| KPI : revenus du mois | `SUM(contacts.amount WHERE status='accepted')` | SSR | 📋 |
| Graphique réservations (recharts) | `bookings GROUP BY DATE(created_at)` | Client Component | 📋 |
| Graphique revenus (recharts) | `contacts GROUP BY DATE(created_at)` | Client Component | 📋 |
| Activité récente | `bookings UNION contacts ORDER BY created_at DESC` | SSR | 📋 |

#### 👥 Gestion photographes (`/admin/photographes`)

| Élément | Données | State | Statut |
|---------|---------|-------|--------|
| Liste de tous les photographes | `photographers JOIN profiles` | SSR + pagination | 📋 |
| Recherche par nom | `profiles.full_name ILIKE '%query%'` | Debounced search | 📋 |
| Activer/désactiver | `UPDATE photographers SET is_available` | Toggle | 📋 |
| Voir profil complet | - | Modal / drawer | 📋 |
| Supprimer photographe | `DELETE FROM profiles CASCADE` | Confirm dialog | 📋 |
| Modérer portfolio (supprimer image) | `DELETE FROM portfolios` | - | 📋 |

#### 👤 Gestion clients (`/admin/clients`)

| Élément | Données | State | Statut |
|---------|---------|-------|--------|
| Liste de tous les clients | `profiles WHERE role='client'` | SSR + pagination | 📋 |
| Recherche | `full_name ILIKE` | Debounced | 📋 |
| Historique réservations | `bookings WHERE client_id` | Expandable row | 📋 |
| Bloquer un client | `UPDATE profiles SET role='banned'` | Toggle | 📋 |

#### 💳 Gestion paiements (`/admin/paiements`)

| Élément | Données | State | Statut |
|---------|---------|-------|--------|
| Liste des contacts/paiements | `contacts JOIN profiles JOIN photographers` | SSR + pagination | 📋 |
| Filtre par statut | `contacts.status` | URL params | 📋 |
| Détail transaction | - | Modal | 📋 |
| Remboursement manuel | Edge Function `auto-refund` (ciblé) | Button + confirm | 📋 |

#### ⚙️ Paramètres dynamiques (`/admin/parametres`)

| Élément | Données | State | Statut |
|---------|---------|-------|--------|
| Liste app_settings | `SELECT * FROM app_settings` | SSR | 📋 |
| Modifier une valeur | `UPDATE app_settings SET value` | Inline edit | 📋 |
| Activer/désactiver la visibilité | `UPDATE app_settings SET is_public` | Toggle | 📋 |
| Créer un nouveau paramètre | `INSERT INTO app_settings` | Form | 📋 |

#### 💰 Providers de paiement (`/admin/parametres/providers`)

| Élément | Données | State | Statut |
|---------|---------|-------|--------|
| Liste des providers | `payment_providers` | SSR | 📋 |
| Activer/désactiver | `UPDATE payment_providers SET is_active` | Toggle | 📋 |
| Modifier la config | `UPDATE payment_providers SET config` | Form JSON | 📋 |
| Ajouter un provider | `INSERT INTO payment_providers` | Form | 📋 |
| Supprimer un provider | `DELETE FROM payment_providers` | Confirm dialog | 📋 |

#### 🏷️ Gestion catégories (`/admin/categories`)

| Élément | Données | State | Statut |
|---------|---------|-------|--------|
| Liste des catégories | `categories` | SSR | 📋 |
| Ajouter une catégorie | `INSERT INTO categories` | Form | 📋 |
| Modifier label/icône | `UPDATE categories` | Inline edit | 📋 |
| Supprimer | `DELETE FROM categories` | Confirm | 📋 |

---

## Application Mobile (Flutter)

### Flux d'authentification

| Écran | Données | State | Statut |
|-------|---------|-------|--------|
| Splash screen | - | - | 🚧 |
| Onboarding (3 slides) | Statique | `PageView` | 📋 |
| Saisie numéro | - | `TextEditingController` | 📋 |
| Vérification OTP | Edge Function `verify-otp` | `AsyncNotifier` | 📋 |
| Redirect home/profil | - | `go_router redirect` | 📋 |

### Écrans principaux

| Écran | Route | Données | State | Statut |
|-------|-------|---------|-------|--------|
| Home / Feed | `/` | `photographers` | `AsyncNotifier` (Riverpod) | 📋 |
| Recherche / Filtres | `/search` | `photographers` avec filtres | `StateNotifier` | 📋 |
| Profil photographe | `/photographer/:id` | `photographer JOIN portfolios JOIN reviews` | `AsyncNotifier` | 📋 |
| Galerie portfolio | `/photographer/:id/portfolio` | `portfolios` | `AsyncNotifier` | 📋 |
| Mes réservations | `/bookings` | `bookings WHERE client_id` | `AsyncNotifier` | 📋 |
| Détail réservation | `/bookings/:id` | `booking JOIN photographer` | `AsyncNotifier` | 📋 |
| Mes contacts | `/contacts` | `contacts WHERE client_id` | `AsyncNotifier` | 📋 |
| Paiement Mobile Money | `/payment` | - | `StateNotifier` | 📋 |
| Mon profil | `/profile` | `profiles WHERE id = user.id` | `AsyncNotifier` | 📋 |
| Modifier profil | `/profile/edit` | - | `StateNotifier` | 📋 |

### Écrans photographe (si role = 'photographer')

| Écran | Route | Données | State | Statut |
|-------|-------|---------|-------|--------|
| Tableau de bord | `/dashboard` | `bookings`, `contacts`, `reviews` | `AsyncNotifier` | 📋 |
| Gérer portfolio | `/portfolio` | `portfolios WHERE photographer_id` | `AsyncNotifier` | 📋 |
| Upload photo | `/portfolio/upload` | Edge Function `watermark` | `StateNotifier` | 📋 |
| Mes demandes | `/requests` | `contacts WHERE photographer_id` | `AsyncNotifier` | 📋 |
| Paramètres disponibilité | `/settings` | `photographers.is_available` | `StateNotifier` | 📋 |

---

## Mapping données / state

### Web : Flux de données (Next.js App Router)

```
URL params/searchParams
       │
       ▼
Server Component (page.tsx)
  → createServerClient() (Supabase SSR)
  → await supabase.from('...').select(...)
       │
       ▼
Client Component (reçoit data en props)
  → useState / useOptimistic pour mutations
  → Server Actions pour mutations
```

### Mobile : Flux de données (Riverpod)

```
UI Widget
  → ref.watch(photographersProvider)
       │
       ▼
AsyncNotifier (Provider)
  → PhotographerRepository
       │
       ▼
RemoteDataSource
  → supabase.from('photographers').select(...)
       │
       ▼
Supabase PostgreSQL
```

### Gestion des erreurs

| Couche | Stratégie |
|--------|-----------|
| Next.js Server | `error.tsx` pages + `try/catch` |
| Next.js Client | `ErrorBoundary` + toast notifications |
| Flutter | `AsyncValue.error` + Snackbar |
| Edge Functions | Codes d'erreur standardisés (voir [API.md](API.md)) |

---

## Statuts d'implémentation

### Récapitulatif global

| Module | Web | Mobile | Backend | Tests |
|--------|-----|--------|---------|-------|
| Auth (OTP WhatsApp) | 📋 | 📋 | 📋 | 📋 |
| Feed photographes | 📋 | 📋 | ✅ | 📋 |
| Profil photographe | 📋 | 📋 | ✅ | 📋 |
| Portfolio (upload + affichage) | 📋 | 📋 | 📋 | 📋 |
| Réservations | 📋 | 📋 | ✅ | 📋 |
| Contacts + paiement | 📋 | 📋 | 📋 | 📋 |
| Avis et notes | 📋 | 📋 | 📋 | 📋 |
| Dashboard admin | 📋 | ❌ | ✅ | 📋 |
| App settings (CRUD) | 📋 | ❌ | ✅ | 📋 |
| Providers paiement | 📋 | ❌ | 📋 | 📋 |
| Auto-refund | ❌ | ❌ | 📋 | 📋 |
| Catégories | 📋 | 📋 | ✅ | 📋 |
| SEO (sitemap, OG) | 📋 | ❌ | ❌ | ❌ |
| Analytics (recharts) | 📋 | ❌ | ✅ | 📋 |
| Dark/Light mode | 📋 | 📋 | ❌ | ❌ |
| Responsive mobile | 📋 | ✅ | ❌ | ❌ |

### Priorités de développement

**Phase 1 (MVP) :**
1. ✅ Structure monorepo
2. ✅ Schéma de base de données
3. 📋 Auth OTP WhatsApp
4. 📋 Feed photographes (lecture seule)
5. 📋 Profil public photographe
6. 📋 Upload portfolio (watermark + R2)

**Phase 2 :**
7. 📋 Système de contacts + paiement
8. 📋 Réservations
9. 📋 Avis et notes
10. 📋 Dashboard admin (base)

**Phase 3 :**
11. 📋 Auto-refund automatique
12. 📋 Analytics admin avancées
13. 📋 Notifications push (mobile)
14. 📋 SEO avancé + sitemap dynamique
