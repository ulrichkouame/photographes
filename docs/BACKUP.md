# Database Backup & Restore — photographes.ci

## Backup Strategy

| Type | Frequency | Retention | Tool |
|------|-----------|-----------|------|
| Continuous WAL archiving | Continuous | 7 days | Supabase Pro (built-in) |
| Daily logical backup (pg_dump) | Daily at 02:00 UTC | 30 days | pg_cron + R2 |
| Weekly full snapshot | Sunday 03:00 UTC | 90 days | pg_cron + R2 |
| Pre-deployment snapshot | Before every production deploy | 14 days | GitHub Actions |

---

## Supabase Built-in Backups (Pro Plan)

Supabase Pro includes:
- **Point-in-time recovery (PITR)** — restore to any second within the last 7 days.
- **Daily backups** — retained for 30 days, downloadable from the Supabase dashboard.

To restore via the Supabase dashboard:
1. Go to **Database → Backups**.
2. Select the target backup point.
3. Click **Restore** and confirm.

> ⚠️ Restoration replaces the entire database. Coordinate with the team and
> announce downtime in `#ops` Slack before restoring production.

---

## Automated Daily Backup to Cloudflare R2

### Setup

The backup script runs as a Supabase Edge Function scheduled via `pg_cron`.
It uses `pg_dump` (via a small Docker container on Railway) to create a
compressed dump and uploads it to R2.

```sql
-- supabase/migrations/YYYYMMDDHHMMSS_setup_backup_cron.sql
SELECT cron.schedule(
  'daily-backup',
  '0 2 * * *',   -- daily at 02:00 UTC
  $$
  SELECT net.http_post(
    url := current_setting('app.backup_function_url'),
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer ' || current_setting('app.backup_function_secret')
    ),
    body := jsonb_build_object('type', 'daily')
  )
  $$
);
```

### Backup Edge Function

```typescript
// supabase/functions/database-backup/index.ts
import { S3Client, PutObjectCommand } from "npm:@aws-sdk/client-s3";

const r2 = new S3Client({
  region: "auto",
  endpoint: Deno.env.get("R2_ENDPOINT"),
  credentials: {
    accessKeyId: Deno.env.get("R2_ACCESS_KEY_ID")!,
    secretAccessKey: Deno.env.get("R2_SECRET_ACCESS_KEY")!,
  },
});

Deno.serve(async (req) => {
  // Validate secret
  const authHeader = req.headers.get("Authorization");
  if (authHeader !== `Bearer ${Deno.env.get("BACKUP_FUNCTION_SECRET")}`) {
    return new Response("Unauthorized", { status: 401 });
  }

  const timestamp = new Date().toISOString().replace(/[:.]/g, "-");
  const key = `backups/db-${timestamp}.sql.gz`;

  // Trigger pg_dump via a secure server-side process
  // (This is a placeholder — actual dump runs on the Railway backup worker)
  await r2.send(new PutObjectCommand({
    Bucket: Deno.env.get("R2_BUCKET_NAME"),
    Key: key,
    Body: new Uint8Array(), // replaced by actual dump data
    ContentType: "application/gzip",
    Metadata: { "backup-type": "daily", "timestamp": timestamp },
  }));

  return Response.json({ success: true, key });
});
```

---

## Backup Verification

### Automated Restore Test (Weekly)

Every Sunday, a GitHub Actions workflow restores the latest backup to a
**staging database** and runs a smoke test:

```yaml
# .github/workflows/backup-verify.yml
name: Verify Database Backup

on:
  schedule:
    - cron: "0 5 * * 0"  # Sunday 05:00 UTC
  workflow_dispatch:

jobs:
  verify:
    name: Restore & Smoke Test
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Download latest backup from R2
        run: |
          aws s3 cp s3://${{ secrets.R2_BUCKET_NAME }}/backups/$(aws s3 ls s3://${{ secrets.R2_BUCKET_NAME }}/backups/ | sort | tail -1 | awk '{print $4}') backup.sql.gz \
            --endpoint-url ${{ secrets.R2_ENDPOINT }}
        env:
          AWS_ACCESS_KEY_ID: ${{ secrets.R2_ACCESS_KEY_ID }}
          AWS_SECRET_ACCESS_KEY: ${{ secrets.R2_SECRET_ACCESS_KEY }}

      - name: Restore to staging database
        run: |
          gunzip -c backup.sql.gz | psql ${{ secrets.STAGING_DATABASE_URL }}

      - name: Run smoke tests
        run: |
          psql ${{ secrets.STAGING_DATABASE_URL }} -c "SELECT COUNT(*) FROM profiles;"
          psql ${{ secrets.STAGING_DATABASE_URL }} -c "SELECT COUNT(*) FROM photographers;"
```

---

## Manual Restore Procedures

### Restore from Supabase PITR

```bash
# Via Supabase CLI (requires project access)
supabase db restore --project-ref <PROJECT_REF> --target-timestamp "2025-03-01T12:00:00Z"
```

### Restore from pg_dump Backup (R2)

```bash
# 1. Download backup
aws s3 cp s3://<BUCKET>/backups/db-<TIMESTAMP>.sql.gz ./restore.sql.gz \
  --endpoint-url <R2_ENDPOINT>

# 2. Decompress
gunzip restore.sql.gz

# 3. Restore (will overwrite existing data)
psql $DATABASE_URL < restore.sql
```

### Emergency Rollback Before Deploy

The deploy workflow automatically creates a pre-deploy snapshot:

```yaml
# In .github/workflows/deploy.yml
- name: Pre-deploy database snapshot
  run: |
    supabase db dump --project-ref ${{ secrets.SUPABASE_PROJECT_REF }} \
      | gzip > pre-deploy-$(date +%Y%m%d%H%M%S).sql.gz
    aws s3 cp pre-deploy-*.sql.gz s3://${{ secrets.R2_BUCKET_NAME }}/pre-deploy/ \
      --endpoint-url ${{ secrets.R2_ENDPOINT }}
```

---

## Backup Checklist

- [ ] Supabase PITR enabled (Pro plan required).
- [ ] Daily pg_dump to R2 configured and running.
- [ ] Backup verification workflow runs weekly without errors.
- [ ] Restore procedure documented and tested by at least one team member.
- [ ] R2 backup bucket has Object Lock enabled (WORM) for compliance.
- [ ] Backup secrets stored in GitHub Secrets (not in code).
- [ ] Alert configured if daily backup fails (see `docs/MONITORING.md`).
