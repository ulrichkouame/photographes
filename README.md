# photographes.ci — Supabase Edge Functions

Documentation technique des Edge Functions déployées sur Supabase pour la plateforme **photographes.ci**.

---

## Table des matières

- [Architecture](#architecture)
- [Prérequis](#prérequis)
- [Configuration](#configuration)
- [Schéma de base de données](#schéma-de-base-de-données)
- [Edge Functions](#edge-functions)
  - [send-otp](#send-otp)
  - [verify-otp](#verify-otp)
  - [watermark](#watermark)
  - [process-payment](#process-payment)
  - [auto-refund](#auto-refund)
  - [sync-settings](#sync-settings)
- [Tests automatisés](#tests-automatisés)
- [Déploiement](#déploiement)
- [Sécurité](#sécurité)

---

## Architecture

```
supabase/
├── config.toml                     # Configuration Supabase locale
├── functions/
│   ├── _shared/                    # Modules partagés entre les functions
│   │   ├── types.ts                # Types TypeScript communs
│   │   ├── utils.ts                # Utilitaires HTTP et OTP
│   │   └── supabase.ts             # Factory clients Supabase
│   ├── send-otp/index.ts           # Envoi OTP WhatsApp via WasenderAPI
│   ├── verify-otp/index.ts         # Vérification OTP + JWT session
│   ├── watermark/index.ts          # Watermark + thumbnail + upload R2
│   ├── process-payment/index.ts    # Traitement Mobile Money
│   ├── auto-refund/index.ts        # Remboursement auto contacts expirés
│   └── sync-settings/index.ts      # Synchronisation paramètres dynamiques
└── tests/
    ├── utils.test.ts
    ├── send-otp.test.ts
    ├── verify-otp.test.ts
    ├── watermark.test.ts
    ├── process-payment.test.ts
    ├── auto-refund.test.ts
    └── sync-settings.test.ts

docs/
└── schema.sql                      # Schéma complet de la base de données
```

### Flux d'authentification

```
Client              send-otp          verify-otp        Auth DB
  │                     │                  │               │
  ├─POST /send-otp ─────►│                  │               │
  │   {phone}            ├──upsert OTP ─────────────────────►│
  │                      ├──WasenderAPI ►WhatsApp            │
  │◄─{success} ──────────┤                  │               │
  │                      │                  │               │
  ├─POST /verify-otp ───────────────────────►│               │
  │   {phone, code}      │                  ├──check OTP ───►│
  │                      │                  ├──get/create user►│
  │◄─{access_token} ──────────────────────────────────────────│
```

---

## Prérequis

- [Deno](https://deno.land/) ≥ 1.40
- [Supabase CLI](https://supabase.com/docs/guides/cli)
- Un projet Supabase (URL + clés)
- Un compte WasenderAPI (envoi WhatsApp)
- Un bucket Cloudflare R2 (images)

---

## Configuration

Toutes les clés dynamiques sont stockées dans la table `app_settings`. Des variables d'environnement servent de fallback.

### Variables d'environnement (secrets Supabase)

```bash
# Obligatoires
SUPABASE_URL=https://xxx.supabase.co
SUPABASE_SERVICE_ROLE_KEY=eyJ...
SUPABASE_ANON_KEY=eyJ...

# WasenderAPI
WASENDER_API_KEY=your-wasender-key

# Cloudflare R2
R2_ACCOUNT_ID=your-cloudflare-account-id
R2_ACCESS_KEY_ID=your-r2-access-key
R2_SECRET_KEY=your-r2-secret-key
R2_BUCKET_NAME=photographes-media
R2_PUBLIC_URL=https://pub-xxx.r2.dev

# Mobile Money providers
PAYMENT_MTN_API_KEY=...
PAYMENT_MTN_API_URL=https://sandbox.momodeveloper.mtn.com
PAYMENT_ORANGE_API_KEY=...
PAYMENT_ORANGE_API_URL=https://api.orange.com
PAYMENT_WAVE_API_KEY=...
PAYMENT_WAVE_API_URL=https://api.wave.com
PAYMENT_MOOV_API_KEY=...
PAYMENT_MOOV_API_URL=https://api.moov.africa
PAYMENT_CALLBACK_URL=https://photographes.ci/webhooks/payment
```

### Paramètres en base (app_settings)

| Clé | Valeur par défaut | Public | Description |
|-----|------------------|--------|-------------|
| `app_name` | `photographes.ci` | ✅ | Nom de l'application |
| `app_version` | `1.0.0` | ✅ | Version |
| `app_currency` | `XOF` | ✅ | Devise (FCFA) |
| `contact_price` | `5000` | ✅ | Prix accès coordonnées |
| `contact_validity_days` | `30` | ✅ | Durée validité accès |
| `otp_expiry_seconds` | `600` | ❌ | Durée OTP en secondes |
| `wasender_api_key` | — | ❌ | Clé API WasenderAPI |
| `refund_provider` | `mtn` | ❌ | Provider de remboursement |
| `r2_account_id` | — | ❌ | Cloudflare account ID |
| `r2_secret_key` | — | ❌ | R2 Secret Key |
| `payment_mtn_api_key` | — | ❌ | Clé API MTN |

---

## Schéma de base de données

Voir [`docs/schema.sql`](docs/schema.sql) pour le schéma complet avec les tables, index, RLS et données initiales.

Tables principales :
- `app_settings` — Configuration dynamique clé/valeur
- `otp_verifications` — Codes OTP temporaires
- `contacts` — Profils des photographes
- `payment_transactions` — Historique des paiements Mobile Money

---

## Edge Functions

### send-otp

**Envoi d'un code OTP par WhatsApp via WasenderAPI.**

```
POST /functions/v1/send-otp
Content-Type: application/json
```

**Requête :**
```json
{ "phone": "+2250700000000" }
```

**Réponse (200) :**
```json
{
  "success": true,
  "message": "Un code de vérification a été envoyé au +2250700000000 via WhatsApp.",
  "expires_in_seconds": 600
}
```

**Erreurs :** `400` champ invalide · `503` config manquante · `502` échec envoi WA

---

### verify-otp

**Vérification du code OTP et retour d'un JWT de session Supabase.**

```
POST /functions/v1/verify-otp
Content-Type: application/json
```

**Requête :**
```json
{ "phone": "+2250700000000", "code": "123456" }
```

**Réponse (200) :**
```json
{
  "success": true,
  "access_token": "eyJhbGci...",
  "refresh_token": "v1:...",
  "user": { "id": "uuid", "phone": "+2250700000000" },
  "message": "Authentification réussie."
}
```

**Erreurs :** `401` code incorrect · `404` OTP introuvable · `410` OTP expiré

---

### watermark

**Watermark «photographes.ci» + thumbnail 400px + upload R2.**

```
POST /functions/v1/watermark
Authorization: Bearer <jwt>
Content-Type: application/json
```

**Requête (URL) :**
```json
{ "image_url": "https://example.com/photo.jpg" }
```

**Requête (Storage) :**
```json
{ "storage_path": "photos/uuid/original.jpg" }
```

**Réponse (200) :**
```json
{
  "success": true,
  "watermarked_url": "https://pub.r2.dev/bucket/watermarked/uuid/photo_watermarked.jpg",
  "thumbnail_url": "https://pub.r2.dev/bucket/thumbnails/uuid/photo_thumbnail.jpg",
  "message": "Image traitée et uploadée avec succès."
}
```

---

### process-payment

**Initiation d'un paiement Mobile Money (MTN, Orange, Wave, Moov).**

```
POST /functions/v1/process-payment
Authorization: Bearer <jwt>
Content-Type: application/json
```

**Requête :**
```json
{
  "amount": 5000,
  "phone": "+2250700000000",
  "provider": "mtn",
  "reference": "PHOTO-2024-001",
  "description": "Accès aux coordonnées photographe",
  "contact_id": "uuid"
}
```

**Providers :** `mtn` | `orange` | `wave` | `moov`

**Réponse (201) :**
```json
{
  "success": true,
  "transaction_id": "uuid",
  "status": "pending",
  "message": "Paiement initié.",
  "provider_reference": "ref-provider"
}
```

---

### auto-refund

**Remboursement automatique des contacts expirés ou non traités.**

```
POST /functions/v1/auto-refund
```

Déclencher via **cron Supabase** (ex : toutes les heures).

**Contacts éligibles :** statut `expired`/`unprocessed`/`pending` + transaction `success` + pas encore remboursé.

**Réponse (200) :**
```json
{
  "success": true,
  "processed": 3,
  "refunded": 2,
  "failed": 1,
  "results": [...]
}
```

---

### sync-settings

**Paramètres de configuration dynamique depuis la base.**

```
GET  /functions/v1/sync-settings     → Paramètres publics (is_public=true)
POST /functions/v1/sync-settings     → Tous les paramètres (avec Bearer token)
```

> Les clés secrètes sont **toujours filtrées**, même pour les admins.

**Réponse (200) :**
```json
{
  "success": true,
  "settings": { "app_name": "photographes.ci", "contact_price": "5000" },
  "count": 6,
  "synced_at": "2024-01-01T00:00:00.000Z"
}
```

---

## Tests automatisés

```bash
# Tous les tests (74 tests)
deno test supabase/tests/

# Un fichier spécifique
deno test supabase/tests/send-otp.test.ts
```

| Fichier | Tests | Couverture |
|---------|-------|-----------|
| `utils.test.ts` | 15 | generateOtp, expiresAt, isExpired, sanitisePhone, validateRequiredFields |
| `send-otp.test.ts` | 9 | Validation, OTP, message WA, requête WasenderAPI |
| `verify-otp.test.ts` | 11 | Codes, expiration, flux succès/échec, réutilisation |
| `watermark.test.ts` | 10 | SHA-256, URLs R2, nommage, config, HMAC |
| `process-payment.test.ts` | 10 | Providers, montants, requêtes, doublons, statuts |
| `auto-refund.test.ts` | 10 | Éligibilité, filtrage, résumés, statuts |
| `sync-settings.test.ts` | 9 | Filtrage public/privé, secrets, auth, structure |
| **Total** | **74** | |

---

## Déploiement

```bash
# Démarrer l'environnement local
supabase start

# Déployer une function
supabase functions deploy send-otp

# Déployer toutes les functions
supabase functions deploy

# Configurer les secrets
supabase secrets set WASENDER_API_KEY=your-key
supabase secrets set R2_SECRET_KEY=your-secret
```

### Cron auto-refund

```sql
SELECT cron.schedule(
  'auto-refund-hourly', '0 * * * *',
  $$ SELECT net.http_post(
    url := 'https://xxx.supabase.co/functions/v1/auto-refund',
    headers := '{"Authorization":"Bearer <service-key>"}'::jsonb,
    body := '{}'::jsonb
  ); $$
);
```

---

## Sécurité

- **Service Role Key** : Utilisée uniquement côté serveur (Edge Functions)
- **OTP** : Généré avec `crypto.getRandomValues()`, durée de vie configurable (600s par défaut)
- **Secrets** : Jamais retournés par `sync-settings`
- **RLS** : Row Level Security activé sur toutes les tables
- **CORS** : Headers configurés sur toutes les réponses
- **Validation** : Tous les inputs validés avant traitement
- **Phone** : Normalisés en E.164, vérifiés pour le format CI (+225, 10 chiffres commençant par 0)
- **R2** : Upload via AWS Signature V4 calculée côté serveur