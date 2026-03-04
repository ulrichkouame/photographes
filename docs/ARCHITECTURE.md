# Architecture — photographes.ci

## Overview

**photographes.ci** is a marketplace connecting photographers with clients in
Côte d'Ivoire and the wider West African region. The platform is built on a
modern, cloud-native stack designed for scalability, offline resilience (mobile),
and fast global delivery.

---

## High-Level Architecture

```
┌───────────────────────────────────────────────────────────────────┐
│                          Clients                                  │
│   ┌──────────────────┐          ┌──────────────────────────────┐  │
│   │   Web Browser    │          │    Mobile (iOS / Android)    │  │
│   │   Next.js App    │          │       Flutter App            │  │
│   └────────┬─────────┘          └──────────────┬───────────────┘  │
└────────────┼───────────────────────────────────┼──────────────────┘
             │ HTTPS                              │ HTTPS
             ▼                                   ▼
┌────────────────────────────────────────────────────────────────────┐
│                     Railway (Edge / CDN)                           │
│         Next.js SSR / ISR served from Railway region               │
└────────────────────────┬───────────────────────────────────────────┘
                         │
          ┌──────────────┼──────────────┐
          │              │              │
          ▼              ▼              ▼
  ┌──────────────┐ ┌──────────────┐ ┌──────────────────────┐
  │  Supabase    │ │  Supabase    │ │  Cloudflare R2       │
  │  Auth        │ │  Edge Fns    │ │  (Object Storage)    │
  │  (JWT/OAuth) │ │  (Deno)      │ │  Photos, videos,     │
  └──────┬───────┘ └──────┬───────┘ │  documents           │
         │                │         └──────────────────────┘
         ▼                ▼
  ┌──────────────────────────────┐
  │  Supabase PostgreSQL         │
  │  (with Row-Level Security)   │
  │  + pgvector (search)         │
  └──────────────────────────────┘
```

---

## Technology Stack

| Layer | Technology | Hosting |
|-------|-----------|---------|
| Web frontend | Next.js 14 (App Router, TypeScript) | Railway |
| Mobile app | Flutter 3 (Dart) | App Store / Play Store |
| Backend functions | Supabase Edge Functions (Deno/TypeScript) | Supabase |
| Database | PostgreSQL 15 via Supabase | Supabase (managed) |
| Authentication | Supabase Auth (JWT, OAuth2) | Supabase |
| Object storage | Cloudflare R2 | Cloudflare |
| Email | Resend (transactional) | Resend |
| Payments | CinetPay / Wave (West Africa) | CinetPay / Wave |
| Monitoring | Sentry (errors), Datadog (APM) | Cloud |
| Analytics | Google Analytics 4 | Google |
| CI/CD | GitHub Actions | GitHub |

---

## Repository Structure

```
photographes/
├── apps/
│   ├── web/               # Next.js application
│   │   ├── app/           # App Router pages and layouts
│   │   ├── components/    # Shared UI components
│   │   ├── lib/           # Utilities, Supabase client, helpers
│   │   ├── public/        # Static assets
│   │   └── tests/         # Jest / Playwright tests
│   └── mobile/            # Flutter application
│       ├── lib/
│       │   ├── core/      # DI, routing, theme
│       │   ├── features/  # Feature-sliced modules
│       │   └── shared/    # Shared widgets, utilities
│       └── test/          # Unit, widget, integration tests
├── supabase/
│   ├── functions/         # Edge Functions (one folder per function)
│   ├── migrations/        # Ordered SQL migration files
│   └── seed.sql           # Development seed data
├── docs/                  # Project documentation
├── infra/                 # IaC (Railway, Cloudflare, Terraform)
└── .github/               # CI/CD, templates, CODEOWNERS
```

---

## Data Model (Core Entities)

```
users          (Supabase auth.users extended via profiles)
photographers  (extends users: bio, portfolio, pricing, availability)
clients        (extends users: contact info, preferences)
bookings       (photographer ↔ client: date, status, pricing)
portfolios     (belongs to photographer: photos, albums)
photos         (belongs to portfolio: R2 key, metadata, AI tags)
reviews        (belongs to booking: rating, text)
messages       (direct messaging between users)
notifications  (in-app and push notifications)
```

---

## Authentication Flow

1. User signs up / logs in via Supabase Auth (email+password or OAuth2).
2. Supabase issues a short-lived JWT (1 h) + a long-lived refresh token stored
   in an httpOnly cookie (web) or secure storage (mobile).
3. The JWT `role` claim drives PostgreSQL RLS policies.
4. Edge Functions validate the JWT on every request using
   `supabase.auth.getUser()`.

---

## Image / Media Pipeline

1. Mobile / web client requests a **signed upload URL** from an Edge Function.
2. The Edge Function validates the user's quota and permissions, then returns a
   pre-signed Cloudflare R2 URL.
3. The client uploads directly to R2 (bypassing the application server).
4. After upload, the Edge Function triggers an async job to:
   - Generate thumbnails (via Cloudflare Images transform or a worker).
   - Extract EXIF metadata.
   - Run AI tagging (optional, via an external model API).
5. The database record is updated with the final R2 key and metadata.

---

## Scalability Considerations

- **Database**: Supabase Pro plan supports read replicas and connection pooling
  (PgBouncer). Indexes on `bookings(photographer_id)`, `photos(portfolio_id)`,
  and full-text search columns.
- **Edge Functions**: Stateless Deno workers auto-scale horizontally.
- **CDN**: Static assets and ISR pages cached at Cloudflare edge.
- **Rate limiting**: Applied per-user at the Edge Function level using Supabase
  KV or Upstash Redis.
- **Background jobs**: Long-running tasks (image processing, email batches)
  handled via Supabase pg_cron or an external queue (e.g., Inngest).

---

## Further Reading

- [DEPLOYMENT.md](DEPLOYMENT.md) — Railway, Supabase, and Cloudflare R2 setup
- [MONITORING.md](MONITORING.md) — Logging, alerting, and observability
- [SECURITY.md](../SECURITY.md) — Security policies and controls
- [GDPR.md](GDPR.md) — Data protection and privacy compliance
