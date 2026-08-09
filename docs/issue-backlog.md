# Traviato — Issue Backlog (MVP)

Paste each as a GitHub Issue. Order = dependency order. Every issue follows
workflow.md: branch `feat/<n>-<slug>`, plan comment first, PR with `Closes #<n>`.
Figma: file `beautify`, page **journey**.

---

## Milestone 1 — Foundation

### #1 Project scaffold + CI
Flutter project scaffold with the agreed stack and a CI workflow.
**AC:**
- `flutter create` scaffold, package name per Traviato working title.
- All pubspec deps from guidelines doc 00 (riverpod code-gen, go_router, fpdart,
  equatable, json_serializable, supabase_flutter, flutter_dotenv, uuid, image_picker,
  cached_network_image, build_runner, flutter_lints).
- `analysis_options.yaml` per coding-standards; zero warnings on empty scaffold.
- Folder skeleton per guidelines doc 01 (`core/`, `features/`).
- GitHub Actions workflow: `dart format --set-exit-if-changed .`, `flutter analyze`,
  `flutter test` on every PR.
- `.env.example` committed; README explains local `.env` setup.

### #2 Supabase wiring + app bootstrap
Connect the app to Supabase; runnable empty app.
**AC:**
- `supabase init` committed (`supabase/` folder).
- `main.dart` per doc 09 skeleton: dotenv load, `Supabase.initialize`, `ProviderScope`
  with retry disabled.
- `supabaseClientProvider` (keepAlive) in `core/providers/`.
- `core/errors/` files (exceptions, failures, failure_message,
  presentation_failure_exception) from guidelines doc 03.
- `core/constants/supabase_constants.dart` stub.

### #3 Theme from Figma tokens
`core/theme/` built from the journey page design values (dark purple, gradients,
typography). Pull exact values via Figma MCP.
**AC:** ThemeData + color/text/spacing tokens; no inline colors anywhere; sample
widgets render correctly in both a golden/widget test.

### #4 Migration: profiles + signup trigger
First migration PR.
**AC:** `profiles` table per data-model.md; RLS (select/update own row); explicit
grants (project has auto-expose off); `handle_new_user()` trigger on `auth.users`;
`supabase db reset` passes locally; PR documents who-can-do-what.

### #5 Auth feature (login/signup/splash + routing)
Full auth vertical slice per guidelines docs 02–07. Figma: registration/login frames
(in progress — confirm frames with designer before UI polish).
**AC:**
- Data: `SupabaseAuthRemoteDataSource` with canonical catch ladder; `UserModel`.
- Domain: `UserEntity`, `AuthRepository` interface.
- Presentation: `AuthController` (unknown/authenticated/unauthenticated),
  login/signup mutations, login + signup pages with loading/error states.
- Router provider with auth redirect + splash (doc 07 pattern), route constants.
- Tests: repository against fake datasource, controller, widget tests for pages.

---

## Milestone 2 — Trips & planning

