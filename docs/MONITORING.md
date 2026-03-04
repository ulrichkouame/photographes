# Monitoring & Observability — photographes.ci

## Goals

| Goal | Target |
|------|--------|
| Error detection | < 5 min time-to-detect (TTD) for P1 incidents |
| Uptime | ≥ 99.9 % monthly (web + API) |
| P95 API latency | < 500 ms |
| Alert noise | < 5 false-positive alerts per week |

---

## Stack Summary

| Layer | Tool | Purpose |
|-------|------|---------|
| Error tracking | **Sentry** | Frontend (web + mobile) and Edge Function exceptions |
| APM / metrics | **Datadog** | Infrastructure metrics, traces, dashboards |
| Structured logs | **Railway Logs** + **Supabase Logs** | Runtime logs with search |
| Uptime monitoring | **Better Uptime** (or UptimeRobot) | External availability checks |
| Alerting | Datadog monitors + PagerDuty (on-call) | Incident escalation |
| Real User Monitoring | Datadog RUM / Sentry Performance | Core Web Vitals, mobile frames |

---

## Sentry Setup

### Web (Next.js)

```typescript
// apps/web/instrumentation.ts
import * as Sentry from "@sentry/nextjs";

Sentry.init({
  dsn: process.env.NEXT_PUBLIC_SENTRY_DSN,
  environment: process.env.NODE_ENV,
  tracesSampleRate: process.env.NODE_ENV === "production" ? 0.1 : 1.0,
  // Capture 100 % of sessions with errors
  replaysOnErrorSampleRate: 1.0,
  replaysSessionSampleRate: 0.05,
  integrations: [Sentry.replayIntegration()],
});
```

### Mobile (Flutter)

```yaml
# apps/mobile/pubspec.yaml (add dependency)
dependencies:
  sentry_flutter: ^7.0.0
```

```dart
// apps/mobile/lib/main.dart
import 'package:sentry_flutter/sentry_flutter.dart';

Future<void> main() async {
  await SentryFlutter.init(
    (options) {
      options.dsn = const String.fromEnvironment('SENTRY_DSN');
      options.environment = const String.fromEnvironment('APP_ENV', defaultValue: 'production');
      options.tracesSampleRate = 0.1;
    },
    appRunner: () => runApp(const App()),
  );
}
```

### Edge Functions (Deno)

```typescript
// supabase/functions/_shared/sentry.ts
import * as Sentry from "https://deno.land/x/sentry/index.mjs";

Sentry.init({
  dsn: Deno.env.get("SENTRY_DSN"),
  environment: Deno.env.get("APP_ENV") ?? "production",
  tracesSampleRate: 0.1,
});

export { Sentry };
```

---

## Datadog Integration

### APM — Railway (Next.js)

Add the Datadog agent as a Railway sidecar or use the APM library:

```bash
npm install dd-trace
```

```typescript
// apps/web/instrumentation.node.ts
import tracer from "dd-trace";
tracer.init({
  service: "photographes-web",
  env: process.env.NODE_ENV,
  version: process.env.NEXT_PUBLIC_APP_VERSION,
  logInjection: true,
});
```

Set `DD_API_KEY` in Railway environment variables.

### Dashboards to Create

1. **Infrastructure**: Railway CPU/memory, Supabase connection pool usage.
2. **API Performance**: Edge Function p50/p95/p99 latency by function name.
3. **Business Metrics**: New sign-ups, bookings created, photos uploaded (per day).
4. **Error Rate**: Sentry error rate by release version.

---

## Railway Logs

Railway streams structured JSON logs. Use the Railway dashboard or CLI:

```bash
railway logs --tail --service photographes-web
```

**Log levels**: Always use structured logging in Next.js:

```typescript
// apps/web/lib/logger.ts
import pino from "pino";

const logger = pino({
  level: process.env.LOG_LEVEL ?? "info",
  base: { service: "photographes-web", env: process.env.NODE_ENV },
});
export default logger;
```

---

## Supabase Observability

- **Dashboard → Logs**: Query Postgres, Edge Function, Auth, and Storage logs.
- **pg_stat_statements**: Enable to track slow queries.
- **Alerts**: Configure Supabase email alerts for database CPU > 80 % and
  storage > 80 %.

```sql
-- Enable pg_stat_statements (run once in Supabase SQL editor)
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;
```

---

## Alerting Rules

| Alert | Condition | Channel | Severity |
|-------|-----------|---------|---------|
| High error rate | Sentry errors > 50/min | Slack #incidents | P1 |
| API latency spike | p95 > 2 s for 5 min | PagerDuty | P1 |
| Uptime check failed | 2 consecutive failures | PagerDuty + SMS | P1 |
| Database CPU high | > 80 % for 10 min | Slack #ops | P2 |
| Storage > 80 % | R2 or Supabase storage | Slack #ops | P2 |
| Daily error budget | SLO burn rate > 2× | Slack #ops | P2 |
| Failed deployment | GitHub Actions failure | Slack #deployments | P2 |
| Security scan finding | CodeQL critical/high | Slack #security | P1 |

---

## On-Call Runbook

1. **P1 Incident declared** → PagerDuty pages the on-call engineer.
2. Engineer joins `#incidents` Slack channel, posts "I'm on it".
3. Check Sentry for error details and affected users.
4. Check Datadog for service health and latency.
5. Check Railway dashboard for recent deploys (consider rollback).
6. Mitigate → patch → post-mortem within 48 hours.

---

## Health Check Endpoints

Each service should expose a `/health` endpoint:

```typescript
// apps/web/app/api/health/route.ts
export async function GET() {
  return Response.json({ status: "ok", timestamp: new Date().toISOString() });
}
```

Edge Functions health check: `supabase/functions/health/index.ts`

---

## SLO Definitions

| Service | SLI | Target |
|---------|-----|--------|
| Web | Availability (successful HTTP responses / total) | 99.9 % |
| API (Edge Functions) | Latency p95 < 500 ms | 99 % of requests |
| Mobile app | Crash-free sessions | ≥ 99.5 % |
| Image uploads | Success rate | ≥ 99 % |
