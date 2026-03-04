# Security Policy — photographes.ci

## Supported Versions

| Version | Supported          |
|---------|--------------------|
| latest  | ✅ Yes             |
| < latest | ❌ No (upgrade required) |

## Reporting a Vulnerability

We take security issues seriously. **Do not open a public GitHub issue for
security vulnerabilities.**

### Responsible Disclosure Process

1. **Private Advisory (preferred)** — Open a
   [GitHub Security Advisory](../../security/advisories/new) directly in this
   repository. This keeps the disclosure private until a patch is released.

2. **Email** — Send details to `security@photographes.ci` with:
   - A description of the vulnerability
   - Steps to reproduce
   - Potential impact
   - Your suggested fix (optional)

### Response Timeline

| Stage | Target SLA |
|-------|-----------|
| Initial acknowledgement | 48 hours |
| Severity assessment | 5 business days |
| Patch for Critical / High | 14 days |
| Patch for Medium | 30 days |
| Patch for Low | 90 days |
| Public disclosure | After patch release |

We follow a coordinated disclosure model: we will credit researchers who report
valid vulnerabilities (unless they prefer to remain anonymous).

## Security Architecture Overview

### Authentication & Authorization
- **Supabase Auth** — JWT-based authentication with RS256 signing.
- **Row-Level Security (RLS)** — enforced at the database level for every table.
- **Role hierarchy**: `anon` → `authenticated` → `photographer` → `admin`.
- Short-lived access tokens (1 hour) with automatic refresh via secure
  httpOnly cookies on the web.
- OAuth2 providers (Google, Apple) handled by Supabase Auth.

### Data in Transit
- All HTTP traffic served over TLS 1.2+ (enforced by Railway / Cloudflare).
- HSTS header with `max-age=31536000; includeSubDomains; preload`.

### Data at Rest
- Supabase PostgreSQL database encrypted at rest (AES-256).
- Cloudflare R2 object storage encrypted at rest.
- Secrets managed via Railway and Supabase environment variables — never
  committed to source code.

### Secrets Management
- `.env` files are listed in `.gitignore` and **must never** be committed.
- Rotate all secrets immediately if accidental exposure occurs.
- Use GitHub Secrets for CI/CD credentials.

### Dependency Security
- `npm audit` and `flutter pub outdated` run on every PR (see
  `.github/workflows/dependency-review.yml`).
- CodeQL static analysis runs on every push (see
  `.github/workflows/codeql.yml`).
- Dependabot alerts are enabled for npm, pub, and GitHub Actions.

## Security Checklist for Contributors

Before submitting a pull request, ensure:

- [ ] No secrets, API keys, or credentials in code or commits.
- [ ] Input validated and sanitized on both client and server.
- [ ] New Supabase tables have RLS policies (`ALTER TABLE … ENABLE ROW LEVEL SECURITY`).
- [ ] New API endpoints require appropriate authentication.
- [ ] Third-party dependencies reviewed for known CVEs.
- [ ] File uploads validated (type, size, content) before storing in R2.
- [ ] GDPR impact assessed for any new personal-data fields (see `docs/GDPR.md`).
