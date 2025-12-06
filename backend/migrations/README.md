# Database Migrations

This directory contains SQL migration files for the PlantCare backend database.

## Migrations

### 004_record_care_action_function.sql

**Purpose**: Creates a transactional PostgreSQL function for recording care actions.

**Problem Solved**: The original `record_care_action` method performed multiple separate database writes (creating a care_history record, then updating plant_collections). If the second operation failed, the first one was not rolled back, leaving data in an inconsistent state.

**Solution**: This migration creates a PostgreSQL function that encapsulates all the logic within a single transaction:

1. Verifies collection ownership
2. Inserts into care_history
3. Updates plant_collections (last_care_date, next_care_date)

All operations succeed or fail together, ensuring data integrity.

## How to Apply Migrations

### Option 1: Using Supabase Dashboard (Recommended)

1. Go to your Supabase project dashboard
2. Navigate to **SQL Editor**
3. Copy the contents of `004_record_care_action_function.sql`
4. Paste into the SQL Editor
5. Click **Run** to execute

### Option 2: Using Supabase CLI

If you have Supabase CLI installed and linked to your project:

```bash
cd backend/migrations
supabase db push 004_record_care_action_function.sql
```

### Option 3: Using psql (Direct Database Connection)

If you have direct PostgreSQL access:

```bash
psql "postgresql://[USERNAME]:[PASSWORD]@[HOST]:[PORT]/[DATABASE]" < backend/migrations/004_record_care_action_function.sql
```

## Verification

After applying the migration, verify the function exists:

```sql
SELECT proname, prosrc
FROM pg_proc
WHERE proname = 'record_care_action';
```

## Testing the Function

You can test the function directly in SQL:

```sql
-- Test recording a care action
SELECT record_care_action(
    '[collection-uuid]'::UUID,
    '[user-uuid]'::UUID,
    'watering'::TEXT,
    'Watered the plant'::TEXT,
    NOW()
);
```

## Rollback

To remove the function:

```sql
DROP FUNCTION IF EXISTS record_care_action(UUID, UUID, TEXT, TEXT, TIMESTAMPTZ);
```

## Notes

-   The function uses `SECURITY DEFINER` to run with the privileges of the function owner
-   Permissions are granted to the `authenticated` role (adjust if your Supabase setup uses different roles)
-   The function returns JSON with both care_history and updated collection data
-   All operations are atomic - if any step fails, all changes are rolled back
