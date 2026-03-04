# Contributing to photographes.ci

Thank you for your interest in contributing to **photographes.ci**! This guide
explains how to set up your environment, submit changes, and meet our quality
standards.

---

## Table of Contents

1. [Code of Conduct](#code-of-conduct)
2. [Project Structure](#project-structure)
3. [Development Setup](#development-setup)
4. [Branching Strategy](#branching-strategy)
5. [Commit Message Convention](#commit-message-convention)
6. [Submitting a Pull Request](#submitting-a-pull-request)
7. [Coding Standards](#coding-standards)
8. [Testing Requirements](#testing-requirements)
9. [Documentation](#documentation)
10. [Reporting Issues](#reporting-issues)

---

## Code of Conduct

This project follows the [Contributor Covenant Code of Conduct](CODE_OF_CONDUCT.md).
By participating you agree to uphold these standards. Report unacceptable
behaviour to `conduct@photographes.ci`.

---

## Project Structure

```
photographes/
├── apps/
│   ├── web/          # Next.js web application
│   └── mobile/       # Flutter mobile application (iOS & Android)
├── supabase/
│   ├── functions/    # Deno Edge Functions
│   └── migrations/   # PostgreSQL migrations
├── docs/             # Project-wide documentation
├── infra/            # Infrastructure-as-code (Railway, Cloudflare)
└── .github/          # CI/CD workflows, templates, CODEOWNERS
```

---

## Development Setup

### Prerequisites

| Tool | Version |
|------|---------|
| Node.js | ≥ 20 |
| Flutter | ≥ 3.x (stable) |
| Deno | ≥ 1.x |
| Supabase CLI | latest |
| Docker | ≥ 24 (for local Supabase) |

### First-time setup

```bash
# 1. Clone the repository
git clone https://github.com/ulrichkouame/photographes.git
cd photographes

# 2. Install web dependencies
cd apps/web && npm install && cd ../..

# 3. Install mobile dependencies
cd apps/mobile && flutter pub get && cd ../..

# 4. Start local Supabase stack
supabase start

# 5. Copy environment files
cp apps/web/.env.example apps/web/.env.local
# Fill in the values from `supabase status`
```

---

## Branching Strategy

We use **GitHub Flow** (simplified trunk-based development):

| Branch | Purpose |
|--------|---------|
| `main` | Production-ready code. Protected; requires PR + review. |
| `develop` | Integration branch for features in progress. |
| `feat/<name>` | New features |
| `fix/<name>` | Bug fixes |
| `chore/<name>` | Dependency updates, tooling, config changes |
| `docs/<name>` | Documentation-only changes |

---

## Commit Message Convention

We follow [Conventional Commits](https://www.conventionalcommits.org/):

```
<type>(scope): <short summary>

[optional body]

[optional footer: Closes #<issue>]
```

**Types**: `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`,
`chore`, `ci`, `revert`.

**Examples**:
```
feat(web): add photographer profile page
fix(mobile): resolve image upload crash on Android 14
docs: update GDPR data inventory table
chore(deps): bump next from 14.1.0 to 14.2.0
```

---

## Submitting a Pull Request

1. Create a branch from `develop` (or `main` for urgent fixes).
2. Make your changes with focused commits.
3. Ensure all CI checks pass locally (see [Testing Requirements](#testing-requirements)).
4. Open a PR against `develop` using the provided PR template.
5. Request a review from at least one maintainer (CODEOWNERS is enforced).
6. Address review comments. Once approved, a maintainer will merge.

---

## Coding Standards

### Web (Next.js / TypeScript)
- ESLint + Prettier enforced via `npm run lint` and `npm run format`.
- Follow the [Next.js App Router](https://nextjs.org/docs/app) conventions.
- Use Server Components by default; add `"use client"` only where needed.
- Accessibility: every interactive element must be keyboard-navigable and have
  an accessible name (see `docs/ACCESSIBILITY.md`).

### Mobile (Flutter / Dart)
- `flutter analyze` must produce zero issues.
- `dart format` applied before committing.
- Follow [Effective Dart](https://dart.dev/effective-dart) guidelines.
- Use `flutter_riverpod` (or the project's chosen state-management solution).

### Edge Functions (Deno / TypeScript)
- `deno lint` and `deno fmt --check` must pass.
- Functions must be idempotent where possible.
- Always validate and sanitise request inputs.
- Document environment variables in `supabase/functions/.env.example`.

### Database (PostgreSQL / Supabase)
- Every new table **must** have RLS enabled and appropriate policies.
- Migrations are sequential and reversible (provide a `down` migration).
- No raw SQL in application code — use the Supabase client or stored functions.

---

## Testing Requirements

| Layer | Minimum coverage |
|-------|-----------------|
| Web unit tests (Jest/Vitest) | 70 % statements |
| Mobile unit & widget tests | 70 % statements |
| Edge Functions (Deno test) | 70 % statements |
| E2E (Playwright / Flutter integration) | Critical user flows |

Run tests locally before pushing:

```bash
# Web
cd apps/web && npm test

# Mobile
cd apps/mobile && flutter test

# Edge Functions
cd supabase/functions && deno test --allow-all
```

---

## Documentation

- Update relevant `docs/` files alongside code changes.
- New environment variables must be added to `.env.example` files.
- API changes must be reflected in the OpenAPI spec (if applicable).
- GDPR-relevant data changes must update `docs/GDPR.md`.

---

## Reporting Issues

- **Bugs** → use the [Bug Report](.github/ISSUE_TEMPLATE/bug_report.md) template.
- **Features** → use the [Feature Request](.github/ISSUE_TEMPLATE/feature_request.md) template.
- **Security** → see [SECURITY.md](SECURITY.md) for responsible disclosure.

---

*Thank you for helping make photographes.ci better!* 🎞️
