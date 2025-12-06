# Transactional Care Action Recording - Implementation Notes

## Date

2025-12-06

## Problem Statement

The `record_care_action` method in `backend/services/collection_service.py` was not transactional. It performed multiple separate database writes:

1. Creating a `care_history` record
2. Updating the `plant_collections` table

If the second operation failed, the first one would not be rolled back, leaving the database in an inconsistent state where a care history record existed but the collection's care dates were not updated.

## Solution

Implemented a PostgreSQL function to ensure all operations are atomic within a single database transaction.

## Changes Made

### 1. Created PostgreSQL Function

**File**: `backend/migrations/004_record_care_action_function.sql`

The function `record_care_action()` performs the following operations atomically:

-   Verifies the collection exists and the user owns it
-   Inserts a new record into `care_history`
-   Updates `plant_collections` with:
    -   `last_care_date` = NOW()
    -   `next_care_date` = calculated from `care_frequency_days`
    -   `updated_at` = NOW()
-   Returns JSON with both `care_history` and updated `collection` data

**Key Features**:

-   `SECURITY DEFINER` - runs with function owner privileges
-   Transaction rollback on any error
-   Detailed error messages with proper SQLSTATE codes
-   JSON response format for easy client parsing

### 2. Updated Service Method

**File**: `backend/services/collection_service.py`

Refactored `record_care_action()` method to:

-   Call the PostgreSQL function via Supabase RPC endpoint
-   Remove separate POST/PATCH operations
-   Simplified error handling (single point of failure)
-   Parse JSON response from the function

**Before** (non-transactional):

```python
# POST to /care_history
care_response = await client.post(...)
# PATCH to /plant_collections
collection_response = await client.patch(...)
```

**After** (transactional):

```python
# Single RPC call to PostgreSQL function
response = await client.post(f"{self.base_url}/rpc/record_care_action", ...)
```

### 3. Documentation

**Files Created/Updated**:

-   `backend/migrations/README.md` - Migration instructions and examples
-   `docs/sprint3/todo.md` - Added transactional improvement notes
-   `backend/migrations/TRANSACTIONAL_IMPROVEMENT.md` - This document

## Benefits

### Data Integrity

✅ **Atomicity**: All operations succeed or fail together
✅ **Consistency**: No partial updates possible
✅ **Isolation**: Changes are isolated until transaction commits
✅ **Durability**: Once committed, changes are permanent

### Code Simplification

-   Reduced code complexity (single RPC call vs multiple HTTP requests)
-   Simplified error handling
-   Removed race conditions between operations
-   Better separation of concerns (business logic in database)

### Performance

-   Fewer network round-trips (1 RPC call instead of 2-3 REST calls)
-   Database-level optimization opportunities
-   Reduced latency for client requests

### Error Handling Improvement (2025-12-06)

**Problem**: The original error handling relied on brittle string matching (`"not found" in str(e).lower()`), and mapped both "not found" and "access denied" to HTTP 404, which is incorrect for authorization failures.

**Solution**: Implemented specific exception types and proper error codes:

-   **Exception Types**:
    -   `CollectionNotFoundError`: Raised when collection doesn't exist (HTTP 404)
    -   `CollectionAccessDeniedError`: Raised when user doesn't own collection (HTTP 403)
    -   `CollectionServiceError`: Base exception for other service errors (HTTP 500)

-   **PostgreSQL Function Updates**:
    -   Separate ownership check from existence check
    -   Distinct error codes: `P0002` (not found), `P0003` (access denied)
    -   Clear error messages for each case

-   **Benefits**:
    -   Type-safe error handling (no string matching)
    -   Correct HTTP status codes (404 vs 403)
    -   More maintainable code
    -   Better client error messages

## Migration Steps

### Prerequisites

-   Supabase project with access to SQL Editor or CLI
-   Admin access to the database

### Apply Migration

**Option 1: Supabase Dashboard**

1. Navigate to SQL Editor in Supabase Dashboard
2. Copy contents of `004_record_care_action_function.sql`
3. Paste and execute

**Option 2: Supabase CLI**

```bash
cd backend/migrations
supabase db push 004_record_care_action_function.sql
```

### Verify Migration

```sql
SELECT proname, prosrc
FROM pg_proc
WHERE proname = 'record_care_action';
```

### Test Function

```sql
SELECT record_care_action(
    '[collection-uuid]'::UUID,
    '[user-uuid]'::UUID,
    'watering'::TEXT,
    'Test watering'::TEXT,
    NOW()
);
```

## Rollback Plan

If issues arise, remove the function:

```sql
DROP FUNCTION IF EXISTS record_care_action(UUID, UUID, TEXT, TEXT, TIMESTAMPTZ);
```

Then restore the previous non-transactional service method from git history.

## Testing Recommendations

### Unit Tests

-   Test successful care action recording
-   Test ownership verification failure
-   Test invalid collection ID
-   Test database transaction rollback on errors

### Integration Tests

-   Test with actual Supabase instance
-   Verify care_history and collection updates happen together
-   Test concurrent care action recordings

### Load Tests

-   Measure performance improvement (fewer HTTP calls)
-   Test under high concurrency

## Security Considerations

-   Function uses `SECURITY DEFINER` - runs with creator's privileges
-   Ownership check is performed within the function
-   User can only record care for collections they own
-   Permissions granted to `authenticated` role only

## Future Improvements

1. **Add more RPC functions**: Consider converting other multi-step operations to RPC functions
2. **Batch operations**: Create RPC for bulk care action recording
3. **Audit logging**: Add audit trail within the function
4. **Performance monitoring**: Track RPC execution times
5. **Error categorization**: Return structured error codes for different failure types

## References

-   PostgreSQL Functions: https://www.postgresql.org/docs/current/sql-createfunction.html
-   Supabase RPC: https://supabase.com/docs/guides/database/functions
-   Database Transactions: https://www.postgresql.org/docs/current/tutorial-transactions.html

## Questions & Support

For questions about this implementation, refer to:

-   `backend/migrations/README.md` - Migration instructions
-   `backend/services/collection_service.py` - Service implementation
-   `backend/migrations/004_record_care_action_function.sql` - SQL function source
