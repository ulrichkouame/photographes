# Architecture — Photographes.ci

## Vue d'ensemble

Photographes.ci est une plateforme Next.js 15 (App Router) pour mettre en relation photographes professionnels et clients en Côte d'Ivoire.

## Stack technique

| Couche | Technologie |
|--------|-------------|
| Framework | Next.js 15 (App Router, TypeScript) |
| UI | Tailwind CSS + shadcn/ui + Radix UI |
| Base de données | Supabase (PostgreSQL) |
| Authentification | Supabase Auth (SSR) |
| Stockage médias | Cloudflare R2 |
| Analytiques | Recharts |
| Tests | Jest + React Testing Library |

## Structure des dossiers

```
src/
├── app/             # Pages et routes (App Router)
│   ├── admin/       # Interface d'administration
│   ├── auth/        # Authentification
│   ├── photographers/ # Profils publics
│   └── api/         # Routes API
├── components/
│   ├── ui/          # Composants primitifs (shadcn)
│   ├── layout/      # Header, Footer, Sidebar
│   ├── photographers/ # Composants photographes
│   └── admin/       # Composants admin
├── hooks/           # Custom React hooks
├── lib/
│   ├── supabase/    # Clients Supabase (browser/server)
│   └── r2/          # Upload Cloudflare R2
└── types/           # Définitions TypeScript
```

## Flux d'authentification

1. L'utilisateur se connecte via `/auth/login`
2. Supabase SSR gère les sessions avec cookies httpOnly
3. Le middleware `src/middleware.ts` protège les routes `/admin/*`
4. Le callback OAuth: `/auth/callback`

## Flux d'upload d'image

1. Le client demande une URL présignée via `POST /api/upload`
2. Le serveur génère une URL S3 présignée pour Cloudflare R2
3. Le client upload directement vers R2 (sans passer par le serveur)
4. L'URL publique est stockée en base de données

## Composants serveur vs client

- **Server Components** (par défaut): pages admin, profils, landing
- **Client Components** (`'use client'`): filtres, formulaires, tableaux interactifs, hooks
