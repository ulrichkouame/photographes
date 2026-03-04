# Conventions — Photographes.ci

> **Liens rapides :** [README](../README.md) | [ARCHITECTURE](ARCHITECTURE.md) | [DATABASE](DATABASE.md) | [API](API.md) | [SETUP](SETUP.md) | [DEPLOYMENT](DEPLOYMENT.md) | [FEATURES](FEATURES.md)

## Table des matières

1. [Conventions de code](#conventions-de-code)
   - [TypeScript / Next.js](#typescript--nextjs)
   - [Flutter / Dart](#flutter--dart)
   - [SQL / Supabase](#sql--supabase)
2. [Workflow Git](#workflow-git)
3. [Règles de nommage](#règles-de-nommage)
4. [Structure des fichiers](#structure-des-fichiers)
5. [Process PR et tests](#process-pr-et-tests)
6. [Exemples de tests](#exemples-de-tests)

---

## Conventions de code

### TypeScript / Next.js

#### Généralités

- **Formatter** : Prettier (config `.prettierrc`)
- **Linter** : ESLint (config `eslint.config.js` ou `.eslintrc.json`)
- **TypeScript** : strict mode activé, pas de `any` explicite

```json
// .prettierrc
{
  "semi": true,
  "singleQuote": true,
  "tabWidth": 2,
  "trailingComma": "es5",
  "printWidth": 100
}
```

#### Nomenclature

| Élément | Convention | Exemple |
|---------|------------|---------|
| Composants React | PascalCase | `PhotographerCard.tsx` |
| Hooks | camelCase, préfixe `use` | `usePhotographers.ts` |
| Utilities | camelCase | `formatPrice.ts` |
| Types/Interfaces | PascalCase | `PhotographerProfile` |
| Constantes | SCREAMING_SNAKE_CASE | `MAX_PORTFOLIO_IMAGES` |
| Variables/Fonctions | camelCase | `fetchPhotographers` |
| Fichiers de route (App Router) | lowercase kebab | `app/photographes/[id]/page.tsx` |

#### Structure d'un composant React

```typescript
// components/PhotographerCard.tsx

import type { Photographer } from '@photographes/shared';

interface PhotographerCardProps {
  photographer: Photographer;
  onContact?: (id: string) => void;
}

export function PhotographerCard({ photographer, onContact }: PhotographerCardProps) {
  return (
    <div className="rounded-lg border p-4">
      {/* ... */}
    </div>
  );
}

export default PhotographerCard;
```

#### Structure d'un hook custom

```typescript
// hooks/usePhotographers.ts

import { useState, useEffect } from 'react';
import { createClient } from '@/lib/supabase/client';
import type { Photographer } from '@photographes/shared';

interface UsePhotographersOptions {
  city?: string;
  limit?: number;
}

export function usePhotographers({ city, limit = 12 }: UsePhotographersOptions = {}) {
  const [photographers, setPhotographers] = useState<Photographer[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<Error | null>(null);

  useEffect(() => {
    // fetch logic
  }, [city, limit]);

  return { photographers, loading, error };
}
```

#### Server Components vs Client Components

- Préférer les **Server Components** par défaut (moins de JS côté client)
- Ajouter `'use client'` uniquement quand nécessaire (hooks, événements, browser APIs)
- Jamais de `'use client'` dans les fichiers de layout

```typescript
// app/photographes/page.tsx — Server Component (SSR)
import { createClient } from '@/lib/supabase/server';

export default async function PhotographesPage() {
  const supabase = createClient();
  const { data } = await supabase.from('photographers').select('*').limit(12);
  return <PhotographerFeed photographers={data ?? []} />;
}
```

```typescript
// components/PhotographerFeed.tsx — Client Component
'use client';

import { useState } from 'react';

export function PhotographerFeed({ photographers }) {
  const [filter, setFilter] = useState('');
  // ...
}
```

### Flutter / Dart

#### Généralités

- **Formatter** : `dart format` (intégré)
- **Linter** : `flutter_lints` (analysis_options.yaml)
- **Architecture** : Feature-first avec Riverpod

#### Nomenclature

| Élément | Convention | Exemple |
|---------|------------|---------|
| Classes | PascalCase | `PhotographerProfile` |
| Fichiers | snake_case | `photographer_card.dart` |
| Variables | camelCase | `photographerList` |
| Constantes | camelCase | `maxPortfolioImages` |
| Providers | camelCase, suffixe `Provider` | `photographersProvider` |
| Notifiers | PascalCase, suffixe `Notifier` | `PhotographersNotifier` |

#### Structure d'un feature

```
lib/features/photographers/
├── data/
│   ├── photographer_repository.dart
│   └── photographer_remote_datasource.dart
├── domain/
│   ├── photographer.dart          # Modèle (Freezed)
│   └── photographer_repository.dart  # Interface
├── presentation/
│   ├── screens/
│   │   ├── photographers_screen.dart
│   │   └── photographer_detail_screen.dart
│   ├── widgets/
│   │   └── photographer_card.dart
│   └── providers/
│       └── photographers_provider.dart
└── photographers_module.dart
```

#### Structure d'un Provider Riverpod

```dart
// features/photographers/presentation/providers/photographers_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/photographer.dart';
import '../../data/photographer_repository.dart';

@riverpod
Future<List<Photographer>> photographers(
  PhotographersRef ref, {
  String? city,
}) async {
  final repository = ref.watch(photographerRepositoryProvider);
  return repository.getPhotographers(city: city);
}
```

### SQL / Supabase

#### Nommage

- Tables : `snake_case` pluriel (ex: `photographers`, `app_settings`)
- Colonnes : `snake_case` (ex: `created_at`, `profile_id`)
- Index : `idx_<table>_<colonne>` (ex: `idx_photographers_city`)
- Politiques RLS : `<table>_<action>_<sujet>` (ex: `photographers_select_public`)
- Triggers : `<table>_<action>` (ex: `profiles_updated_at`)
- Fonctions : `snake_case` verbe (ex: `handle_new_user`, `update_photographer_rating`)

#### Préfixe des tables (pour compatibilité multi-projet)

Les tables utilisent le préfixe `photographes_` uniquement si partagées avec d'autres projets dans le même schema. Dans le cadre de ce projet, le schema `public` est dédié.

#### Format des migrations SQL

```sql
-- Migration : 20260304000001_contacts.sql
-- Description : Ajout de la table contacts et du trigger d'expiration
-- Auteur : ulrichkouame
-- Date : 2026-03-04

-- ─── Table contacts ───────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.contacts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  -- ...
);

-- ─── RLS ──────────────────────────────────────────────────────
ALTER TABLE public.contacts ENABLE ROW LEVEL SECURITY;

-- ─── Politiques ───────────────────────────────────────────────
CREATE POLICY "contacts_select_client" ON public.contacts
  FOR SELECT USING (client_id = auth.uid());

-- ─── Index ────────────────────────────────────────────────────
CREATE INDEX idx_contacts_expires_at ON public.contacts (expires_at)
  WHERE status = 'pending';
```

---

## Workflow Git

### Branches

| Branche | Rôle | Protection |
|---------|------|------------|
| `main` | Production stable | ✅ Branch protection |
| `feat/<description>` | Nouvelles fonctionnalités | ❌ |
| `fix/<description>` | Corrections de bugs | ❌ |
| `docs/<description>` | Documentation | ❌ |
| `chore/<description>` | Maintenance, refactoring | ❌ |
| `hotfix/<description>` | Fix urgent en production | ❌ |

### Commits conventionnels

Format : `<type>(<scope>): <description>`

| Type | Usage |
|------|-------|
| `feat` | Nouvelle fonctionnalité |
| `fix` | Correction de bug |
| `docs` | Documentation uniquement |
| `style` | Formatage (pas de changement logique) |
| `refactor` | Refactoring sans changement fonctionnel |
| `test` | Ajout ou modification de tests |
| `chore` | Maintenance, dépendances |
| `perf` | Amélioration de performance |
| `ci` | Changements CI/CD |

**Exemples :**

```bash
feat(photographers): add multi-criteria search with city and category filters
fix(auth): handle OTP expiry edge case in verify-otp function
docs(api): add process-payment endpoint examples
test(watermark): add unit tests for image resize logic
chore(deps): upgrade next.js to 15.2.9
```

### Scopes disponibles

`photographers`, `auth`, `portfolio`, `bookings`, `contacts`, `payments`, `admin`, `web`, `mobile`, `api`, `db`, `ci`, `docs`

---

## Règles de nommage

### Fichiers et dossiers

| Contexte | Convention | Exemple |
|----------|------------|---------|
| Composants React | PascalCase | `PhotographerCard.tsx` |
| Pages Next.js | `page.tsx` | `app/photographes/[id]/page.tsx` |
| Layouts | `layout.tsx` | `app/layout.tsx` |
| Routes API | `route.ts` | `app/api/photographers/route.ts` |
| Hooks | `use-*.ts` | `use-photographers.ts` |
| Utilities | `kebab-case.ts` | `format-price.ts` |
| Tests | `*.test.ts(x)` | `PhotographerCard.test.tsx` |
| Fichiers Flutter | `snake_case.dart` | `photographer_card.dart` |
| Migrations SQL | `YYYYMMDDHHMMSS_nom.sql` | `20260304000001_contacts.sql` |
| Edge Functions | `kebab-case/index.ts` | `send-otp/index.ts` |

### Variables d'environnement

- **Publiques (Next.js)** : `NEXT_PUBLIC_` préfixe (ex: `NEXT_PUBLIC_SUPABASE_URL`)
- **Serveur uniquement** : sans préfixe (ex: `R2_SECRET_ACCESS_KEY`)
- **Dart defines** : SCREAMING_SNAKE_CASE (ex: `SUPABASE_URL`)
- **Secrets GitHub** : SCREAMING_SNAKE_CASE (ex: `SUPABASE_ACCESS_TOKEN`)

### IDs et clés de base de données

- Toujours utiliser des UUIDs v4 (`gen_random_uuid()`)
- Jamais d'IDs auto-incrémentés (integers) pour les tables publiques
- Les clés étrangères doivent avoir le même nom que la colonne référencée + `_id`

---

## Structure des fichiers

### `apps/web/`

```
apps/web/
├── src/
│   ├── app/                    # App Router Next.js
│   │   ├── (public)/           # Routes publiques (sans auth)
│   │   │   ├── page.tsx        # Landing page
│   │   │   ├── photographes/   # Feed photographes
│   │   │   │   ├── page.tsx
│   │   │   │   └── [id]/
│   │   │   │       └── page.tsx
│   │   ├── (auth)/             # Routes auth
│   │   │   └── connexion/
│   │   │       └── page.tsx
│   │   ├── admin/              # Dashboard admin (protégé)
│   │   │   ├── layout.tsx
│   │   │   ├── page.tsx
│   │   │   ├── photographes/
│   │   │   ├── clients/
│   │   │   ├── paiements/
│   │   │   └── parametres/
│   │   ├── api/                # Route Handlers Next.js
│   │   │   └── [...]/
│   │   ├── layout.tsx          # Root layout
│   │   └── globals.css
│   ├── components/
│   │   ├── ui/                 # shadcn/ui components
│   │   ├── photographers/      # Composants métier
│   │   ├── bookings/
│   │   └── admin/
│   ├── hooks/                  # Custom React hooks
│   ├── lib/
│   │   ├── supabase/
│   │   │   ├── client.ts       # Client-side Supabase
│   │   │   ├── server.ts       # Server-side Supabase (SSR)
│   │   │   └── middleware.ts   # Auth middleware
│   │   └── utils.ts
│   └── types/                  # Types locaux (en complément de @photographes/shared)
├── public/
│   └── images/
├── .env.example
├── .env.local                  # (gitignored)
├── next.config.js
├── package.json
└── tsconfig.json
```

### `apps/mobile/`

```
apps/mobile/
├── lib/
│   ├── main.dart
│   ├── app.dart                # PhotographesApp widget
│   ├── core/
│   │   ├── supabase/
│   │   │   └── supabase_service.dart
│   │   ├── router/
│   │   │   └── app_router.dart
│   │   └── theme/
│   │       └── app_theme.dart
│   └── features/
│       ├── auth/
│       ├── photographers/
│       ├── portfolio/
│       ├── bookings/
│       └── profile/
├── test/
│   ├── widget_test.dart
│   └── features/
│       └── photographers/
├── pubspec.yaml
└── analysis_options.yaml
```

### `supabase/`

```
supabase/
├── config.toml
├── functions/
│   ├── _shared/
│   │   ├── cors.ts
│   │   ├── db.ts
│   │   └── errors.ts
│   ├── send-otp/
│   │   ├── index.ts
│   │   └── index.test.ts
│   ├── verify-otp/
│   │   ├── index.ts
│   │   └── index.test.ts
│   ├── watermark/
│   │   ├── index.ts
│   │   └── index.test.ts
│   ├── process-payment/
│   │   ├── index.ts
│   │   └── index.test.ts
│   ├── auto-refund/
│   │   ├── index.ts
│   │   └── index.test.ts
│   └── sync-settings/
│       ├── index.ts
│       └── index.test.ts
└── migrations/
    └── *.sql
```

---

## Process PR et tests

### Checklist PR

Avant d'ouvrir une PR :

- [ ] Branche à jour avec `main` (`git rebase main` ou `git merge main`)
- [ ] Code formaté (`npm run format`, `dart format .`)
- [ ] Lint sans erreur (`npm run lint`, `flutter analyze`)
- [ ] Tests passent (`npm test`, `flutter test`)
- [ ] Build réussit (`npm run build`, `flutter build apk`)
- [ ] Pas de secrets dans le code
- [ ] Documentation mise à jour si nécessaire

### Template de PR

```markdown
## Description
<!-- Résumé des changements -->

## Type de changement
- [ ] Nouvelle fonctionnalité (feat)
- [ ] Correction de bug (fix)
- [ ] Documentation (docs)
- [ ] Refactoring (refactor)

## Tests
- [ ] Tests unitaires ajoutés/mis à jour
- [ ] Tests d'intégration ajoutés/mis à jour
- [ ] Testé manuellement

## Checklist
- [ ] Le code suit les conventions du projet
- [ ] Lint sans avertissement
- [ ] Build réussit
- [ ] Pas de secrets dans le code
```

### Revue de code

- Au moins **1 approbation** requise avant merge
- Les commentaires de revue doivent être résolus avant merge
- Le CI/CD doit passer (lint, build, tests)
- Utiliser "Squash and merge" pour garder un historique propre

---

## Exemples de tests

### Tests Web (Jest + React Testing Library)

```typescript
// components/PhotographerCard.test.tsx
import { render, screen } from '@testing-library/react';
import { PhotographerCard } from './PhotographerCard';

const mockPhotographer = {
  id: '1',
  city: 'Abidjan',
  commune: 'Cocody',
  specialties: ['mariage'],
  price_per_hour: 25000,
  rating_avg: 4.8,
  rating_count: 24,
  is_available: true,
  profiles: { full_name: 'Kouamé Yao', avatar_url: null },
};

describe('PhotographerCard', () => {
  it('affiche le nom du photographe', () => {
    render(<PhotographerCard photographer={mockPhotographer} />);
    expect(screen.getByText('Kouamé Yao')).toBeInTheDocument();
  });

  it('affiche la ville', () => {
    render(<PhotographerCard photographer={mockPhotographer} />);
    expect(screen.getByText(/Abidjan/)).toBeInTheDocument();
  });

  it('affiche la note moyenne', () => {
    render(<PhotographerCard photographer={mockPhotographer} />);
    expect(screen.getByText('4.8')).toBeInTheDocument();
  });

  it('indique disponible si is_available = true', () => {
    render(<PhotographerCard photographer={mockPhotographer} />);
    expect(screen.getByText(/disponible/i)).toBeInTheDocument();
  });
});
```

### Tests Flutter (flutter_test)

```dart
// test/features/photographers/photographer_card_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:photographes_mobile/features/photographers/presentation/widgets/photographer_card.dart';
import 'package:photographes_mobile/features/photographers/domain/photographer.dart';

void main() {
  group('PhotographerCard', () {
    final mockPhotographer = Photographer(
      id: '1',
      city: 'Abidjan',
      specialties: ['mariage'],
      pricePerHour: 25000,
      ratingAvg: 4.8,
      ratingCount: 24,
      isAvailable: true,
      fullName: 'Kouamé Yao',
    );

    testWidgets('affiche le nom du photographe', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PhotographerCard(photographer: mockPhotographer),
          ),
        ),
      );
      expect(find.text('Kouamé Yao'), findsOneWidget);
    });

    testWidgets('affiche la ville', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PhotographerCard(photographer: mockPhotographer),
          ),
        ),
      );
      expect(find.textContaining('Abidjan'), findsOneWidget);
    });
  });
}
```

### Tests Edge Functions (Deno)

```typescript
// supabase/functions/send-otp/index.test.ts
import { assertEquals } from 'https://deno.land/std@0.168.0/testing/asserts.ts';

Deno.test('send-otp: valide le format du numéro', async () => {
  const cases = [
    { phone: '+2250700000000', valid: true },
    { phone: '0700000000', valid: false },   // Sans indicatif
    { phone: 'invalid', valid: false },
    { phone: '', valid: false },
  ];

  for (const { phone, valid } of cases) {
    const req = new Request('http://localhost/functions/v1/send-otp', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ phone }),
    });

    const { default: handler } = await import('./index.ts');
    const res = await handler(req);

    if (valid) {
      assertEquals(res.status, 200, `${phone} devrait être valide`);
    } else {
      assertEquals(res.status, 400, `${phone} devrait être invalide`);
    }
  }
});

Deno.test('sync-settings: retourne uniquement les settings publics', async () => {
  const req = new Request('http://localhost/functions/v1/sync-settings', {
    method: 'GET',
  });

  // Mocker le client Supabase
  // ...

  const { default: handler } = await import('../sync-settings/index.ts');
  const res = await handler(req);
  const body = await res.json();

  assertEquals(res.status, 200);
  assert(body.settings !== undefined);
});
```

### Tests BDD (Cucumber / Gherkin)

```gherkin
# features/search_photographers.feature

Fonctionnalité: Recherche de photographes
  En tant que client
  Je veux rechercher des photographes
  Afin de trouver le bon professionnel pour mon événement

  Scénario: Recherche par ville
    Étant donné que je suis sur la page de recherche
    Quand je filtre par ville "Abidjan"
    Alors je vois uniquement des photographes d'Abidjan
    Et les résultats sont triés par note décroissante

  Scénario: Filtrer par disponibilité
    Étant donné que je suis sur la page de recherche
    Quand j'active le filtre "Disponible uniquement"
    Alors tous les photographes affichés sont disponibles

  Scénario: Aucun résultat
    Étant donné que je suis sur la page de recherche
    Quand je filtre par ville "Yamoussoukro" et catégorie "sous-marin"
    Alors je vois le message "Aucun photographe trouvé"
    Et je vois des suggestions de photographes similaires
```
