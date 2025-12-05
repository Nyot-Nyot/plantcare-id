# Database Migration Guide - Sprint 3

## Overview

Panduan ini menjelaskan cara menjalankan migrasi database untuk Sprint 3 features: Treatment Guides dan Plant Collections.

## Prerequisites

-   Akses ke Supabase Dashboard
-   Project PlantCare.ID sudah ada di Supabase
-   Koneksi internet stabil

## Migration Files

1. `001_create_treatment_guides.sql` - Membuat tabel treatment_guides
2. `002_create_plant_collections.sql` - Membuat tabel plant_collections dan care_history
3. `003_seed_treatment_guides.sql` - Seed data untuk sample treatment guides

## Step-by-Step Execution

### 1. Login ke Supabase Dashboard

1. Buka https://supabase.com/dashboard
2. Login dengan akun yang memiliki akses ke project PlantCare.ID
3. Pilih project PlantCare.ID

### 2. Buka SQL Editor

1. Di sidebar kiri, klik **SQL Editor**
2. Klik tombol **+ New Query** untuk membuat query baru

### 3. Jalankan Migration 001 - Treatment Guides Table

#### Copy dan Paste

1. Buka file `backend/migrations/001_create_treatment_guides.sql`
2. Copy seluruh isi file
3. Paste ke SQL Editor di Supabase
4. Klik tombol **Run** (atau tekan Ctrl/Cmd + Enter)

#### Verifikasi

Jalankan query berikut untuk memastikan tabel berhasil dibuat:

```sql
-- Check table exists
SELECT table_name, column_name, data_type
FROM information_schema.columns
WHERE table_name = 'treatment_guides'
ORDER BY ordinal_position;

-- Check indexes
SELECT indexname, indexdef
FROM pg_indexes
WHERE tablename = 'treatment_guides';
```

**Expected Output:**

-   11 kolom (id, plant_id, disease_name, severity, guide_type, steps, materials, estimated_duration_minutes, estimated_duration_text, created_at, updated_at)
-   3 indexes (idx_guides_plant_id, idx_guides_disease, idx_guides_type)
-   1 trigger (update_treatment_guides_updated_at)
-   1 function (update_updated_at_column)

**Note:** Migration ini juga membuat fungsi `update_updated_at_column()` yang akan otomatis update timestamp `updated_at` setiap ada UPDATE pada tabel. Fungsi ini reusable untuk tabel lain.

### 4. Jalankan Migration 002 - Collections Tables

#### Copy dan Paste

1. Buka file `backend/migrations/002_create_plant_collections.sql`
2. Copy seluruh isi file
3. Paste ke SQL Editor di Supabase (query baru)
4. Klik tombol **Run**

#### Verifikasi

Jalankan query berikut:

```sql
-- Check plant_collections table
SELECT table_name, column_name, data_type
FROM information_schema.columns
WHERE table_name = 'plant_collections'
ORDER BY ordinal_position;

-- Check care_history table
SELECT table_name, column_name, data_type
FROM information_schema.columns
WHERE table_name = 'care_history'
ORDER BY ordinal_position;

-- Check foreign keys
SELECT
    tc.constraint_name,
    tc.table_name,
    kcu.column_name,
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name
FROM information_schema.table_constraints AS tc
JOIN information_schema.key_column_usage AS kcu
    ON tc.constraint_name = kcu.constraint_name
JOIN information_schema.constraint_column_usage AS ccu
    ON ccu.constraint_name = tc.constraint_name
WHERE tc.constraint_type = 'FOREIGN KEY'
AND tc.table_name IN ('plant_collections', 'care_history');
```

**Expected Output:**

-   plant_collections: 15 kolom (id, user_id, plant_id, common_name, scientific_name, image_url, identified_at, last_care_date, next_care_date, care_frequency_days, health_status, notes, is_synced, created_at, updated_at)
-   care_history: 6 kolom (id, collection_id, care_date, care_type, notes, created_at)
-   2 foreign keys (plant_collections -> auth.users, care_history -> plant_collections)
-   1 trigger (update_plant_collections_updated_at)
-   Reuses function update_updated_at_column() from migration 001

**Note:** Trigger `update_plant_collections_updated_at` memastikan `updated_at` otomatis diperbarui setiap kali ada UPDATE pada collection.

### 5. Jalankan Migration 003 - Seed Data

#### Copy dan Paste

1. Buka file `backend/migrations/003_seed_treatment_guides.sql`
2. Copy seluruh isi file
3. Paste ke SQL Editor di Supabase (query baru)
4. Klik tombol **Run**

#### Verifikasi

