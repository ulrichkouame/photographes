# Photographes.ci

La plateforme de référence pour les photographes professionnels en Côte d'Ivoire.

## Stack technique

- **Next.js 15** (App Router, TypeScript)
- **Tailwind CSS** + shadcn/ui + Radix UI
- **Supabase** (PostgreSQL + Auth SSR)
- **Cloudflare R2** (stockage des images)
- **Recharts** (analytiques)
- **Jest** + React Testing Library

## Démarrage rapide

```bash
# Installer les dépendances
npm install

# Configurer les variables d'environnement
cp .env.example .env.local
# Editer .env.local avec vos clés Supabase et R2

# Démarrer le serveur de développement
npm run dev
```

Ouvrir [http://localhost:3000](http://localhost:3000).

## Variables d'environnement

Voir [`.env.example`](.env.example) pour la liste complète.

| Variable | Description |
|----------|-------------|
| `NEXT_PUBLIC_SUPABASE_URL` | URL de votre projet Supabase |
| `NEXT_PUBLIC_SUPABASE_ANON_KEY` | Clé publique Supabase |
| `SUPABASE_SERVICE_ROLE_KEY` | Clé service Supabase (serveur seulement) |
| `CLOUDFLARE_R2_ACCOUNT_ID` | ID compte Cloudflare |
| `CLOUDFLARE_R2_ACCESS_KEY_ID` | Clé d'accès R2 |
| `CLOUDFLARE_R2_SECRET_ACCESS_KEY` | Clé secrète R2 |
| `CLOUDFLARE_R2_BUCKET_NAME` | Nom du bucket R2 |
| `CLOUDFLARE_R2_PUBLIC_URL` | URL publique du bucket R2 |

## Scripts

```bash
npm run dev       # Serveur de développement
npm run build     # Build de production
npm run start     # Démarrer en production
npm run lint      # Linter
npm test          # Tests unitaires
npm run test:coverage  # Tests avec couverture
```

## Structure du projet

```
src/
├── app/
│   ├── page.tsx              # Page d'accueil
│   ├── photographers/        # Liste et profils photographes
│   ├── auth/                 # Connexion / Inscription
│   ├── admin/                # Interface d'administration
│   └── api/                  # Routes API
├── components/
│   ├── ui/                   # Composants primitifs (shadcn)
│   ├── layout/               # Header, Footer, AdminSidebar
│   ├── photographers/        # Composants photographes
│   └── admin/                # Composants administration
├── hooks/                    # Custom React hooks
├── lib/
│   ├── supabase/             # Clients Supabase
│   ├── r2/                   # Upload Cloudflare R2
│   └── utils.ts              # Utilitaires
└── types/                    # Types TypeScript
```

## Documentation

- [Architecture](docs/architecture.md)
- [Schéma de base de données](docs/database-schema.md)
- [Exemples d'API](docs/api-examples.md)

## Base de données

Toutes les tables sont préfixées `photographes_`. Voir [docs/database-schema.md](docs/database-schema.md).

Tables principales :
- `photographes_photographers` — Profils photographes
- `photographes_clients` — Profils clients
- `photographes_bookings` — Réservations
- `photographes_payments` — Paiements
- `photographes_portfolio` — Photos portfolio
- `photographes_app_settings` — Paramètres dynamiques

## Administration

L'interface admin est accessible à `/admin` (authentification requise) :

- **Tableau de bord** — KPIs et revenus
- **Photographes** — Gestion CRUD
- **Clients** — Liste des clients
- **Paiements** — Historique des paiements
- **Analytiques** — Graphiques Recharts
- **Modération** — Contenu à valider
- **Paramètres** — Configuration dynamique

## Licence

Propriétaire — © 2024 Photographes.ci
