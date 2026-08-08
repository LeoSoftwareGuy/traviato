# 01 — Architecture & Folder Structure

## The simplified structure (use this)

**One Flutter package. Feature-first at the top, layered inside each feature.**

```
lib/
├── main.dart
├── core/                          # shared, cross-feature building blocks
│   ├── config/
│   │   └── router/
│   │       ├── app_router.dart          # @riverpod GoRouter
│   │       └── route_constants.dart     # RoutePaths + RouteNames
│   ├── constants/
│   │   └── supabase_constants.dart      # Tables, Views, RPC fn names, Storage buckets
│   ├── errors/
│   │   ├── exceptions.dart              # AppException + subtypes (data layer throws)
│   │   ├── failures.dart                # Failure + subtypes (domain returns)
│   │   └── failure_message.dart         # Failure/Object -> String for UI
│   ├── providers/
│   │   └── supabase_providers.dart      # supabaseClientProvider (keepAlive)
│   ├── events/                          # optional: global event bus (see doc 08)
│   └── widgets/                         # shared widgets (error/retry, nav bar, ...)
│
└── features/
    ├── auth/
    │   ├── data/
    │   │   ├── datasources/
    │   │   │   └── auth_remote_data_source.dart   # interface + supabase impl
    │   │   ├── models/
    │   │   │   └── user_model.dart
    │   │   └── repositories/
    │   │       └── auth_repository_impl.dart
    │   ├── domain/
    │   │   ├── entities/
    │   │   │   └── user_entity.dart
    │   │   └── repositories/
    │   │       └── auth_repository.dart            # abstract interface
    │   └── presentation/
    │       ├── controllers/
    │       │   └── auth_controller.dart            # + auth_state.dart if complex
    │       ├── mutations/
    │       │   └── auth_mutations.dart
    │       ├── providers/
    │       │   └── auth_providers.dart             # DI: datasource/repo wiring
    │       └── pages/
    │           ├── login_page.dart
    │           └── signup_page.dart
    │
    ├── post/           # same data/domain/presentation triad
    ├── profile/
    └── search/
```

### Rules

- **Top level = features, not layers.** Everything about "post" lives under `features/post`.
- **Inside a feature = the three layers** `data / domain / presentation`. Keep the dependency
  direction: `presentation → domain → data`. Presentation may reference `data` *only* through
  the DI providers file (to construct the concrete repository); business code depends on the
  `domain` interfaces.
- **`core/` holds only cross-feature code.** If two+ features need it, it goes in `core`.
  Don't preemptively put feature-specific code there.
- **The DI wiring lives in `presentation/providers/<feature>_providers.dart`.** This is the
  one spot allowed to import both the `data` implementations and the `domain` interfaces.
  It exposes `repository` (and, if used, `useCase`) providers typed as the domain interface.

## When to keep the layers vs. flatten further

The full triad is worth it for features that hit the backend. For a trivial, purely-local
feature (e.g. a settings toggle) you may collapse to just `presentation/`. Judgement call —
but **never** skip the repository interface for anything that touches Supabase, because that
boundary is what keeps the app testable and swappable.

## When (not) to extract a real pub package

Only split code into a separate package under `packages/` when **both** are true:

1. It is consumed by more than one Flutter app (e.g. a customer app + an admin app), **and**
2. It has a stable public API you're willing to version.

Otherwise a folder is strictly better: no `pubspec` juggling, no barrel-export maintenance,
instant refactors. The reference project's `core`/`domain`/`data_supabase` packages are a
teaching artifact — do not copy that layout into a normal app.

## Dependency-rule quick check

| From | May import |
|------|-----------|
| `presentation` | its own `domain`; `core`; `data` **only** in the `providers/` DI file |
| `domain` | `core/errors`, `equatable`, `fpdart`. **Never** Flutter, Supabase, or JSON |
| `data` | its own `domain` (to implement interfaces & extend entities); `core`; Supabase |
| `core` | nothing feature-specific |

If a domain file needs `import 'package:supabase_flutter/...'` or `package:flutter/...`,
you've put logic in the wrong layer.