Query terakhir di file akan otomatis menampilkan hasil:

```sql
SELECT
    id,
    plant_id,
    disease_name,
    severity,
    guide_type,
    jsonb_array_length(steps) as step_count,
    estimated_duration_minutes,
    estimated_duration_text
FROM treatment_guides
ORDER BY created_at DESC;
```

**Expected Output:**
5 rows dengan data:

1. Leaf Spot (medium, disease_treatment, 5 steps, 20160 min = 2 weeks, "2-3 minggu")
2. Root Rot (high, disease_treatment, 4 steps, 64800 min = 45 days, "1-2 bulan recovery")
3. Aphid Infestation (medium, disease_treatment, 3 steps, 20160 min = 2 weeks, "2-3 minggu")
4. Monstera Care (low, identification, 3 steps, NULL, "ongoing care")
5. Yellowing Leaves (low, disease_treatment, 4 steps, 10080 min = 1 week, "1-2 minggu")

**Note:**

-   `estimated_duration_minutes` menyimpan durasi dalam menit untuk kalkulasi (e.g., 1440 = 1 hari, 10080 = 1 minggu)
-   `estimated_duration_text` menyimpan teks human-readable untuk display UI

## Troubleshooting

### Error: "function uuid_generate_v4() does not exist"

**Penyebab:** Extension uuid-ossp belum diaktifkan

**Solusi:**

```sql
-- Enable UUID extension manually
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Lalu jalankan ulang migration
```

**Note:** Migration files sudah include perintah ini di awal, jadi seharusnya tidak terjadi error ini.

### Error: "relation treatment_guides already exists"

**Penyebab:** Tabel sudah pernah dibuat sebelumnya

**Solusi:**

```sql
-- Drop tabel existing (HATI-HATI: ini akan menghapus semua data)
DROP TABLE IF EXISTS treatment_guides CASCADE;

-- Lalu jalankan ulang migration 001
```

### Error: "foreign key constraint... does not exist"

**Penyebab:** Tabel auth.users tidak ada atau nama kolom salah

**Solusi:**

```sql
-- Verifikasi tabel auth.users
SELECT id FROM auth.users LIMIT 1;

-- Jika error, berarti schema auth belum ada
-- Pastikan Supabase Auth sudah diaktifkan di dashboard
```

### Error: "CHECK constraint violated"

**Penyebab:** Data seed mencoba insert nilai yang tidak sesuai constraint

**Solusi:**

-   Periksa nilai severity harus: 'low', 'medium', atau 'high'
-   Periksa nilai guide_type harus: 'identification' atau 'disease_treatment'
-   Periksa nilai health_status harus: 'healthy', 'needs_attention', atau 'sick'
-   Periksa nilai care_type harus salah satu dari: 'watering', 'fertilizing', 'pruning', 'repotting', 'pest_control', 'other'

## Post-Migration Checklist

### ✅ Verifikasi Database Structure

```sql
-- List all tables
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
ORDER BY table_name;

-- Expected: care_history, plant_collections, treatment_guides

-- Verify triggers and functions
SELECT trigger_name, event_object_table, action_statement
FROM information_schema.triggers
WHERE trigger_schema = 'public'
ORDER BY event_object_table, trigger_name;

-- Expected triggers:
-- update_plant_collections_updated_at on plant_collections
-- update_treatment_guides_updated_at on treatment_guides

-- Verify the update_updated_at_column function exists
SELECT routine_name, routine_type
FROM information_schema.routines
WHERE routine_schema = 'public' AND routine_name = 'update_updated_at_column';
```

### ✅ Test Sample Queries

```sql
-- Test treatment_guides query
SELECT
    disease_name,
    severity,
    guide_type,
    jsonb_array_length(steps) as steps_count
FROM treatment_guides
WHERE guide_type = 'disease_treatment';

-- Test plant_collections (akan kosong karena belum ada user)
SELECT COUNT(*) FROM plant_collections;

-- Test care_history (akan kosong)
SELECT COUNT(*) FROM care_history;

-- Test auto-update timestamp trigger (menggunakan data seed)
-- Ambil salah satu guide untuk di-update
DO $$
DECLARE
    guide_id UUID;
    old_timestamp TIMESTAMPTZ;
    new_timestamp TIMESTAMPTZ;
BEGIN
    -- Ambil ID guide pertama
    SELECT id, updated_at INTO guide_id, old_timestamp
    FROM treatment_guides
    LIMIT 1;

    -- Tunggu 1 detik
    PERFORM pg_sleep(1);

    -- Update guide
    UPDATE treatment_guides
    SET estimated_duration_text = '1-2 weeks'
    WHERE id = guide_id;

    -- Ambil timestamp baru
    SELECT updated_at INTO new_timestamp
    FROM treatment_guides
    WHERE id = guide_id;

    -- Verifikasi timestamp berubah
    IF new_timestamp > old_timestamp THEN
        RAISE NOTICE 'SUCCESS: Auto-update timestamp works! Old: %, New: %', old_timestamp, new_timestamp;
    ELSE
        RAISE EXCEPTION 'FAILED: Timestamp not updated! Old: %, New: %', old_timestamp, new_timestamp;
    END IF;
END $$;
```

