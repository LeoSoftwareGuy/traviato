# Traviato

The place where your travel life lives — plan your trip, log it as you go, and it
becomes a beautiful journal you keep forever. A mobile app built with Flutter (Dart)
and Supabase.

## Tech stack

Flutter · Riverpod (code-gen) · go_router · Supabase · fpdart · json_serializable.
See `docs/00-tech-stack-and-philosophy.md` and `docs/01-architecture-and-folder-structure.md`
for the full architecture and folder conventions.

## Getting started

### Prerequisites

- Flutter `3.44.1` (stable) with Dart `3.12+`.
- A Supabase project (for URL + publishable key).

### Setup

1. Install dependencies:

   ```bash
   flutter pub get
   ```

2. Create your local environment file by copying the example and filling in your
   Supabase credentials:

   ```bash
   cp .env.example .env
   ```

   Then set the values in `.env` (found under Supabase dashboard → Project Settings → API):

   ```
   SUPABASE_URL=https://your-project-ref.supabase.co
   SUPABASE_PUBLISHABLE_KEY=sb_publishable_your_key_here
   ```

   `.env` is git-ignored and must never be committed. It is loaded at runtime via
   `flutter_dotenv` and bundled as an asset (see `pubspec.yaml`).

3. Run the app:

   ```bash
   flutter run
   ```

### Code generation

Riverpod providers, JSON models, and the router rely on generated `*.g.dart` files.
During development keep the generator running:

```bash
dart run build_runner watch -d
```

## Before opening a PR

All three must pass (also enforced by CI on every PR — see `.github/workflows/ci.yml`):

```bash
dart format --set-exit-if-changed .
flutter analyze
flutter test
```

## Contributing

Read `docs/workflow.md` — every task starts from a GitHub Issue, work happens on a
`feat/<issue-number>-<slug>` branch, and ends in a PR to `main` (never commit to `main`
directly).
