# Typesense Sync

## Symptoms

- Search returns stale results after data was updated
- New records don't appear in search results
- Deleted records still appear in search results
- Search returns zero results for a collection that should have data
- `Collection '{name}' not found` error from Typesense client
- Search works for some records but not others (partial sync failure)

## Common Causes (ordered by likelihood)

1. Sync job failed silently — records updated in database but sync job threw and wasn't retried
2. Collection doesn't exist yet — schema never initialized in Typesense
3. Schema mismatch — collection schema in Typesense doesn't match what the sync code sends
4. Typesense API key missing or wrong in environment variables
5. Sync job only runs on schedule and hasn't run since the data change
6. Record was soft-deleted in DB but Typesense wasn't updated

## Diagnosis Steps

1. Check Typesense admin to see if the collection exists and has documents:
   ```bash
   # Typesense admin API — get collection stats
   curl -H "X-TYPESENSE-API-KEY: {admin-key}" \
     https://{typesense-host}/collections/{collection-name}
   ```

2. Check the sync job logs in Vercel:
   ```bash
   vercel logs --filter=typesense
   # Or check Vercel dashboard → Jobs → look for sync job failures
   ```

3. Verify the collection schema matches what's in your search package:
   ```bash
   ls {PROJECT_ROOT}/packages/search/
   # Check collection definitions and compare against Typesense admin
   ```

4. Test a direct document lookup to see if the record exists:
   ```bash
   curl -H "X-TYPESENSE-API-KEY: {admin-key}" \
     "https://{typesense-host}/collections/{collection}/documents/{id}"
   ```

5. Check environment variables for the sync job:
   ```bash
   vercel env ls | grep TYPESENSE
   ```

## Resolution

### Cause 1: Sync job failed

Trigger a manual re-sync:

```bash
# Check for a manual sync endpoint or job trigger in your jobs app
ls {PROJECT_ROOT}/apps/jobs/
# Look for a sync or reindex script
```

If no manual trigger exists, find the sync function in your search package and call it directly from a one-off script:

```typescript
import { syncRecords } from '@yourapp/search'
await syncRecords({ /* relevant filters */ })
```

### Cause 2: Collection doesn't exist

Initialize the collection schema:

```bash
# Find the collection initialization script in your search package
grep -rn "createCollection\|collections.create" \
  {PROJECT_ROOT}/packages/search/
```

Run the initialization, then trigger a full reindex.

### Cause 3: Schema mismatch

The Typesense collection schema and the sync code must agree on field names and types. To fix:

1. Delete the collection in Typesense (this deletes all indexed documents)
2. Re-create it with the correct schema from your search package
3. Trigger a full reindex

```bash
# Delete collection
curl -X DELETE -H "X-TYPESENSE-API-KEY: {admin-key}" \
  https://{typesense-host}/collections/{collection-name}
```

### Cause 4: Missing API key

Add or correct the Typesense env vars in Vercel:

```bash
printf '{typesense-api-key}' | vercel env add TYPESENSE_API_KEY production
printf '{typesense-host}' | vercel env add TYPESENSE_HOST production
```

Check your jobs app's `.env.local` for the correct variable names.

### Cause 5: Job hasn't run since data change

Check the cron schedule in your jobs app and either wait for the next scheduled run or trigger manually (see Cause 1 resolution).

### Cause 6: Soft delete not propagated

If the record was soft-deleted (e.g., `deleted_at` set, not actually removed from DB), the sync job must explicitly delete it from Typesense:

```typescript
await typesense.collections(collectionName).documents(id).delete()
```

Check if the sync logic handles soft deletes. If not, this is a bug to fix in your search package.

## Prevention

- Monitor sync job success rate — add alerting for failed sync runs
- After any bulk data change, verify a sample of records appear correctly in search
- Keep Typesense collection schema in sync with DB schema changes — update your search package when adding columns that should be searchable
- Test search functionality after migrations that affect indexed tables
