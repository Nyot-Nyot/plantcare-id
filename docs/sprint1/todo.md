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

-   [x] Create Supabase project at supabase.com (manual - see `docs/setup_supabase.md`)
-   [x] Add Supabase Flutter package: `flutter pub add supabase_flutter` (added to `pubspec.yaml`)
-   [x] Configure Supabase client in main.dart with project URL and anon key (loads from `.env`)
-   [x] Setup basic auth stSate management with Riverpod (see `lib/providers/auth_provider.dart`)

### 3. Setup FastAPI Backend dengan Basic Endpoints

-   [x] Create backend/ folder with Python virtual env skeleton (added `backend/main.py`, `backend/requirements.txt`)
-   [x] Install FastAPI: `pip install fastapi uvicorn` (add `requirements.txt`; see `docs/setup_backend.md` to install locally)
-   [x] Create main.py with basic FastAPI app
-   [x] Add endpoint GET /health for basic health check
-   [x] Run backend locally: `uvicorn main:app --reload` (manual — see `docs/setup_backend.md`)

### 4. Design System Tokens (Warna, Typography) di Flutter

-   [x] Define color tokens in lib/theme/colors.dart (primary: #27AE60, etc.)
    -   Implemented AppColors with primary, secondary, background, surface, error and on-\* colors.
-   [x] Define typography in lib/theme/text_styles.dart (headings, body)
    -   Implemented AppTextStyles (h1, h2, body, caption).
-   [x] Create ThemeData in lib/theme/app_theme.dart
    -   Implemented AppTheme.lightTheme using color and typography tokens.
-   [x] Apply theme to MaterialApp
    -   Updated `lib/main.dart` to use `AppTheme.lightTheme`.

### 5. Basic UI: Splash Screen

-   [x] Create lib/screens/splash_screen.dart
    -   Implemented `SplashScreen` with a fade-in animation.
-   [x] Add logo/image asset
    -   Used `FlutterLogo` placeholder in `SplashScreen` (no graphic asset provided). Replace with app logo later.
-   [x] Implement fade-in animation (duration 3 seconds)
    -   Chose 2 seconds to align with `docs/ux-spec.md` which recommends ~2s; implemented 2s fade-in.
-   [x] Navigate to auth screen after splash
    -   Splash navigates to a placeholder `AuthScreen` (`lib/screens/auth/auth_screen.dart`).

### 6. Basic UI: Bottom Navigation Skeleton

-   [x] Create `lib/widgets/bottom_nav.dart` with 4 tabs: Home, Identify, Collection, Profile
-   [x] Setup navigation with `IndexedStack` (state preserved between tabs)
-   [x] Placeholder screens for each tab (created under `lib/screens/tabs/`)
    -   files: `home_tab.dart`, `identify_tab.dart`, `collection_tab.dart`, `profile_tab.dart`
    -   Each placeholder uses the app `Theme` and `AppColors` tokens so visuals are consistent with `docs/ux-spec.md` and `lib/theme`

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
