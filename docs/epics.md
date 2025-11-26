# Epics — PlantCare.ID

**Versi:** 1.0
**Tanggal:** 10 November 2025
**Penulis:** AI Assistant (berdasarkan docs)

---

## Daftar Isi

-   [Pendahuluan](#pendahuluan)
-   [Epic 1: Plant Identification](#epic-1-plant-identification)
-   [Epic 2: Health Assessment](#epic-2-health-assessment)
-   [Epic 3: Treatment Guidance](#epic-3-treatment-guidance)
-   [Epic 4: Personal Plant Collection](#epic-4-personal-plant-collection)
-   [Epic 5: Authentication & Access](#epic-5-authentication--access)
-   [Epic 6: Offline-First Architecture](#epic-6-offline-first-architecture)
-   [Epic 7: Backend Orchestration & AI Integration](#epic-7-backend-orchestration--ai-integration)
-   [Referensi Dokumen Terkait](#referensi-dokumen-terkait)

---

## Pendahuluan

Epics ini dirancang berdasarkan [Product Requirements Document (PRD)](prd.md), [Product Brief](product-brief.md), [Arsitektur Sistem](architect.md), dan [Spesifikasi Front-End](ux-spec.md). Epics mengelompokkan fitur besar menjadi area pengembangan utama, dengan user stories dan acceptance criteria. Setiap epic mencakup aspek fungsional, teknis, dan UI/UX.

Epics ini mendukung pengembangan MVP berbasis Agile (Scrum/Kanban), dengan fokus pada offline-first, AI integration, dan user experience yang intuitif.

---

## Epic 1: Plant Identification

**Deskripsi:** Pengguna dapat mengidentifikasi tanaman dari gambar dengan hasil yang jelas dan akurat.
**FR Terkait:** FR1
**Prioritas:** High
**Acceptance Criteria:** Confidence score >70%, fallback API, image validation.

**User Stories:**

1. Sebagai **pengguna**, saya ingin **mengambil foto tanaman** melalui kamera aplikasi agar saya bisa mengidentifikasi jenis tanaman.
2. Sebagai **pengguna**, saya ingin **memilih foto dari galeri** agar saya bisa menggunakan foto yang sudah ada.
3. Sebagai **pengguna**, saya ingin **melihat hasil identifikasi dengan confidence score** agar saya tahu tingkat akurasi hasilnya.
4. Sebagai **pengguna**, saya ingin **melihat nama lokal & latin tanaman** agar saya mengenali tanaman tersebut dengan benar.

**Technical Notes:** Integrasi Plant.id API, caching, client-side compression.
**UI/UX Notes:** Camera overlay, real-time tips, result card.

---

## Epic 2: Health Assessment

**Deskripsi:** Pengguna dapat melakukan health assessment tanaman berdasarkan foto untuk mendeteksi masalah kesehatan.
**FR Terkait:** FR2
**Prioritas:** High
**Acceptance Criteria:** Health status akurat (is_healthy boolean + probability), disease suggestions dengan treatment details, severity levels, fallback API.

**User Stories:**

1. Sebagai **pengguna**, saya ingin **mengambil foto tanaman** agar sistem bisa menganalisis kondisi kesehatannya.
2. Sebagai **pengguna**, saya ingin **melihat status kesehatan tanaman (sehat/tidak sehat)** dengan tingkat kepercayaan.
3. Sebagai **pengguna**, saya ingin **melihat daftar penyakit yang terdeteksi** jika tanaman tidak sehat, beserta deskripsi dalam bahasa sederhana.
4. Sebagai **pengguna**, saya ingin **melihat penyebab umum & tingkat keparahan penyakit** agar saya tahu tindakan yang tepat.

**Technical Notes:** Plant.id API v3 dengan parameter health (only/auto/all), biaya kredit 1-2 tergantung mode, response includes is_healthy + disease->suggestions.
**UI/UX Notes:** Similar to identification, with health status badge (sehat/tidak sehat), disease list if unhealthy.

---

## Epic 3: Treatment Guidance

**Deskripsi:** Pengguna mendapat panduan tindakan perawatan langsung setelah diagnosis.
**FR Terkait:** FR3
**Prioritas:** Core
**Acceptance Criteria:** ≤5 steps, visual guides, materials checklist.

**User Stories:**

1. Sebagai **pengguna**, saya ingin **melihat langkah-langkah perawatan visual** agar mudah diikuti.
2. Sebagai **pengguna**, saya ingin **mengetahui bahan yang dibutuhkan untuk tiap langkah** agar bisa menyiapkan alat & bahan.
3. Sebagai **pengguna**, saya ingin **melihat progress bar langkah-langkah** agar tahu sejauh mana proses perawatan.
4. Sebagai **pengguna**, saya ingin **menandai langkah sebagai selesai** agar saya merasa ada progres nyata.

**Technical Notes:** Guide service, structured JSON guides.
**UI/UX Notes:** Step cards, progress indicator, mark complete.

---

## Epic 4: Personal Plant Collection

**Deskripsi:** Pengguna dapat menyimpan dan mengelola koleksi tanaman serta menerima pengingat.
**FR Terkait:** FR4, FR6, FR7
**Prioritas:** Medium
**Acceptance Criteria:** Local storage, sync, notifications.

**User Stories:**

1. Sebagai **pengguna terdaftar**, saya ingin **menyimpan hasil identifikasi ke koleksi pribadi** agar saya bisa melacak riwayatnya.
2. Sebagai **pengguna**, saya ingin **melihat daftar tanaman saya dalam grid dengan foto dan status** agar mudah dikelola.
3. Sebagai **pengguna**, saya ingin **mendapatkan notifikasi pengingat perawatan** agar tidak lupa merawat tanaman.
4. Sebagai **pengguna**, saya ingin **mengakses panduan meski sedang offline** agar tetap bisa merawat tanaman tanpa internet.

**Technical Notes:** Hive/SQLite, background jobs, FCM notifications.
**UI/UX Notes:** Grid cards, filter, empty states.

---

## Epic 5: Authentication & Access

**Deskripsi:** Pengguna dapat mengakses aplikasi dengan cepat tanpa hambatan login kompleks.
**FR Terkait:** FR5
**Prioritas:** High
**Acceptance Criteria:** Guest mode, JWT auth, secure storage.

**User Stories:**

1. Sebagai **pengguna baru**, saya ingin **mendaftar hanya dengan email dan password sederhana** agar prosesnya cepat.
2. Sebagai **pengguna**, saya ingin **masuk sebagai tamu (guest)** agar bisa mencoba tanpa mendaftar.
3. Sebagai **pengguna terdaftar**, saya ingin **logout dengan aman** agar data saya terlindungi.

**Technical Notes:** Supabase Auth, JWT verification.
**UI/UX Notes:** Welcome screen, auth cards.

---

## Epic 6: Offline-First Architecture

**Deskripsi:** Aplikasi berfungsi penuh tanpa koneksi, dengan sync otomatis.
**FR Terkait:** FR7, NFRs
**Prioritas:** Medium
**Acceptance Criteria:** Cache guides, background sync, offline UI.

**User Stories:**

1. Sebagai **pengguna**, saya ingin **akses panduan offline** setelah download.
2. Sebagai **pengguna**, saya ingin **data tersimpan lokal** dan sync saat online.
3. Sebagai **pengguna**, saya ingin **notifikasi offline mode** jika tidak ada koneksi.

**Technical Notes:** Drift/Hive, sync protocol, conflict resolution.
**UI/UX Notes:** Offline states, progress indicators.

---

## Epic 7: Backend Orchestration & AI Integration

**Deskripsi:** Backend mengorkestrasi AI APIs, menyediakan endpoints, dan mengelola data.
**FR Terkait:** Semua, dari architect.md
**Prioritas:** High
**Acceptance Criteria:** FastAPI, Supabase, Redis, reliable APIs.

**User Stories:**

1. Sebagai **developer**, saya ingin **orchestrator** yang memanggil Plant.id dan fallback.
2. Sebagai **developer**, saya ingin **cached results** untuk mengurangi biaya API.
3. Sebagai **developer**, saya ingin **secure auth** dengan JWT.

**Technical Notes:** FastAPI, Celery, S3 storage.
**UI/UX Notes:** Loading states, error handling.

---

## Referensi Dokumen Terkait

-   [Product Requirements Document (PRD)](prd.md)
-   [Product Brief](product-brief.md)
-   [Arsitektur Sistem](architect.md)
-   [Spesifikasi Front-End](ux-spec.md)
-   [Sprint Planning](sprint-planning.md) - Rencana sprint untuk development.</content>
    <parameter name="filePath">/home/nyotnyot/Project/Kuliah/Semester_5/IMK/plantcare_id/docs/epics.md
