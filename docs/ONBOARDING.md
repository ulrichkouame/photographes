# User Onboarding — photographes.ci

## Overview

This document describes the onboarding experience for both **photographers**
(service providers) and **clients** (people booking photographers), as well as
the technical implementation of the onboarding flows.

---

## Photographer Onboarding Flow

```
Sign Up
  └── Verify Email
        └── Choose Role: Photographer
              └── Step 1: Basic Profile (name, bio, location)
                    └── Step 2: Portfolio (upload ≥ 3 photos)
                          └── Step 3: Services & Pricing
                                └── Step 4: Availability Calendar
                                      └── Step 5: KYC (ID upload)
                                            └── Profile Under Review
                                                  └── Profile Live ✅
```

### Key UX Principles

- **Progress indicator**: Show a stepper (1/5, 2/5 …) at the top of each step.
- **Save and continue later**: Auto-save each step; allow resuming at the last
  incomplete step.
- **Tooltips and examples**: Each field has an info icon with a tooltip
  explaining what to enter (e.g., sample bio, pricing guidance).
- **Photo upload guidance**: Show recommended resolution, aspect ratio, and
  lighting tips inline.

---

## Client Onboarding Flow

```
Sign Up (or Sign in with Google/Apple)
  └── Verify Email
        └── Choose Role: Client
              └── Complete Profile (name, phone — optional)
                    └── Discover Feed (curated photographer recommendations)
                          └── First Search or Browse
                                └── Book a Photographer ✅
```

Client onboarding is intentionally lightweight — the goal is to get users to
their first search or booking with minimal friction.

---

## In-App Onboarding Features

### Welcome Tooltips (Web)

Use **Intro.js** or **Shepherd.js** for interactive guided tours:

```typescript
// apps/web/lib/onboarding/welcomeTour.ts
import Shepherd from "shepherd.js";

export function startPhotographerWelcomeTour() {
  const tour = new Shepherd.Tour({
    useModalOverlay: true,
    defaultStepOptions: {
      cancelIcon: { enabled: true },
      scrollTo: true,
    },
  });

  tour.addStep({
    id: "profile-photo",
    attachTo: { element: "#avatar-upload", on: "bottom" },
    text: "Commencez par ajouter une belle photo de profil — elle sera la première chose que les clients verront.",
    buttons: [
      { text: "Suivant →", action: tour.next },
    ],
  });

  tour.addStep({
    id: "portfolio",
    attachTo: { element: "#portfolio-section", on: "top" },
    text: "Votre portfolio est votre vitrine. Ajoutez vos meilleures photos pour attirer des clients.",
    buttons: [
      { text: "← Précédent", action: tour.back },
      { text: "Terminer", action: tour.complete },
    ],
  });

  tour.start();
}
```

### Welcome Tooltips (Flutter)

```dart
// Use showcaseview package for Flutter onboarding
// pubspec.yaml: showcaseview: ^3.0.0

ShowCaseWidget(
  onStart: (index, key) {},
  onComplete: (index, key) {},
  onFinish: () => _markOnboardingComplete(),
  builder: (ctx) => Showcase(
    key: _portfolioKey,
    description: "Votre portfolio est votre vitrine. Ajoutez vos meilleures photos.",
    child: PortfolioSection(),
  ),
)
```

### Empty State Guidance

Every empty state screen should include:
- An illustration (SVG).
- A clear explanation of what the section is for.
- A clear CTA button to add the first item.

```tsx
// apps/web/components/EmptyPortfolio.tsx
export function EmptyPortfolio({ onUpload }: { onUpload: () => void }) {
  return (
    <div className="flex flex-col items-center gap-4 py-12">
      <PortfolioIllustration />
      <h2 className="text-xl font-semibold">Votre portfolio est vide</h2>
      <p className="text-muted-foreground text-center max-w-sm">
        Ajoutez vos meilleures photos pour présenter votre travail aux clients.
      </p>
      <Button onClick={onUpload}>
        Ajouter des photos
      </Button>
    </div>
  );
}
```

---

## Onboarding Progress Tracking

Store onboarding completion in the database:

```sql
-- supabase/migrations/YYYYMMDDHHMMSS_onboarding_progress.sql
CREATE TABLE onboarding_progress (
  user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  role TEXT NOT NULL CHECK (role IN ('photographer', 'client')),
  steps_completed TEXT[] NOT NULL DEFAULT '{}',
  completed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE onboarding_progress ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can manage their own onboarding progress"
  ON onboarding_progress FOR ALL USING (auth.uid() = user_id);
```

```typescript
// Track step completion
await supabase
  .from("onboarding_progress")
  .upsert({
    user_id: user.id,
    role: "photographer",
    steps_completed: ["basic_profile", "portfolio"],
    updated_at: new Date().toISOString(),
  });
```

---

## Email Onboarding Sequence

Trigger via **Supabase Auth webhooks** → **Resend**:

| Email | Trigger | Delay |
|-------|---------|-------|
| Welcome + verification | Sign-up | Immediate |
| Onboarding tips | Email verified | +1 day |
| Profile incomplete reminder | Step 1 done, Step 2 not done | +3 days |
| First booking tips (client) | Account created | +7 days |
| Success email | Profile goes live (photographer) | Immediate |

---

## Video Guides

Host short screen-recorded tutorials (60–120 s) for:
- "Comment créer votre profil photographe" (How to create your photographer profile)
- "Comment trouver et réserver un photographe" (How to find and book a photographer)
- "Comment gérer vos réservations" (How to manage your bookings)

Embed videos in:
1. The onboarding wizard (each step shows a relevant 30-s clip).
2. The Help Centre (`/aide`).
3. The YouTube channel linked from the landing page.

Use **Loom** for initial recordings; migrate to a proper CDN (R2) as volume grows.

---

## Onboarding Metrics to Track

| Metric | Target |
|--------|--------|
| Onboarding completion rate (photographers) | ≥ 70 % |
| Onboarding completion rate (clients) | ≥ 90 % |
| Time to first booking (client) | < 7 days |
| Time to profile live (photographer) | < 3 days |
| Drop-off rate per step | < 20 % per step |
