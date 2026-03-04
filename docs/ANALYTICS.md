# Analytics — photographes.ci

## Overview

We use a layered analytics strategy to understand user behaviour, measure
product performance, and drive data-informed decisions.

| Tool | Purpose | Data classification |
|------|---------|-------------------|
| Google Analytics 4 (GA4) | Web traffic, funnel analysis, conversion | Pseudonymised |
| Datadog RUM | Real User Monitoring — Core Web Vitals, errors | Pseudonymised |
| Sentry Performance | Frontend performance tracing | Pseudonymised |
| Supabase Analytics | API usage, query performance | Internal |
| Custom Events (Supabase) | Business metrics (bookings, sign-ups) | Internal |

> **Privacy**: Analytics are only activated after user consent via the cookie
> banner (see `docs/GDPR.md`). IP addresses are anonymised in GA4.

---

## Google Analytics 4 (GA4)

### Setup (Next.js)

```typescript
// apps/web/lib/analytics.ts
export const GA_MEASUREMENT_ID = process.env.NEXT_PUBLIC_GA_MEASUREMENT_ID!;

export function pageview(url: string) {
  if (typeof window === "undefined" || !window.gtag) return;
  window.gtag("config", GA_MEASUREMENT_ID, { page_path: url });
}

export function event(action: string, params: Record<string, unknown>) {
  if (typeof window === "undefined" || !window.gtag) return;
  window.gtag("event", action, params);
}
```

```tsx
// apps/web/app/layout.tsx — load GA only after consent
"use client";
import Script from "next/script";
import { useConsent } from "@/lib/consent";
import { GA_MEASUREMENT_ID } from "@/lib/analytics";

export default function RootLayout({ children }: { children: React.ReactNode }) {
  const { analyticsConsented } = useConsent();
  return (
    <html lang="fr">
      <body>
        {analyticsConsented && (
          <>
            <Script
              src={`https://www.googletagmanager.com/gtag/js?id=${GA_MEASUREMENT_ID}`}
              strategy="afterInteractive"
            />
            <Script id="ga-init" strategy="afterInteractive">
              {`
                window.dataLayer = window.dataLayer || [];
                function gtag(){dataLayer.push(arguments);}
                gtag('js', new Date());
                gtag('config', '${GA_MEASUREMENT_ID}', {
                  anonymize_ip: true,
                  allow_google_signals: false
                });
              `}
            </Script>
          </>
        )}
        {children}
      </body>
    </html>
  );
}
```

### Key Events to Track

| Event name | Trigger | Parameters |
|-----------|---------|-----------|
| `sign_up` | User creates account | `method` (email/google/apple) |
| `login` | User logs in | `method` |
| `photographer_view` | Photographer profile viewed | `photographer_id` |
| `booking_initiated` | Booking form opened | `photographer_id`, `category` |
| `booking_completed` | Payment confirmed | `booking_id`, `value`, `currency` |
| `portfolio_view` | Portfolio album opened | `portfolio_id` |
| `search` | Search executed | `search_term`, `category`, `location` |
| `contact_photographer` | Message sent | `photographer_id` |

### GA4 Audiences (Suggested)

- **Active Clients** — users who completed ≥ 1 booking in the last 90 days.
- **Engaged Photographers** — photographers with ≥ 3 profile views/week.
- **Churned Users** — users inactive for 60+ days.
- **High-Intent Visitors** — viewed ≥ 3 photographer profiles without booking.

---

## Mobile Analytics (Flutter)

### Firebase Analytics

```yaml
# apps/mobile/pubspec.yaml
dependencies:
  firebase_analytics: ^10.0.0
  firebase_core: ^2.0.0
```

```dart
// apps/mobile/lib/core/analytics/analytics_service.dart
import 'package:firebase_analytics/firebase_analytics.dart';

class AnalyticsService {
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  Future<void> logBookingInitiated({
    required String photographerId,
    required String category,
  }) async {
    await _analytics.logEvent(
      name: 'booking_initiated',
      parameters: {
        'photographer_id': photographerId,
        'category': category,
      },
    );
  }

  Future<void> logSearch({
    required String searchTerm,
    required String? location,
  }) async {
    await _analytics.logSearch(searchTerm: searchTerm);
  }
}
```

---

## Datadog Real User Monitoring (Web)

```typescript
// apps/web/lib/datadog.ts
import { datadogRum } from "@datadog/browser-rum";

export function initDatadogRum() {
  if (process.env.NODE_ENV !== "production") return;

  datadogRum.init({
    applicationId: process.env.NEXT_PUBLIC_DD_APPLICATION_ID!,
    clientToken: process.env.NEXT_PUBLIC_DD_CLIENT_TOKEN!,
    site: "datadoghq.eu",
    service: "photographes-web",
    env: process.env.NODE_ENV,
    version: process.env.NEXT_PUBLIC_APP_VERSION,
    sessionSampleRate: 10,
    sessionReplaySampleRate: 5,
    trackUserInteractions: true,
    trackResources: true,
    trackLongTasks: true,
  });
}
```

---

## Business Intelligence Dashboard (Supabase)

Use Supabase's built-in dashboard or connect **Metabase** / **Retool** to the
read replica for internal KPI dashboards:

- Daily active users (DAU) and monthly active users (MAU)
- Bookings per day / week / month
- Average booking value and revenue
- Photographer onboarding funnel (sign-up → profile complete → first booking)
- Geographic distribution of users

---

## Analytics Checklist for New Features

- [ ] Identify the key actions users perform in the new feature.
- [ ] Implement `gtag('event', ...)` / `analytics.logEvent(...)` calls.
- [ ] Verify events appear in GA4 DebugView / Firebase DebugView.
- [ ] Add new events to the Key Events table above.
- [ ] Confirm events fire only after consent (web).
