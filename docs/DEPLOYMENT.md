# Deployment Guide — photographes.ci

## Infrastructure Overview

| Component | Platform | Region |
|-----------|---------|--------|
| Web app (Next.js) | Railway | Europe West (Paris) |
| Edge Functions | Supabase | West Africa (or nearest) |
| Database (PostgreSQL) | Supabase | West Africa (or nearest) |
| Object storage | Cloudflare R2 | Global |
| Mobile (Android) | Google Play Store | Global |
| Mobile (iOS) | Apple App Store | Global |

---

## Required Secrets

### GitHub Secrets (for CI/CD)

| Secret | Used by | Description |
|--------|---------|-------------|
| `RAILWAY_TOKEN` | deploy.yml | Railway API token |
| `SUPABASE_PROJECT_REF` | deploy.yml | Supabase project reference |
| `SUPABASE_ACCESS_TOKEN` | deploy.yml | Supabase personal access token |
| `SUPABASE_URL` | CI + deploy | Supabase project URL |
| `SUPABASE_ANON_KEY` | CI + deploy | Supabase anonymous (public) key |
| `R2_ACCESS_KEY_ID` | backup.yml | Cloudflare R2 access key |
| `R2_SECRET_ACCESS_KEY` | backup.yml | Cloudflare R2 secret key |
| `R2_ENDPOINT` | backup.yml | R2 endpoint URL |
| `R2_BUCKET_NAME` | backup.yml | R2 bucket name |
| `ANDROID_KEYSTORE_BASE64` | deploy.yml | Android release keystore (base64) |
| `ANDROID_KEY_ALIAS` | deploy.yml | Android key alias |
| `ANDROID_KEY_PASSWORD` | deploy.yml | Android key password |
| `ANDROID_STORE_PASSWORD` | deploy.yml | Android keystore password |
| `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON` | deploy.yml | Google Play service account |
| `APPSTORE_ISSUER_ID` | deploy.yml | App Store Connect issuer ID |
| `APPSTORE_API_KEY_ID` | deploy.yml | App Store Connect API key ID |
| `APPSTORE_API_PRIVATE_KEY` | deploy.yml | App Store Connect private key |
| `E2E_SUPABASE_URL` | e2e.yml | Staging Supabase URL for E2E tests |
| `E2E_SUPABASE_ANON_KEY` | e2e.yml | Staging Supabase anon key for E2E |
| `LHCI_GITHUB_APP_TOKEN` | lighthouse.yml | Lighthouse CI GitHub App token |
| `STAGING_DATABASE_URL` | backup-verify.yml | Staging PostgreSQL connection string |
| `SLACK_OPS_WEBHOOK_URL` | backup-verify.yml | Slack Incoming Webhook URL for ops alerts |

---

## Railway — Web Application

### First-time Setup

```bash
# Install Railway CLI
npm install -g @railway/cli

# Login
railway login

# Link to project
railway link

# Set environment variables
railway variables set NEXT_PUBLIC_SUPABASE_URL=https://xxx.supabase.co
railway variables set NEXT_PUBLIC_SUPABASE_ANON_KEY=eyJ...
railway variables set SENTRY_DSN=https://...@sentry.io/...
railway variables set NEXT_PUBLIC_GA_MEASUREMENT_ID=G-XXXXXXXXXX
```

### railway.toml Configuration

```toml
# railway.toml
[build]
builder = "NIXPACKS"
buildCommand = "npm run build"

[deploy]
startCommand = "npm run start"
healthcheckPath = "/api/health"
healthcheckTimeout = 30
restartPolicyType = "ON_FAILURE"
restartPolicyMaxRetries = 3

[[services]]
name = "photographes-web"
source = "apps/web"
```

### Rollback

```bash
# List recent deployments
railway deployments list

# Rollback to a specific deployment
railway deployments rollback <DEPLOYMENT_ID>
```

---

## Supabase — Edge Functions & Database

### Deploy All Edge Functions

```bash
# Authenticate
supabase login

# Link to project
supabase link --project-ref <PROJECT_REF>

# Deploy all functions
supabase functions deploy

# Deploy a specific function
supabase functions deploy <function-name>
```

### Run Database Migrations

```bash
# Apply pending migrations to production
supabase db push --project-ref <PROJECT_REF>

# Check migration status
supabase migration list
```

### Environment Variables for Functions

```bash
supabase secrets set SENTRY_DSN=https://...@sentry.io/...
supabase secrets set R2_ACCESS_KEY_ID=...
supabase secrets set R2_SECRET_ACCESS_KEY=...
```

---

## Cloudflare R2 — Object Storage

### Bucket Setup

```bash
# Create production bucket
wrangler r2 bucket create photographes-media

# Enable CORS for web uploads
# (configure via Cloudflare dashboard → R2 → bucket → Settings → CORS)
```

### CORS Policy

```json
[
  {
    "AllowedOrigins": ["https://photographes.ci", "https://www.photographes.ci"],
    "AllowedMethods": ["GET", "PUT"],
    "AllowedHeaders": ["Content-Type", "Content-Length"],
    "MaxAgeSeconds": 3600
  }
]
```

### Custom Domain for Media

Map `cdn.photographes.ci` to the R2 bucket via Cloudflare DNS:
- Type: `CNAME`
- Name: `cdn`
- Target: `<bucket-name>.<account-id>.r2.cloudflarestorage.com`
- Proxy: ✅ (enables Cloudflare CDN and transforms)

---

## Mobile Releases

### Android — Google Play

1. Increment `versionCode` and `versionName` in `apps/mobile/android/app/build.gradle`.
2. Push to `main` — the `deploy.yml` workflow builds and uploads to the
   **internal** track automatically.
3. Promote from internal → alpha → production via the Google Play Console.

### iOS — App Store

1. Increment `CFBundleVersion` and `CFBundleShortVersionString` in `Info.plist`.
2. Push to `main` — the `deploy.yml` workflow builds and uploads to TestFlight.
3. Submit for App Store Review via App Store Connect.

---

## Deployment Checklist

Before deploying to production:

- [ ] All CI checks pass on `main`.
- [ ] Database migrations reviewed and tested on staging.
- [ ] Pre-deploy database snapshot taken (automated by deploy.yml).
- [ ] Environment variables set in Railway / Supabase for the new release.
- [ ] Sentry release created with source maps uploaded.
- [ ] Smoke tests pass on staging after deploy.
- [ ] Team notified in `#deployments` Slack channel.
