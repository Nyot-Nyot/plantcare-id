# Spesifikasi Front-End — PlantCare.ID

**Versi:** 1.0
**Tanggal:** 6 November 2025

---

## Daftar Isi

-   [Ringkasan](#ringkasan)
-   [Daftar Halaman Utama](#daftar-halaman-utama)
-   [Desain Prinsip & Aturan Umum](#desain-prinsip--aturan-umum)
-   [Desain Sistem — Design Tokens](#desain-sistem--design-tokens)
-   [Komponen UI (Katalog)](#komponen-ui-katalog)
-   [Halaman Detail (Page Specs)](#halaman-detail-page-specs)
-   [Flow & State Diagrams (verbal)](#flow--state-diagrams-verbal)
-   [Interaksi & Mikrointeraksi](#interaksi--mikrointeraksi)
-   [Accessibility](#accessibility)
-   [Performance & Offline Strategy](#performance--offline-strategy)
-   [API Contract (UI → Backend / External)](#api-contract-ui--backend--external)
-   [Error Handling & Edge Cases](#error-handling--edge-cases)
-   [Testing & QA Checklist (Front-End)](#testing--qa-checklist-front-end)
-   [Design Handoff Assets & Figma Prompts](#design-handoff-assets--figma-prompts)
-   [Developer Notes (Flutter Specific)](#developer-notes-flutter-specific)

---

## Ringkasan

Dokumen ini adalah spesifikasi front-end untuk aplikasi mobile **PlantCare.ID** (Flutter). Tujuannya: memberikan panduan lengkap kepada desainer UI dan developer front-end (Flutter) agar implementasi antarmuka konsisten, dapat diakses, mudah diuji, dan siap untuk pengembangan MVP.

Ruangan cakupan: struktur halaman, komponen UI, states & flows, aksesibilitas, desain responsif (berfokus pada mobile), animasi & mikrointeraksi, guideline visual (warna, tipografi), serta kontrak UI → API (endpoints yang relevan), dan checklist QA untuk front-end.

---

## Daftar Halaman Utama

1. Splash Screen

2. Welcome / Auth (Login / Register / Guest)

3. Home / Dashboard

4. Kamera Identifikasi

5. Hasil Identifikasi (Plant Detail)

6. Panduan Perawatan (Step-by-Step) — Treatment View

7. Koleksi Tanaman (Grid & Detail)

8. Profile & Pengaturan

9. Error / Offline / Empty States

Untuk setiap halaman dijabarkan komponen, tata letak, interaksi utama, dan state penting.

---

## Desain Prinsip & Aturan Umum

-   **Visual-first**: foto dan ilustrasi menjadi anchor visual utama.

-   **Minimal cognitive load**: maksimal 7±2 elemen penting per layar.

-   **Thumb-friendly**: CTA penting ditempatkan dalam jangkauan ibu jari (bottom/center).

-   **Progressive disclosure**: detail tersembunyi kecuali diminta.

-   **Accessible by default**: kontras minimum 4.5:1, target touch 44x44pt, label untuk screen reader.

-   **Consistency**: spacing grid 8pt, border radius 12pt default untuk cards,

-   **Platform**: Flutter (single codebase), gunakan widget yang mudah diuji dan accessible.

---

## Desain Sistem — Design Tokens

Gunakan design tokens untuk memudahkan implementasi theming dan konsistensi.

### Warna (tokens)

-   `primary` : #27AE60

-   `primary-strong` : #1E8449

-   `secondary` : #58D68D

-   `accent` : #F2C94C

-   `danger` : #E74C3C

-   `bg` : #FFFFFF

-   `surface` : #F6F8F9

-   `muted` : #9AA4A6

-   `text-primary` : #17202A

-   `text-secondary` : #5D6D7E

### Typografi

-   `h1` : 24sp, SemiBold

-   `h2` : 20sp, SemiBold

-   `h3` : 16sp, Medium

-   `body` : 14sp, Regular

-   `caption` : 12sp, Regular

### Spacing & Layout

-   Grid: 8pt base

-   Padding utama: 16pt horizontal pada screen level

-   Card radius: 12pt

-   Touch target minimum: 44x44pt

### Iconography

-   Gunakan style outline untuk actions, filled untuk primary CTA

-   Ukuran icon default 24sp

### Elevation & Shadow

-   Card: elevation ringan (z=2) — shadow subtle

-   Modal / bottom sheet: z=10

---

## Komponen UI (Katalog)

Setiap komponen diberikan nama, props utama, states, dan aksesibilitas.

### 1. AppBar (Top Bar)

**Props:** title, subtitle (optional), leading, actions (list)
**States:** default, elevated (scrolled)
**A11y:** title semantic role `header`.
**Use:** Home, Plant Detail, Guide.

### 2. BottomNavigationBar

**Items:** Home, Identify, Collection, Guide, Profile
**Behavior:** persistent, highlight active item
**Accessibility:** each item has `label` untuk screen reader

### 3. Large CTA Button (Primary)

**Props:** label, icon (optional), disabled
**Position:** biasanya bottom center or sticky
**Style:** background `primary`, white text, 16sp
**A11y:** accessible name = label, role = button

### 4. Camera Viewfinder Component

**Props:** mode (identify/disease), overlayGuides (boolean), tipsText
**States:** ready, capturing, processing, error
**Notes:** semi-transparent UI overlay, ensure camera preview area ≥80% height

### 5. Image Quality Validator / Tips Overlay

**Function:** memberikan feedback real-time (lighting, focus, framing)
**Visual:** small chip/icon near preview with short message
**A11y:** aria-live region untuk updates

### 6. Result Card (Identification Result)

**Props:** image, commonName, scientificName, confidenceScore, healthStatus
**Actions:** View Guide, Save to Collection, Retake
**States:** normal, low-confidence (confidence < 70%) — show warning

### 7. Step Card (Guide Step)

**Props:** stepNumber, title, description, image, materials (list), isCritical (boolean)
**Actions:** Next, Previous, MarkComplete
**States:** active, completed, disabled
**UX:** progress bar at top of screen shows currentStep/total

### 8. Plant Grid Card (Collection)

**Props:** image, name, lastCareDate, statusBadge
**Interaction:** tap -> open Plant Detail, long-press -> quick actions (edit, delete)

### 9. Empty State / Offline State Component

**Visual:** illustration + short message + CTA (retry or go offline mode)
**Behavior:** clear actions for next step

### 10. Toast & Modal Patterns

-   Toast: transient, non-blocking, bottom area

-   Modal: confirm delete, require explicit action (Cancel / Confirm)

-   Use accessible focus trap for modal

---

## Halaman Detail (Page Specs)

Setiap halaman diberikan wireframe verbal, komponen yang digunakan, dan semua state.

### 1. Splash Screen

-   Duration: ~2s or until initialization complete

-   Elements: centered logo (svg), app name, subtle grow animation

-   Behavior: prefetch small resources, check auth state

### 2. Welcome / Auth

-   Sections: Illustration (top 40%), auth card (email/password), Guest link

-   Actions: Login, Register, Guest Mode

-   Error states: invalid credentials, network error

### 3. Home / Dashboard

-   Header: welcome message + quick access identify button

-   Main: two large action tiles: Identify Plant, Detect Disease

-   Secondary: Recent Collections horizontal scroll (3 items)

-   BottomNav: persistent

-   States: empty collections -> show CTA to identify

### 4. Camera Identifikasi

-   Fullscreen camera preview (80%) + overlay guide

-   Bottom controls: capture button, gallery shortcut, flip camera

-   Real-time tips overlay

-   After capture: immediate validation; if invalid -> show small message and retry

-   While processing: show radial progress + animated plant grow

### 5. Hasil Identifikasi (Plant Detail)

-   Top: image (40%), title block (name + confidence + status badge)

-   Actions: View Care Guide (primary), Save to Collection (secondary), Retake

-   Below: Expandable cards: Quick Facts, Environmental Needs, Similar Species

-   Low confidence: show explanation and option to report or retake

### 6. Panduan Perawatan (Guide View)

-   Top: progress indicator (Step x of y)

-   Middle: Step Card (icon, title, image, description)

-   Bottom: materials checklist (expandable) + Prev/Next sticky buttons

-   Mark as complete toggles steps, final screen shows summary & next reminders

### 7. Koleksi Tanaman

-   Grid 3-column with spacing 8pt

-   Filter: All, Healthy, Need Care, Critical

-   Each card: tap opens Plant Detail, long-press shows quick actions

-   Empty state shows illustration and large CTA

### 8. Profile & Settings

-   Sections: Account, Notifications, Preferences, Help

-   Toggle: reminder on/off, language selection, data sync

---

## Flow & State Diagrams (verbal)

_Berikan contoh flow kritis: Capture → Validate → Upload → Result → View Guide → Complete Step → Save_

State transitions penting:

-   Camera: ready → capturing → validating → processing → (result | error)

-   Guide: notStarted → inProgress → completed → archived

-   Collection item: saved → updated → archived

---

## Interaksi & Mikrointeraksi

-   Capture tap: haptic feedback + quick flash overlay

-   Progress: smooth linear progress bar with easing (200–300ms)

-   Step completion: check animation + confetti micro-animation for final step (low-intensity)

-   Error: shake animation for invalid input + inline message

---

## Accessibility

-   All interactive elements memiliki label untuk screen reader

-   Headings semantik & order logical

-   Contrast ratios ≥ 4.5:1 untuk teks utama

-   Support for dynamic font size (scalable typography)

-   Touch targets ≥ 44x44pt

-   Live regions for camera tips and process updates

---

## Performance & Offline Strategy

-   Image compression client-side: balance quality vs size (suggested: 80% quality, max 2MB)

-   Local cache for recent identifications & guides (SQLite / Hive)

-   Background sync when online

-   Lazy loading for images in collection

---

## API Contract (UI → Backend / External)

> Catatan: API spesifikasi ini bersifat minimal; endpoint detail teknis disesuaikan dengan tim backend.

### 1. POST /identify

**Request**: multipart/form-data { image }
**Response (200)**:

```
{
  "status": "ok",
  "plant": {
    "catalog_id": "plant_123",
    "common_name": "Puring",
    "scientific_name": "Euphorbia pulcherrima",
    "confidence": 0.92,
    "health_status": "healthy",
    "suggested_guide_id": "guide_45"
  },
  "notes": {
    "confidence_label": "High",
    "explanation": "Matched leaves pattern with 92% similarity"
  }
}
```

**Errors:** 400 (bad image), 503 (service unavailable)

### 2. POST /detect-disease

**Request**: multipart/form-data { image, focus_area }
**Response:** diagnosis object with `disease_id`, `name`, `severity`, `suggested_treatment_ids`

### 3. GET /guide/{guide_id}

**Response:** guide object

```
{
 "id":"guide_45",
 "title":"Mengatasi daun menguning pada puring",
 "language":"id",
 "steps":[
   {"n":1,"title":"Periksa penyiraman","description":"...","materials":["air","gembor"],"image_url":"..."},
   ...
 ]
}
```

### 4. POST /collection

**Request**: { user_id, plant_id, image_url, notes }
**Response:** saved object with timestamp

### 5. POST /feedback/report

**Request**: { user_id, plant_id, issue_type, comment }
**Response:** ack

---

## Error Handling & Edge Cases

-   **Low confidence**: tampilkan badge "Low Confidence" + CTA "Retake / Report".

-   **No connection**: fallback ke cached guides; disable identify/detect dengan message

-   **Large image**: client-side compress & warn if >2MB

-   **API rate limit**: show friendly message and suggest retry later

---

## Testing & QA Checklist (Front-End)

1.  All screens render correctly on Android (API 29+) and iOS (iOS14+)

2.  Accessibility check: labels, contrast, focus order

3.  Camera interaction: capture, gallery pick, device rotation

4.  Image upload & compression behaviour

5.  Guide navigation: next/prev, mark complete

6.  Offline: view cached guide, collection read/write

7.  Error states & toasts

8.  Performance: identify response ≤8s on 3G emulation

9.  Automated widget tests for core components (Button, StepCard, ResultCard)

---

## Design Handoff Assets & Figma Prompts

Sertakan artboards berikut di Figma: Splash, Welcome, Home, Camera, Result, Guide Step, Collection Grid, Profile. Gunakan prompt yang sudah disiapkan di BAB 3 — contoh prompt Figma ada pada file proposal.

**Example Figma prompt untuk Guide Step:**

```
Design a step-by-step guide card for mobile: numbered step (1), icon, title, short description, demonstration image, materials checklist (collapsible), Next/Previous buttons fixed at bottom. Ensure high-contrast text and large touch targets.
```

---

## Developer Notes (Flutter Specific)

-   Use `Provider` or `Riverpod` untuk state management (recommendation: Riverpod for testability)

-   Camera: pakai `camera` plugin; fallback ke `image_picker` untuk gallery

-   Local storage: Hive / SQLite untuk offline cache

-   Network: retrofit-like client (Dio) dengan interceptors untuk retry & offline handling

-   Image processing: `image` package untuk compression & resizing

-   Accessibility: use semantics widgets & media queries for font scaling

---

## Referensi Dokumen Terkait

-   [Product Requirements Document (PRD)](prd.md) - Persyaratan produk dan fitur.
-   [Product Brief](product-brief.md) - Ringkasan produk dan visi.
-   [Arsitektur Sistem](architect.md) - Detail arsitektur teknis dan kontrak API lengkap.
-   [Epics](epics.md) - Rancangan epics berdasarkan docs.
-   [Sprint Planning](sprint-planning.md) - Rencana sprint untuk development.