**Expected:** Pesan "SUCCESS: Auto-update timestamp works!" dengan timestamps yang berbeda.

### ✅ Setup Row Level Security (RLS)

**PENTING:** Untuk production, aktifkan RLS:

```sql
-- Enable RLS on treatment_guides (public read)
ALTER TABLE treatment_guides ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Treatment guides are viewable by everyone"
ON treatment_guides FOR SELECT
USING (true);

-- Enable RLS on plant_collections (user-specific)
ALTER TABLE plant_collections ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own collections"
ON plant_collections FOR SELECT
USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own collections"
ON plant_collections FOR INSERT
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own collections"
ON plant_collections FOR UPDATE
USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own collections"
ON plant_collections FOR DELETE
USING (auth.uid() = user_id);

-- Enable RLS on care_history (user-specific via collection)
ALTER TABLE care_history ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own care history"
ON care_history FOR SELECT
USING (
    EXISTS (
        SELECT 1 FROM plant_collections
        WHERE plant_collections.id = care_history.collection_id
        AND plant_collections.user_id = auth.uid()
    )
);

CREATE POLICY "Users can insert own care history"
ON care_history FOR INSERT
WITH CHECK (
    EXISTS (
        SELECT 1 FROM plant_collections
        WHERE plant_collections.id = care_history.collection_id
        AND plant_collections.user_id = auth.uid()
    )
);

CREATE POLICY "Users can update own care history"
ON care_history FOR UPDATE
USING (
    EXISTS (
        SELECT 1 FROM plant_collections
        WHERE plant_collections.id = care_history.collection_id
        AND plant_collections.user_id = auth.uid()
    )
);

CREATE POLICY "Users can delete own care history"
ON care_history FOR DELETE
USING (
    EXISTS (
        SELECT 1 FROM plant_collections
        WHERE plant_collections.id = care_history.collection_id
        AND plant_collections.user_id = auth.uid()
    )
);
```

## Helper Information

### Duration Minutes Conversion

Untuk konsistensi data `estimated_duration_minutes`:

```sql
-- Common conversions
-- 1 hour = 60 minutes
-- 1 day = 1440 minutes
-- 1 week = 10080 minutes
-- 2 weeks = 20160 minutes
-- 1 month (30 days) = 43200 minutes
-- 45 days = 64800 minutes

-- Example: Convert minutes to human-readable
SELECT
    estimated_duration_minutes,
    CASE
        WHEN estimated_duration_minutes < 60 THEN
            estimated_duration_minutes || ' menit'
        WHEN estimated_duration_minutes < 1440 THEN
            ROUND(estimated_duration_minutes / 60.0, 1) || ' jam'
        WHEN estimated_duration_minutes < 10080 THEN
            ROUND(estimated_duration_minutes / 1440.0, 1) || ' hari'
        ELSE
            ROUND(estimated_duration_minutes / 10080.0, 1) || ' minggu'
    END as duration_display
FROM treatment_guides
WHERE estimated_duration_minutes IS NOT NULL;
```

### ✅ Update Environment Variables

Pastikan file `.env` di backend dan Flutter sudah memiliki:

```bash
# Backend .env
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_KEY=your-anon-key
SUPABASE_SERVICE_KEY=your-service-role-key

# Flutter .env
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
```

## Next Steps

Setelah migrasi selesai:

1. ✅ Update backend API endpoints untuk menggunakan tabel baru
2. ✅ Test endpoint `/api/guides` dengan Postman/curl
3. ✅ Update Flutter models untuk match dengan schema
4. ✅ Test local database sync (sqflite)
5. ✅ Implement Collection features di client

## References

-   Supabase SQL Editor: https://supabase.com/docs/guides/database/overview
-   RLS Policies: https://supabase.com/docs/guides/auth/row-level-security
-   Migration Best Practices: https://supabase.com/docs/guides/database/migrations

---

**Last Updated:** Sprint 3 - Day 1
**Status:** Ready for execution
