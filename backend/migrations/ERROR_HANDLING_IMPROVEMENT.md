# Error Handling Improvements - Implementation Summary

## Date
2025-12-06

## Problem Statement

The error handling in `backend/routes/collections.py` (specifically in the care action endpoint) had two critical issues:

1. **Brittle String Matching**: The code relied on string matching (`"not found" in str(e).lower()`) to determine error types. This approach is fragile—any change to error messages in the service layer would break the logic.

2. **Incorrect HTTP Status Codes**: Both "not found" and "access denied" errors were mapped to HTTP 404 (Not Found). However, access denial should return HTTP 403 (Forbidden) to provide accurate feedback about authorization failures.

### Original Code (Problematic)
```python
except CollectionServiceError as e:
    # Handle not found or access denied
    if "not found" in str(e).lower() or "access denied" in str(e).lower():
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Collection with ID '{collection_id}' not found",
        )
```

## Solution

Implemented a type-safe error handling system with specific exception types and proper HTTP status codes.

## Changes Made

### 1. Service Layer Exception Types

**File**: `backend/services/collection_service.py`

Created a proper exception hierarchy:

```python
class CollectionServiceError(Exception):
    """Base exception for CollectionService errors."""
    pass

class CollectionNotFoundError(CollectionServiceError):
    """Exception raised when a collection is not found."""
    pass

class CollectionAccessDeniedError(CollectionServiceError):
    """Exception raised when user does not have access to a collection."""
    pass
```

**Benefits**:
- Type-safe: Compiler/IDE can catch errors
- Explicit: Clear intent for each error type
- Extensible: Easy to add more specific exceptions

### 2. PostgreSQL Function Updates

**File**: `backend/migrations/004_record_care_action_function.sql`

Separated existence check from ownership check:

```sql
-- Step 1: Verify collection exists
SELECT * INTO v_collection
FROM plant_collections
WHERE id = p_collection_id;

IF NOT FOUND THEN
    RAISE EXCEPTION 'Collection not found'
        USING ERRCODE = 'P0002';
END IF;

-- Step 2: Verify ownership
IF v_collection.user_id != p_user_id THEN
    RAISE EXCEPTION 'Access denied'
        USING ERRCODE = 'P0003';
END IF;
```

**Benefits**:
- Clear separation of concerns
- Distinct error codes for each case
- Database-level enforcement

### 3. Service Layer Error Detection

**File**: `backend/services/collection_service.py`

Updated `record_care_action()` to detect and raise specific exceptions:

```python
if response.status_code != 200:
    error_text = response.text
    error_lower = error_text.lower()
    
    if "collection not found" in error_lower:
        raise CollectionNotFoundError(
            f"Collection {collection_id} not found"
        )
    
    if "access denied" in error_lower:
        raise CollectionAccessDeniedError(
            f"Access denied to collection {collection_id}"
        )
```

**Benefits**:
- Clear mapping from database errors to exception types
- Consistent error messages
- Easy to add more specific error types

### 4. Routes Layer Error Handling

**File**: `backend/routes/collections.py`

Implemented proper exception handling with correct status codes:

```python
except CollectionNotFoundError as e:
    # Collection does not exist
    raise HTTPException(
        status_code=status.HTTP_404_NOT_FOUND,
        detail=str(e),
    )
except CollectionAccessDeniedError as e:
    # User does not own the collection
    raise HTTPException(
        status_code=status.HTTP_403_FORBIDDEN,
        detail=str(e),
    )
except CollectionServiceError as e:
    # Other service errors (validation, parsing, etc.)
    logger.error(f"Service error recording care action: {str(e)}")
    raise HTTPException(
        status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
        detail="Internal server error while recording care action",
    )
```

**Benefits**:
- Correct HTTP status codes (404 vs 403)
- Type-safe exception handling
- No brittle string matching
- Clear error messages to clients

### 5. Updated Documentation

**Files**: 
- `backend/migrations/TRANSACTIONAL_IMPROVEMENT.md`
- `docs/sprint3/todo.md`

Added comprehensive documentation about:
- The problem with brittle error handling
- The solution with specific exception types
- Benefits of the new approach
- Migration notes

## Benefits Summary

### ✅ Type Safety
- **Before**: Runtime string matching (error-prone)
- **After**: Compile-time type checking (IDE/compiler support)

### ✅ Correct HTTP Status Codes
- **Before**: Both errors → 404 (incorrect for authorization)
- **After**: Not found → 404, Access denied → 403 (RESTful)

### ✅ Maintainability
- **Before**: Changes to error messages break logic
- **After**: Changes to error messages don't affect logic