### #6 Migration: trips + trip_card_view
**AC:** `trips` table per data-model.md (client-generated uuid PK, goals text[]
check ≤3, date check); RLS owner-only all ops; grants; `trip_card_view` with derived
status/photo count/points (points column may return 0 until #14); db reset passes.

### #7 Home screen
Figma: `main screen`, `current screen`.
**AC:** trip sections New/Current/Upcoming/Latest from `trip_card_view`; search
filter by name; trip cards (cover, name, dates); empty states; loading/error/data
handled; controller + tests. Bottom nav placeholder (3 tabs per functionality.md
proposal) — final design pending.

### #8 Trip creation flow (3 steps)
Figma: `name`, `Goal`, `Plan` frames (+ first-time variant).
**AC:** step 1 basics (name, destination, dates — skippable); step 2 goal tags
(max 3, fixed list); step 3 plan overview with computed day-count ring and day
cards; create-trip mutation with client-generated uuid; cover image optional;
event bus `TripCreatedDispatched` prepends to home list; tests.

### #9 Migration: quests
**AC:** `quests` table incl. `completed_at`; RLS via parent trip; grants; db reset.

### #10 Day planning
Figma: `Day 1`, `Day 2`, add/edit plan sheets.
**AC:** per-day screen with date + Day N + arrows; ordered timed quests; add sheet
(name → time), edit sheet (save/delete); empty state; reorder via position; tests.

### #11 Migration: checklist + seed
**AC:** `checklist_items`, `checklist_suggestions` + seed data; RLS + grants;
db reset.

### #12 Checklist UI
Figma: `checklist` sheets.
**AC:** suggestions with search, check off, custom item add (design in progress —
implement basic input, polish later); reachable from plan overview; tests.

---

## Milestone 3 — During the trip

### #13 Migration: day_notes + photos + storage bucket
**AC:** both tables per data-model.md; `trip-photos` bucket + path-owner policies
(`{user_id}/{trip_id}/{photo_id}.{ext}`); RLS + grants; db reset.

### #14 Migration: points_ledger + bonus tasks + award_points RPC
**AC:** `points_ledger` (unique earn guard), `bonus_task_templates` + seed from
functionality.md §7, `bonus_task_assignments`; `award_points` RPC holding the value
table (note 1 / photo 2 / quest 1 / bonus per template) — clients cannot insert
ledger rows directly; RLS + grants; db reset; update `trip_card_view` points column.

### #15 Current-trip day view
Figma: `Current trip 4`, `Current trip 6`, `Update 1/2`.
**AC:** "trip starts today" screen; day tabs with photo thumbnails; future days
locked; day note add/edit (1/day, awards points via RPC); To Do list = day's quests,
check-off sets `completed_at` + awards points; delete trip (confirm dialog — keeps
points); per-trip stars in header; tests.

### #16 Photo capture & upload
Figma: `photos` component + gallery add flow (partly undesigned — basic flow first).
**AC:** pick/take photo, client-side compression, EXIF geotag + taken_at extraction
(with permission), upload to bucket then insert row (client uuid), optional caption/
place tag; awards points; quick-log path from nav camera opens current trip day;
tests with fake storage.

### #17 Gallery
Figma: `Gallery` frames.
**AC:** per-trip masonry grid with captions; empty state; photo detail with caption/
place/people tags (free-text); tests.

### #18 Bonus tasks
Figma: `Bonus Tasks` sheet + popup.
**AC:** assignment issuing logic (from templates' trigger field), countdown display,
task list sheet with badge, single-task popup (camera / Later), completion via photo
→ status + points; expiry handling; tests.

---

## Milestone 4 — Memory

### #19 Migration: memories + edge function `generate_memory`
**AC:** `memories` table per data-model.md; edge function gathers trip data, calls
Anthropic API, writes screenplay JSONB; validates JWT + trip ownership; idempotent
(returns existing screenplay); API key in function secrets only; function deploy via
CI post-merge; RLS + grants; db reset.

### #20 Memory playback screen
Figma: finished-trip screen (in progress — coordinate with designer).
**AC:** tapping a finished trip triggers generation (first time, with progress UI)
then plays screenplay: Mapbox route animation day by day, photos in sequence
(cached), narrative text; graceful fallback for trips without location data; add
`mapbox_maps_flutter` dependency (justify in PR); tests for screenplay parsing.

### #21 Memory editing + publish
**AC:** edit mode (reorder/remove blocks, edit text), saves to `content`; "publish"
sets `published_at`; tests.

### #22 Profile & points balance
Figma: not designed — basic version.
**AC:** profile screen with user info, total points (ledger SUM), logout; per-trip
points visible; tests.

---

## Backlog notes

- Free-tier 3-trip limit: app-side check at trip creation (revisit server-side
  pre-launch) — fold into #8.
- MP4 export, social feed, shared trips: post-MVP, not in this backlog.
- Design-gap issues (#5 UI polish, #7 nav bar, #12 custom-item UI, #20 screen) may
  need follow-up issues when final designs land — one issue per gap, per workflow
  scope discipline.
