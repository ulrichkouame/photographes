# Support & Helpdesk — photographes.ci

## Support Channels

| Channel | Use case | SLA |
|---------|---------|-----|
| In-app chat (Intercom) | Real-time user support | First reply < 4 h (business hours) |
| Email `support@photographes.ci` | Non-urgent enquiries | < 24 h |
| Help Centre (`/aide`) | Self-service documentation | Always available |
| Status page (`status.photographes.ci`) | Incident announcements | Updated within 15 min of P1 |
| Community forum (optional) | Peer support, feature discussion | Community-driven |

---

## Helpdesk — Intercom

### Integration (Web)

```typescript
// apps/web/lib/intercom.ts
declare global {
  interface Window {
    Intercom: (...args: unknown[]) => void;
    intercomSettings: Record<string, unknown>;
  }
}

export function bootIntercom(user?: { id: string; email: string; name: string; createdAt: number }) {
  if (typeof window === "undefined" || !window.Intercom) return;

  window.Intercom("boot", {
    app_id: process.env.NEXT_PUBLIC_INTERCOM_APP_ID,
    ...(user
      ? {
          user_id: user.id,
          email: user.email,
          name: user.name,
          created_at: user.createdAt,
        }
      : {}),
  });
}

export function shutdownIntercom() {
  if (typeof window === "undefined" || !window.Intercom) return;
  window.Intercom("shutdown");
}

export function trackIntercomEvent(event: string, metadata?: Record<string, unknown>) {
  if (typeof window === "undefined" || !window.Intercom) return;
  window.Intercom("trackEvent", event, metadata);
}
```

```tsx
// apps/web/app/layout.tsx — load Intercom after consent
import Script from "next/script";

// Pass the app ID via a safe data attribute to avoid interpolating
// untrusted values into a dangerouslySetInnerHTML script block.
<div id="intercom-config" data-app-id={process.env.NEXT_PUBLIC_INTERCOM_APP_ID} hidden />
<Script
  id="intercom-init"
  strategy="afterInteractive"
  src={`https://widget.intercom.io/widget/${process.env.NEXT_PUBLIC_INTERCOM_APP_ID}`}
/>
<Script
  id="intercom-boot"
  strategy="afterInteractive"
  dangerouslySetInnerHTML={{
    __html: `
      (function(){
        var appId = document.getElementById('intercom-config').dataset.appId;
        window.intercomSettings = { app_id: appId };
        var ic = window.Intercom;
        if (typeof ic === 'function') { ic('reattach_activator'); ic('update', window.intercomSettings); }
      })();
    `,
  }}
/>
```

### Integration (Flutter)

```yaml
# apps/mobile/pubspec.yaml
dependencies:
  intercom_flutter: ^8.0.0
```

```dart
// apps/mobile/lib/core/support/intercom_service.dart
import 'package:intercom_flutter/intercom_flutter.dart';

class SupportService {
  static Future<void> init() async {
    await Intercom.instance.initialize(
      const String.fromEnvironment('INTERCOM_APP_ID'),
      androidApiKey: const String.fromEnvironment('INTERCOM_ANDROID_KEY'),
      iosApiKey: const String.fromEnvironment('INTERCOM_IOS_KEY'),
    );
  }

  static Future<void> loginUser(String userId, String email) async {
    await Intercom.instance.loginIdentifiedUser(userId: userId, email: email);
  }

  static Future<void> logout() async {
    await Intercom.instance.logout();
  }

  static void show() {
    Intercom.instance.displayMessenger();
  }
}
```

---

## Help Centre (`/aide`)

### Structure

```
/aide
├── Démarrage rapide
│   ├── Créer un compte
│   ├── Trouver un photographe
│   └── Réserver une séance
├── Photographes
│   ├── Créer votre profil
│   ├── Gérer votre portfolio
│   ├── Gérer vos disponibilités
│   └── Recevoir des paiements
├── Réservations
│   ├── Comment ça marche ?
│   ├── Modifier ou annuler
│   └── Litiges et remboursements
├── Paiements
│   ├── Modes de paiement acceptés
│   ├── Facturation
│   └── Remboursements
└── Confidentialité & Compte
    ├── Modifier vos informations
    ├── Supprimer votre compte
    └── Politique de confidentialité
```

Use a headless CMS (e.g., **Sanity** or **Contentful**) or a simple Markdown-
based approach (e.g., **Fumadocs** / **Nextra**) to manage Help Centre content.

---

## User Feedback Collection

### In-App NPS Survey (Web + Mobile)

Trigger a Net Promoter Score (NPS) survey 7 days after account creation and
after each completed booking:

```typescript
// apps/web/lib/feedback.ts
export function showNpsSurvey(userId: string, triggeredBy: "signup" | "booking") {
  // Use Intercom surveys, or a custom modal
  if (typeof window === "undefined" || !window.Intercom) return;
  window.Intercom("startSurvey", process.env.NEXT_PUBLIC_NPS_SURVEY_ID);
}
```

### Post-Booking Review Prompt

After a booking is marked as completed, prompt both parties to leave a review:

```typescript
// Triggered by a Supabase Edge Function webhook on booking status change
// supabase/functions/send-review-prompt/index.ts
```

### Bug Report Button

Include a floating "Signaler un problème" button on every page (web) and in the
settings screen (mobile). Pre-fill the Intercom message with:
- Current page URL
- App version
- User ID (anonymised)
- Browser / OS

---

## Support Escalation Matrix

| Severity | Description | Response | Escalation |
|----------|-------------|---------|-----------|
| P1 — Critical | Service down, data loss, security breach | 15 min | CTO + on-call engineer |
| P2 — High | Feature broken for many users | 2 h | Engineering lead |
| P3 — Medium | Feature degraded, workaround available | 8 h | Support team |
| P4 — Low | Minor bug, cosmetic issue | 48 h | Support team |

---

## Status Page

Use **Better Uptime** or **Instatus** for the public status page:

- URL: `https://status.photographes.ci`
- Monitors: Web app, API (Edge Functions), Auth, Object Storage.
- Subscribers can opt in to email/SMS notifications for incidents.
- Automatically updated by the uptime monitoring integration.
