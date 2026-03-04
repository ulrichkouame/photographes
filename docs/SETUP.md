# Guide d'installation — Photographes.ci

> **Liens rapides :** [README](../README.md) | [ARCHITECTURE](ARCHITECTURE.md) | [DATABASE](DATABASE.md) | [API](API.md) | [DEPLOYMENT](DEPLOYMENT.md) | [CONVENTIONS](CONVENTIONS.md) | [FEATURES](FEATURES.md)

## Table des matières

1. [Prérequis](#prérequis)
2. [Variables d'environnement](#variables-denvironnement)
3. [Installation locale](#installation-locale)
4. [Démarrage des services](#démarrage-des-services)
5. [Commandes utiles](#commandes-utiles)
6. [CI/CD (GitHub Actions)](#cicd-github-actions)
7. [Dépannage](#dépannage)

---

## Prérequis

### Outils requis

| Outil | Version min | Lien |
|-------|-------------|------|
| [Git](https://git-scm.com/) | 2.x | |
| [Node.js](https://nodejs.org/) | 18.x | LTS recommandé |
| [npm](https://www.npmjs.com/) | 9.x | Inclus avec Node.js |
| [Flutter SDK](https://flutter.dev/docs/get-started/install) | 3.x | Stable channel |
| [Dart SDK](https://dart.dev/get-dart) | 3.x | Inclus avec Flutter |
| [Supabase CLI](https://supabase.com/docs/guides/cli) | Latest | |
| [Docker](https://www.docker.com/) | 24.x | Requis pour Supabase local |

### Comptes requis

| Service | Gratuit | Lien |
|---------|---------|------|
| [GitHub](https://github.com/) | ✅ | Hébergement du code |
| [Supabase](https://supabase.com/) | ✅ (Free tier) | Backend |
| [Cloudflare R2](https://developers.cloudflare.com/r2/) | ✅ (10 Go/mois) | Stockage images |
| [WasenderAPI](https://wasenderapi.com/) | ❌ (payant) | OTP WhatsApp |

### Vérification des prérequis

```bash
node --version     # ≥ 18.0.0
npm --version      # ≥ 9.0.0
flutter --version  # ≥ 3.0.0
supabase --version # ≥ 1.0.0
docker --version   # ≥ 24.0.0
```

---

## Variables d'environnement

### Web (`apps/web/.env.local`)

Créer le fichier `apps/web/.env.local` à partir du template :

```bash
cp apps/web/.env.example apps/web/.env.local
```

Contenu du fichier `.env.local` :

```env
# ─── Supabase ────────────────────────────────────────────
NEXT_PUBLIC_SUPABASE_URL=https://<project-ref>.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...

# ─── Cloudflare R2 (serveur uniquement) ──────────────────
R2_ACCOUNT_ID=abc123def456
R2_ACCESS_KEY_ID=your_r2_access_key
R2_SECRET_ACCESS_KEY=your_r2_secret_key
R2_BUCKET_NAME=photographes
R2_PUBLIC_URL=https://pub-xxx.r2.dev

# ─── App ─────────────────────────────────────────────────
NEXT_PUBLIC_APP_URL=http://localhost:3000
NEXT_PUBLIC_APP_NAME=Photographes.ci
```

> ⚠️ **Important** : Ne jamais committer `.env.local`. Il est déjà dans `.gitignore`.

### Mobile (`apps/mobile/.env`)

Les variables d'environnement Flutter sont passées via `--dart-define` au moment du build :

```bash
# Développement
flutter run \
  --dart-define=SUPABASE_URL=https://<project-ref>.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...

# Production
flutter build apk \
  --dart-define=SUPABASE_URL=$SUPABASE_URL \
  --dart-define=SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY
```

Créer un fichier `.env` local pour faciliter le développement :

```env
# apps/mobile/.env (NE PAS COMMITTER)
SUPABASE_URL=https://<project-ref>.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

### Supabase Edge Functions (`supabase/functions/.env`)

```env
# supabase/functions/.env (NE PAS COMMITTER — déjà dans .gitignore)
WASENDER_API_KEY=your_wasender_api_key
R2_ACCOUNT_ID=abc123def456
R2_ACCESS_KEY_ID=your_r2_access_key
R2_SECRET_ACCESS_KEY=your_r2_secret_key
R2_BUCKET_NAME=photographes
```

### GitHub Secrets (CI/CD)

Ajouter ces secrets dans **Settings > Secrets and variables > Actions** :

| Secret | Description |
|--------|-------------|
| `SUPABASE_ACCESS_TOKEN` | Token d'accès Supabase CLI |
| `SUPABASE_PROJECT_REF` | Référence du projet Supabase |
| `SUPABASE_DB_PASSWORD` | Mot de passe de la base de données |

---

## Installation locale

### 1. Cloner le dépôt

```bash
git clone https://github.com/ulrichkouame/photographes.git
cd photographes
```

### 2. Installer les dépendances Web

```bash
# Depuis la racine du monorepo
npm install
# ou
cd apps/web && npm install
```

### 3. Installer les dépendances Flutter

```bash
cd apps/mobile
flutter pub get
```

### 4. Configurer les variables d'environnement

```bash
# Web
cp apps/web/.env.example apps/web/.env.local
# Éditer apps/web/.env.local avec vos valeurs

# Edge Functions
cp supabase/functions/.env.example supabase/functions/.env
# Éditer supabase/functions/.env avec vos valeurs
```

### 5. Démarrer Supabase en local

```bash
# Démarrer tous les services Supabase (DB, Auth, Storage, Edge Functions)
supabase start

# Appliquer les migrations
supabase db reset
```

Après `supabase start`, noter les URLs et clés affichées :

```
API URL: http://127.0.0.1:54321
DB URL: postgresql://postgres:postgres@127.0.0.1:54322/postgres
Studio URL: http://127.0.0.1:54323
Inbucket URL: http://127.0.0.1:54324
anon key: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
service_role key: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

Mettre à jour `apps/web/.env.local` avec ces valeurs locales.

---

## Démarrage des services

### Web (Next.js)

```bash
# Mode développement (hot reload)
npm run dev:web
# ou
cd apps/web && npm run dev
# → http://localhost:3000

# Build de production
npm run build:web
# ou
cd apps/web && npm run build

# Démarrer en mode production
cd apps/web && npm run start
```

### Mobile (Flutter)

```bash
cd apps/mobile

# Lister les appareils disponibles
flutter devices

# Lancer sur simulateur iOS
flutter run -d iPhone

# Lancer sur émulateur Android
flutter run -d emulator-5554

# Lancer sur navigateur (Chrome)
flutter run -d chrome
```

### Supabase local

```bash
# Démarrer tous les services
supabase start

# Vérifier l'état des services
supabase status

# Ouvrir le Studio Supabase
open http://localhost:54323

# Arrêter tous les services
supabase stop

# Réinitialiser la base de données (applique toutes les migrations)
supabase db reset

# Déployer les Edge Functions en local
supabase functions serve

# Tester une Edge Function spécifique
supabase functions serve send-otp --debug
```

---

## Commandes utiles

### Monorepo (racine)

```bash
# Démarrer le web en développement
npm run dev:web

# Build du web
npm run build:web

# Lint tous les workspaces
npm run lint

# Typecheck partagé
npm run typecheck --workspace=packages/shared
```

### Web (apps/web)

```bash
# Développement
npm run dev

# Build
npm run build

# Start production
npm start

# Lint
npm run lint

# Tests
npm run test

# Tests avec couverture
npm run test:coverage

# Storybook (si configuré)
npm run storybook
```

### Mobile (apps/mobile)

```bash
# Installer les dépendances
flutter pub get

# Lancer en développement
flutter run

# Analyser le code (équivalent lint)
flutter analyze

# Exécuter les tests
flutter test

# Tests avec couverture
flutter test --coverage

# Build APK debug
flutter build apk --debug

# Build APK release
flutter build apk --release

# Build iOS
flutter build ios

# Générer le code (freezed, riverpod)
dart run build_runner build --delete-conflicting-outputs
```

### Supabase

```bash
# Migrations
supabase migration new <nom>           # Créer une migration
supabase db reset                      # Reset + migration locale
supabase db diff                       # Voir les changements non migrés
supabase db push                       # Push vers production

# Edge Functions
supabase functions new <nom>           # Créer une fonction
supabase functions serve               # Servir toutes les fonctions
supabase functions deploy <nom>        # Déployer une fonction
supabase functions deploy              # Déployer toutes les fonctions

# Types
supabase gen types typescript          # Générer les types TypeScript
supabase gen types typescript > packages/shared/src/database.types.ts

# Logs
supabase logs --project-ref <ref>
```

### Git

```bash
# Créer une branche feature
git checkout -b feat/<description>

# Créer une branche fix
git checkout -b fix/<description>

# Créer une branche docs
git checkout -b docs/<description>

# Commit conventionnel
git commit -m "feat(photographers): add multi-criteria search filter"

# Push et PR
git push origin feat/<description>
```

---

## CI/CD (GitHub Actions)

Le projet dispose de 3 workflows GitHub Actions :

### `.github/workflows/web-ci.yml`

Déclenché sur push/PR vers `main` sur les chemins `apps/web/**` et `packages/shared/**`.

```
Étapes :
1. actions/checkout@v4
2. actions/setup-node@v4 (Node 20, cache npm)
3. npm ci
4. npm run lint
5. npm run build
```

### `.github/workflows/mobile-ci.yml`

Déclenché sur push/PR vers `main` sur le chemin `apps/mobile/**`.

```
Étapes :
1. actions/checkout@v4
2. subosito/flutter-action@v2 (Flutter 3.x stable)
3. flutter pub get
4. flutter analyze
5. flutter test
```

### `.github/workflows/supabase-ci.yml`

Déclenché sur push/PR vers `main` sur le chemin `supabase/**`.

```
Étapes :
1. actions/checkout@v4
2. supabase/setup-cli@v1
3. supabase db lint (valide les migrations)

Secrets requis :
- SUPABASE_PROJECT_REF
- SUPABASE_ACCESS_TOKEN
```

### Ajouter des tests au CI Web

Ajouter dans `apps/web/package.json` :

```json
{
  "scripts": {
    "test": "jest",
    "test:coverage": "jest --coverage"
  }
}
```

Ajouter l'étape dans `.github/workflows/web-ci.yml` :

```yaml
- name: Test
  run: npm run test
```

---

## Dépannage

### Supabase local ne démarre pas

```bash
# Vérifier que Docker est démarré
docker ps

# Réinitialiser Supabase
supabase stop --no-backup
supabase start
```

### Erreur de migration

```bash
# Voir l'historique des migrations
supabase migration list

# Réappliquer toutes les migrations
supabase db reset
```

### Erreur Flutter : packages outdated

```bash
flutter clean
flutter pub cache repair
flutter pub get
```

### Erreur Next.js : module not found

```bash
# Supprimer le cache et réinstaller
rm -rf apps/web/.next apps/web/node_modules
npm install
npm run dev:web
```

### Types TypeScript non à jour

```bash
# Régénérer depuis le schéma Supabase
supabase gen types typescript > packages/shared/src/database.types.ts
```

### Variables d'environnement manquantes

Vérifier que :
1. Le fichier `apps/web/.env.local` existe et contient toutes les variables
2. Les variables commençant par `NEXT_PUBLIC_` sont bien publiques (pas de secrets)
3. Redémarrer `npm run dev:web` après modification du `.env.local`
