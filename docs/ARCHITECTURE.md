# Architecture — Photographes.ci

> **Liens rapides :** [README](../README.md) | [DATABASE](DATABASE.md) | [API](API.md) | [SETUP](SETUP.md) | [DEPLOYMENT](DEPLOYMENT.md) | [CONVENTIONS](CONVENTIONS.md) | [FEATURES](FEATURES.md)

## Table des matières

1. [Vue d'ensemble](#vue-densemble)
2. [Diagramme des composants](#diagramme-des-composants)
3. [Flux de données](#flux-de-données)
4. [Choix techniques](#choix-techniques)
5. [Sécurité](#sécurité)
6. [Performance](#performance)
7. [Scalabilité](#scalabilité)

---

## Vue d'ensemble

**Photographes.ci** est une plateforme de mise en relation entre photographes professionnels et clients en Côte d'Ivoire. Le projet est structuré en **monorepo** regroupant toutes les applications et services.

```
┌─────────────────────────────────────────────────────────────────┐
│                        Photographes.ci                          │
│                                                                 │
│  ┌──────────────┐   ┌──────────────┐   ┌────────────────────┐  │
│  │  Flutter App  │   │  Next.js Web │   │  Supabase Backend  │  │
│  │  (Mobile)     │   │  (Web)       │   │  (API + DB + Auth) │  │
│  └──────┬───────┘   └──────┬───────┘   └────────┬───────────┘  │
│         │                  │                     │              │
│         └──────────────────┴─────────────────────┘              │
│                         Supabase JS SDK                         │
└─────────────────────────────────────────────────────────────────┘
```

### Composants principaux

| Composant | Technologie | Rôle |
|-----------|-------------|------|
| `apps/mobile` | Flutter 3 | Application iOS & Android |
| `apps/web` | Next.js 15 (App Router) | Site vitrine & portail admin |
| `supabase/` | Supabase (PostgreSQL 15) | Backend, Auth, Edge Functions |
| `packages/shared` | TypeScript | Types et utilitaires partagés |
| Cloudflare R2 | Objet Storage S3-compatible | Stockage des portfolios images |

---

## Diagramme des composants

```
┌──────────────────────────────────────────────────────────────────────┐
│                           CLIENTS                                    │
│                                                                      │
│  ┌─────────────────┐              ┌──────────────────────────────┐   │
│  │  Mobile (Flutter)│              │     Web (Next.js)            │   │
│  │                  │              │                              │   │
│  │  • Auth screens  │              │  • Landing page (SSG)        │   │
│  │  • Feed photos   │              │  • Feed photographes (SSR)   │   │
│  │  • Profile       │              │  • Profils publics           │   │
│  │  • Booking       │              │  • Admin dashboard           │   │
│  │  • Portfolio     │              │  • Auth (SSR cookies)        │   │
│  └────────┬─────────┘              └──────────┬───────────────────┘   │
└───────────┼──────────────────────────────────┼──────────────────────┘
            │                                  │
            │   Supabase JS SDK v2              │   Next.js Server Actions
            │   (supabase_flutter)              │   / Route Handlers
            │                                  │
┌───────────▼──────────────────────────────────▼──────────────────────┐
│                         SUPABASE BACKEND                             │
│                                                                      │
│  ┌────────────────┐  ┌──────────────────┐  ┌──────────────────────┐ │
│  │  Auth (GoTrue)  │  │  PostgreSQL 15   │  │   Edge Functions     │ │
│  │                 │  │                  │  │   (Deno runtime)     │ │
│  │  • JWT tokens   │  │  Tables:         │  │                      │ │
│  │  • OTP WhatsApp │  │  • profiles      │  │  • send-otp          │ │
│  │  • RLS policies │  │  • photographers │  │  • verify-otp        │ │
│  │  • Refresh token│  │  • bookings      │  │  • watermark         │ │
│  └────────────────┘  │  • contacts      │  │  • process-payment   │ │
│                       │  • portfolios    │  │  • auto-refund       │ │
│  ┌────────────────┐  │  • app_settings  │  │  • sync-settings     │ │
│  │  Storage       │  │  • reviews       │  └──────────┬───────────┘ │
│  │                │  │  • categories    │             │             │
│  │  • avatars     │  └──────────────────┘             │             │
│  │  (bucket pub.) │                                   │             │
│  └────────────────┘                       ┌───────────▼───────────┐ │
│                                           │   Services externes   │ │
└───────────────────────────────────────────┤                       ├─┘
                                            │  • WasenderAPI (OTP)  │
                                            │  • Cloudflare R2      │
                                            │  • Mobile Money APIs  │
                                            └───────────────────────┘
```

---

## Flux de données

### Authentification (OTP WhatsApp)

```
Utilisateur         Mobile/Web          Edge Function       WasenderAPI
    │                   │               send-otp                │
    │──── numéro ────►  │                   │                   │
    │                   │──── POST ────►    │                   │
    │                   │                   │──── sendMessage ─►│
    │                   │                   │ ◄── 200 OK ───────│
    │                   │ ◄── {sent:true} ──│                   │
    │ ◄── SMS/WhatsApp ─│                   │                   │
    │                   │                   │                   │
    │──── OTP code ───► │                   │                   │
    │                   │──── POST ────►  verify-otp            │
    │                   │                   │─── check DB ──►   │
    │                   │                   │ ◄── valid ────     │
    │                   │ ◄── JWT session ──│                   │
```

### Upload Portfolio (Image + Watermark)

```
Photographe         Web/Mobile          Edge Function       Cloudflare R2
    │                   │               watermark               │
    │── upload image ►  │                   │                   │
    │                   │── multipart ────► │                   │
    │                   │                   │── sharp/process   │
    │                   │                   │   add watermark   │
    │                   │                   │   gen thumbnail   │
    │                   │                   │──── PUT ─────────►│
    │                   │                   │ ◄── URL ──────────│
    │                   │ ◄── {urls} ───────│                   │
    │ ◄── confirmation ─│                   │                   │
```

### Flux de réservation

```
Client              API Supabase        Photographe         Payment Provider
    │                   │                   │                   │
    │── recherche ────► │                   │                   │
    │ ◄── feed ────────│                   │                   │
    │                   │                   │                   │
    │── crée contact ─► │                   │                   │
    │                   │── notifie ───────►│                   │
    │                   │                   │                   │
    │── paiement ─────► │                   │                   │
    │                   │──── process ──────────────────────── ►│
    │                   │ ◄── confirmation ──────────────────── │
    │ ◄── reçu ─────── │                   │                   │
    │                   │── confirme ──────►│                   │
```

---

## Choix techniques

### Pourquoi Next.js 15 (App Router) ?

| Critère | Choix | Raison |
|---------|-------|--------|
| Rendu | SSR + SSG hybride | SEO des profils photographes + perf |
| Auth | Supabase SSR (`@supabase/ssr`) | Cookies server-side, sécurisé |
| UI | Tailwind CSS + shadcn/ui | Rapidité de développement |
| Images | `next/image` | Optimisation automatique WebP/AVIF |
| État | React Server Components + hooks | Minimal bundle, perf maximale |

### Pourquoi Flutter 3 ?

| Critère | Choix | Raison |
|---------|-------|--------|
| State | Riverpod 2 | DI + réactivité, testable |
| Navigation | go_router | Déclaratif, deep linking |
| Images | cached_network_image | Cache local, placeholders |
| Auth | supabase_flutter | Intégration native Supabase |

### Pourquoi Supabase ?

| Critère | Choix | Raison |
|---------|-------|--------|
| DB | PostgreSQL 15 | ACID, RLS natif, extensions |
| Auth | GoTrue (JWT) | Intégré, OTP, OAuth |
| API | PostgREST auto-généré | CRUD sans code |
| Functions | Deno (TypeScript) | Sécurisé, moderne |
| Realtime | WebSocket natif | Notifications en temps réel |

### Pourquoi Cloudflare R2 ?

- Compatible S3 (AWS SDK standard)
- Pas d'egress fees (0€ de sortie de données)
- CDN mondial intégré (Cloudflare Workers)
- Moins cher que S3 pour les assets statiques

### Monorepo avec npm workspaces

```
photographes/
├── apps/
│   ├── mobile/          # Flutter (pubspec.yaml)
│   └── web/             # Next.js (package.json)
├── packages/
│   └── shared/          # TypeScript types partagés
├── supabase/            # Backend Supabase
├── docs/                # Documentation
└── package.json         # Workspace root
```

**Avantages :**
- Types partagés entre web et mobile (via `@photographes/shared`)
- Un seul `git clone` pour tout le projet
- CI/CD partagé (GitHub Actions)
- Refactorisation cross-app facilitée

---

## Sécurité

### Principes de sécurité appliqués

1. **Row Level Security (RLS)** : Chaque table PostgreSQL a ses politiques RLS activées. Les données ne sont accessibles qu'aux utilisateurs autorisés, même via l'API PostgREST directe.

2. **JWT à durée limitée** : Les tokens JWT expirent après 1 heure (`jwt_expiry = 3600`). Le refresh token est tournant (`enable_refresh_token_rotation = true`).

3. **Secrets en variables d'environnement** : Jamais de secrets dans le code source. Utilisation de `.env.local` en développement, de secrets GitHub en CI/CD.

4. **CORS restreint** : Les Edge Functions n'autorisent que les origines connues.

5. **Validation des entrées** : Chaque Edge Function valide les paramètres d'entrée avant traitement.

6. **Permissions CI/CD** : Tous les workflows GitHub Actions ont `permissions: contents: read` (principe du moindre privilège).

### Flux d'authentification sécurisé

```
Client ──► Supabase Auth ──► JWT (httpOnly cookie) ──► API calls
                │
                └──► RLS policies enforce data access
```

### Points critiques de sécurité

| Point | Mesure |
|-------|--------|
| Clés API R2 | Variables d'env serveur uniquement, jamais exposées au client |
| OTP WhatsApp | Expiration 5 min, usage unique, rate limiting |
| Upload images | Validation MIME, taille max, scan antivirus recommandé |
| Paiements | Ne jamais logger les détails de carte/wallet |
| Admin routes | Middleware de vérification du rôle `admin` |
| SQL injection | Impossible via PostgREST (paramétrisé) + Edge Functions |

---

## Performance

### Stratégies d'optimisation

| Couche | Technique |
|--------|-----------|
| Images | WebP/AVIF via `next/image`, thumbnails 400px via Edge Function |
| DB | Index sur `city`, `is_available`, `status` ; pagination cursor-based |
| Cache | ISR (Next.js) pour les profils photographes (revalidate 60s) |
| CDN | Cloudflare R2 + Cloudflare CDN pour les assets |
| Mobile | `cached_network_image` avec cache local 7 jours |
| API | Requêtes PostgREST avec `.select()` sélectif (pas de `SELECT *`) |

### Métriques cibles

| Métrique | Cible |
|----------|-------|
| LCP (web) | < 2.5s |
| FID (web) | < 100ms |
| CLS (web) | < 0.1 |
| Cold start Edge Function | < 200ms |
| API response time | < 300ms (P95) |

---

## Scalabilité

### Scaling horizontal

- **Supabase** : Scaling automatique de PostgreSQL + read replicas disponibles
- **Edge Functions** : Serverless, scaling automatique par Supabase
- **Next.js** : Déployable sur Railway/Vercel avec auto-scaling
- **R2** : Storage objet illimité, CDN mondial intégré

### Points de contention potentiels

1. **Table `contacts`** : Forte charge en période de pointe → index sur `created_at`, `status`
2. **Upload d'images** : La Edge Function `watermark` est CPU-intensive → limiter à 10MB
3. **Notifications realtime** : Limiter le nombre de subscriptions simultanées par client

### Architecture future (v2)

```
                    ┌─────────────────┐
                    │  Redis (cache)  │
                    │  (Upstash)      │
                    └────────┬────────┘
                             │
Client ──► CDN ──► Next.js ──┤──► Supabase ──► PostgreSQL
                             │
                    ┌────────┴────────┐
                    │  Queue (BullMQ) │
                    │  async tasks    │
                    └─────────────────┘
```
