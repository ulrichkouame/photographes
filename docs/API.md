# API — Photographes.ci

> **Liens rapides :** [README](../README.md) | [ARCHITECTURE](ARCHITECTURE.md) | [DATABASE](DATABASE.md) | [SETUP](SETUP.md) | [DEPLOYMENT](DEPLOYMENT.md) | [CONVENTIONS](CONVENTIONS.md) | [FEATURES](FEATURES.md)

## Table des matières

1. [Vue d'ensemble](#vue-densemble)
2. [Authentification](#authentification)
3. [API PostgREST (auto-générée)](#api-postgrest-auto-générée)
4. [Edge Functions](#edge-functions)
   - [send-otp](#send-otp)
   - [verify-otp](#verify-otp)
   - [watermark](#watermark)
   - [process-payment](#process-payment)
   - [auto-refund](#auto-refund)
   - [sync-settings](#sync-settings)
5. [Codes d'erreur](#codes-derreur)
6. [Exemples complets](#exemples-complets)

---

## Vue d'ensemble

L'API de Photographes.ci est composée de deux couches :

| Couche | URL | Rôle |
|--------|-----|------|
| **PostgREST** | `https://<project>.supabase.co/rest/v1/` | CRUD automatique sur toutes les tables |
| **Edge Functions** | `https://<project>.supabase.co/functions/v1/` | Logique métier complexe (paiement, OTP, etc.) |

### Headers requis

```http
Authorization: Bearer <JWT_TOKEN>
apikey: <SUPABASE_ANON_KEY>
Content-Type: application/json
```

### Variables d'URL

- `<project>` : ID du projet Supabase (ex: `abcdefghijklmnop`)
- `BASE_URL` : `https://<project>.supabase.co`

---

## Authentification

### Schéma d'authentification

L'authentification se fait en deux étapes via OTP WhatsApp :

```
1. POST /functions/v1/send-otp      → Envoi du code OTP
2. POST /functions/v1/verify-otp    → Vérification + retour du JWT
```

Le JWT retourné est utilisé dans le header `Authorization: Bearer <JWT>` pour toutes les requêtes authentifiées.

### Refresh du token

```typescript
const { data, error } = await supabase.auth.refreshSession();
// Le nouveau access_token est automatiquement utilisé par le client
```

---

## API PostgREST (auto-générée)

Documentation officielle : [PostgREST Docs](https://postgrest.org/en/stable/references/api.html)

### `GET /rest/v1/photographers`

Liste les photographes avec filtres.

**Paramètres de requête :**

| Paramètre | Type | Description |
|-----------|------|-------------|
| `city` | `eq.string` | Filtrer par ville (ex: `eq.Abidjan`) |
| `is_available` | `eq.bool` | Disponibilité (ex: `eq.true`) |
| `price_per_hour` | `lte.number` | Prix max (ex: `lte.50000`) |
| `rating_avg` | `gte.number` | Note min (ex: `gte.4`) |
| `select` | `string` | Champs à retourner |
| `order` | `string` | Tri (ex: `rating_avg.desc`) |
| `limit` | `number` | Nombre de résultats |
| `offset` | `number` | Pagination |

**Exemple :**

```http
GET /rest/v1/photographers?is_available=eq.true&city=eq.Abidjan&order=rating_avg.desc&limit=12
Authorization: Bearer <ANON_KEY>
apikey: <ANON_KEY>
```

**Réponse 200 :**

```json
[
  {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "city": "Abidjan",
    "commune": "Cocody",
    "specialties": ["mariage", "portrait"],
    "price_per_hour": 25000,
    "rating_avg": 4.8,
    "rating_count": 24,
    "is_available": true,
    "portfolio_cover": "https://cdn.photographes.ci/covers/photo.jpg",
    "created_at": "2026-01-15T10:00:00Z"
  }
]
```

### `GET /rest/v1/photographers?id=eq.:id&select=*,profiles!profile_id(*),portfolios(*)`

Profil complet d'un photographe.

**Réponse 200 :**

```json
[
  {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "city": "Abidjan",
    "commune": "Plateau",
    "specialties": ["mariage", "événementiel"],
    "price_per_hour": 30000,
    "rating_avg": 4.9,
    "rating_count": 42,
    "is_available": true,
    "bio": "Photographe professionnel avec 8 ans d'expérience...",
    "profiles": {
      "full_name": "Kouamé Yao",
      "avatar_url": "https://cdn.photographes.ci/avatars/kouame.jpg"
    },
    "portfolios": [
      {
        "id": "7f3e1234-...",
        "image_url": "https://cdn.photographes.ci/portfolio/img1.jpg",
        "thumb_url": "https://cdn.photographes.ci/portfolio/thumb1.jpg",
        "title": "Mariage à la lagune",
        "is_featured": true
      }
    ]
  }
]
```

### `POST /rest/v1/bookings`

Créer une réservation.

**Corps :**

```json
{
  "client_id": "auth-user-uuid",
  "photographer_id": "550e8400-...",
  "event_date": "2026-06-15",
  "duration_hours": 4,
  "total_price": 120000,
  "notes": "Mariage civil suivi d'une réception"
}
```

**Réponse 201 :**

```json
{
  "id": "a1b2c3d4-...",
  "status": "pending",
  "created_at": "2026-03-04T10:00:00Z"
}
```

### `GET /rest/v1/app_settings?is_public=eq.true&select=key,value`

Récupérer les paramètres publics.

**Réponse 200 :**

```json
[
  { "key": "contact_price_xof", "value": "2000" },
  { "key": "contact_expiry_hours", "value": "72" },
  { "key": "max_portfolio_images", "value": "30" }
]
```

---

## Edge Functions

Les Edge Functions sont hébergées sur Supabase et exécutées via le runtime Deno. Elles partagent un module utilitaire commun dans `supabase/functions/_shared/`.

### Architecture des Edge Functions

```
supabase/functions/
├── _shared/
│   ├── cors.ts          # Headers CORS
│   ├── db.ts            # Client Supabase admin
│   ├── errors.ts        # Types d'erreurs standardisés
│   └── validation.ts    # Helpers de validation
├── send-otp/
│   └── index.ts
├── verify-otp/
│   └── index.ts
├── watermark/
│   └── index.ts
├── process-payment/
│   └── index.ts
├── auto-refund/
│   └── index.ts
└── sync-settings/
    └── index.ts
```

---

### `send-otp`

Envoie un code OTP via WhatsApp (WasenderAPI) au numéro de téléphone fourni.

**Endpoint :** `POST /functions/v1/send-otp`

**Auth :** Non requise (appel public)

**Corps de la requête :**

```json
{
  "phone": "+2250700000000"
}
```

| Champ | Type | Requis | Description |
|-------|------|--------|-------------|
| `phone` | `string` | ✅ | Numéro au format international (ex: `+2250700000000`) |

**Réponse 200 :**

```json
{
  "success": true,
  "message": "Code OTP envoyé sur WhatsApp"
}
```

**Réponse 400 (validation) :**

```json
{
  "error": "INVALID_PHONE",
  "message": "Le numéro de téléphone est invalide"
}
```

**Réponse 429 (rate limit) :**

```json
{
  "error": "RATE_LIMITED",
  "message": "Trop de tentatives. Réessayez dans 60 secondes."
}
```

**Réponse 500 (erreur WasenderAPI) :**

```json
{
  "error": "OTP_SEND_FAILED",
  "message": "Impossible d'envoyer le message WhatsApp"
}
```

**Logique interne :**

1. Valider le format du numéro
2. Vérifier le rate limit (max 3 OTP/heure par numéro)
3. Générer un code OTP à 6 chiffres
4. Hacher le code (SHA-256) et le stocker dans `otp_codes`
5. Appeler WasenderAPI pour envoyer le message WhatsApp
6. Retourner `{ success: true }`

---

### `verify-otp`

Vérifie le code OTP et retourne une session JWT Supabase.

**Endpoint :** `POST /functions/v1/verify-otp`

**Auth :** Non requise (appel public)

**Corps de la requête :**

```json
{
  "phone": "+2250700000000",
  "code": "123456"
}
```

| Champ | Type | Requis | Description |
|-------|------|--------|-------------|
| `phone` | `string` | ✅ | Numéro au format international |
| `code` | `string` | ✅ | Code OTP à 6 chiffres |

**Réponse 200 :**

```json
{
  "success": true,
  "session": {
    "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "refresh_token": "v1.refresh.token...",
    "expires_in": 3600,
    "token_type": "bearer",
    "user": {
      "id": "a1b2c3d4-...",
      "phone": "+2250700000000",
      "role": "authenticated"
    }
  }
}
```

**Réponse 400 (code invalide) :**

```json
{
  "error": "INVALID_OTP",
  "message": "Code OTP invalide ou expiré"
}
```

**Réponse 400 (code expiré) :**

```json
{
  "error": "OTP_EXPIRED",
  "message": "Le code OTP a expiré. Demandez un nouveau code."
}
```

**Logique interne :**

1. Rechercher l'OTP le plus récent non utilisé pour ce numéro
2. Vérifier que l'OTP n'est pas expiré (`expires_at > now()`)
3. Comparer le hash SHA-256 du code fourni avec celui stocké
4. Marquer l'OTP comme utilisé
5. Créer ou connecter l'utilisateur Supabase Auth via `auth.admin.createUser()` ou `signInWithOtp()`
6. Retourner la session JWT

---

### `watermark`

Ajoute un watermark "photographes.ci" sur une image, génère un thumbnail 400px, et uploade les deux vers Cloudflare R2.

**Endpoint :** `POST /functions/v1/watermark`

**Auth :** Requise (`Authorization: Bearer <JWT>`)

**Corps de la requête :** `multipart/form-data`

| Champ | Type | Requis | Description |
|-------|------|--------|-------------|
| `file` | `File` | ✅ | Image originale (JPEG, PNG, WebP, max 10 Mo) |
| `photographer_id` | `string` | ✅ | UUID du photographe |
| `title` | `string` | ❌ | Titre optionnel de la photo |

**Réponse 200 :**

```json
{
  "success": true,
  "image_url": "https://pub-xxx.r2.dev/portfolio/abcd1234.jpg",
  "thumb_url": "https://pub-xxx.r2.dev/portfolio/thumbs/abcd1234.jpg",
  "portfolio_id": "7f3e1234-..."
}
```

**Réponse 400 (validation) :**

```json
{
  "error": "INVALID_FILE_TYPE",
  "message": "Seuls les formats JPEG, PNG et WebP sont acceptés"
}
```

**Réponse 413 (taille dépassée) :**

```json
{
  "error": "FILE_TOO_LARGE",
  "message": "La taille maximale est de 10 Mo"
}
```

**Réponse 403 (quota dépassé) :**

```json
{
  "error": "QUOTA_EXCEEDED",
  "message": "Vous avez atteint la limite de 30 images"
}
```

**Logique interne :**

1. Vérifier l'authentification et les droits
2. Valider le type MIME et la taille du fichier
3. Vérifier le quota images du photographe
4. Ajouter le watermark textuel "photographes.ci" (bas-droite, police semi-transparente)
5. Générer un thumbnail 400px de large (ratio conservé)
6. Uploader les deux fichiers vers Cloudflare R2
7. Insérer un enregistrement dans `portfolios`
8. Retourner les URLs

---

### `process-payment`

Traite un paiement Mobile Money via le provider configuré dans `payment_providers`.

**Endpoint :** `POST /functions/v1/process-payment`

**Auth :** Requise (`Authorization: Bearer <JWT>`)

**Corps de la requête :**

```json
{
  "amount": 2000,
  "phone": "+2250700000000",
  "provider_slug": "orange-money",
  "contact_id": "a1b2c3d4-...",
  "description": "Mise en contact avec Kouamé Yao"
}
```

| Champ | Type | Requis | Description |
|-------|------|--------|-------------|
| `amount` | `number` | ✅ | Montant en XOF |
| `phone` | `string` | ✅ | Numéro Mobile Money |
| `provider_slug` | `string` | ✅ | Slug du provider (ex: `orange-money`) |
| `contact_id` | `string` | ✅ | UUID du contact associé |
| `description` | `string` | ❌ | Description du paiement |

**Réponse 200 :**

```json
{
  "success": true,
  "payment_ref": "PAY-2026-ABC123",
  "status": "pending",
  "message": "Paiement initié. Validez sur votre téléphone."
}
```

**Réponse 400 (provider inactif) :**

```json
{
  "error": "PROVIDER_INACTIVE",
  "message": "Ce provider de paiement n'est pas disponible"
}
```

**Réponse 402 (paiement refusé) :**

```json
{
  "error": "PAYMENT_DECLINED",
  "message": "Paiement refusé. Solde insuffisant ou numéro invalide."
}
```

**Logique interne :**

1. Vérifier l'authentification
2. Charger la configuration du provider depuis `payment_providers`
3. Appeler l'API du provider avec les paramètres de paiement
4. Mettre à jour le `contact` avec la référence de paiement
5. Retourner le statut du paiement

---

### `auto-refund`

Job programmé : rembourse automatiquement les contacts expirés et non traités.

**Endpoint :** `POST /functions/v1/auto-refund`

**Auth :** Service Role Key (appel interne uniquement, ex: via `pg_cron`)

**Corps de la requête :** Vide (ou `{}`)

**Réponse 200 :**

```json
{
  "success": true,
  "refunded_count": 3,
  "details": [
    {
      "contact_id": "a1b2c3d4-...",
      "amount": 2000,
      "payment_ref": "PAY-2026-ABC123",
      "refund_ref": "REF-2026-XYZ789"
    }
  ]
}
```

**Logique interne :**

1. Sélectionner tous les contacts avec `status = 'pending'` et `expires_at < now()`
2. Pour chaque contact :
   a. Appeler l'API du provider pour initier le remboursement
   b. Mettre à jour `contacts.status = 'refunded'` et `refund_at = now()`
3. Retourner le récapitulatif

**Configuration pg_cron :**

```sql
-- Exécuter auto-refund toutes les heures
SELECT cron.schedule(
  'auto-refund-expired-contacts',
  '0 * * * *',
  $$
  SELECT net.http_post(
    url := 'https://<project>.supabase.co/functions/v1/auto-refund',
    headers := '{"Authorization": "Bearer <SERVICE_ROLE_KEY>"}'::jsonb
  );
  $$
);
```

---

### `sync-settings`

Récupère les constantes dynamiques publiques depuis `app_settings`.

**Endpoint :** `GET /functions/v1/sync-settings`

**Auth :** Non requise (retourne uniquement les settings `is_public = true`)

**Paramètres de requête :**

| Paramètre | Type | Description |
|-----------|------|-------------|
| `keys` | `string` | Clés séparées par virgule (optionnel, sinon retourne tout) |

**Exemple :**

```http
GET /functions/v1/sync-settings?keys=contact_price_xof,otp_expiry_minutes
```

**Réponse 200 :**

```json
{
  "settings": {
    "contact_price_xof": "2000",
    "otp_expiry_minutes": "5"
  },
  "cached_at": "2026-03-04T10:00:00Z"
}
```

**Logique interne :**

1. Parser le paramètre `keys` (optionnel)
2. Requête sur `app_settings` filtrée sur `is_public = true`
3. Si `keys` fourni, filtrer les résultats
4. Retourner un objet clé/valeur

---

## Codes d'erreur

### Codes HTTP utilisés

| Code | Signification |
|------|--------------|
| `200` | Succès |
| `201` | Créé avec succès |
| `204` | Succès sans contenu (ex: DELETE) |
| `400` | Requête invalide (validation) |
| `401` | Non authentifié |
| `403` | Accès interdit (droits insuffisants) |
| `404` | Ressource non trouvée |
| `409` | Conflit (ex: ressource déjà existante) |
| `413` | Payload trop large |
| `422` | Entité non traitable |
| `429` | Trop de requêtes (rate limiting) |
| `500` | Erreur serveur interne |
| `503` | Service temporairement indisponible |

### Codes d'erreur applicatifs

| Code | HTTP | Description |
|------|------|-------------|
| `INVALID_PHONE` | 400 | Format de numéro invalide |
| `INVALID_OTP` | 400 | Code OTP incorrect |
| `OTP_EXPIRED` | 400 | Code OTP expiré |
| `RATE_LIMITED` | 429 | Trop de tentatives OTP |
| `INVALID_FILE_TYPE` | 400 | Type MIME non supporté |
| `FILE_TOO_LARGE` | 413 | Fichier dépasse la limite |
| `QUOTA_EXCEEDED` | 403 | Quota portfolio dépassé |
| `PROVIDER_INACTIVE` | 400 | Provider de paiement inactif |
| `PAYMENT_DECLINED` | 402 | Paiement refusé |
| `CONTACT_NOT_FOUND` | 404 | Contact introuvable |
| `ALREADY_REFUNDED` | 409 | Contact déjà remboursé |
| `UNAUTHORIZED` | 401 | Token JWT manquant ou invalide |
| `FORBIDDEN` | 403 | Droits insuffisants |
| `UPLOAD_FAILED` | 500 | Échec upload vers R2 |
| `OTP_SEND_FAILED` | 500 | Échec envoi WhatsApp |

### Format d'erreur standard

Toutes les Edge Functions retournent les erreurs dans ce format :

```json
{
  "error": "ERROR_CODE",
  "message": "Description lisible de l'erreur",
  "details": {}
}
```

---

## Exemples complets

### Exemple 1 : Inscription et connexion

```typescript
// 1. Envoyer l'OTP
const sendRes = await fetch(`${BASE_URL}/functions/v1/send-otp`, {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({ phone: '+2250700000000' }),
});
const { success } = await sendRes.json();
// → { success: true, message: "Code OTP envoyé sur WhatsApp" }

// 2. Vérifier l'OTP
const verifyRes = await fetch(`${BASE_URL}/functions/v1/verify-otp`, {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({ phone: '+2250700000000', code: '123456' }),
});
const { session } = await verifyRes.json();
// Stocker session.access_token pour les requêtes suivantes
```

### Exemple 2 : Upload d'une photo de portfolio

```typescript
const formData = new FormData();
formData.append('file', imageFile);
formData.append('photographer_id', 'uuid-photographe');
formData.append('title', 'Mariage à Grand-Bassam');

const res = await fetch(`${BASE_URL}/functions/v1/watermark`, {
  method: 'POST',
  headers: { Authorization: `Bearer ${accessToken}` },
  body: formData,
});
const { image_url, thumb_url } = await res.json();
```

### Exemple 3 : Initier un paiement Mobile Money

```typescript
const res = await fetch(`${BASE_URL}/functions/v1/process-payment`, {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    Authorization: `Bearer ${accessToken}`,
  },
  body: JSON.stringify({
    amount: 2000,
    phone: '+2250700000000',
    provider_slug: 'orange-money',
    contact_id: 'uuid-contact',
    description: 'Mise en contact avec Kouamé Yao',
  }),
});
const { payment_ref, status } = await res.json();
```

### Exemple 4 : Recherche de photographes (TypeScript + Supabase SDK)

```typescript
import { createClient } from '@supabase/supabase-js';

const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

async function searchPhotographers(filters: {
  city?: string;
  category?: string;
  minRating?: number;
  maxPrice?: number;
  page?: number;
}) {
  const { city, category, minRating, maxPrice, page = 0 } = filters;
  const PAGE_SIZE = 12;

  let query = supabase
    .from('photographers')
    .select(`
      id, city, commune, specialties, price_per_hour,
      rating_avg, rating_count, is_available, portfolio_cover,
      profiles!profile_id (full_name, avatar_url)
    `, { count: 'exact' })
    .eq('is_available', true)
    .order('rating_avg', { ascending: false })
    .range(page * PAGE_SIZE, (page + 1) * PAGE_SIZE - 1);

  if (city) query = query.eq('city', city);
  if (minRating) query = query.gte('rating_avg', minRating);
  if (maxPrice) query = query.lte('price_per_hour', maxPrice);
  if (category) query = query.contains('specialties', [category]);

  const { data, count, error } = await query;
  return { photographers: data, total: count, error };
}
```

### Exemple 5 : Test d'une Edge Function (Deno)

```typescript
// supabase/functions/send-otp/index.test.ts
import { assertEquals } from 'https://deno.land/std@0.168.0/testing/asserts.ts';

Deno.test('send-otp: rejects invalid phone', async () => {
  const req = new Request('http://localhost/functions/v1/send-otp', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ phone: 'invalid' }),
  });

  const { default: handler } = await import('./index.ts');
  const res = await handler(req);
  const body = await res.json();

  assertEquals(res.status, 400);
  assertEquals(body.error, 'INVALID_PHONE');
});
```