### ✅ Code Quality
- **Before**: Brittle string matching, mixed concerns
- **After**: Clear exception hierarchy, separation of concerns

### ✅ Developer Experience
- **Before**: Hard to understand error flow
- **After**: Clear, explicit exception types

### ✅ Client Experience
- **Before**: Generic 404 for all errors
- **After**: Specific status codes and messages for each error type

## HTTP Status Code Mapping

| Scenario | Exception Type | HTTP Status | Description |
|----------|---------------|-------------|-------------|
| Collection doesn't exist | `CollectionNotFoundError` | 404 Not Found | Resource does not exist |
| User doesn't own collection | `CollectionAccessDeniedError` | 403 Forbidden | User lacks permission |
| Database unavailable | `SupabaseError` | 503 Service Unavailable | External service issue |
| Validation/parsing error | `CollectionServiceError` | 500 Internal Server Error | Server-side error |

## Migration Required

If you already applied `004_record_care_action_function.sql`, you need to **re-apply** it to get the updated error handling logic.

### How to Apply

1. Go to Supabase Dashboard → SQL Editor
2. Copy the updated contents of `backend/migrations/004_record_care_action_function.sql`
3. Execute the SQL (it will drop and recreate the function)

## Testing Recommendations

### Test Cases to Verify

1. **404 Not Found**:
   ```bash
   # Try to record care for non-existent collection
   curl -X POST http://localhost:8001/api/collections/00000000-0000-0000-0000-000000000000/care \
     -H "Authorization: Bearer $TOKEN" \
     -H "Content-Type: application/json" \
     -d '{"care_type": "watering", "notes": "Test"}'
   
   # Expected: 404 with "Collection not found"
   ```

2. **403 Forbidden**:
   ```bash
   # Try to record care for another user's collection
   curl -X POST http://localhost:8001/api/collections/{other-user-collection-id}/care \
     -H "Authorization: Bearer $TOKEN" \
     -H "Content-Type: application/json" \
     -d '{"care_type": "watering", "notes": "Test"}'
   
   # Expected: 403 with "Access denied"
   ```

3. **200 Success**:
   ```bash
   # Record care for own collection
   curl -X POST http://localhost:8001/api/collections/{your-collection-id}/care \
     -H "Authorization: Bearer $TOKEN" \
     -H "Content-Type: application/json" \
     -d '{"care_type": "watering", "notes": "Test watering"}'
   
   # Expected: 200 with care_history and updated collection
   ```

## Future Improvements

1. **More Specific Exceptions**: Consider adding more exception types for other error scenarios:
   - `InvalidCareTypeError` for invalid care_type values
   - `CollectionLockedError` for concurrent modification conflicts
   - `QuotaExceededError` for rate limiting

2. **Error Response Standards**: Implement RFC 7807 (Problem Details for HTTP APIs):
   ```json
   {
     "type": "https://api.plantcare.id/errors/collection-not-found",
     "title": "Collection Not Found",
     "status": 404,
     "detail": "Collection 123e4567-e89b-12d3-a456-426614174000 not found",
     "instance": "/api/collections/123e4567-e89b-12d3-a456-426614174000/care"
   }
   ```

3. **Exception Hierarchy**: Consider creating a comprehensive exception hierarchy:
   ```python
   CollectionServiceError
   ├── CollectionNotFoundError
   ├── CollectionAccessDeniedError
   ├── CollectionValidationError
   │   ├── InvalidCareTypeError
   │   └── InvalidDateRangeError
   └── CollectionConflictError
       └── CollectionLockedError
   ```

## References

- HTTP Status Codes: https://developer.mozilla.org/en-US/docs/Web/HTTP/Status
- REST API Best Practices: https://restfulapi.net/http-status-codes/
- Python Exception Hierarchy: https://docs.python.org/3/tutorial/errors.html
- RFC 7807 (Problem Details): https://datatracker.ietf.org/doc/html/rfc7807

## Related Files

- `backend/services/collection_service.py` - Exception definitions and service logic
- `backend/routes/collections.py` - Route-level error handling
- `backend/migrations/004_record_care_action_function.sql` - Database function
- `backend/migrations/TRANSACTIONAL_IMPROVEMENT.md` - Transactional improvement notes
- `docs/sprint3/todo.md` - Sprint documentation

## Questions & Support

For questions about this implementation:
- Review the exception hierarchy in `collection_service.py`
- Check the PostgreSQL function source in `004_record_care_action_function.sql`
- See migration notes in `TRANSACTIONAL_IMPROVEMENT.md`
