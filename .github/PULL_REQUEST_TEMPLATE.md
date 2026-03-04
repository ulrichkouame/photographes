## Description

<!-- Describe the changes introduced by this PR and why they are needed. -->

## Related Issue

Closes #<!-- issue number -->

## Type of Change

- [ ] 🐛 Bug fix (non-breaking change that fixes an issue)
- [ ] ✨ New feature (non-breaking change that adds functionality)
- [ ] 💥 Breaking change (fix or feature that causes existing functionality to change)
- [ ] ♻️  Refactor (code change that neither fixes a bug nor adds a feature)
- [ ] 📝 Documentation update
- [ ] 🔒 Security fix
- [ ] ⚡ Performance improvement
- [ ] 🌐 Localization / i18n

## Checklist

### General
- [ ] My code follows the project's coding style and conventions
- [ ] I have performed a self-review of my own code
- [ ] I have added or updated relevant tests
- [ ] All existing tests pass locally
- [ ] I have updated documentation where necessary

### Web (Next.js) — if applicable
- [ ] `npm run lint` passes
- [ ] `npm run type-check` passes
- [ ] `npm test` passes
- [ ] Lighthouse score maintained (Performance ≥ 90, A11y ≥ 95)
- [ ] Accessibility: semantic HTML, ARIA roles, keyboard navigation verified

### Mobile (Flutter) — if applicable
- [ ] `flutter analyze` passes
- [ ] `dart format` applied
- [ ] `flutter test` passes
- [ ] Tested on both Android and iOS simulators

### Edge Functions (Supabase/Deno) — if applicable
- [ ] `deno lint` and `deno fmt --check` pass
- [ ] `deno test` passes
- [ ] Row-Level Security (RLS) policies verified for any new tables

### Security
- [ ] No secrets or API keys committed
- [ ] Input validation added for any new endpoints
- [ ] New dependencies reviewed for known vulnerabilities (`npm audit` / `flutter pub outdated`)
- [ ] GDPR: new user data fields documented in `docs/GDPR.md`

## Screenshots / Recordings

<!-- Add screenshots, screen recordings, or Lighthouse report links if applicable. -->

## Deployment Notes

<!-- Any environment variables, migrations, or configuration changes needed. -->
