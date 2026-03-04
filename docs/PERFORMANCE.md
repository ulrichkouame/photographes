# Performance — photographes.ci

## Performance Targets

| Metric | Target | Measurement tool |
|--------|--------|----------------|
| Lighthouse Performance (web) | ≥ 90 | Lighthouse CI |
| Lighthouse Accessibility (web) | ≥ 95 | Lighthouse CI |
| First Contentful Paint (FCP) | < 1.5 s | Lighthouse / Datadog RUM |
| Largest Contentful Paint (LCP) | < 2.5 s | Lighthouse / Datadog RUM |
| Cumulative Layout Shift (CLS) | < 0.1 | Lighthouse / Datadog RUM |
| Interaction to Next Paint (INP) | < 200 ms | Lighthouse / Datadog RUM |
| API p95 latency | < 500 ms | Datadog |
| Flutter app startup (cold) | < 2 s | Firebase Performance |
| Flutter frame rate | ≥ 60 fps (120 on capable devices) | Flutter DevTools |

---

## Web Performance (Next.js)

### Image Optimisation

Always use `next/image` for all images:

```tsx
import Image from "next/image";

// ✅ Correct
<Image
  src={photo.url}
  alt={photo.alt}
  width={800}
  height={600}
  sizes="(max-width: 768px) 100vw, 50vw"
  priority={isAboveFold}  // only for LCP images
  placeholder="blur"
  blurDataURL={photo.blurHash}
/>
```

Photos served from Cloudflare R2 should use Cloudflare Image Transforms to
serve WebP/AVIF and resize on-the-fly:

```
https://cdn.photographes.ci/images/{r2-key}?width=800&format=auto&quality=85
```

### Bundle Optimisation

```bash
# Analyse bundle size
cd apps/web && ANALYZE=true npm run build
```

Guidelines:
- Keep total JavaScript < 200 KB (compressed) for the initial load.
- Use dynamic imports for heavy components (date pickers, map, rich text editor).
- Prefer Server Components; only use `"use client"` when necessary.

```tsx
// Lazy-load heavy components
const MapView = dynamic(() => import("@/components/MapView"), {
  loading: () => <MapSkeleton />,
  ssr: false,
});
```

### Caching Strategy

| Resource | Strategy | Max-age |
|---------|---------|---------|
| Static assets (`/_next/static/`) | `immutable` | 1 year |
| ISR pages | `s-maxage=60, stale-while-revalidate=300` | 60 s |
| API routes (public data) | `Cache-Control: public, s-maxage=30` | 30 s |
| API routes (user-specific) | `Cache-Control: private, no-cache` | — |
| Images (R2/Cloudflare) | `Cache-Control: public, max-age=31536000` | 1 year |

### Lighthouse CI Configuration

```json
// apps/web/.lighthouserc.json
{
  "ci": {
    "collect": {
      "startServerCommand": "npm run start",
      "url": ["http://localhost:3000", "http://localhost:3000/photographers"]
    },
    "assert": {
      "assertions": {
        "categories:performance": ["error", { "minScore": 0.9 }],
        "categories:accessibility": ["error", { "minScore": 0.95 }],
        "categories:best-practices": ["warn", { "minScore": 0.9 }],
        "categories:seo": ["warn", { "minScore": 0.9 }]
      }
    }
  }
}
```

### Deno Profiling (Edge Functions)

For slow Edge Functions, enable Deno's built-in profiler:

```bash
deno run --inspect-brk supabase/functions/my-function/index.ts
# Connect Chrome DevTools to chrome://inspect
```

Use `console.time` / `console.timeEnd` for quick measurements:

```typescript
console.time("db-query");
const data = await supabase.from("photos").select("*");
console.timeEnd("db-query");
```

---

## Mobile Performance (Flutter)

### Profile Mode Testing

Always profile in `--profile` mode, never in `--debug`:

```bash
flutter run --profile
# Then use Flutter DevTools
flutter pub global run devtools
```

### Common Flutter Performance Patterns

#### Avoid Rebuilding Entire Trees

```dart
// ✅ Use const constructors where possible
const PhotographerCard(photographer: mockData)

// ✅ Use Consumer / select to minimise rebuilds (Riverpod)
ref.watch(photographerProvider.select((p) => p.name))
```

#### Efficient List Rendering

```dart
// ✅ Use ListView.builder for long lists
ListView.builder(
  itemCount: photographers.length,
  itemBuilder: (context, index) => PhotographerCard(
    photographer: photographers[index],
  ),
);
```

#### Image Caching

```yaml
dependencies:
  cached_network_image: ^3.0.0
```

```dart
CachedNetworkImage(
  imageUrl: photo.thumbnailUrl,
  placeholder: (ctx, url) => const ShimmerBox(),
  errorWidget: (ctx, url, err) => const Icon(Icons.broken_image),
  memCacheWidth: 400, // Downscale in memory
)
```

#### Reduce Shader Jank

```bash
# Pre-warm shaders during app development
flutter run --cache-sksl --purge-persistent-cache
```

### Firebase Performance Monitoring

```dart
import 'package:firebase_performance/firebase_performance.dart';

final trace = FirebasePerformance.instance.newTrace('booking_flow');
await trace.start();
// ... perform work
await trace.stop();
```

---

## Database Performance (Supabase PostgreSQL)

### Essential Indexes

```sql
-- Photographer discovery queries
CREATE INDEX idx_photographers_location ON photographers USING GIN (location_tsv);
CREATE INDEX idx_photographers_category ON photographers (category_id);
CREATE INDEX idx_photographers_rating ON photographers (average_rating DESC);

-- Booking queries
CREATE INDEX idx_bookings_client ON bookings (client_id, created_at DESC);
CREATE INDEX idx_bookings_photographer ON bookings (photographer_id, event_date);

-- Photo queries
CREATE INDEX idx_photos_portfolio ON photos (portfolio_id, created_at DESC);
```

### Slow Query Detection

```sql
-- Find queries taking > 100 ms (requires pg_stat_statements)
SELECT query, mean_exec_time, calls
FROM pg_stat_statements
WHERE mean_exec_time > 100
ORDER BY mean_exec_time DESC
LIMIT 20;
```

---

## Performance Review Process

1. **PR**: Lighthouse CI score compared to `main` branch (fails if regression).
2. **Weekly**: Review Datadog RUM dashboard for Core Web Vitals degradation.
3. **Monthly**: Profile slow API endpoints using Deno inspector.
4. **Quarterly**: Full performance audit — Lighthouse, Flutter DevTools, DB
   query analysis.
