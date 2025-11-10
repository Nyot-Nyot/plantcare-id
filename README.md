# PlantCare.ID

**PlantCare.ID** adalah aplikasi mobile cross-platform berbasis Flutter yang membantu pengguna mendiagnosis dan merawat tanaman menggunakan foto. Aplikasi ini mengubah hasil diagnosis menjadi panduan perawatan praktis dan visual, sehingga mudah digunakan oleh siapa saja, dari penghobi hingga petani.

## Fitur Utama MVP

-   Identifikasi tanaman dari foto (dengan AI Plant.id dan fallback PlantNet).
-   Panduan perawatan step-by-step (maksimal 5 langkah).
-   Koleksi tanaman pribadi dengan notifikasi.
-   Offline-first support.
-   Autentikasi sederhana + guest mode.

## Tech Stack

-   **Frontend:** Flutter (Dart) dengan Riverpod untuk state management.
-   **Backend:** FastAPI (Python) untuk orchestration.
-   **Database:** Supabase (PostgreSQL hosted).
-   **AI:** Plant.id primary, PlantNet fallback.
-   **Storage:** S3-compatible untuk gambar.
-   **Notifications:** FCM untuk push notifications.

---

## Getting Started

### Prerequisites

-   Flutter SDK (versi 3.35.7 atau lebih baru).
-   Python 3.9+ untuk backend.
-   GitHub account untuk Copilot.
-   Supabase account untuk database.

### Setup Project

1. Clone repo: `git clone <repo-url>`
2. Setup Flutter: `flutter doctor` dan install dependencies.
3. Setup backend: `cd backend && pip install -r requirements.txt`
4. Setup Supabase: Buat project di supabase.com, copy API keys ke `.env`.
5. Jalankan app: `flutter run` untuk mobile, `uvicorn main:app` untuk backend.

---

## Development Workflow

Workflow ini berdasarkan docs di folder `docs/`. Ikuti langkah-langkah ini untuk development yang terstruktur:

1. **Baca Docs Terlebih Dahulu (5-10 menit):**

    - Mulai dari [Product Brief](docs/product-brief.md) untuk visi dan scope.
    - Lanjut [PRD](docs/prd.md) untuk requirements detail.
    - Baca [Arsitektur](docs/architect.md) untuk tech decisions dan API contracts.
    - Lihat [UX Spec](docs/ux-spec.md) untuk UI guidelines dan design tokens.
    - Periksa [Epics](docs/epics.md) untuk user stories.
    - Ikuti [Sprint Planning](docs/sprint-planning.md) untuk timeline dan assignment.

2. **Setup Environment**

-   Pasang tools yang diperlukan (lihat bagian "Prerequisites" di atas). Contoh umum: Git, Node.js, Python, Docker, VS Code.
-   Cek apakah terpasang:
    -   `git --version`
    -   `node -v`
    -   `python --version`
-   Jika proyek menyediakan file contoh konfigurasi, salin lalu sesuaikan:
    -   `cp .env.example .env` dan edit `.env`
-   Buat branch baru untuk setiap sprint/pekerjaan agar perubahan terisolasi:
    -   Buat branch: `git checkout -b sprint-1`
    -   Push ke remote: `git push -u origin sprint-1`
    -   Kerjakan sprint
    -   Saat selesai, buat Pull Request dan review sebelum merge ke `main`

3. **Implementasi per Sprint:**

    - Assign developer sesuai sprint-planning.md (Dzaki : Sprint 1 & 3, Firman: Sprint 2 & 4).
    - Buat todo list untuk sprint: Lihat contoh di docs/sprint1/todo.md (untuk Sprint 1).
    - Kerjakan tasks satu per satu dari todo list, test setiap fitur.
    - Gunakan GitHub Copilot untuk generate code cepat.
    - Update todo.md: Tandai [x] saat selesai, commit per task.
    - Jika stuck, referensi docs atau tanya tim.

    **Contoh untuk Sprint 1:**

    - Buka GitHub Copilot Chat di VS Code.
    - Attach folder docs/ sebagai context (klik ikon paperclip, pilih folder docs/).
    - Berikan prompt: "Berdasarkan sprint-planning.md dan epics.md, buat todo list detail untuk Sprint 1: Setup, Auth & Basic UI. Breakdown tasks menjadi item kecil yang actionable, dengan estimasi waktu jika mungkin. Sertakan acceptance criteria dari docs. buat file docs/sprintx/todo.md untuk tracking changes dan panduan."
    - Kerjakan setiap task: Misal, untuk task 1:

    ```md
    lihat di docs/sprint1/todo.md

    ### 1. Setup Flutter Project with Riverpod

    [ ] Install Flutter SDK and create new project: `flutter create plantcare_id`
    [ ] Add Riverpod dependency: `flutter pub add riverpod`
    [ ] Setup basic project structure (lib/, assets/, etc.)
    [ ] Configure main.dart with ProviderScope
    ```

    berikan prompt:

    ```prompt
    berdasarkan docs/sprint1/todo.md pada task 1, buat todo list dan kerjakan satu persatu. kemudian tandai setiap task yg sudah selesai di docs/sprint1/todo.md
    ```

    - Test: Jalankan `flutter run`, pastikan app launch.

4. **Testing & Review:**

    - Jalankan aplikasi dan pastikan aplikasi berjalan sesuai dengan kriteria.
    - Review code, pastikan sesuai acceptance criteria di epics.md.

5. **Iterate:**
    - Lanjutkan ke task 2 dan seterusnya di todo.md dengan cara yang sama.

---

## Sprint Implementation Guide

Ikuti sprint-planning.md. Setiap sprint 1 minggu, fokus 1 developer per sprint.

-   **Sprint 1 (Developer A):** Setup Flutter, auth Supabase, basic UI. Lihat todo list di docs/sprint1/todo.md. Gunakan Copilot untuk generate auth screens.
-   **Sprint 2 (Developer B):** Camera integration, API Plant.id. Prompt Copilot "Integrasi camera plugin, compress image <2MB".
-   **Sprint 3 (Developer A):** Guides dan collection. Copilot untuk step-by-step UI.
-   **Sprint 4 (Developer B):** Offline mode, polish. Copilot untuk caching logic.

Estimasi: 25 SP per sprint. Jika stuck, tanya tim atau referensi docs.

---

## Contributing

-   Ikuti workflow di atas.
-   Commit per fitur kecil.
-   Gunakan Copilot untuk code review suggestions.

## References

-   [Docs Lengkap](docs/)
-   [Flutter Docs](https://flutter.dev/docs)
-   [FastAPI Docs](https://fastapi.tiangolo.com/)
-   [Supabase Docs](https://supabase.com/docs)

Selamat coding! 🚀
