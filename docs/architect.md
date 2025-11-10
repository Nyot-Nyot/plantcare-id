# Arsitektur Sistem — PlantCare.ID

**Versi:** 1.0
**Tanggal:** 6 November 2025

---

> Dokumen arsitektur ini dibuat berdasarkan PRD PlantCare.ID (v2.0) dan Spesifikasi Front-End (UX v1.0). Tujuannya: menyajikan arsitektur tingkat sistem (logical + physical), keputusan teknologi, kontrak API terperinci, skenario deployment, serta pertimbangan non-fungsional (security, performance, availability) untuk mendukung implementasi MVP berbasis Flutter (Android/iOS) dengan pendekatan open-source.

---

## Daftar Isi

-   [Keputusan Utama (Decision Summary)](#keputusan-utama-decision-summary)
-   [Auth Integration (Supabase Auth)](#auth-integration-supabase-auth)
-   [Ringkasan Arsitektur (High-level)](#ringkasan-arsitektur-high-level)
-   [Keputusan Teknologi (Technology Choices)](#keputusan-teknologi-technology-choices)
-   [Arsitektur Logical — Layanan & Tanggung Jawab](#arsitektur-logical--layanan--tanggung-jawab)
-   [Data Model (High-level)](#data-model-high-level)
-   [API Contracts (Extended)](#api-contracts-extended)
-   [Offline-First Strategy & Sync Protocol](#offline-first-strategy--sync-protocol)
-   [Security & Privacy Considerations](#security--privacy-considerations)
-   [Scalability & Cost Control](#scalability--cost-control)
-   [Observability & SLOs](#observability--slos)
-   [CI/CD & Deployment Plan](#cicd--deployment-plan)
-   [Integration & Contribution Guidelines (Open Source)](#integration--contribution-guidelines-open-source)
-   [Risks teknis & Mitigasi (engineering)](#risks-teknis--mitigasi-engineering)

---

## Keputusan Utama (Decision Summary)

| Kategori          | Keputusan                          |                                                                                                                                       Versi (verifikasi) | Rationale                                                     |
| ----------------- | ---------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------: | ------------------------------------------------------------- |
| Mobile framework  | Flutter                            |                                                                                                  3.35.7 (verified 2025-11-06 via Flutter releases index) | Cross-platform mobile client, single codebase for Android/iOS |
| Backend framework | FastAPI (preferred)                |                                                                                0.121.0 (verified 2025-11-06 via PyPI: https://pypi.org/project/fastapi/) | Fast development for orchestration + ML integrations          |
| Database          | Supabase (hosted PostgreSQL)       |      supabase/postgres tag 17.6.1.038-storage-1 (verified 2025-11-05 via GitHub: https://github.com/supabase/postgres/releases/tag/17.6.1.038-storage-1) | Managed Postgres with built-in auth/storage; simplifies infra |
| Object storage    | S3-compatible (AWS S3 / DO Spaces) |                                                                                                                   provider-managed (verify per provider) | Widely supported, simple integration                          |
| Cache / Jobs      | Redis (cache) + Celery/RQ (jobs)   | Redis 8.2.3 (verified 2025-11-06 via https://download.redis.io/releases/), Celery 5.5.3 (verified 2025-11-06 via PyPI: https://pypi.org/project/celery/) | Proven components for caching and background processing       |

> NOTE: Versions above are assumed placeholders to make decisions explicit. Please verify live (WebSearch) and replace with exact version numbers and verification dates.

### Version verification

Please update the "Versi (verifikasi)" column with exact release numbers and the date you verified them. Recommended quick checks:

1. Flutter: check `flutter --version` and the Flutter stable release notes.
2. FastAPI: check PyPI or FastAPI release notes for latest stable.
3. Supabase / Postgres: confirm the Postgres minor version used by your Supabase project (e.g., Postgres 15.x).
4. Redis / Celery: confirm latest compatible releases for your chosen stack.

Record verification like: "FastAPI 0.121.0 (verified 2025-11-06 via PyPI: https://pypi.org/project/fastapi/)".

---

## Auth Integration (Supabase Auth)

We will use Supabase Auth (GoTrue-based) as the primary authentication provider. Rationale: built-in integration with Supabase projects, client SDKs for Flutter and server-side verification endpoints, and token lifecycle management out-of-the-box.

Key points:

-   Scheme: JWT issued by Supabase Auth (access token) with refresh token support. Tokens include standard claims (exp, iat, sub) and Supabase-specific claims (role, provider).
-   Client flow (mobile):

    1. User signs up / signs in via Supabase Flutter client (supabase-dart / supabase-flutter). The client obtains an access token (JWT) and a refresh token.
    2. Client stores the refresh token securely (secure storage) and keeps the access token in memory/local secure storage for API calls.
    3. When access token expires, client uses the refresh token via Supabase client to exchange for a new access token (handled by Supabase SDK). Refresh tokens are long-lived and should be rotated per best-practices.

-   Backend (FastAPI) verification:

    -   For each incoming request with Authorization: Bearer <access_token>, validate the JWT by:
        1. Fetching the project's JWKs (JSON Web Key Set) from the Supabase project's Auth JWKS endpoint (pattern: https://<project>.supabase.co/auth/v1/.well-known/jwks.json) or the managed Supabase docs for JWK location.
        2. Verify token signature, `exp`, `aud`/`iss` claims, and required custom claims (e.g., `role`). Reject tokens that fail validation.
    -   Optionally, use the Supabase service role key (server secret) for server-to-server operations that require elevated privileges — keep this secret out of client code and rotate regularly.

-   Integration tips for FastAPI:

    -   Use a lightweight JWT verification middleware (e.g., using python-jose or PyJWT + jwcrypto) to validate tokens and attach `current_user` to request scope.
    -   For common operations, consider using the `supabase-py` client for server-side calls that require the service key.

-   Security considerations:
    -   Do not store service role keys on client devices.
    -   Enforce HTTPS for all token exchange endpoints.
    -   Set short lifetimes for access tokens (e.g., 15m) and use refresh tokens for session continuity.
    -   Log authentication failures and monitor unusual refresh activity.

References:

-   Supabase Auth docs (general): https://supabase.com/docs/guides/auth
-   Supabase project JWKS pattern: https://<project>.supabase.co/auth/v1/.well-known/jwks.json

This subsection closes the previous gap around authentication scheme and server verification guidance; include any project-specific JWKS URL after project bootstrap.

## Ringkasan Arsitektur (High-level)

PlantCare.ID dirancang sebagai aplikasi mobile cross-platform (Flutter) dengan backend berbasis cloud yang menyediakan layanan identifikasi dan manajemen konten panduan. Arsitektur mengikuti prinsip _offline-first_, dengan caching lokal untuk koleksi dan panduan, serta fallback multi-API untuk identifikasi tanaman.

**Komponen utama:**

1. Mobile Client (Flutter)

2. Backend API (REST) + Orchestration Layer

3. AI Identification Services (3rd-party: Plant.id primary, PlantNet fallback)

4. Content & Guide Service (CMS ringan / Headless)

5. Data Store: Cloud DB + Object Storage

6. Local Storage (on-device cache) + Sync Engine

7. Notification Service (reminder scheduler)

8. CI/CD & Observability

Diagram ringkas (logical):

Mobile (Flutter)
↕ HTTPS
Backend API (Gateway)
↕
{Auth Service, Identify Orchestrator, Guide Service, Collection Service, Notification Service}
↕
Cloud DB (Postgres) + Object Storage (S3) + 3rd-party AI APIs

---

## Keputusan Teknologi (Technology Choices)

**Mobile**

-   Flutter (Dart) — single codebase Android/iOS. Rekomendasi state management: Riverpod.

-   Plugins: `camera`, `image_picker`, `cached_network_image`, `hive`/`drift` (SQLite) untuk local cache.

**Backend**

-   Bahasa: Node.js (TypeScript) atau Python (FastAPI) — preferensi: **FastAPI (Python)** untuk cepat mengembangkan orchestration microservice dan mudah integrasi ML/HTTP.

-   Web framework: FastAPI + Uvicorn + Gunicorn (Prod)

-   API Gateway: NGINX / Cloud Load Balancer

**Database & Storage**

-   Relational DB: Supabase (hosted PostgreSQL service) — recommended for managed Postgres, auth, and object storage integration. For FastAPI the recommended ORM is SQLModel / SQLAlchemy to ensure compatibility with Postgres features.

-   Object Storage: S3-compatible (AWS S3 / DigitalOcean Spaces)

-   Cache: Redis untuk rate-limiting & temporary caching

-   Local device storage: Hive (key-value) dan Drift (SQLite) untuk struktur yang kompleks

**Integrasi AI**

-   Primary: Plant.id API (image recognition)

-   Fallback: PlantNet API

-   Lokal: Rule-based pre-check (image quality) dan lightweight heuristics client-side

**Messaging & Notifications**

-   Background jobs: Celery (Python) or RQ with Redis

-   Push notifications: Firebase Cloud Messaging (FCM) for Android/iOS

**DevOps & CI/CD**

-   Repo: GitHub (public) — open-source

-   CI: GitHub Actions for tests, lint, build, deploy

-   Container: Docker for backend services

-   Infra: Terraform (optional) for reproducible infra

**Monitoring & Logging**

-   Logs: centralized (ELK stack / Cloud provider logs)

-   Metrics: Prometheus + Grafana or cloud-native metrics

-   Error tracking: Sentry

---

## Arsitektur Logical — Layanan & Tanggung Jawab

### 1. Mobile Client (Flutter)

Tanggung jawab:

-   UI/UX interaction

-   Camera capture + client-side image pre-processing (resize, compress)

-   Local cache management (collections, guides)

-   Offline-first UX: read-from-cache, background sync

-   API client with retry, exponential backoff

-   Local notification scheduler (for reminders)

Komponen internal:

-   Presentation Layer (screens, widgets)

-   State Layer (Riverpod providers)

-   Data Layer (repositories: remote/local)

-   Services: CameraService, ImageValidator, SyncService, NotificationScheduler

### 2. API Gateway / Backend

Tanggung jawab utama:

-   Routing request dari client ke layanan internal

-   Authentication & Authorization

-   Orchestration: call identificaion APIs, aggregate responses, return normalized result

-   Content endpoints: provide guide payloads

-   Manage user collections & reminders

Endpoints kunci (disingkat):

-   POST /api/v1/identify

-   POST /api/v1/detect-disease

-   GET /api/v1/guide/{id}

-   POST /api/v1/collection

-   GET /api/v1/collection?userId=...

-   POST /api/v1/auth/register

-   POST /api/v1/auth/login

-   POST /api/v1/feedback/report

### 3. Identify Orchestrator

-   Memanggil Plant.id API dengan image, normalisasi response

-   Jika primary API gagal atau confidence rendah → panggil PlantNet fallback

-   Business logic rules: jika confidence > 0.8 → automatically include suggested guide; if 0.5–0.8 → mark low-confidence and request user confirm/retake; if <0.5 → suggest retake + manual search

-   Caching of recent identifications to reduce 3rd-party API cost

### 4. Guide Service / CMS

-   Menyimpan panduan perawatan (structured guide documents: steps, materials, images)

-   Expose endpoints untuk fetch guide by id or by plant/disease tag

-   Admin interface (lightweight) untuk menambahkan/edit guide (open-source contributors)

### 5. Collection Service

-   Manages user-saved plants, notes, last care timestamps, local/remote sync state

### 6. Notification Service

-   Schedules reminders for periodic care

-   Triggers push via FCM and in-app local notifications

### 7. Background Jobs

-   Retry failed syncs

-   Periodic cleanup of stale cache

-   Daily job to handle scheduled reminders

---

## Data Model (High-level)

### Table: users

-   id (uuid)

-   email (nullable if guest)

-   password_hash (nullable for guest)

-   display_name

-   created_at

### Table: plants_catalog (optional)

-   id

-   common_name

-   scientific_name

-   tags

-   default_guides (list of guide ids)

### Table: guides

-   id

-   title

-   plant_id / disease_id

-   steps (jsonb) -> [{n, title, description, materials:[], image_url}]

-   language

-   created_by

-   updated_at

### Table: collections

-   id

-   user_id

-   plant_catalog_id (nullable)

-   custom_name

-   image_url

-   notes

-   last_cared_at

-   reminders (json)

-   created_at

### Table: identifications

-   id

-   user_id (nullable)

-   plant_catalog_id

-   confidence

-   raw_response (json)

-   image_url

-   created_at

---

## API Contracts (Extended)

### POST /api/v1/identify

_Request (multipart/form-data):_

-   image (file)

-   user_id (optional)

-   focus_area (optional)

_Response 200:_

```
{
  "status":"ok",
  "plant":{
    "catalog_id":"plant_123",
    "common_name":"Puring",
    "scientific_name":"Euphorbia pulcherrima",
    "confidence":0.92,
    "health_status":"healthy",
    "suggested_guide_id":"guide_45"
  },
  "notes":{
    "confidence_label":"High",
    "explanation":"Matched leaves pattern with 92% similarity"
  }
}
```

_Error handling:_

-   400: invalid image

-   503: external service unavailable

-   429: rate limit (include `retry_after` header)

### GET /api/v1/guide/{id}

_Response:_

```
{
  "id":"guide_45",
  "title":"Mengatasi daun menguning pada puring",
  "language":"id",
  "steps":[{ "n":1, "title":"Periksa penyiraman", "description":"...", "materials":["air","gembor"], "image_url":"..." }]
}
```

---

## Offline-First Strategy & Sync Protocol

**Prinsip:** aplikasi harus tetap berguna tanpa koneksi dan menyinkronkan perubahan ketika online.

### On-device storage

-   Use Hive for quick key-value (user prefs, last known state)

-   Use Drift/SQLite for structured datasets (collections, identifications)

-   Cached guide content stored as JSON + images stored in local cache

### Sync model (eventual consistency)

-   Client records local changes with `sync_status` (`pending` / `synced` / `conflict`)

-   SyncService runs in background with exponential backoff

-   Conflict resolution: last-write-wins for non-critical fields; for collisions user is prompted to choose

### Data Minimization

-   Avoid uploading images by default; when uploading, send compressed version (<2MB)

-   Option: users can opt-in to upload full images for model improvement

---

## Security & Privacy Considerations

-   Enforce TLS for all network traffic

-   Store minimal PII; support anonymous/guest workflows

-   Encrypt sensitive local storage (use OS-level encrypted storage where available)

-   Apps must request permissions with contextual explanation before accessing camera

-   Rate-limit external API calls and enforce API key management in backend (do not embed keys in client)

---

## Scalability & Cost Control

-   Cache identification results (Redis) for repeated requests on same image hash

-   Use tiered fallback to reduce cost: local heuristics → Plant.id (paid) → PlantNet (free)

-   Implement rate-limits and quota per user

-   Horizontal scale backend services with stateless containers, DB as managed service

---

## Observability & SLOs

-   SLO: Identification API 95th percentile latency < 2s (excluding external API time)

-   Uptime target: 99.5% for backend API

-   Instrument endpoints for latency, error rates, and external API failure counts

---

## CI/CD & Deployment Plan

1. Repo structure: `mobile/`, `backend/`, `infra/`, `docs/`

2. CI (GitHub Actions): unit tests, widget tests, lint, build (`flutter build apk`), docker build for backend

3. CD: deploy backend to container service (ECS/GKE/DigitalOcean App Platform) using rolling updates

4. Releases: tag-based release; publish APK to internal testers (for academic beta) via Firebase App Distribution

---

## Integration & Contribution Guidelines (Open Source)

-   Public repo on GitHub, issue templates, contributing.md

-   Modules: keep backend modular (identify-orchestrator separable)

-   Provide sample `.env.example` without keys

-   Document how to obtain API keys for Plant.id / PlantNet and how to configure fallback

---

## Risks teknis & Mitigasi (engineering)

-   **Third-party downtime** — implement retries, exponential backoff, fallback API

-   **Cost of identification API** — cache results, limit guest usage rate, enable community-maintained guide DB

-   **Data privacy concerns** — keep images local by default, opt-in server upload

-   **Device fragmentation** — test on representative low-end devices and Android Go

---

## Referensi Dokumen Terkait

-   [Product Requirements Document (PRD)](prd.md) - Persyaratan produk dan fitur.
-   [Product Brief](product-brief.md) - Ringkasan produk dan visi.
-   [Spesifikasi Front-End](ux-spec.md) - Panduan UI/UX dan kontrak API lengkap.
-   [Epics](epics.md) - Rancangan epics berdasarkan docs.
-   [Sprint Planning](sprint-planning.md) - Rencana sprint untuk development.
