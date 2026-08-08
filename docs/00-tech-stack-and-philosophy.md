# 00 — Tech Stack & Philosophy

## Fixed stack (do not substitute)

| Concern | Package | Notes |
|---------|---------|-------|
| Backend / auth / storage / realtime | `supabase_flutter` | Single source of truth for remote data |
| State management + DI | `flutter_riverpod` + `riverpod_annotation` (code-gen) | Always use the generator, never hand-write `Provider(...)` |
| Routing | `go_router` | One router, exposed as a Riverpod provider |
| Value equality | `equatable` | Every entity/state class extends `Equatable` |
| Functional error type | `fpdart` | `Either<Failure, T>` at the repository boundary |
| JSON | `json_serializable` + `json_annotation` | Models only; entities stay JSON-free |
| Env | `flutter_dotenv` | Supabase URL/keys from `.env` (git-ignored) |
| IDs | `uuid` | Client-generated IDs when needed (e.g. image folder before insert) |
| Images | `image_picker`, `cached_network_image` | |
| Dev | `build_runner`, `riverpod_generator`, `flutter_lints` | |

Minimum toolchain assumptions: Dart 3.11+, `flutter_riverpod` 3.x (Mutations API lives in
`package:flutter_riverpod/experimental/mutation.dart`), `riverpod_annotation` 4.x.

## Core principles

1. **Layered dependency rule.** `presentation → domain → data`. The domain layer knows
   nothing about Supabase, JSON, or Flutter. Never import `supabase_flutter` outside the
   data layer. Never import `package:flutter/*` into domain.
2. **Entities are pure; models are dirty.** Domain exposes `Entity` classes. The data layer
   defines `Model extends Entity` that adds `fromJson`. The rest of the app only ever sees
   entities.
3. **Errors are typed and never leak.** Data sources throw `AppException` subtypes;
   repositories convert them to `Failure` subtypes and return `Either<Failure, T>`. The UI
   converts `Failure` to a user-facing string. Raw exceptions must not reach widgets.
4. **Riverpod is both state and DI.** Plain `@riverpod` functions wire dependencies
   (data source → repository → use case). `@riverpod class` notifiers hold screen state.
5. **Read vs write are different tools.** Screen *state you display* = a controller/notifier.
   *One-shot actions* (submit form, toggle like, delete) = a **Mutation**. Don't overload a
   watched provider with imperative side-effects.
6. **Immutable state + `copyWith`.** State classes are `Equatable`, fields are `final`,
   updates go through `copyWith`. Use the `Function()`-wrapper trick to allow setting
   nullable fields back to `null` (see [05](05-domain-layer.md)).
7. **Generate, don't hand-roll.** Run `dart run build_runner watch -d` during development.
   Providers, models, and router all depend on generated `*.g.dart` files.

## What we KEEP from the reference project

- Clean-architecture layering (data / domain / presentation).
- `Either<Failure, T>` repositories and the exception→failure mapping.
- Entity/Model split with `json_serializable`.
- Riverpod code-gen providers as DI.
- Controllers (`AsyncNotifier`) + separate immutable state classes for complex screens.
- Mutations for one-shot actions.
- go_router as a provider that redirects on auth.
- A global event bus to keep independent screens in sync.

## What we DROP / SIMPLIFY

- ❌ **Multi-package monorepo.** The reference splits `core`/`domain`/`data_supabase`/app
  into separate pub packages. **Use a single Flutter package** with folders instead
  (see [01](01-architecture-and-folder-structure.md)). Only extract a package if you
  genuinely ship a second app against the same domain.
- ❌ **A use-case class for every call.** The reference has ~25 one-line use-case classes
  that just forward to the repository. **Skip the use-case layer by default** and let
  controllers/mutations call the repository directly. Introduce a use case only when there
  is *real* logic (orchestrating multiple repositories, combining/transforming results).
  See [05](05-domain-layer.md).
- ❌ **Six-state pagination enums with `refilling`/`refrefreshing`.** Start simple
  (`loading / loaded / error` + `hasReachedMax`). Add substates only when the UX needs them.
- ❌ **Artificial `Future.delayed` calls.** Those exist in the reference only to demo
  spinners. Never ship them.

> Rule of thumb: **fewer files until a real second use appears.** Clean architecture is
> about dependency *direction*, not about maximizing the number of classes.
