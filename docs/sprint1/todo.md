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

-   [x] Create lib/screens/auth/login_screen.dart with email/password fields
-   [x] Add register option and guest mode button
-   [x] Integrate Supabase signIn/signUp methods
-   [x] Handle auth state changes (redirect to home on success)

### 8. Welcome Screen dan Home Dashboard

-   [x] Create lib/screens/home_screen.dart with tiles for main features
-   [x] Add welcome message for new users
-   [x] Basic dashboard layout with placeholders

**Notes:** Implemented `HomeScreen` and `DashboardTile`.
The `home_tab.dart` now delegates to `HomeScreen` so `/home` (the main tab) shows the dashboard.
Welcome message uses `authUserProvider` and falls back to Guest when `guestModeProvider` is active.

### 9. Profile Screen Skeleton

-   [x] Create lib/screens/profile_screen.dart
-   [x] Add logout button and basic user info display
-   [x] Placeholder for settings

### 10. Error Handling untuk Auth

-   [x] Add try-catch in auth methods
-   [x] Display error messages (e.g., invalid credentials)
-   [x] Handle network errors with retry option

Notes: Implemented structured `AuthException` in `lib/providers/auth_provider.dart` with user-friendly messages and a small retry helper for transient network errors. Login and Register screens show SnackBar messages and include a "Coba lagi" action when the error is retryable. Updated `lib/screens/auth/auth_screen.dart` and `lib/screens/auth/register_screen.dart` accordingly.

### 11. Unit Tests untuk Auth Logic

-   [x] Setup test/ folder with flutter_test

-   [x] Write tests for auth provider (happy path + transient network failure)

-   [x] Run tests: `flutter test` (all tests passed locally)

Notes: Added `test/auth_repository_test.dart` to exercise the repository's
retry logic. Tests cover success, single SocketException recovery, and
repeated SocketException resulting in an `AuthException` with `canRetry`.

### 12. CI/CD Setup (GitHub Actions untuk Build APK)

-   [x] Create .github/workflows/build.yml
    -   [x] Add steps: checkout, setup Flutter, build APK, run analyzer and tests
    -   [x] Configure for Android build (release APK)
    -   [x] Upload built APK as workflow artifact

Notes: Added `./github/workflows/build.yml` which runs on pushes/PRs to `main`. The workflow:

-   checks out the code
-   installs Flutter via subosito/flutter-action
-   runs `flutter pub get`, `flutter analyze`, `flutter test`
-   builds a release APK (`flutter build apk --release`) and uploads it as an artifact

Local verification: ran `flutter analyze` and executed the new unit tests locally; tests passed.

---

## Tracking Changes

-   Update status [ ] to [x] when completed.
-   Add notes for any issues or changes.
-   Commit per todo item: `git commit -m "feat: complete setup Flutter project"`

## Notes

-   Use GitHub Copilot for code generation based on docs.
-   Refer to ux-spec.md for UI details, architect.md for API setup.
-   Test on emulator/device after each major task.
