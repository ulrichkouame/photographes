# Photographes.ci

Plateforme de mise en relation entre photographes professionnels et clients en Côte d'Ivoire.

## Description

**Photographes.ci** est un monorepo regroupant toutes les applications et services de la plateforme :

- 📱 **Mobile** (`apps/mobile`) — Application Flutter (iOS & Android)
- 🌐 **Web** (`apps/web`) — Application Next.js (site vitrine & portail client)
- ⚙️ **Backend** (`supabase`) — Base de données, authentification et fonctions via Supabase

## Structure du projet

```
photographes/
├── apps/
│   ├── mobile/          # Application Flutter
│   └── web/             # Application Next.js
├── packages/
│   └── shared/          # Types et utilitaires partagés
├── supabase/
│   ├── migrations/      # Migrations de base de données
│   ├── functions/       # Edge Functions Supabase
│   └── config.toml      # Configuration Supabase
├── .github/
│   └── workflows/       # Pipelines CI/CD
└── README.md
```

## Démarrage rapide

### Prérequis

- [Flutter SDK](https://flutter.dev/docs/get-started/install) ≥ 3.x
- [Node.js](https://nodejs.org/) ≥ 18.x
- [Supabase CLI](https://supabase.com/docs/guides/cli)

### Installation

```bash
# Cloner le dépôt
git clone https://github.com/ulrichkouame/photographes.git
cd photographes

# Installer les dépendances Web
cd apps/web && npm install

# Installer les dépendances Flutter
cd apps/mobile && flutter pub get

# Démarrer Supabase en local
supabase start
```

## Licence

MIT
