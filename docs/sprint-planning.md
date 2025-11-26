# Sprint Planning — PlantCare.ID

**Versi:** 1.0
**Tanggal:** 10 November 2025
**Penulis:** AI Assistant (berdasarkan docs)

---

## Daftar Isi

-   [Pendahuluan](#pendahuluan)
-   [Sprint 1: Setup, Auth & Basic UI (1 minggu)](#sprint-1-setup-auth--basic-ui-1-minggu)
-   [Sprint 2: Plant Identification (1 minggu)](#sprint-2-plant-identification-1-minggu)
-   [Sprint 3: Treatment Guidance & Collection (1 minggu)](#sprint-3-treatment-guidance--collection-1-minggu)
-   [Sprint 4: Offline Mode & Polish (1 minggu)](#sprint-4-offline-mode--polish-1-minggu)
-   [Assignment Developer](#assignment-developer)
-   [Paralel vs Kronologis](#paralel-vs-kronologis)
-   [Estimasi Total & Risiko](#estimasi-total--risiko)
-   [Referensi Dokumen Terkait](#referensi-dokumen-terkait)

---

## Pendahuluan

Sprint planning ini dirancang berdasarkan [Timeline di Product Brief](product-brief.md), [Epics](epics.md), dan [PRD](prd.md). Total durasi MVP: 4 minggu (4 sprint MVP).

**Asumsi:**

-   Tim: 2 developer (Developer A dan Developer B), 1 designer, 1 QA.
-   Estimasi dalam story points (SP): 1 SP = 1 hari kerja.
-   Velocity: 20-30 SP per sprint per developer.
-   Prioritas: High/Core epics dulu.

**Goal Overall:** MVP siap untuk usability testing.

---

## Sprint 1: Setup, Auth & Basic UI (1 minggu)

**Goal:** Siapkan infrastruktur dasar dan implementasi auth serta UI dasar.

**Tasks:**

-   Setup Flutter project dengan Riverpod state management.
-   Integrasi Supabase untuk auth dan DB.
-   Setup FastAPI backend dengan basic endpoints.
-   Design system tokens (warna, typography) di Flutter.
-   Basic UI: Splash screen, bottom nav skeleton.
-   Implementasi login/register/guest mode (Supabase Auth).
-   Welcome screen, home dashboard dengan tiles.
-   Profile screen skeleton.
-   Error handling untuk auth.
-   Unit tests untuk auth logic.
-   CI/CD setup (GitHub Actions untuk build APK).

**Epics Covered:** Epic 5, partial Epic 7.

**Estimasi:** 25 SP.

**Acceptance Criteria:** App bisa dijalankan, user bisa login/guest, navigate screens.

---

## Sprint 2: Plant Identification (1 minggu)

**Goal:** Core feature identifikasi tanaman.

**Tasks:**

-   Camera integration (camera plugin), overlay tips.
-   Image compression & validation client-side.
-   API call ke Plant.id, fallback PlantNet.
-   Result screen dengan confidence, save to collection.
-   Offline cache untuk results.
-   UI: Camera viewfinder, result card.

**Epics Covered:** Epic 1, partial Epic 6.

**Estimasi:** 25 SP.

**Acceptance Criteria:** Identify plant dengan confidence >70%, handle errors.

---

## Sprint 3: Treatment Guidance & Collection (1 minggu)

**Goal:** Panduan perawatan dan koleksi pribadi.

**Tasks:**

-   Guide service backend, fetch guide by ID.
-   Step-by-step UI: progress bar, mark complete.
-   Collection grid, save/edit/delete plants.
-   Notifications setup (FCM, local).
-   Sync collection ke backend.
-   UI: Step cards, collection grid.

**Epics Covered:** Epic 3, Epic 4.

**Estimasi:** 25 SP.

**Acceptance Criteria:** Full guide flow, collection management.

---

## Sprint 4: Offline Mode & Polish (1 minggu)

**Goal:** Offline support dan final polish.

**Tasks:**

-   Offline-first: Cache guides, sync protocol.
-   Health assessment (similar to identification, with health parameter).
-   Error states, empty states.
-   Performance optimization, accessibility checks.
-   QA: Automated tests, usability testing.
-   Final UI polish, animations.

**Epics Covered:** Epic 2, Epic 6, Epic 7.

**Estimasi:** 25 SP.

**Acceptance Criteria:** Offline works, SUS >75, no critical bugs.

---

## Assignment Developer

Dengan 2 developer (Developer A dan Developer B), assignment sebagai berikut:

-   **Developer A:** Sprint 1 (Setup, Auth & Basic UI) dan Sprint 3 (Treatment Guidance & Collection).
-   **Developer B:** Sprint 2 (Plant Identification) dan Sprint 4 (Offline Mode & Polish).

Setiap developer mengerjakan satu sprint penuh per minggu, dengan fokus pada tasks yang ditugaskan.

---

## Paralel vs Kronologis

-   **Kronologis (Berurutan):** Semua sprint dikerjakan secara berurutan karena ada dependensi. Sprint 1 harus selesai sebelum Sprint 2, dan seterusnya, karena infrastruktur dasar diperlukan untuk fitur berikutnya.
-   **Paralel:** Tidak ada sprint yang bisa dikerjakan paralel dalam 4 minggu ini, karena tim kecil (2 developer) dan dependensi antar sprint. Developer A dan B bekerja pada sprint berbeda per minggu, tapi sprint tetap kronologis.

Jika ada overlap kecil, Sprint 2 dan 3 bisa mulai paralel jika Sprint 1 selesai lebih awal, tapi secara umum kronologis.

---

## Estimasi Total & Risiko

**Total Estimasi:** 100 SP (4 minggu).

**Risiko:**

-   API downtime: Mitigasi dengan fallback dan caching.
-   Device fragmentation: Test on multiple devices.
-   Learning curve: Allocate time for new tech (Supabase, FastAPI).

**Mitigasi:** Buffer 20% untuk unexpected issues.

---

## Referensi Dokumen Terkait

-   [Epics](epics.md)
-   [PRD](prd.md)
-   [Product Brief](product-brief.md)
-   [Arsitektur Sistem](architect.md)
-   [Spesifikasi Front-End](ux-spec.md)</content>
    <parameter name="filePath">/home/nyotnyot/Project/Kuliah/Semester_5/IMK/plantcare_id/docs/sprint-planning.md
