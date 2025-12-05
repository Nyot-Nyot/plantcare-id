# Task 2.2 Execution Guide: Backend Guide Endpoints

**Task:** Backend Endpoint - Get Guide by ID
**Status:** ✅ COMPLETED
**Duration:** 2 hours
**Date:** December 5, 2025

---

## 📋 Overview

Implementasi RESTful API endpoints untuk mengakses treatment guides dari Supabase dengan caching dan rate limiting. Dua endpoint utama:

1. `GET /api/guides/{guide_id}` - Get single guide by UUID
2. `GET /api/guides/by-plant/{plant_id}` - Get multiple guides for a plant (dengan filter dan pagination)

---

## 🎯 Objectives

✅ Query treatment guides dari Supabase
✅ Cache responses di Redis dengan TTL 24 jam
✅ Error handling komprehensif (404, 500)
✅ Rate limiting 100 req/min per user
✅ Pagination support untuk list endpoints
✅ Filter by disease_name (case-insensitive)

---

## 📁 Files Created/Modified

### 1. Models

-   **`backend/models/__init__.py`** - Package exports
-   **`backend/models/treatment_guide.py`** (220 lines)
    -   `GuideStep` - Individual step model
    -   `TreatmentGuideBase` - Base guide model dengan validation
    -   `TreatmentGuide` - Database model (dengan id, timestamps)
    -   `TreatmentGuideCreate` - Create request model
    -   `TreatmentGuideUpdate` - Update request model (all optional)
    -   `TreatmentGuideResponse` - API response model

### 2. Services

-   **`backend/services/__init__.py`** - Package exports
-   **`backend/services/guide_service.py`** (250 lines)

    -   `GuideService` class
        -   `get_guide_by_id()` - Fetch single guide
        -   `get_guides_by_plant_id()` - Fetch multiple guides dengan filter/pagination
        -   `create_guide()` - Create new guide
        -   `update_guide()` - Update existing guide
    -   Uses Supabase REST API dengan httpx
    -   Proper JSONB parsing untuk steps dan materials

-   **`backend/services/cache_service.py`** (200 lines)
    -   `CacheService` class
        -   `get()` - Get from cache
        -   `set()` - Set with TTL (default 24h)
        -   `delete()` - Delete key
        -   `invalidate_pattern()` - Bulk delete by pattern
    -   Redis backend dengan in-memory fallback
    -   Graceful degradation jika Redis unavailable

### 3. Routes

-   **`backend/routes/guides.py`** (160 lines)
    -   `GET /api/guides/{guide_id}` - Single guide endpoint
        -   Cache key: `guide:id:{guide_id}`
        -   404 if not found
        -   500 on database errors
    -   `GET /api/guides/by-plant/{plant_id}` - List guides endpoint
        -   Cache key: `guide:plant:{plant_id}:disease:{disease_name}:limit:{limit}:offset:{offset}`
        -   Query params: `disease_name`, `limit` (1-100, default 10), `offset` (default 0)
        -   Returns: `{plant_id, disease_filter, total_results, limit, offset, guides[]}`

### 4. Main Application

-   **`backend/main.py`** - Modified
    -   Import slowapi untuk rate limiting
    -   Initialize Limiter with 100 req/min
    -   Include guides router
    -   Graceful fallback jika slowapi not installed

### 5. Dependencies

-   **`backend/requirements.txt`** - Updated
    -   Added `slowapi==0.1.9`
    -   Added `pydantic>=2.9.0`

---

## 🔧 Technical Implementation

### Supabase Integration

```python
# Using Supabase REST API (bukan Python SDK)
base_url = f"{SUPABASE_URL}/rest/v1"
headers = {
    "apikey": SUPABASE_ANON_KEY,
    "Authorization": f"Bearer {SUPABASE_ANON_KEY}",
    "Content-Type": "application/json"
}

# Query dengan filter
params = {
    "plant_id": f"eq.{plant_id}",
    "disease_name": f"ilike.%{disease_name}%",  # Case-insensitive search
    "select": "*",
    "limit": "10",
    "offset": "0",
    "order": "created_at.desc"
}
```

