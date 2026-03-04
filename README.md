<<<<<<< HEAD
# Photographes.ci

Plateforme de mise en relation entre photographes professionnels et clients en Côte d'Ivoire.

## Description

**Photographes.ci** est un monorepo regroupant toutes les applications et services de la plateforme :

- 📱 **Mobile** (`apps/mobile`) — Application Flutter (iOS & Android)
- 🌐 **Web** (`apps/web`) — Application Next.js (site vitrine, portail client & dashboard admin)
- ⚙️ **Backend** (`supabase`) — Base de données PostgreSQL, authentification OTP WhatsApp, Edge Functions, Storage
- 📦 **Shared** (`packages/shared`) — Types TypeScript partagés entre web et mobile
=======
# photographes.ci

> Marketplace connecting photographers with clients in Côte d'Ivoire and West Africa.

[![CI](https://github.com/ulrichkouame/photographes/actions/workflows/ci.yml/badge.svg)](https://github.com/ulrichkouame/photographes/actions/workflows/ci.yml)
[![CodeQL](https://github.com/ulrichkouame/photographes/actions/workflows/codeql.yml/badge.svg)](https://github.com/ulrichkouame/photographes/actions/workflows/codeql.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

---

## Stack

| Layer | Technology |
|-------|-----------|
| Web frontend | Next.js 14 (App Router, TypeScript) — hosted on Railway |
| Mobile app | Flutter 3 (iOS & Android) |
| Backend | Supabase Edge Functions (Deno/TypeScript) |
| Database | PostgreSQL 15 (Supabase, with RLS) |
| Auth | Supabase Auth (JWT, OAuth2: Google, Apple) |
| Object storage | Cloudflare R2 |
| Email | Resend |
| Payments | CinetPay / Wave |
| Monitoring | Sentry + Datadog |
| Analytics | Google Analytics 4 + Firebase Analytics |

---

## Repository Structure

```
photographes/
├── apps/
│   ├── web/          # Next.js application
│   └── mobile/       # Flutter application
├── supabase/
│   ├── functions/    # Deno Edge Functions
│   └── migrations/   # PostgreSQL migrations
├── docs/             # Project documentation
├── infra/            # Infrastructure-as-code
└── .github/          # CI/CD, templates, CODEOWNERS
```

---

## Quick Start

### Prerequisites

- Node.js ≥ 20
- Flutter ≥ 3.x (stable channel)
- Deno ≥ 1.x
- Supabase CLI (latest)
- Docker ≥ 24 (for local Supabase)

### Setup

```bash
# Clone
git clone https://github.com/ulrichkouame/photographes.git
cd photographes

# Web
cd apps/web && npm install && cp .env.example .env.local && cd ../..

# Mobile
cd apps/mobile && flutter pub get && cd ../..

# Local Supabase
supabase start
```

---
>>>>>>> origin/copilot/audit-project-photographes-ci

## Documentation

| Document | Description |
|----------|-------------|
<<<<<<< HEAD
| [ARCHITECTURE.md](docs/ARCHITECTURE.md) | Diagrammes d'architecture, flux de données, choix techniques, sécurité |
| [DATABASE.md](docs/DATABASE.md) | ERD, description des tables, politiques RLS, index, triggers |
| [API.md](docs/API.md) | Edge Functions, endpoints, exemples de requêtes/réponses, codes d'erreur |
| [SETUP.md](docs/SETUP.md) | Guide d'installation, variables d'environnement, prérequis, commandes |
| [DEPLOYMENT.md](docs/DEPLOYMENT.md) | Déploiement Railway, Supabase, Cloudflare R2, Next.js, Flutter |
| [CONVENTIONS.md](docs/CONVENTIONS.md) | Conventions de code, workflow Git, règles de nommage, process PR/tests |
| [FEATURES.md](docs/FEATURES.md) | Checklist des écrans/features, mapping données/state, statuts d'implémentation |

## Structure du projet

```
photographes/
├── apps/
│   ├── mobile/          # Application Flutter (iOS & Android)
│   └── web/             # Application Next.js (App Router, TypeScript)
├── packages/
│   └── shared/          # Types TypeScript partagés
├── supabase/
│   ├── migrations/      # Migrations SQL
│   ├── functions/       # Edge Functions (Deno/TypeScript)
│   └── config.toml      # Configuration Supabase local
├── docs/                # Documentation complète
├── .github/
│   └── workflows/       # Pipelines CI/CD (web, mobile, supabase)
└── README.md
```

## Stack technique

| Couche | Technologie |
|--------|-------------|
| Web frontend | Next.js 15 (App Router, TypeScript, Tailwind CSS, shadcn/ui) |
| Mobile | Flutter 3 (Riverpod, GoRouter, supabase_flutter) |
| Backend | Supabase (PostgreSQL 15, Auth, Edge Functions Deno, Storage) |
| Storage images | Cloudflare R2 (S3-compatible, CDN mondial) |
| OTP WhatsApp | WasenderAPI |
| Paiement | Mobile Money (Orange Money CI, MTN MoMo CI) |
| CI/CD | GitHub Actions |
| Déploiement web | Railway |

## Démarrage rapide

### Prérequis

- [Flutter SDK](https://flutter.dev/docs/get-started/install) ≥ 3.x
- [Node.js](https://nodejs.org/) ≥ 18.x
- [Supabase CLI](https://supabase.com/docs/guides/cli) (latest)
- [Docker](https://www.docker.com/) ≥ 24.x (pour Supabase local)

### Installation

```bash
# 1. Cloner le dépôt
git clone https://github.com/ulrichkouame/photographes.git
cd photographes

# 2. Installer les dépendances Web
npm install

# 3. Installer les dépendances Flutter
cd apps/mobile && flutter pub get && cd ../..

# 4. Configurer les variables d'environnement
cp apps/web/.env.example apps/web/.env.local
# Éditer apps/web/.env.local avec vos valeurs Supabase

# 5. Démarrer Supabase en local
supabase start
supabase db reset

# 6. Démarrer le serveur web
npm run dev:web
# → http://localhost:3000

# 7. Lancer l'app mobile (émulateur requis)
cd apps/mobile && flutter run
```

> 📖 **Guide complet** : voir [docs/SETUP.md](docs/SETUP.md)

## Commandes principales

```bash
# Web (depuis la racine)
npm run dev:web       # Démarrage développement
npm run build:web     # Build production
npm run lint          # Lint tous les workspaces

# Mobile (depuis apps/mobile)
flutter run           # Lancer sur émulateur
flutter test          # Tests unitaires
flutter analyze       # Lint Dart

# Supabase
supabase start        # Démarrer en local
supabase db reset     # Appliquer les migrations
supabase functions serve  # Servir les Edge Functions
```

## Licence

MIT
=======
| [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) | System design and data model |
| [docs/DEPLOYMENT.md](docs/DEPLOYMENT.md) | Railway, Supabase, Cloudflare R2 setup |
| [docs/MONITORING.md](docs/MONITORING.md) | Sentry, Datadog, alerting, SLOs |
| [docs/GDPR.md](docs/GDPR.md) | Data protection and privacy compliance |
| [docs/ACCESSIBILITY.md](docs/ACCESSIBILITY.md) | WCAG 2.1 AA guidelines |
| [docs/ANALYTICS.md](docs/ANALYTICS.md) | GA4, Firebase, Datadog RUM setup |
| [docs/LOCALIZATION.md](docs/LOCALIZATION.md) | i18n, locale-aware formatting |
| [docs/PERFORMANCE.md](docs/PERFORMANCE.md) | Lighthouse targets, profiling guides |
| [docs/BACKUP.md](docs/BACKUP.md) | Database backup and restore procedures |
| [docs/ONBOARDING.md](docs/ONBOARDING.md) | User onboarding flows and UX |
| [docs/SUPPORT.md](docs/SUPPORT.md) | Helpdesk, Intercom, feedback collection |
| [CONTRIBUTING.md](CONTRIBUTING.md) | How to contribute |
| [SECURITY.md](SECURITY.md) | Security policy and responsible disclosure |

---

## CI/CD Workflows

| Workflow | Trigger | Description |
|---------|---------|-------------|
| `ci.yml` | Push / PR | Lint, type-check, unit tests (web, mobile, functions) |
| `e2e.yml` | Push to main / PR / nightly | Playwright (web) + Flutter integration tests (Android) |
| `codeql.yml` | Push / PR / weekly | CodeQL static analysis |
| `deploy.yml` | Push to main | Deploy web → Railway, functions → Supabase, mobile → stores |
| `lighthouse.yml` | PR / weekly | Lighthouse performance & accessibility audit |
| `dependency-review.yml` | PR | Dependency vulnerability review |

---

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for setup instructions, branching
strategy, commit conventions, and pull request guidelines.

## Security

See [SECURITY.md](SECURITY.md) for the vulnerability reporting process and
security architecture overview.

## License

[MIT](LICENSE) © photographes.ci
>>>>>>> origin/copilot/audit-project-photographes-ci
