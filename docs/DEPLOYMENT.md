# Guide de déploiement — Photographes.ci

> **Liens rapides :** [README](../README.md) | [ARCHITECTURE](ARCHITECTURE.md) | [DATABASE](DATABASE.md) | [API](API.md) | [SETUP](SETUP.md) | [CONVENTIONS](CONVENTIONS.md) | [FEATURES](FEATURES.md)

## Table des matières

1. [Vue d'ensemble](#vue-densemble)
2. [Supabase (Backend)](#supabase-backend)
3. [Cloudflare R2 (Storage)](#cloudflare-r2-storage)
4. [Next.js sur Railway](#nextjs-sur-railway)
5. [Flutter (Mobile)](#flutter-mobile)
6. [Checklist de déploiement](#checklist-de-déploiement)

---

## Vue d'ensemble

```
┌─────────────────────────────────────────────────────────┐
│                  Infrastructure Production               │
│                                                         │
│  ┌──────────────────┐      ┌─────────────────────────┐ │
│  │   Railway         │      │   Supabase (Cloud)      │ │
│  │   (Next.js Web)   │◄────►│   - PostgreSQL 15       │ │
│  │                   │      │   - Auth (GoTrue)       │ │
│  │  photographes.ci  │      │   - Edge Functions      │ │
│  └──────────────────┘      │   - Storage             │ │
│                             └─────────────────────────┘ │
│                                        │                 │
│  ┌──────────────────┐                  ▼                 │
│  │  App Stores       │      ┌─────────────────────────┐ │
│  │  (Flutter)        │      │   Cloudflare R2          │ │
│  │  - Play Store     │      │   - Portfolio images    │ │
│  │  - App Store      │      │   - Thumbnails          │ │
│  └──────────────────┘      └─────────────────────────┘ │
└─────────────────────────────────────────────────────────┘
```

---

## Supabase (Backend)

### 1. Créer un projet Supabase

1. Aller sur [app.supabase.com](https://app.supabase.com)
2. Cliquer **New project**
3. Choisir un nom : `photographes`
4. Choisir la région : **EU West (Paris)** ou **US East** selon l'audience
5. Définir un mot de passe fort pour la base de données
6. Cliquer **Create new project**

### 2. Récupérer les credentials

Dans **Project Settings > API** :

| Variable | Emplacement |
|----------|-------------|
| `SUPABASE_URL` | Project URL |
| `SUPABASE_ANON_KEY` | `anon` public key |
| `SUPABASE_SERVICE_ROLE_KEY` | `service_role` key (secret) |
| `SUPABASE_PROJECT_REF` | Reference ID (dans l'URL) |

### 3. Appliquer les migrations

```bash
# Lier le projet local au projet Supabase Cloud
supabase link --project-ref <PROJECT_REF>

# Pousser toutes les migrations
supabase db push

# Vérifier que les migrations ont été appliquées
supabase migration list
```

### 4. Déployer les Edge Functions

```bash
# Déployer toutes les fonctions
supabase functions deploy

# Déployer une fonction spécifique
supabase functions deploy send-otp
supabase functions deploy verify-otp
supabase functions deploy watermark
supabase functions deploy process-payment
supabase functions deploy auto-refund
supabase functions deploy sync-settings
```

### 5. Configurer les secrets des Edge Functions

```bash
# Ajouter les secrets (une fois)
supabase secrets set WASENDER_API_KEY=your_key
supabase secrets set R2_ACCOUNT_ID=your_account_id
supabase secrets set R2_ACCESS_KEY_ID=your_access_key
supabase secrets set R2_SECRET_ACCESS_KEY=your_secret_key
supabase secrets set R2_BUCKET_NAME=photographes

# Lister les secrets configurés
supabase secrets list
```

### 6. Configurer l'authentification

Dans **Authentication > Settings** :

- **Site URL** : `https://photographes.ci`
- **Redirect URLs** : `https://photographes.ci/**`, `com.photographes.app://login-callback`
- **JWT Expiry** : `3600` (1 heure)
- **Enable Phone Auth** : ✅

### 7. Configurer Storage

Dans **Storage** :
1. Créer un bucket `avatars` (public)
2. Configurer les politiques RLS pour avatars

```sql
-- Politique lecture publique des avatars
CREATE POLICY "Public avatar access"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'avatars');

-- Politique upload pour utilisateurs authentifiés
CREATE POLICY "Upload own avatar"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'avatars'
    AND auth.uid()::text = (storage.foldername(name))[1]
  );
```

### 8. Configurer pg_cron (auto-refund)

Dans l'éditeur SQL de Supabase :

```sql
-- Activer l'extension pg_cron
CREATE EXTENSION IF NOT EXISTS pg_cron;

-- Planifier l'auto-refund toutes les heures
SELECT cron.schedule(
  'auto-refund-expired-contacts',
  '0 * * * *',
  $$
  SELECT net.http_post(
    url := current_setting('app.supabase_url') || '/functions/v1/auto-refund',
    headers := json_build_object(
      'Authorization', 'Bearer ' || current_setting('app.service_role_key'),
      'Content-Type', 'application/json'
    )::jsonb,
    body := '{}'::jsonb
  );
  $$
);
```

---

## Cloudflare R2 (Storage)

### 1. Créer un bucket R2

1. Aller dans [Cloudflare Dashboard](https://dash.cloudflare.com/) > **R2**
2. Cliquer **Create bucket**
3. Nom du bucket : `photographes`
4. Région : Automatique

### 2. Configurer l'accès public

1. Dans le bucket **photographes** > **Settings**
2. Activer **Public access**
3. Configurer un domaine personnalisé (optionnel) : `cdn.photographes.ci`

### 3. Créer les credentials API

1. Aller dans **R2 > Manage R2 API tokens**
2. Cliquer **Create API token**
3. Permissions : **Object Read & Write**
4. Scope : **Specific bucket** → `photographes`
5. Copier `Access Key ID` et `Secret Access Key`

### 4. Structure du bucket

```
photographes/ (bucket)
├── portfolio/
│   ├── <photographer_id>/
│   │   ├── <image_id>.jpg         # Image originale avec watermark
│   │   └── thumbs/
│   │       └── <image_id>.jpg     # Thumbnail 400px
└── avatars/
    └── <user_id>.jpg
```

### 5. Variables R2 à configurer

```env
R2_ACCOUNT_ID=abc123def456
R2_ACCESS_KEY_ID=your_access_key_id
R2_SECRET_ACCESS_KEY=your_secret_access_key
R2_BUCKET_NAME=photographes
R2_PUBLIC_URL=https://pub-xxx.r2.dev
# ou avec domaine personnalisé :
R2_PUBLIC_URL=https://cdn.photographes.ci
```

---

## Next.js sur Railway

### 1. Créer un projet Railway

1. Aller sur [railway.app](https://railway.app)
2. Cliquer **New Project** > **Deploy from GitHub repo**
3. Sélectionner `ulrichkouame/photographes`
4. Railway détecte automatiquement Next.js

### 2. Configurer le service

Dans Railway > Settings du service :

- **Root Directory** : `apps/web`
- **Build Command** : `npm run build`
- **Start Command** : `npm run start`
- **Node.js version** : `20.x`

### 3. Ajouter les variables d'environnement

Dans Railway > Variables :

```env
NEXT_PUBLIC_SUPABASE_URL=https://<project>.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=eyJhbGci...
R2_ACCOUNT_ID=abc123
R2_ACCESS_KEY_ID=your_key
R2_SECRET_ACCESS_KEY=your_secret
R2_BUCKET_NAME=photographes
R2_PUBLIC_URL=https://cdn.photographes.ci
NEXT_PUBLIC_APP_URL=https://photographes.ci
NODE_ENV=production
```

### 4. Configurer le domaine personnalisé

Dans Railway > Settings > Domains :

1. Ajouter le domaine `photographes.ci`
2. Configurer les DNS chez votre registrar :
   - `CNAME photographes.ci → <id>.railway.app`
   - ou `A photographes.ci → <ip_railway>`

### 5. Déploiement automatique

Railway redéploie automatiquement à chaque push sur `main`.

Pour forcer un redéploiement :

```bash
# Via CLI Railway
railway up --service web
```

### 6. Vérification du déploiement

```bash
# Vérifier les logs
railway logs --service web

# Vérifier le statut
railway status
```

---

## Flutter (Mobile)

### Build Android (APK / AAB)

#### 1. Configurer la signature

Créer un keystore :

```bash
keytool -genkey -v -keystore android/app/photographes.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias photographes
```

Créer `apps/mobile/android/key.properties` :

```properties
storePassword=<mot_de_passe>
keyPassword=<mot_de_passe>
keyAlias=photographes
storeFile=photographes.jks
```

> ⚠️ Ne jamais committer `key.properties` et `*.jks`. Ils sont dans `.gitignore`.

#### 2. Build APK de production

```bash
cd apps/mobile

# Build APK release
flutter build apk --release \
  --dart-define=SUPABASE_URL=$SUPABASE_URL \
  --dart-define=SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY

# APK disponible dans : build/app/outputs/apk/release/app-release.apk
```

#### 3. Build AAB (Google Play Store)

```bash
flutter build appbundle --release \
  --dart-define=SUPABASE_URL=$SUPABASE_URL \
  --dart-define=SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY

# AAB disponible dans : build/app/outputs/bundle/release/app-release.aab
```

### Build iOS

#### 1. Prérequis

- macOS avec Xcode 15+
- Compte Apple Developer (99$/an)
- Certificats de distribution configurés dans Xcode

#### 2. Build IPA

```bash
cd apps/mobile

flutter build ipa --release \
  --dart-define=SUPABASE_URL=$SUPABASE_URL \
  --dart-define=SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY

# IPA disponible dans : build/ios/ipa/
```

### CI/CD Mobile (GitHub Actions)

Ajouter dans `.github/workflows/mobile-ci.yml` :

```yaml
- name: Build APK
  if: github.ref == 'refs/heads/main'
  run: |
    flutter build apk --release \
      --dart-define=SUPABASE_URL=${{ secrets.SUPABASE_URL }} \
      --dart-define=SUPABASE_ANON_KEY=${{ secrets.SUPABASE_ANON_KEY }}

- name: Upload APK artifact
  if: github.ref == 'refs/heads/main'
  uses: actions/upload-artifact@v4
  with:
    name: app-release
    path: apps/mobile/build/app/outputs/apk/release/app-release.apk
```

---

## Checklist de déploiement

### Avant le premier déploiement

- [ ] Compte Supabase créé et projet configuré
- [ ] Migrations appliquées sur Supabase Cloud
- [ ] Edge Functions déployées
- [ ] Secrets Edge Functions configurés
- [ ] Bucket Cloudflare R2 créé et accès public activé
- [ ] Credentials R2 générés
- [ ] Variables d'environnement Web configurées sur Railway
- [ ] Domaine personnalisé configuré (Railway + DNS)
- [ ] Auth Supabase configurée (Site URL, Redirect URLs)
- [ ] pg_cron configuré pour auto-refund

### Pour chaque déploiement

- [ ] Tests passent en local (`npm test`, `flutter test`)
- [ ] Build réussit en local (`npm run build`, `flutter build apk`)
- [ ] Migrations de base de données vérifiées
- [ ] Edge Functions testées en local (`supabase functions serve`)
- [ ] PR approuvée avant merge sur `main`
- [ ] CI/CD GitHub Actions passe ✅

### Après déploiement

- [ ] Vérifier les logs Railway (pas d'erreurs critiques)
- [ ] Tester les pages publiques (landing, feed)
- [ ] Tester l'authentification OTP
- [ ] Tester l'upload d'une image de portfolio
- [ ] Tester un paiement Mobile Money (sandbox)
- [ ] Vérifier les métriques Supabase (latence, erreurs)

### Rollback

En cas de problème :

```bash
# Railway : redéployer la version précédente
railway rollback --service web

# Supabase : rollback de migration (attention !)
supabase db rollback --target <migration_name>

# Edge Functions : redéployer la version précédente depuis git
git checkout <previous_commit>
supabase functions deploy
```
