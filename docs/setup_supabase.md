# Supabase setup (quick guide)

This document lists the manual steps you must perform to create a Supabase project and obtain the keys required by the app.

1) Create a Supabase project

- Go to https://app.supabase.com and sign in / sign up.
- Create a new project and follow the prompts. Choose your password and region.

2) Get project URL and anon key

- In the Supabase dashboard for your project, go to Settings -> API.
- Copy the `Project URL` and the `anon` public key (labeled "anon key" / "anon public" or similar).

3) Add keys to your local `.env` file

Create a file named `.env` in the project root (same folder as `pubspec.yaml`) with the following content:

```
SUPABASE_URL=https://your-project-ref.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOi... (your anon key)
```

Replace the placeholders with the values from the dashboard.

4) Install dependencies and run the app

If you haven't already, fetch packages:

```fish
flutter pub get
```

Then run the app:

```fish
flutter run
```

5) Notes for CI / production

- Do not commit `.env` to source control. Add it to `.gitignore` if necessary.
- For CI, add `SUPABASE_URL` and `SUPABASE_ANON_KEY` as repository secrets and inject them as env vars for the build.

If you want, I can create a sample GitHub Actions workflow that injects secrets and builds an APK.
