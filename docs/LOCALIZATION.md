# Localization (i18n) — photographes.ci

## Supported Locales

| Locale | Language | Region | Status |
|--------|---------|--------|--------|
| `fr-CI` | French (Côte d'Ivoire) | Default | ✅ Supported |
| `fr-FR` | French (France) | Fallback | ✅ Supported |
| `en-US` | English (United States) | International | 🚧 Planned |

---

## Web (Next.js)

### Library

We use **next-intl** for translations and locale routing.

```bash
cd apps/web && npm install next-intl
```

### File Structure

```
apps/web/
├── messages/
│   ├── fr-CI.json   # Primary locale
│   ├── fr-FR.json   # Fallback
│   └── en-US.json   # Planned
├── next.config.js   # next-intl plugin config
└── middleware.ts    # Locale detection & routing
```

### Translation File Example

```json
// apps/web/messages/fr-CI.json
{
  "navigation": {
    "findPhotographer": "Trouver un photographe",
    "myBookings": "Mes réservations",
    "signIn": "Se connecter",
    "signUp": "S'inscrire"
  },
  "booking": {
    "title": "Réserver {photographerName}",
    "priceLabel": "Prix estimé",
    "confirmButton": "Confirmer la réservation",
    "successMessage": "Réservation confirmée ! Vous recevrez un email de confirmation."
  },
  "errors": {
    "generic": "Une erreur est survenue. Veuillez réessayer.",
    "notFound": "Page introuvable."
  }
}
```

### Usage in Components

```tsx
// apps/web/app/[locale]/photographers/page.tsx
import { useTranslations } from "next-intl";

export default function PhotographersPage() {
  const t = useTranslations("navigation");
  return <h1>{t("findPhotographer")}</h1>;
}
```

### Locale-Aware Formatting

```tsx
import { useFormatter } from "next-intl";

function BookingPrice({ amount }: { amount: number }) {
  const format = useFormatter();
  // Formats as "45 000 FCFA" for fr-CI, "$45,000" for en-US
  return (
    <span>
      {format.number(amount, { style: "currency", currency: "XOF" })}
    </span>
  );
}
```

### Date & Time Formatting

```tsx
// Display dates in locale-appropriate format
const format = useFormatter();
format.dateTime(date, { dateStyle: "long" });
// fr-CI: "15 mars 2025"
// en-US: "March 15, 2025"
```

### Middleware — Locale Detection

```typescript
// apps/web/middleware.ts
import createMiddleware from "next-intl/middleware";

export default createMiddleware({
  locales: ["fr-CI", "fr-FR", "en-US"],
  defaultLocale: "fr-CI",
  localeDetection: true, // use Accept-Language header
});

export const config = {
  matcher: ["/((?!api|_next|_vercel|.*\\..*).*)"],
};
```

---

## Mobile (Flutter)

### Library

Use Flutter's built-in `flutter_localizations` + `intl` package + ARB files:

```yaml
# apps/mobile/pubspec.yaml
dependencies:
  flutter_localizations:
    sdk: flutter
  intl: ^0.19.0

flutter:
  generate: true  # Enables code generation from ARB files
```

### ARB Files

```
apps/mobile/
└── lib/
    └── l10n/
        ├── app_fr.arb   # French (default)
        └── app_en.arb   # English (planned)
```

```json
// apps/mobile/lib/l10n/app_fr.arb
{
  "@@locale": "fr",
  "appTitle": "photographes.ci",
  "findPhotographer": "Trouver un photographe",
  "bookNow": "Réserver maintenant",
  "bookingConfirmed": "Réservation confirmée !",
  "price": "{amount, number, currency}",
  "@price": {
    "placeholders": {
      "amount": { "type": "double", "format": "currency", "optionalParameters": { "name": "XOF" } }
    }
  }
}
```

### Usage

```dart
// Access translations
Text(AppLocalizations.of(context)!.findPhotographer)
```

### RTL Support

Although current locales are LTR, structure the code to support RTL:

```dart
// Use Directionality-aware widgets
Padding(
  padding: const EdgeInsetsDirectional.only(start: 16, end: 8),
  child: Text(label),
)
```

---

## Currency & Number Formatting

- **Primary currency**: XOF (West African CFA franc) — no decimal places,
  space as thousands separator: `45 000 FCFA`.
- **Secondary currencies**: support EUR, USD for international photographers.
- Always store amounts in the smallest unit (centimes for EUR, whole francs for XOF).

---

## Contribution Workflow for Translations

1. All translatable strings must be added to the base locale file first
   (`fr-CI.json` / `app_fr.arb`).
2. Open a PR with new strings — CI will fail if keys are missing in other
   locales (configured via `next-intl` type-safe mode).
3. Translation PRs can be submitted by community contributors via
   [Crowdin](https://crowdin.com/) (integration to be set up).

---

## i18n Checklist for New Features

- [ ] All user-visible strings use translation keys (no hardcoded text).
- [ ] New keys added to all supported locale files.
- [ ] Dates, times, and numbers use locale-aware formatters.
- [ ] Currency amounts formatted correctly for XOF.
- [ ] RTL layout considered (even for LTR locales, use directional padding/margin).
- [ ] Images or icons containing text have locale variants if needed.
