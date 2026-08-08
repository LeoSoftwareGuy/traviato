# Flutter + Supabase + Riverpod — Coding Guidelines
 
These documents are the coding standard for new Flutter apps built with **Supabase**,
**Riverpod (code-gen)** and **go_router**. They are distilled from the reference project
`community_board_riverpod`, but **deliberately simplified**: that project split every layer
into its own pub package (`core`, `domain`, `data_supabase`, `riverpod_app`). For a normal
app that is overkill. These guidelines keep the *good* architectural ideas (clear layers,
typed errors, testable data access) but collapse them into **one Flutter package with
feature-first folders**.
 
Read them in order. Each is short and rule-driven with copy-pasteable examples.
 
| # | File | What it covers |
|---|------|----------------|
| 00 | [tech-stack-and-philosophy](00-tech-stack-and-philosophy.md) | Fixed stack, core principles, what to keep vs drop from the reference project |
| 01 | [architecture-and-folder-structure](01-architecture-and-folder-structure.md) | The simplified single-package layered / feature-first structure |
| 02 | [riverpod-conventions](02-riverpod-conventions.md) | Code-gen providers, controllers, `ref.watch`/`read`, Mutations, disposal |
| 03 | [error-handling](03-error-handling.md) | Exception→Failure→UI, `Either`/fpdart, transient errors |
| 04 | [data-layer-supabase](04-data-layer-supabase.md) | Data sources, models, JSON, Supabase queries/RPC/storage, error mapping |
| 05 | [domain-layer](05-domain-layer.md) | Entities, repositories, use cases (and when to skip them) |
| 06 | [presentation-controllers-and-mutations](06-presentation-controllers-and-mutations.md) | Pages, controllers + state, forms, optimistic updates, pagination |
| 07 | [routing-gorouter](07-routing-gorouter.md) | Router provider, auth redirect, route constants, shell routes |
| 08 | [cross-feature-communication](08-cross-feature-communication.md) | Global event bus for keeping lists/screens in sync |
| 09 | [naming-and-style-cheatsheet](09-naming-and-style-cheatsheet.md) | File/type/variable naming, barrels, quick do/don't table |
| 10 | [anti-patterns-and-evolution](10-anti-patterns-and-evolution.md) | Legacy Riverpod API, network-in-widget, untyped Either, get_it DI, callable class explained |
 
## The one-paragraph summary
 
Build **feature-first**. Inside each feature keep three layers — `data/`, `domain/`,
`presentation/`. Data sources talk to Supabase and throw typed `Exception`s; repositories
catch them and return `Either<Failure, T>`; the presentation layer turns `Failure` into a
message. State lives in Riverpod **code-gen** notifiers (`@riverpod`); plain provider
functions are your dependency injection. One-shot user actions (login, create, delete) go
through Riverpod **Mutations**, not controller methods watched by the UI. Navigation is a
single `@riverpod GoRouter` that redirects on auth state.