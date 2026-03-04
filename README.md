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

## Documentation

| Document | Description |
|----------|-------------|
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