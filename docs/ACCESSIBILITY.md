# Accessibility (A11y) — photographes.ci

## Commitment

photographes.ci targets **WCAG 2.1 Level AA** conformance for the web
application and follows Flutter's accessibility best practices for the mobile
app. Our minimum Lighthouse Accessibility score is **95**.

---

## Web (Next.js)

### Tooling

| Tool | Purpose | When |
|------|---------|------|
| `axe-core` / `jest-axe` | Automated A11y unit tests | Every PR |
| `@axe-core/playwright` | E2E accessibility audit | Every PR |
| Lighthouse CI | Overall A11y score tracking | Every PR + nightly |
| Storybook A11y addon | Component-level checks | During development |
| Manual screen-reader test | VoiceOver (macOS), NVDA (Windows) | Before each release |

### Implementation Guidelines

#### Semantic HTML
```tsx
// ✅ Correct — use semantic elements
<nav aria-label="Main navigation">
  <ul>
    <li><a href="/photographers">Find a Photographer</a></li>
  </ul>
</nav>

<main>
  <h1>Photographer Profile</h1>
  <article>...</article>
</main>

// ❌ Avoid — non-semantic div soup
<div class="nav">
  <div class="link" onClick={...}>Find a Photographer</div>
</div>
```

#### Images
```tsx
// Informative images — provide meaningful alt text
<Image src={photo.url} alt={`Photo by ${photo.photographerName}: ${photo.description}`} />

// Decorative images — empty alt attribute
<Image src={decorativeBanner.url} alt="" aria-hidden="true" />
```

#### Interactive Elements
- All interactive elements must be reachable via `Tab` key.
- Custom components must implement `onKeyDown` for `Enter`/`Space` activation.
- Focus indicators must be visible (do not suppress `outline` without a
  replacement).
- Minimum touch target: 44 × 44 px (WCAG 2.5.5).

#### Colour Contrast
- Text on backgrounds: ≥ 4.5:1 (AA normal text), ≥ 3:1 (AA large text).
- UI components and graphic objects: ≥ 3:1.
- Use the [WebAIM Contrast Checker](https://webaim.org/resources/contrastchecker/)
  to validate new colour pairs.

#### Forms
```tsx
// Always associate labels with inputs
<label htmlFor="email">Email address</label>
<input
  id="email"
  type="email"
  autoComplete="email"
  aria-required="true"
  aria-describedby="email-error"
/>
{error && <p id="email-error" role="alert">{error}</p>}
```

#### Announcements & Live Regions
```tsx
// Announce dynamic content changes (e.g., search results)
<div aria-live="polite" aria-atomic="true">
  {isLoading ? "Loading results…" : `${results.length} photographers found`}
</div>
```

#### Reduced Motion
```css
@media (prefers-reduced-motion: reduce) {
  *,
  *::before,
  *::after {
    animation-duration: 0.01ms !important;
    transition-duration: 0.01ms !important;
  }
}
```

### Automated Test Example

```typescript
// apps/web/tests/a11y/homepage.test.tsx
import { render } from "@testing-library/react";
import { axe, toHaveNoViolations } from "jest-axe";
import HomePage from "@/app/page";

expect.extend(toHaveNoViolations);

it("Home page has no accessibility violations", async () => {
  const { container } = render(<HomePage />);
  const results = await axe(container);
  expect(results).toHaveNoViolations();
});
```

---

## Mobile (Flutter)

### Flutter Accessibility Guidelines

| Feature | Implementation |
|---------|---------------|
| Screen reader support | Use `Semantics` widget for all custom components |
| Text scaling | Never use fixed font sizes; use `TextScaler` |
| Touch targets | Minimum 48 × 48 dp (`Material` tap target guideline) |
| Colour contrast | Same WCAG 2.1 AA ratios apply |
| Focus traversal | `FocusTraversalGroup` for complex layouts |

```dart
// Providing semantic labels for custom widgets
Semantics(
  label: 'Photographer profile photo for ${photographer.name}',
  image: true,
  child: CachedNetworkImage(imageUrl: photographer.avatarUrl),
);

// Button with accessible label
Semantics(
  button: true,
  label: 'Book ${photographer.name}',
  child: ElevatedButton(
    onPressed: () => _onBook(photographer),
    child: const Text('Book'),
  ),
);
```

### Testing with Flutter

```bash
# Run accessibility checks with Flutter's a11y testing tools
flutter test test/accessibility/
```

Use `SemanticsController` in widget tests:

```dart
testWidgets('Photographer card has accessible semantics', (tester) async {
  final handle = tester.ensureSemantics();
  await tester.pumpWidget(const PhotographerCard(photographer: mockPhotographer));

  expect(
    tester.getSemantics(find.byType(PhotographerCard)),
    matchesSemantics(label: 'Photographer Jane Doe'),
  );

  handle.dispose();
});
```

---

## Accessibility Review Process

1. **Development**: Developers run `axe` / `jest-axe` locally on new components.
2. **PR**: Lighthouse CI reports A11y score; fails if < 95.
3. **Release**: Manual screen-reader test using VoiceOver (iOS/macOS) and
   TalkBack (Android).
4. **Quarterly**: Full WCAG 2.1 AA audit using a dedicated accessibility tool or
   an external auditor.

---

## Known Issues & Roadmap

| Issue | Severity | Target release |
|-------|---------|---------------|
| (Track issues here as they are discovered) | — | — |

---

## Resources

- [WCAG 2.1 Quick Reference](https://www.w3.org/WAI/WCAG21/quickref/)
- [Flutter Accessibility docs](https://docs.flutter.dev/accessibility-and-localization/accessibility)
- [Next.js Accessibility docs](https://nextjs.org/docs/pages/building-your-application/optimizing/accessibility)
- [Axe-core rules](https://dequeuniversity.com/rules/axe/)
