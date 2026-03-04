# Exemples d'API

## GET /api/photographers

Recherche et filtrage des photographes.

### Paramètres de requête

| Paramètre | Type | Description |
|-----------|------|-------------|
| search | string | Recherche dans nom et bio |
| category | string | Filtrer par catégorie |
| commune | string | Filtrer par commune |
| min_rating | number | Note minimale |
| available | boolean | Disponibles uniquement |
| page | number | Page (défaut: 1) |
| limit | number | Résultats par page (défaut: 12) |

### Exemple de requête
```
GET /api/photographers?category=Mariage&commune=Cocody&min_rating=4&available=true&page=1&limit=9
```

### Réponse
```json
{
  "photographers": [
    {
      "id": "uuid-1",
      "name": "Kouamé Studio",
      "commune": "Cocody",
      "categories": ["Mariage", "Portrait"],
      "rating": 4.8,
      "available": true,
      "subscription_plan": "premium",
      "featured": true,
      "cover_url": "https://pub-xxx.r2.dev/covers/kouame.jpg"
    }
  ],
  "total": 24
}
```

---

## GET /api/portfolio

Récupérer les photos du portfolio.

### Paramètres
| Paramètre | Type | Description |
|-----------|------|-------------|
| photographer_id | uuid | Filtrer par photographe |

### Réponse
```json
{
  "items": [
    {
      "id": "uuid-1",
      "photographer_id": "uuid-p",
      "url": "https://pub-xxx.r2.dev/portfolio/photo1.jpg",
      "caption": "Mariage à Cocody",
      "featured": true,
      "created_at": "2024-01-15T10:00:00Z"
    }
  ]
}
```

---

## POST /api/upload

Générer une URL présignée pour uploader vers Cloudflare R2.

### Corps de la requête
```json
{
  "filename": "photo.jpg",
  "contentType": "image/jpeg",
  "folder": "portfolio"
}
```

### Réponse
```json
{
  "uploadUrl": "https://account.r2.cloudflarestorage.com/bucket/key?X-Amz-...",
  "publicUrl": "https://pub-xxx.r2.dev/portfolio/uuid-photo.jpg",
  "key": "portfolio/uuid-photo.jpg"
}
```

### Utilisation côté client
```typescript
// 1. Obtenir l'URL présignée
const { uploadUrl, publicUrl } = await fetch('/api/upload', {
  method: 'POST',
  body: JSON.stringify({ filename: file.name, contentType: file.type })
}).then(r => r.json())

// 2. Uploader directement vers R2
await fetch(uploadUrl, {
  method: 'PUT',
  body: file,
  headers: { 'Content-Type': file.type }
})

// 3. Sauvegarder l'URL publique en base
await fetch('/api/portfolio', {
  method: 'POST',
  body: JSON.stringify({ url: publicUrl, caption: '...' })
})
```