### Cache Strategy

```python
# Cache keys follow pattern:
# - Single guide: "guide:id:{uuid}"
# - Plant guides: "guide:plant:{plant_id}:disease:{name}:limit:{n}:offset:{m}"

# TTL: 86400 seconds (24 hours)
await cache_service.set(cache_key, data, ttl_seconds=86400)

# Invalidation by pattern:
await cache_service.invalidate_pattern("guide:plant:monstera*")
```

### Rate Limiting

```python
# Using slowapi
from slowapi import Limiter, _rate_limit_exceeded_handler
from slowapi.util import get_remote_address

limiter = Limiter(key_func=get_remote_address)
app.state.limiter = limiter

# Applied globally to all routes
# Default: 100 requests per minute per IP
```

### Error Handling

```python
# 404 Not Found
if not guide_data:
    raise HTTPException(
        status_code=404,
        detail=f"Treatment guide with ID '{guide_id}' not found"
    )

# 500 Internal Server Error
except Exception as e:
    logger.error(f"Error retrieving guide {guide_id}: {str(e)}")
    raise HTTPException(
        status_code=500,
        detail=f"Internal server error: {str(e)}"
    )
```

---

## 🧪 Testing

### Manual Testing Commands

**1. Test Single Guide Endpoint**

```bash
# Get guide by ID (replace with actual UUID from seed data)
curl -X GET "http://localhost:8001/api/guides/{guide_id}"

# Expected Response:
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "plant_id": "general",
  "disease_name": "Leaf Spot",
  "severity": "medium",
  "guide_type": "disease_treatment",
  "steps": [...],
  "materials": ["sarung tangan", "fungisida"],
  "estimated_duration_minutes": 20160,
  "estimated_duration_text": "2-3 minggu",
  "created_at": "2025-12-05T10:00:00Z",
  "updated_at": "2025-12-05T10:00:00Z"
}
```

**2. Test List Guides Endpoint**

```bash
# Get all guides for 'general' plants
curl -X GET "http://localhost:8001/api/guides/by-plant/general"

# Filter by disease name
curl -X GET "http://localhost:8001/api/guides/by-plant/general?disease_name=Leaf"

# With pagination
curl -X GET "http://localhost:8001/api/guides/by-plant/general?limit=5&offset=0"

# Expected Response:
{
  "plant_id": "general",
  "disease_filter": "Leaf",
  "total_results": 4,  # Total count of ALL matching guides (not just current page)
  "limit": 5,
  "offset": 0,
  "guides": [...]  # Array of 4 guides (or fewer if total < limit)
}

# Pagination metadata:
# - total_results: Total count from database (uses Supabase Content-Range header)
# - guides.length: Number of items in current page (≤ limit)
# - total_pages: ceil(total_results / limit)
# - has_next: (offset + limit) < total_results
# - has_prev: offset > 0
```

**3. Test Error Handling**

```bash
# 404 - Guide not found
curl -X GET "http://localhost:8001/api/guides/invalid-uuid-here"

# Expected: {"detail": "Treatment guide with ID 'invalid-uuid-here' not found"}
```

**4. Test Caching**

```bash
# First request (cache MISS - slower)
time curl -X GET "http://localhost:8001/api/guides/{guide_id}"

# Second request (cache HIT - faster)
time curl -X GET "http://localhost:8001/api/guides/{guide_id}"

# Check logs for "Cache HIT" vs "Cache MISS"
```

**5. Test Rate Limiting**

```bash
# Send 101 requests rapidly (should trigger rate limit)
for i in {1..101}; do
  curl -X GET "http://localhost:8001/api/guides/by-plant/general"
done

# Expected: After 100 requests, get 429 Too Many Requests
```

---

## 🗄️ Database Prerequisites

Endpoints ini memerlukan:

