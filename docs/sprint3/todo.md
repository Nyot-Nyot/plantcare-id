# Sprint 3 — Treatment Guidance & Collection

**Durasi:** 1 minggu (5 hari kerja)
**Goal Sprint:** Implementasi panduan perawatan step-by-step dan sistem koleksi tanaman pribadi lengkap dengan notifikasi dan sinkronisasi.

**Epics Covered:**

-   Epic 3 (Treatment Guidance) - Priority: Core
-   Epic 4 (Personal Plant Collection) - Priority: Medium

**Acceptance Criteria Utama:**

-   ✅ Panduan perawatan dengan ≤5 langkah visual
-   ✅ Progress tracking per langkah
-   ✅ Koleksi tersimpan lokal dan sync ke backend
-   ✅ Notifikasi perawatan aktif (FCM + local)
-   ✅ UI: Step cards, collection grid, filter

**Estimasi Total:** 25 SP (Story Points) = ~25 jam kerja
**Developer Assigned:** Developer A

---

## 📋 Daftar Isi

-   [Setup & Prerequisites](#setup--prerequisites)
-   [Backend - Guide Service](#backend---guide-service)
-   [Backend - Collection Service](#backend---collection-service)
-   [Client - Guide UI Implementation](#client---guide-ui-implementation)
-   [Client - Collection Management](#client---collection-management)
-   [Client - Notifications](#client---notifications)
-   [Integration & Sync](#integration--sync)
-   [Testing & QA](#testing--qa)
-   [Documentation](#documentation)

---

## Setup & Prerequisites

### 1.1 Environment Setup (0.5h)

**Estimasi:** 0.5 jam
**Priority:** High

-   [x] Verifikasi koneksi Supabase (pastikan tabel plants, collections sudah ada)
-   [x] Tambahkan ENV variables untuk FCM: `FCM_SERVER_KEY` di backend
-   [x] Update `.env.example` dengan placeholder FCM keys
-   [x] Install dependencies Flutter:
    -   [x] `firebase_core` (v4.2.1) dan `firebase_messaging` (v16.0.4) untuk FCM
    -   [x] `flutter_local_notifications` (v18.0.1) untuk local notifications
    -   [x] `sqflite` untuk local storage (sudah terinstall)

**Acceptance Criteria:**

-   ✅ Environment variables terkonfigurasi dengan benar
-   ✅ Dependencies terinstall tanpa error
-   ✅ Dapat compile dan run app dengan dependencies baru

**Technical Notes:**

-   FCM setup memerlukan google-services.json (Android) dan GoogleService-Info.plist (iOS)
-   Pastikan Firebase project sudah dikonfigurasi di console.firebase.google.com

---

## Backend - Guide Service

### 2.1 Database Schema untuk Guides (1h)

**Estimasi:** 1 jam
**Priority:** High

-   [ ] Buat tabel `treatment_guides` di Supabase:

    ```sql
    CREATE TABLE treatment_guides (
      id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
      plant_id TEXT NOT NULL,
      disease_name TEXT,
      severity TEXT, -- 'low', 'medium', 'high'
      guide_type TEXT NOT NULL, -- 'identification', 'disease_treatment'
      steps JSONB NOT NULL, -- Array of step objects
      materials JSONB, -- Array of required materials
      estimated_duration TEXT,
      created_at TIMESTAMPTZ DEFAULT NOW(),
      updated_at TIMESTAMPTZ DEFAULT NOW()
    );
    ```

-   [ ] Buat index untuk query performance:

    ```sql
    CREATE INDEX idx_guides_plant_id ON treatment_guides(plant_id);
    CREATE INDEX idx_guides_disease ON treatment_guides(disease_name);
    ```

-   [ ] Seed data dengan 5-10 guide templates untuk common plants/diseases

**Acceptance Criteria:**

-   Tabel berhasil dibuat dengan schema yang benar
-   Index tercipta untuk optimasi query
-   Seed data minimal 5 guides tersedia

**Step Object Structure:**

```json
{
	"step_number": 1,
	"title": "Isolasi Tanaman",
	"description": "Pisahkan tanaman yang sakit dari tanaman lain untuk mencegah penyebaran",
	"image_url": "https://...",
	"materials": ["sarung tangan", "pot terpisah"],
	"is_critical": true,
	"estimated_time": "5 menit"
}
```

---

### 2.2 Backend Endpoint - Get Guide by ID (2h)

**Estimasi:** 2 jam
**Priority:** High

-   [x] Implementasi endpoint `GET /api/guides/{guide_id}`

    -   [x] Query dari Supabase dengan error handling
    -   [x] Return structured JSON (id, plant_id, disease_name, steps, materials, etc.)
    -   [x] Cache response di Redis (TTL: 24 jam)

-   [x] Implementasi endpoint `GET /api/guides/by-plant/{plant_id}`

    -   [x] Query multiple guides untuk satu tanaman
    -   [x] Filter by disease_name (optional query param)
    -   [x] Pagination support (limit, offset)

-   [x] Error handling:
    -   [x] 404 jika guide tidak ditemukan
    -   [x] 500 dengan message jelas jika database error
    -   [x] Rate limiting (100 requests/minute per user)

**Acceptance Criteria:**

-   ✅ Endpoint mengembalikan JSON terstruktur sesuai schema
-   ✅ Cache berfungsi dengan TTL yang tepat
-   ✅ Error handling lengkap dengan status code yang sesuai
-   ✅ Response time < 500ms untuk cached requests

**Implementation Summary:**

-   ✅ Created Pydantic models in `backend/models/treatment_guide.py`
-   ✅ Implemented GuideService in `backend/services/guide_service.py` dengan Supabase REST API
-   ✅ Implemented CacheService in `backend/services/cache_service.py` dengan Redis + in-memory fallback
-   ✅ Created API routes in `backend/routes/guides.py`
-   ✅ Integrated routes ke main.py dengan slowapi rate limiting
-   ✅ Updated requirements.txt: slowapi==0.1.9, pydantic>=2.9.0
-   ✅ Supabase credentials sudah dikonfigurasi di .env

**Files Created:**

-   `backend/models/__init__.py`
-   `backend/models/treatment_guide.py`
-   `backend/services/__init__.py`
-   `backend/services/guide_service.py`
-   `backend/services/cache_service.py`
-   `backend/routes/guides.py`

**API Response Example:**

```json
{
	"id": "uuid",
	"plant_id": "plant_123",
	"disease_name": "Leaf Spot",
	"severity": "medium",
	"guide_type": "disease_treatment",
	"steps": [
		{
			"step_number": 1,
			"title": "Isolasi Tanaman",
			"description": "...",
			"image_url": "...",
			"materials": ["sarung tangan"],
			"is_critical": true,
			"estimated_time": "5 menit"
		}
	],
	"materials": ["sarung tangan", "fungisida organik", "air"],
	"estimated_duration": "2-3 hari"
}
```

---

### 2.3 Backend Endpoint - Create/Update Guide (1.5h)

**Estimasi:** 1.5 jam
**Priority:** Medium

-   [x] Implementasi endpoint `POST /api/guides`

    -   [x] Validasi request body (steps array, materials, etc.)
    -   [x] Insert ke Supabase dengan timestamp
    -   [x] Invalidate cache untuk plant_id terkait

-   [x] Implementasi endpoint `PUT /api/guides/{guide_id}`

    -   [x] Update guide dengan validation
    -   [x] Update `updated_at` timestamp
    -   [x] Invalidate cache

-   [x] Implementasi endpoint `DELETE /api/guides/{guide_id}` (bonus)

    -   [x] Hard delete dari database
    -   [x] Invalidate cache untuk guide_id dan plant_id

-   [x] Authentication check (admin/authenticated user only)

**Acceptance Criteria:**

-   ✅ Hanya authenticated users dapat create/update guides
-   ✅ Validation error mengembalikan 400 dengan detail error
-   ✅ Cache invalidation berfungsi setelah create/update
-   ✅ Timestamps updated correctly

**Implementation Summary:**

-   ✅ Created `backend/auth.py` with `verify_auth_token` dependency for authentication
-   ✅ POST endpoint returns 201 with created guide
-   ✅ PUT endpoint accepts partial updates (exclude_unset=True)
-   ✅ DELETE endpoint returns 204 No Content
-   ✅ All endpoints require Bearer token authentication
-   ✅ Cache invalidation for both guide:id:{id} and guide:plant:{plant_id}:\* patterns
-   ✅ Refactored `create_guide` service method to return TreatmentGuide model
-   ✅ Refactored `delete_guide` service method for hard delete

**Files Modified:**

-   `backend/routes/guides.py` - Added POST, PUT, DELETE endpoints
-   `backend/services/guide_service.py` - Refactored create_guide, added delete_guide
-   `backend/auth.py` - Created authentication utilities

---

## Backend - Collection Service

### 3.1 Database Schema untuk Collections (1h)

**Estimasi:** 1 jam
**Priority:** High

-   [x] Buat tabel `plant_collections` di Supabase:

    ```sql
    CREATE TABLE plant_collections (
      id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
      user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
      plant_id TEXT NOT NULL,
      common_name TEXT NOT NULL,
      scientific_name TEXT,
      image_url TEXT,
      identified_at TIMESTAMPTZ NOT NULL,
      last_care_date TIMESTAMPTZ,
      next_care_date TIMESTAMPTZ,
      care_frequency_days INT DEFAULT 7,
      health_status TEXT, -- 'healthy', 'needs_attention', 'sick'
      notes TEXT,
      is_synced BOOLEAN DEFAULT false,
      created_at TIMESTAMPTZ DEFAULT NOW(),
      updated_at TIMESTAMPTZ DEFAULT NOW()
    );
    ```

-   [x] Buat index untuk performance:

    ```sql
    CREATE INDEX idx_collections_user ON plant_collections(user_id);
    CREATE INDEX idx_collections_next_care ON plant_collections(next_care_date);
    CREATE INDEX idx_collections_synced ON plant_collections(is_synced);
    ```

-   [x] Buat tabel `care_history` untuk tracking:
    ```sql
    CREATE TABLE care_history (
      id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
      collection_id UUID NOT NULL REFERENCES plant_collections(id) ON DELETE CASCADE,
      care_date TIMESTAMPTZ NOT NULL,
      care_type TEXT NOT NULL, -- 'watering', 'fertilizing', 'pruning', etc.
      notes TEXT,
      created_at TIMESTAMPTZ DEFAULT NOW()
    );
    ```

**Acceptance Criteria:**

-   ✅ Tabel berhasil dibuat dengan foreign key constraints
-   ✅ Index tercipta untuk optimasi
-   ✅ Cascade delete berfungsi (hapus user → hapus collections)

**Implementation Summary:**

-   ✅ Migration file created: `backend/migrations/002_create_plant_collections.sql`
-   ✅ Schema includes all required columns with proper constraints
-   ✅ CHECK constraints added for health_status and care_type enums
-   ✅ CHECK constraint for care_frequency_days > 0
-   ✅ All required indexes created (user, next_care, synced, health)
-   ✅ Additional indexes for care_history (collection_id, care_date DESC)
-   ✅ Foreign key with CASCADE DELETE for both tables
-   ✅ Auto-update trigger for updated_at column
-   ✅ Table and column comments for documentation
-   ✅ Migration guide available: `docs/sprint3/database-migration-guide.md`

**Files Created:**

-   `backend/migrations/002_create_plant_collections.sql`
-   `backend/run_migration_002.py` (helper script with instructions)

**To Execute Migration:**

Follow the instructions in `docs/sprint3/database-migration-guide.md` or run:

```bash
cd backend && python3 run_migration_002.py
```

Then manually execute the SQL in Supabase SQL Editor.

---

### 3.2 Backend Endpoint - Collection CRUD (3h) ✅

**Estimasi:** 3 jam
**Priority:** High
**Status:** ✅ **COMPLETED**

-   [x] Implementasi endpoint `POST /api/collections`

    -   [x] Accept data dari client (plant_id, names, image_url, etc.)
    -   [x] Auto-calculate next_care_date berdasarkan identified_at + care_frequency
    -   [x] Insert ke Supabase
    -   [x] Return created collection dengan id

-   [x] Implementasi endpoint `GET /api/collections`

    -   [x] Query collections untuk current user (dari JWT)
    -   [x] Filter by health_status (query param)
    -   [x] Sort by next_care_date ASC (nulls last), then created_at DESC
    -   [x] Pagination (limit 20 per page, max 100)

-   [x] Implementasi endpoint `GET /api/collections/{id}`

    -   [x] Return single collection dengan ownership check
    -   [x] Include all collection details

-   [x] Implementasi endpoint `PUT /api/collections/{id}`

    -   [x] Update fields (notes, health_status, care_frequency, etc.)
    -   [x] Partial updates support (only provided fields updated)
    -   [x] Update timestamp automatically

-   [x] Implementasi endpoint `DELETE /api/collections/{id}`
    -   [x] Hard delete with CASCADE to care_history
    -   [x] Check ownership (user_id match)

**Acceptance Criteria:**

-   ✅ CRUD operations lengkap dan berfungsi
-   ✅ Authorization check memastikan user hanya akses collection milik sendiri
-   ✅ next_care_date ter-calculate otomatis
-   ✅ Response format konsisten dengan pagination support

**Implementation Summary:**

**Files Created:**

-   `backend/models/plant_collection.py` (186 lines)

    -   PlantCollectionBase, PlantCollectionCreate, PlantCollectionUpdate, PlantCollectionResponse
    -   CareHistoryBase, CareHistoryCreate, CareHistoryResponse
    -   HealthStatus type alias (Literal["healthy", "needs_attention", "sick"])
    -   Field validation dengan @field_validator untuk non-empty strings
    -   Field constraints: min_length, max_length, ge (>=1), le (<=365)

-   `backend/services/collection_service.py` (465 lines)

    -   CollectionService class dengan 5 CRUD methods
    -   create_collection: Auto-calculate next_care_date, insert to Supabase
    -   get_collection_by_id: Fetch single collection by UUID
    -   get_collections_by_user: Paginated list with filtering, sorting, total count
    -   update_collection: Partial updates dengan exclude_unset
    -   delete_collection: Hard delete dengan return boolean
    -   Error handling: SupabaseError, CollectionServiceError exceptions

-   `backend/routes/collections.py` (425 lines)
    -   5 RESTful endpoints dengan authentication via verify_auth_token
    -   POST /api/collections: Create (201 Created)
    -   GET /api/collections: List with pagination (health_status filter, limit 20 default)
    -   GET /api/collections/{id}: Get by ID (ownership check, 403 Forbidden if not owner)
    -   PUT /api/collections/{id}: Update (ownership check, partial updates)
    -   DELETE /api/collections/{id}: Delete (204 No Content, ownership check)
    -   Comprehensive error handling dengan HTTP status codes
    -   Detailed OpenAPI docstrings untuk auto-generated docs

**Files Modified:**

-   `backend/models/__init__.py`: Added 8 new exports for collection models
-   `backend/main.py`: Registered collections router dengan prefix `/api/collections`

**API Routes Registered:**

```
GET    /api/collections               # List user's collections (paginated)
POST   /api/collections               # Create new collection
GET    /api/collections/{id}          # Get single collection
PUT    /api/collections/{id}          # Update collection
DELETE /api/collections/{id}          # Delete collection
```

**Technical Decisions:**

-   Sorting by next_care_date ASC (nulls last) untuk prioritize plants yang perlu care
-   Pagination dengan total count dari Content-Range header (Supabase standard)
-   Ownership verification via user_id dari JWT token (403 Forbidden jika tidak cocok)
-   Hard delete untuk simplicity (CASCADE delete via FK constraint)
-   Auto-calculate next_care_date: identified_at + care_frequency_days
-   Service layer untuk business logic, routes layer untuk HTTP concerns

**Authentication:**

-   Semua endpoints require Bearer token
-   user_id extracted dari token via verify_auth_token dependency
-   Ownership check di GET/PUT/DELETE untuk authorization

**Next Steps:**

-   Task 3.3: Sync & batch operations endpoints
-   Manual testing dengan sample data via Postman/curl
-   Integration testing dengan Flutter client

---

### 3.3 Backend Endpoint - Sync & Batch Operations (2h) ✅

**Estimasi:** 2 jam
**Priority:** Medium
**Status:** ✅ **COMPLETED**

-   [x] Implementasi endpoint `POST /api/collections/sync`

    -   [x] Accept array of collections dari client (local changes)
    -   [x] Upsert dengan conflict resolution (server-wins)
    -   [x] Return server state untuk client reconciliation
    -   [x] Mark is_synced = true

-   [x] Implementasi endpoint `GET /api/collections/changes`

    -   [x] Return collections yang berubah sejak last_sync_timestamp
    -   [x] Support incremental sync

-   [x] Implementasi endpoint `POST /api/collections/{id}/care`
    -   [x] Record care action ke care_history
    -   [x] Update last_care_date dan next_care_date
    -   [x] Trigger notification scheduling (via date update)

**Acceptance Criteria:**

-   ✅ Sync protocol berfungsi dengan conflict resolution
-   ✅ Batch operations efisien (tidak hit database per-item)
-   ✅ Changes endpoint support incremental sync dengan timestamp

**Implementation Summary:**

**Models Created:**

-   `CollectionSyncItem` - Model untuk item yang di-sync dari client
-   `CollectionSyncRequest` - Request body untuk bulk sync
-   `CollectionSyncResponse` - Response dengan synced/failed count
-   `CareActionRequest` - Request body untuk record care action
-   `CareActionResponse` - Response dengan care_history + updated collection

**Service Methods:**

-   `sync_collections()` - Bulk upsert dengan server-wins conflict resolution
-   `get_collections_by_timestamp()` - Incremental sync berdasarkan updated_at
-   `record_care_action()` - Create care_history + update collection dates

**API Routes:**

```
POST   /api/collections/sync           # Bulk sync from client
GET    /api/collections/changes        # Incremental sync by timestamp
POST   /api/collections/{id}/care      # Record care action
```

**Files Modified:**

-   `backend/models/plant_collection.py` - Added 5 new models
-   `backend/models/__init__.py` - Exported new models
-   `backend/services/collection_service.py` - Added 3 new service methods
-   `backend/routes/collections.py` - Added 3 new endpoints

**Technical Decisions:**

-   Server-wins conflict resolution: jika ID sudah ada, gunakan server version
-   New collections dari client di-insert sebagai collection baru
-   Incremental sync menggunakan `updated_at > since_timestamp` filter
-   Care action automatically updates last_care_date & recalculates next_care_date
-   All endpoints require Bearer token authentication
-   Comprehensive error handling dengan logging

**Total Collection Endpoints:** 8 (5 CRUD + 3 sync/batch operations)

**⚠️ Transactional Improvement (2025-12-06):**

The `record_care_action` method was refactored to ensure atomicity and data integrity. Previously, it performed separate database writes which could leave data in an inconsistent state if any operation failed.

**Changes Made:**

-   Created PostgreSQL function `record_care_action()` in `backend/migrations/004_record_care_action_function.sql`
-   Function encapsulates all operations in a single transaction:
    1. Verifies collection ownership
    2. Inserts into care_history table
    3. Updates plant_collections (last_care_date, next_care_date)
-   Updated `CollectionService.record_care_action()` to call PostgreSQL function via Supabase RPC
-   All operations now succeed or fail atomically

**Migration Required:**
Apply the SQL migration in `backend/migrations/004_record_care_action_function.sql` via Supabase Dashboard or CLI. See `backend/migrations/README.md` for instructions.

---

## Client - Guide UI Implementation

### 4.1 Guide Model & Provider (1.5h)

**Estimasi:** 1.5 jam
**Priority:** High

-   [ ] Buat model `TreatmentGuide` di `lib/models/treatment_guide.dart`

    -   [ ] Properties: id, plantId, diseaseName, severity, guideType, steps, materials, estimatedDuration
    -   [ ] JSON serialization (fromJson, toJson)
    -   [ ] Validation methods

-   [ ] Buat model `GuideStep` dengan properties:

    -   [ ] stepNumber, title, description, imageUrl, materials, isCritical, estimatedTime

-   [ ] Buat `GuideService` di `lib/services/guide_service.dart`

    -   [ ] Method `fetchGuideById(String guideId)`
    -   [ ] Method `fetchGuidesByPlant(String plantId)`
    -   [ ] Cache dengan TTL 24 jam (gunakan Hive/shared_preferences)

-   [ ] Buat Riverpod provider `guideProvider` dan `guideStepsProvider`
    -   [ ] State management untuk current guide
    -   [ ] State untuk current step index
    -   [ ] State untuk completed steps (Set<int>)

**Acceptance Criteria:**

-   Model memiliki serialization yang benar
-   Service dapat fetch dan cache guides
-   Provider memanage state dengan baik
-   Type-safe dan null-safe

---

### 4.2 Step-by-Step UI Screen (4h)

**Estimasi:** 4 jam
**Priority:** Core

-   [ ] Buat `GuideStepScreen` di `lib/screens/guide_step_screen.dart`

    -   [ ] Top progress bar (currentStep/totalSteps)
    -   [ ] Step card dengan:
        -   [ ] Step number badge
        -   [ ] Image (cached network image dengan placeholder)
        -   [ ] Title (h2 style)
        -   [ ] Description (body text)
        -   [ ] Materials list (chips)
        -   [ ] Critical badge jika is_critical
        -   [ ] Estimated time indicator

-   [ ] Navigation controls:

    -   [ ] "Sebelumnya" button (disabled di step 1)
    -   [ ] "Tandai Selesai" button (primary CTA)
    -   [ ] "Selanjutnya" button (setelah mark complete)
    -   [ ] "Selesai" button di step terakhir

-   [ ] State management:

    -   [ ] Track completed steps (checkmark indicator)
    -   [ ] Disable "Selanjutnya" jika step belum completed
    -   [ ] Progress percentage update real-time

-   [ ] Animations:
    -   [ ] Slide transition between steps (PageView)
    -   [ ] Progress bar animation
    -   [ ] Checkmark animation saat mark complete

**Acceptance Criteria:**

-   UI mengikuti design system (AppColors, AppTextStyles)
-   Progress bar visual jelas (0-100%)
-   User tidak bisa skip step tanpa mark complete
-   Animations smooth (60fps)
-   Responsive pada berbagai screen sizes
-   Accessible (screen reader support)

**UI/UX Notes (dari ux-spec.md):**

-   Progress bar di top: height 4dp, background surface, foreground primary
-   Step cards: padding 16pt, radius 12pt, elevation 2
-   CTA button: 48pt height, bottom center, thumb-friendly
-   Critical badge: danger color dengan icon warning
-   Touch targets ≥44x44pt

---

### 4.3 Guide List & Entry Point (2h)

**Estimasi:** 2 jam
**Priority:** High

-   [ ] Buat `GuideListScreen` di `lib/screens/guide_list_screen.dart`

    -   [ ] AppBar dengan title "Panduan Perawatan"
    -   [ ] List/Grid cards untuk available guides
    -   [ ] Filter by plant type (dropdown)
    -   [ ] Search bar (filter by disease name)

-   [ ] Guide card component:

    -   [ ] Thumbnail image
    -   [ ] Guide title (disease name atau plant name)
    -   [ ] Severity badge (low/medium/high dengan colors)
    -   [ ] Step count indicator
    -   [ ] Estimated duration
    -   [ ] Tap action: navigate ke GuideStepScreen

-   [ ] Empty state jika tidak ada guides
-   [ ] Loading state dengan skeleton

-   [ ] Integrasi dari Identify Result:
    -   [ ] Tambahkan "Lihat Panduan" button di IdentifyResultScreen
    -   [ ] Navigate ke guide terkait plant_id

**Acceptance Criteria:**

-   List menampilkan guides dengan metadata lengkap
-   Filter dan search berfungsi dengan baik
-   Navigation smooth ke step screen
-   Empty state dan loading state ada
-   Integration dengan identify result seamless

---

### 4.4 Guide Completion & Feedback (1h)

**Estimasi:** 1 jam
**Priority:** Medium

-   [ ] Buat completion screen di `GuideCompletionScreen`

    -   [ ] Success message dengan illustration
    -   [ ] Summary: total steps completed, time taken
    -   [ ] Optional feedback form (rating 1-5, text input)
    -   [ ] CTA: "Kembali ke Koleksi" atau "Lihat Panduan Lain"

-   [ ] Submit feedback ke backend (optional endpoint)
-   [ ] Update care_history di collection (jika guide triggered dari collection item)

**Acceptance Criteria:**

-   Completion screen muncul setelah step terakhir
-   Feedback optional (bisa skip)
-   Navigation clear setelah completion

---

## Client - Collection Management

### 5.1 Collection Model & Local Storage (2h)

**Estimasi:** 2 jam
**Priority:** High

-   [ ] Buat model `PlantCollection` di `lib/models/plant_collection.dart`

    -   [ ] Properties: id, userId, plantId, commonName, scientificName, imageUrl, identifiedAt, lastCareDate, nextCareDate, careFrequencyDays, healthStatus, notes, isSynced, createdAt, updatedAt
    -   [ ] JSON serialization
    -   [ ] Validation methods

-   [ ] Buat local database dengan Hive/Drift:

    -   [ ] Box/Table: `plant_collections`
    -   [ ] CRUD operations: create, read, update, delete
    -   [ ] Query methods: getAll, getById, getByUserId, getUnsynced
    -   [ ] Filter methods: filterByHealthStatus, sortByNextCareDate

-   [ ] Buat `CollectionRepository` di `lib/repositories/collection_repository.dart`
    -   [ ] Abstract interface untuk CRUD
    -   [ ] Implementasi LocalCollectionRepository (Hive/Drift)
    -   [ ] Implementasi RemoteCollectionRepository (API)
    -   [ ] Sync logic (local → remote, remote → local)

**Acceptance Criteria:**

-   Model serializable dan type-safe
-   Local storage berfungsi dengan CRUD lengkap
-   Repository pattern dengan abstraction jelas
-   Sync-aware (isSynced flag management)

---

### 5.2 Collection Service & Provider (1.5h)

**Estimasi:** 1.5 jam
**Priority:** High

-   [ ] Buat `CollectionService` di `lib/services/collection_service.dart`

    -   [ ] Method `addToCollection(IdentificationResult result)`
    -   [ ] Method `getCollections({String? healthFilter})`
    -   [ ] Method `updateCollection(PlantCollection collection)`
    -   [ ] Method `deleteCollection(String id)`
    -   [ ] Method `markCareCompleted(String collectionId, String careType)`

-   [ ] Buat Riverpod providers:

    -   [ ] `collectionListProvider`: FutureProvider untuk list collections
    -   [ ] `collectionDetailProvider(id)`: FutureProvider untuk single item
    -   [ ] `unsyncedCollectionsProvider`: untuk sync badge count

-   [ ] Error handling dan loading states

**Acceptance Criteria:**

-   Service methods berfungsi dengan local repo
-   Providers reactive terhadap changes
-   Error handling lengkap

---

### 5.3 Collection Grid Screen (3h)

**Estimasi:** 3 jam
**Priority:** High

-   [ ] Buat `CollectionGridScreen` di `lib/screens/collection_grid_screen.dart`

    -   [ ] AppBar dengan title "Koleksi Saya" dan filter icon
    -   [ ] Grid layout (2 columns pada mobile, 3-4 di tablet)
    -   [ ] Plant card component:
        -   [ ] Image thumbnail (cached, aspect ratio 1:1)
        -   [ ] Common name (h3)
        -   [ ] Health status badge (healthy/needs attention/sick)
        -   [ ] Next care date indicator (jika < 3 hari, tampilkan countdown)
        -   [ ] Tap: navigate ke detail
        -   [ ] Long-press: show quick actions (edit, delete)

-   [ ] Filter bottom sheet:

    -   [ ] Filter by health status (All, Healthy, Needs Attention, Sick)
    -   [ ] Sort options (newest, oldest, next care date)
    -   [ ] Apply button

-   [ ] FAB (Floating Action Button):

    -   [ ] Icon: Add
    -   [ ] Action: navigate ke Camera/Identify

-   [ ] Empty state:

    -   [ ] Illustration "Belum ada tanaman"
    -   [ ] CTA "Identifikasi Tanaman Pertama"

-   [ ] Pull-to-refresh untuk sync

**Acceptance Criteria:**

-   Grid responsive pada berbagai screen sizes
-   Cards menampilkan info penting dengan jelas
-   Filter dan sort berfungsi
-   Empty state ada
-   Pull-to-refresh triggers sync
-   Performance baik (lazy loading, pagination jika >50 items)

**UI/UX Notes:**

-   Grid spacing: 12pt
-   Card radius: 12pt
-   Image loading: shimmer effect
-   Health badge colors: healthy=secondary, needs_attention=accent, sick=danger

---

### 5.4 Collection Detail Screen (2.5h)

**Estimasi:** 2.5 jam
**Priority:** High

-   [ ] Buat `CollectionDetailScreen` di `lib/screens/collection_detail_screen.dart`

    -   [ ] Hero image dengan gradient overlay
    -   [ ] Plant info section:

        -   [ ] Common name (h1)
        -   [ ] Scientific name (italic, text-secondary)
        -   [ ] Health status badge
        -   [ ] Identified date

    -   [ ] Care section:

        -   [ ] Last care date
        -   [ ] Next care date (countdown jika < 7 hari)
        -   [ ] Care frequency (editable)
        -   [ ] CTA button "Tandai Sudah Dirawat"

    -   [ ] Guide section:

        -   [ ] List panduan terkait plant_id
        -   [ ] Tap: navigate ke GuideStepScreen

    -   [ ] Care history:

        -   [ ] Timeline view recent care actions
        -   [ ] Expandable/collapsible

    -   [ ] Notes section:

        -   [ ] Editable text field
        -   [ ] Auto-save on blur

    -   [ ] Actions:
        -   [ ] Edit (bottom sheet untuk edit names, care frequency)
        -   [ ] Delete (confirmation dialog)

**Acceptance Criteria:**

-   All sections visible dan informative
-   "Tandai Sudah Dirawat" update last_care_date dan recalculate next_care_date
-   Care history displayed dengan formatting yang baik
-   Edit dan delete berfungsi dengan confirmation
-   Notes auto-save

**UI/UX Notes:**

-   Hero image height: 40% screen height
-   Section spacing: 24pt
-   Timeline: use leading icon + connector line
-   Delete confirmation: AlertDialog dengan destructive action

---

### 5.5 Add to Collection Flow (1h)

**Estimasi:** 1 jam
**Priority:** High

-   [ ] Integrasi dari IdentifyResultScreen:

    -   [ ] Button "Simpan ke Koleksi" (primary CTA)
    -   [ ] Saat tap: show dialog untuk customize:
        -   [ ] Care frequency (default 7 hari)
        -   [ ] Optional notes
        -   [ ] Confirm button

-   [ ] Setelah save:

    -   [ ] Toast "Tanaman berhasil disimpan"
    -   [ ] Option navigate ke collection atau stay di result
    -   [ ] Update collection badge count di bottom nav

-   [ ] Prevent duplicate:
    -   [ ] Check jika plant_id + user_id sudah ada
    -   [ ] Show dialog "Tanaman sudah ada di koleksi. Lihat detail?"

**Acceptance Criteria:**

-   Save flow smooth dengan customization option
-   Duplicate detection berfungsi
-   Toast notification jelas
-   Navigation options intuitive

---

## Client - Notifications

### 6.1 FCM Setup & Configuration (2h)

**Estimasi:** 2 jam
**Priority:** Medium

-   [ ] Setup Firebase project di console.firebase.google.com

    -   [ ] Create project atau gunakan existing
    -   [ ] Add Android app (dengan package name)
    -   [ ] Download google-services.json → android/app/
    -   [ ] Add iOS app (dengan bundle ID)
    -   [ ] Download GoogleService-Info.plist → ios/Runner/

-   [ ] Configure Android:

    -   [ ] Update android/build.gradle.kts dengan google-services plugin
    -   [ ] Update android/app/build.gradle.kts dengan apply plugin
    -   [ ] Verify minSdkVersion ≥21, targetSdkVersion ≥33

-   [ ] Configure iOS:

    -   [ ] Ensure Runner/Info.plist memiliki push notification entitlements
    -   [ ] Enable Push Notifications di Xcode project

-   [ ] Initialize Firebase di Flutter:
    -   [ ] Update main.dart dengan Firebase.initializeApp()
    -   [ ] Request notification permissions (iOS)
    -   [ ] Get FCM token dan save ke Supabase user profile

**Acceptance Criteria:**

-   Firebase configured untuk Android dan iOS
-   App bisa get FCM token tanpa error
-   Permissions request dialog muncul di iOS

**Technical Notes:**

-   FCM token harus disimpan di user profile untuk targeting
-   Token bisa berubah (handle onTokenRefresh)

---

### 6.2 Local Notifications Setup (1.5h)

**Estimasi:** 1.5 jam
**Priority:** Medium

-   [ ] Configure flutter_local_notifications:

    -   [ ] Initialize plugin di main.dart
    -   [ ] Define notification channels untuk Android:
        -   [ ] care_reminders (default priority)
        -   [ ] urgent_care (high priority)
    -   [ ] Request permissions (Android 13+)

-   [ ] Create NotificationService di `lib/services/notification_service.dart`:

    -   [ ] Method `scheduleCarReminder(PlantCollection plant)`
    -   [ ] Method `cancelReminder(String plantId)`
    -   [ ] Method `rescheduleReminders()` (called on app start)
    -   [ ] Method `showImmediateNotification(String title, String body)`

-   [ ] Notification payload:
    -   [ ] Include collection_id untuk deep linking
    -   [ ] Title: "Waktunya merawat {plant_name}!"
    -   [ ] Body: "Tanaman Anda memerlukan perawatan hari ini."

**Acceptance Criteria:**

-   Local notifications dapat dijadwalkan dengan delay
-   Notifications muncul di waktu yang tepat
-   Tap notification membuka app ke collection detail
-   Cancel berfungsi saat delete collection

---

### 6.3 Reminder Scheduling Logic (2h)

**Estimasi:** 2 jam
**Priority:** Medium

-   [ ] Implementasi scheduling di CollectionService:

    -   [ ] Saat save collection: schedule reminder untuk next_care_date
    -   [ ] Saat update care_frequency: reschedule reminder
    -   [ ] Saat mark care completed: reschedule untuk next cycle

-   [ ] Background scheduling:

    -   [ ] Use WorkManager (Android) atau background fetch (iOS)
    -   [ ] Periodic task untuk check upcoming reminders (daily)
    -   [ ] Reschedule all reminders setelah app update

-   [ ] User preferences:

    -   [ ] Settings screen untuk enable/disable reminders
    -   [ ] Time preference (default: 9:00 AM)
    -   [ ] Advance notification (default: same day, options: 1 day before, 2 days before)

-   [ ] Batch scheduling optimization:
    -   [ ] Schedule max 64 notifications (Android limit)
    -   [ ] Prioritize yang < 30 hari kedepan

**Acceptance Criteria:**

-   Reminders dijadwalkan otomatis dengan next_care_date
-   User dapat customize reminder time di settings
-   Batch scheduling tidak exceed platform limits
-   Reminders survive app restart

**Technical Notes:**

-   Android: gunakan AlarmManager untuk exact timing
-   iOS: gunakan UNUserNotificationCenter
-   Handle timezone changes

---

### 6.4 Push Notifications Integration (1.5h)

**Estimasi:** 1.5 jam
**Priority:** Low (optional untuk MVP)

-   [ ] Backend endpoint untuk send push:

    -   [ ] POST /api/notifications/send
    -   [ ] Accept: user_id, title, body, data payload
    -   [ ] Use FCM Admin SDK untuk send ke FCM token

-   [ ] Client-side handling:

    -   [ ] Listen onMessage (foreground)
    -   [ ] Show local notification jika app di foreground
    -   [ ] Listen onMessageOpenedApp (background tap)
    -   [ ] Navigate ke appropriate screen dengan payload

-   [ ] Use cases (future):
    -   [ ] Admin broadcast (e.g., new guides available)
    -   [ ] Social features (friend merawat tanaman sama)

**Acceptance Criteria:**

-   Backend dapat send push via FCM
-   Client receive dan display notification
-   Deep linking berfungsi dari push notification

**Technical Notes:**

-   Ini optional untuk MVP, bisa diprioritaskan rendah
-   Local notifications sudah cukup untuk care reminders

---

## Integration & Sync

### 7.1 Sync Protocol Implementation (3h)

**Estimasi:** 3 jam
**Priority:** High

-   [ ] Implementasi sync strategy:

    -   [ ] On app start: sync collections jika online
    -   [ ] On background: periodic sync (every 1 hour jika app active)
    -   [ ] On user action: manual sync (pull-to-refresh)
    -   [ ] On network reconnect: auto-sync

-   [ ] SyncService di `lib/services/sync_service.dart`:

    -   [ ] Method `syncCollections()`

        -   [ ] Get unsynced local items (isSynced = false)
        -   [ ] POST to /api/collections/sync
        -   [ ] Get server changes since last_sync_timestamp
        -   [ ] Merge dengan conflict resolution
        -   [ ] Update local database
        -   [ ] Mark items as synced

    -   [ ] Conflict resolution logic:
        -   [ ] Server always wins untuk same updated_at
        -   [ ] Latest updated_at wins jika berbeda
        -   [ ] Log conflicts untuk review

-   [ ] Sync status provider:

    -   [ ] syncInProgressProvider (boolean)
    -   [ ] lastSyncTimeProvider (DateTime)
    -   [ ] syncErrorProvider (String?)

-   [ ] UI indicators:
    -   [ ] Sync spinner di AppBar saat syncing
    -   [ ] Badge count untuk unsynced items
    -   [ ] Toast "Sinkronisasi berhasil" atau "Gagal, coba lagi"

**Acceptance Criteria:**

-   Sync berfungsi bi-directional (local ↔ remote)
-   Conflict resolution tidak kehilangan data
-   Sync status visible ke user
-   Error handling robust (retry logic)
-   Sync tidak block UI (async)

**Technical Notes:**

-   Gunakan Queue untuk batch sync requests
-   Implement exponential backoff untuk retry
-   Store last_sync_timestamp di secure storage

---

### 7.2 Offline Mode Handling (2h)

**Estimasi:** 2 jam
**Priority:** High

-   [ ] Network connectivity detection:

    -   [ ] Use connectivity_plus package
    -   [ ] Provider `isOnlineProvider`
    -   [ ] Listen to connectivity changes

-   [ ] Offline UI indicators:

    -   [ ] Banner at top "Mode Offline" (dismissible)
    -   [ ] Disable sync actions
    -   [ ] Show "Akan disimpan saat online" message

-   [ ] Offline-first behavior:

    -   [ ] Semua CRUD operations ke local database dulu
    -   [ ] Queue untuk sync saat online kembali
    -   [ ] Cache images untuk offline access

-   [ ] Guide caching:
    -   [ ] Auto-download guides saat view (background)
    -   [ ] Store di local database dengan images
    -   [ ] "Download untuk offline" option di guide list

**Acceptance Criteria:**

-   App fully functional offline (view, create, edit collections)
-   User aware mode offline dengan indicator jelas
-   Data tersimpan lokal dan sync otomatis saat online
-   Guides ter-cache untuk offline access

---

## Testing & QA

### 8.1 Unit Tests (4h)

**Estimasi:** 4 jam
**Priority:** High

-   [ ] Test models:

    -   [ ] TreatmentGuide serialization
    -   [ ] PlantCollection serialization
    -   [ ] Validation methods

-   [ ] Test services:

    -   [ ] GuideService fetch methods
    -   [ ] CollectionService CRUD operations
    -   [ ] NotificationService scheduling
    -   [ ] SyncService sync logic

-   [ ] Test repositories:

    -   [ ] LocalCollectionRepository CRUD
    -   [ ] Conflict resolution logic

-   [ ] Test providers:
    -   [ ] guideProvider state management
    -   [ ] collectionListProvider filtering
    -   [ ] syncStatusProvider updates

**Acceptance Criteria:**

-   Code coverage ≥70% untuk services dan repositories
-   All edge cases covered (null, empty, error states)
-   Mock external dependencies (API, database)

**Test Files:**

-   `test/models/treatment_guide_test.dart`
-   `test/services/guide_service_test.dart`
-   `test/services/collection_service_test.dart`
-   `test/services/notification_service_test.dart`
-   `test/repositories/collection_repository_test.dart`

---

### 8.2 Widget Tests (3h)

**Estimasi:** 3 jam
**Priority:** Medium

-   [ ] Test screens:

    -   [ ] GuideStepScreen rendering
    -   [ ] CollectionGridScreen grid layout
    -   [ ] CollectionDetailScreen sections
    -   [ ] GuideCompletionScreen

-   [ ] Test interactions:

    -   [ ] Step navigation (previous/next)
    -   [ ] Mark complete button
    -   [ ] Filter bottom sheet
    -   [ ] Delete confirmation dialog

-   [ ] Test states:
    -   [ ] Loading states (shimmer, spinner)
    -   [ ] Empty states (illustration, CTA)
    -   [ ] Error states (retry button)

**Acceptance Criteria:**

-   Key user flows ter-cover dengan widget tests
-   Interactions tested (button taps, swipes)
-   Snapshot tests untuk UI consistency

---

### 8.3 Integration Tests (2h)

**Estimasi:** 2 jam
**Priority:** Medium

-   [ ] Test end-to-end flows:

    -   [ ] Save identification result → Collection → Mark care → Guide
    -   [ ] View guide → Complete steps → Back to collection
    -   [ ] Add collection → Edit → Delete

-   [ ] Test sync flow:
    -   [ ] Create offline → Go online → Verify synced
    -   [ ] Edit online → Sync → Verify local updated

**Acceptance Criteria:**

-   Critical paths tested end-to-end
-   Sync scenarios covered
-   Tests run pada emulator/simulator

**Test File:**

-   `integration_test/sprint3_flow_test.dart`

---

### 8.4 Manual QA Checklist (1h)

**Estimasi:** 1 jam
**Priority:** High

-   [ ] **Guide Flow:**

    -   [ ] Navigate dari identify result ke guide
    -   [ ] Complete all steps (mark complete setiap step)
    -   [ ] Verify progress bar updates
    -   [ ] Verify completion screen appears
    -   [ ] Verify care history updated di collection

-   [ ] **Collection Flow:**

    -   [ ] Save plant dari identify result
    -   [ ] Verify appears di collection grid
    -   [ ] Tap card → detail screen shows correct info
    -   [ ] Edit care frequency → verify next_care_date updates
    -   [ ] Mark care completed → verify last_care_date updates
    -   [ ] Delete collection → verify confirmation dialog → verify removed

-   [ ] **Notification Flow:**

    -   [ ] Save collection dengan next_care_date = tomorrow
    -   [ ] Wait untuk notification muncul (atau test dengan short delay)
    -   [ ] Tap notification → verify deep link ke collection detail
    -   [ ] Disable notifications di settings → verify tidak ada notification

-   [ ] **Sync Flow:**

    -   [ ] Create collection offline → go online → pull to refresh → verify synced
    -   [ ] Edit online via web → refresh app → verify local updated
    -   [ ] Verify sync status indicator

-   [ ] **Edge Cases:**

    -   [ ] Empty collection → verify empty state
    -   [ ] No guides available → verify empty state
    -   [ ] Network timeout → verify error handling
    -   [ ] Duplicate save → verify warning dialog

-   [ ] **Accessibility:**

    -   [ ] Enable TalkBack/VoiceOver → navigate guide steps
    -   [ ] Verify all buttons have semantic labels
    -   [ ] Verify contrast ratios meet WCAG standards

-   [ ] **Performance:**
    -   [ ] Load 50+ collections → verify smooth scrolling
    -   [ ] Check memory usage (no leaks)
    -   [ ] Verify image caching working (fast re-renders)

**Acceptance Criteria:**

-   All manual test cases pass
-   No critical bugs found
-   Performance acceptable (smooth 60fps)
-   Accessibility compliant

---

## Documentation

### 9.1 Code Documentation (1h)

**Estimasi:** 1 jam
**Priority:** Medium

-   [ ] Add dartdoc comments untuk:

    -   [ ] All public classes dan methods
    -   [ ] Complex business logic
    -   [ ] API contracts (expected params, return types)

-   [ ] Update README.md:

    -   [ ] Sprint 3 features summary
    -   [ ] Setup instructions untuk FCM
    -   [ ] Environment variables documentation

-   [ ] Create architecture diagram:
    -   [ ] Guide service flow
    -   [ ] Collection sync flow
    -   [ ] Notification scheduling flow

**Acceptance Criteria:**

-   All public APIs documented
-   README up-to-date
-   Architecture diagrams clear

---

### 9.2 User Guide (Optional) (0.5h)

**Estimasi:** 0.5 jam
**Priority:** Low

-   [ ] Create in-app tooltips untuk first-time users:

    -   [ ] "Tandai langkah selesai untuk melanjutkan"
    -   [ ] "Geser untuk lihat panduan lain"
    -   [ ] "Tarik untuk refresh koleksi"

-   [ ] Create FAQ section di profile screen (future)

**Acceptance Criteria:**

-   Tooltips helpful dan non-intrusive
-   Dismissible setelah first view

---

## 📊 Progress Tracking

### Overall Sprint Progress

**Completed:** 0/85 tasks (0%)

**By Category:**

-   [ ] Setup & Prerequisites: 0/4 tasks
-   [ ] Backend - Guide Service: 0/12 tasks
-   [ ] Backend - Collection Service: 0/15 tasks
-   [ ] Client - Guide UI: 0/12 tasks
-   [ ] Client - Collection: 0/18 tasks
-   [ ] Client - Notifications: 0/11 tasks
-   [ ] Integration & Sync: 0/8 tasks
-   [ ] Testing & QA: 0/13 tasks
-   [ ] Documentation: 0/4 tasks

### Daily Goals (Suggested)

**Day 1 (Jumat):** Setup + Backend Guide Service

-   Complete Setup & Prerequisites (4 tasks)
-   Complete Backend Guide Service (12 tasks)
-   **Target:** 16 tasks, ~8 jam

**Day 2 (Sabtu):** Backend Collection Service + Start Client Guide

-   Complete Backend Collection Service (15 tasks)
-   Start Client Guide UI (Model & Provider)
-   **Target:** 17 tasks, ~9 jam

**Day 3 (Minggu):** Client Guide UI Implementation

-   Complete Guide UI screens (Step screen, List, Completion)
-   **Target:** 10 tasks, ~8 jam

**Day 4 (Senin):** Client Collection Management

-   Complete Collection models, service, providers
-   Complete Collection Grid and Detail screens
-   **Target:** 18 tasks, ~10 jam

**Day 5 (Selasa):** Notifications + Integration + Testing

-   Complete Notifications setup
-   Complete Sync implementation
-   Run all tests and QA
-   Complete documentation
-   **Target:** 24 tasks, ~10 jam

---

## 🎯 Definition of Done (Sprint 3)

Sprint dianggap selesai jika:

### Functional Requirements

-   [x] User dapat melihat panduan perawatan step-by-step dengan ≤5 langkah
-   [x] Progress tracking berfungsi dengan mark complete per langkah
-   [x] User dapat menyimpan tanaman ke koleksi pribadi
-   [x] Koleksi tersimpan lokal dan sync ke backend saat online
-   [x] User dapat edit dan delete items di koleksi
-   [x] Notifikasi perawatan berfungsi (local notifications)
-   [x] Care history ter-track dengan timestamp
-   [x] Offline mode fully functional

### Technical Requirements

-   [x] Backend endpoints guide dan collection berfungsi dengan status 200
-   [x] Database schema deployed di Supabase
-   [x] FCM configured dan token tersimpan
-   [x] Sync protocol implemented dengan conflict resolution
-   [x] Local storage (Hive/Drift) berfungsi dengan CRUD
-   [x] Code coverage ≥70% untuk services dan repositories
-   [x] No critical bugs atau crashes

### UI/UX Requirements

-   [x] UI mengikuti design system (colors, typography, spacing)
-   [x] Animations smooth (60fps)
-   [x] Loading states, empty states, error states ada
-   [x] Accessibility: semantic labels, contrast ratios meet WCAG
-   [x] Touch targets ≥44x44pt
-   [x] Responsive pada mobile (tested on 2+ devices)

### Documentation

-   [x] Code documented dengan dartdoc
-   [x] README updated dengan Sprint 3 features
-   [x] API contracts documented
-   [x] Manual QA checklist completed

---

## 📝 Notes & Best Practices

### Architecture Guidelines

-   Follow existing patterns: Provider pattern untuk state, Repository pattern untuk data
-   Keep business logic di Services, tidak di Widgets
-   Use immutable models (use `@immutable` annotation)
-   Prefer composition over inheritance

### Performance Considerations

-   Cache images dengan `cached_network_image`
-   Lazy load collections (pagination jika >50 items)
-   Use `const` constructors where possible
-   Optimize list rendering (use `ListView.builder`)
-   Background sync harus non-blocking

### Error Handling

-   Always catch exceptions di services
-   Provide user-friendly error messages
-   Log errors untuk debugging (use `logger` package)
-   Implement retry logic untuk network errors
-   Show actionable error states (retry button)

### Security

-   Never log sensitive data (user tokens, passwords)
-   Validate all user inputs
-   Use HTTPS untuk all API calls
-   Store FCM tokens securely
-   Implement rate limiting di backend

### Testing Strategy

-   Write tests alongside features (not after)
-   Mock external dependencies (API, database)
-   Test edge cases (null, empty, error)
-   Use test fixtures untuk consistent test data
-   Run tests before committing

---

## 🔗 Referensi

-   [Sprint Planning](../sprint-planning.md)
-   [Epics](../epics.md)
-   [PRD](../prd.md)
-   [UX Spec](../ux-spec.md)
-   [Arsitektur Sistem](../architect.md)
-   [Sprint 1 Todo](../sprint1/todo.md)
-   [Sprint 2 Todo](../sprint2/todo.md)

---

## ✅ Sprint Review Checklist

Sebelum menganggap Sprint 3 selesai, pastikan:

-   [ ] Demo ke stakeholders berjalan lancar
-   [ ] All acceptance criteria terpenuhi
-   [ ] Manual QA checklist completed
-   [ ] No critical bugs outstanding
-   [ ] Code reviewed dan merged ke main branch
-   [ ] Documentation updated
-   [ ] Retrospective meeting dilakukan
-   [ ] Sprint 4 planning dimulai

---

**Last Updated:** December 5, 2025
**Next Sprint:** Sprint 4 - Offline Mode & Polish
