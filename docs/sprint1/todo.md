# Todo List for Sprint 1: Setup, Auth & Basic UI

**Sprint Goal:** Siapkan infrastruktur dasar dan implementasi auth serta UI dasar.

**Epics Covered:** Epic 5 (Authentication & Access), partial Epic 7 (Backend Orchestration & AI Integration).

**Acceptance Criteria:** App bisa dijalankan, user bisa login/guest, navigate screens.

**Estimasi:** 25 SP (1 minggu).

**Developer Assigned:** Developer A.

---

## Todo Items

### 1. Setup Flutter Project with Riverpod

-   [x] Install Flutter SDK and create new project: `flutter create .`
-   [x] Add Riverpod dependency: `flutter pub add riverpod` (implemented as `flutter_riverpod` in `pubspec.yaml`)
-   [x] Setup basic project structure (lib/, assets/, etc.)
-   [x] Configure main.dart with ProviderScope

### 2. Integrasi Supabase untuk Auth dan DB

-   [ ] Create Supabase project at supabase.com (manual - see `docs/setup_supabase.md`)
-   [x] Add Supabase Flutter package: `flutter pub add supabase_flutter` (added to `pubspec.yaml`)
-   [x] Configure Supabase client in main.dart with project URL and anon key (loads from `.env`)
-   [x] Setup basic auth state management with Riverpod (see `lib/providers/auth_provider.dart`)

### 3. Setup FastAPI Backend dengan Basic Endpoints

-   [ ] Create backend/ folder with Python virtual env
-   [ ] Install FastAPI: `pip install fastapi uvicorn`
-   [ ] Create main.py with basic FastAPI app
-   [ ] Add endpoint GET /health for basic health check
-   [ ] Run backend locally: `uvicorn main:app --reload`

### 4. Design System Tokens (Warna, Typography) di Flutter

-   [ ] Define color tokens in lib/theme/colors.dart (primary: #27AE60, etc.)
-   [ ] Define typography in lib/theme/text_styles.dart (headings, body)
-   [ ] Create ThemeData in lib/theme/app_theme.dart
-   [ ] Apply theme to MaterialApp

### 5. Basic UI: Splash Screen

-   [ ] Create lib/screens/splash_screen.dart
-   [ ] Add logo/image asset
-   [ ] Implement fade-in animation (duration 3 seconds)
-   [ ] Navigate to auth screen after splash

### 6. Basic UI: Bottom Navigation Skeleton

-   [ ] Create lib/widgets/bottom_nav.dart with 5 tabs: Home, Identify, Collection, Guide, Profile
-   [ ] Setup navigation with PageView or IndexedStack
-   [ ] Placeholder screens for each tab

### 7. Implementasi Login/Register/Guest Mode (Supabase Auth)

-   [ ] Create lib/screens/auth/login_screen.dart with email/password fields
-   [ ] Add register option and guest mode button
-   [ ] Integrate Supabase signIn/signUp methods
-   [ ] Handle auth state changes (redirect to home on success)

### 8. Welcome Screen dan Home Dashboard

-   [ ] Create lib/screens/home_screen.dart with tiles for main features
-   [ ] Add welcome message for new users
-   [ ] Basic dashboard layout with placeholders

### 9. Profile Screen Skeleton

-   [ ] Create lib/screens/profile_screen.dart
-   [ ] Add logout button and basic user info display
-   [ ] Placeholder for settings

### 10. Error Handling untuk Auth

-   [ ] Add try-catch in auth methods
-   [ ] Display error messages (e.g., invalid credentials)
-   [ ] Handle network errors with retry option

### 11. Unit Tests untuk Auth Logic

-   [ ] Setup test/ folder with flutter_test
-   [ ] Write tests for auth provider (login success/failure)
-   [ ] Run tests: `flutter test`

### 12. CI/CD Setup (GitHub Actions untuk Build APK)

-   [ ] Create .github/workflows/build.yml
-   [ ] Add steps: checkout, setup Flutter, build APK
-   [ ] Configure for Android build
-   [ ] Test workflow on push to main

---

## Tracking Changes

-   Update status [ ] to [x] when completed.
-   Add notes for any issues or changes.
-   Commit per todo item: `git commit -m "feat: complete setup Flutter project"`

## Notes

-   Use GitHub Copilot for code generation based on docs.
-   Refer to ux-spec.md for UI details, architect.md for API setup.
-   Test on emulator/device after each major task.