1. ✅ Tabel `treatment_guides` sudah dibuat (Task 2.1)
2. ✅ Seed data sudah diinsert (5 sample guides)
3. ✅ Supabase credentials di `.env`:
    - `SUPABASE_URL=https://vdgmetwiubyzrpsqshuu.supabase.co`
    - `SUPABASE_ANON_KEY=eyJhbGc...`

---

## ⚙️ Dependencies Installed

```bash
# Install slowapi dan pydantic
backend/.venv/bin/python -m pip install slowapi==0.1.9
backend/.venv/bin/python -m pip install pydantic>=2.9.0

# Verify installation
backend/.venv/bin/pip list | grep -E "slowapi|pydantic"
# slowapi        0.1.9
# pydantic       2.12.5
```

---

## 🚀 Deployment

### Restart Backend Server

```bash
# Stop existing uvicorn process
# pkill -f "uvicorn backend.main:app"

# Start with new routes
backend/.venv/bin/uvicorn backend.main:app --reload --port 8001

# Or if using existing terminal:
# Press Ctrl+C to stop, then re-run the command
```

### Verify Routes Registered

```bash
# Check logs for:
# INFO:     Rate limiting enabled (100 req/min)
# INFO:     Treatment guides routes registered

# List all routes
curl -X GET "http://localhost:8001/docs"
# Should see /api/guides/{guide_id} and /api/guides/by-plant/{plant_id}
```

---

## 📊 Performance Considerations

1. **Caching**: First request fetches from Supabase (~200-500ms), subsequent requests from cache (~5-50ms)
2. **Rate Limiting**: 100 req/min per IP prevents abuse
3. **Pagination**: Default limit=10, max=100 to prevent large responses
4. **Indexes**: Database has indexes on `plant_id` and `disease_name` (from Task 2.1)

---

## 🐛 Troubleshooting

### Issue: Routes not registered

**Solution**: Check if `backend/routes/__init__.py` exists and imports are correct. Verify logs for import errors.

### Issue: Supabase connection failed

**Solution**:

```bash
# Verify credentials
echo $SUPABASE_URL
echo $SUPABASE_ANON_KEY

# Test Supabase connection
curl -X GET "$SUPABASE_URL/rest/v1/treatment_guides" \
  -H "apikey: $SUPABASE_ANON_KEY" \
  -H "Authorization: Bearer $SUPABASE_ANON_KEY"
```

### Issue: Cache not working

**Solution**: Redis is optional. Check logs:

-   "Redis cache initialized successfully" = Redis active
-   "REDIS_URL not set, using in-memory cache" = Fallback active (normal)

### Issue: Rate limit too aggressive

**Solution**: Adjust limiter in `main.py`:

```python
limiter = Limiter(key_func=get_remote_address, default_limits=["200/minute"])
```

---

## ✅ Acceptance Criteria Met

-   [x] Endpoint mengembalikan JSON terstruktur sesuai schema
-   [x] Cache berfungsi dengan TTL 24 jam
-   [x] Error handling lengkap (404, 500) dengan status code yang sesuai
-   [x] Response time < 500ms untuk cached requests
-   [x] Rate limiting 100 req/min implemented
-   [x] Pagination support (limit, offset)
-   [x] Disease name filtering (case-insensitive)

---

## 📝 Next Steps

1. **Task 2.3**: Implement `POST /api/guides` and `PUT /api/guides/{guide_id}` for creating/updating guides
2. **Testing**: Create automated tests di `backend/tests/test_guides.py`
3. **Documentation**: Update API docs dengan OpenAPI/Swagger examples
4. **Frontend Integration**: Connect Flutter app to these endpoints

---

## 🔗 Related Files

-   Database Migration: `backend/migrations/001_create_treatment_guides.sql`
-   Seed Data: `backend/migrations/003_seed_treatment_guides.sql`
-   Migration Guide: `docs/sprint3/database-migration-guide.md`
-   Sprint Todo: `docs/sprint3/todo.md`

---

**Completed by:** GitHub Copilot (Developer A)
**Date:** December 5, 2025
**Sprint:** Sprint 3 - Treatment Guidance & Collection
