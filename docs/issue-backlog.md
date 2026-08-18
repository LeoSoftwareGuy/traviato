# Trevy — Issue Backlog (MVP, v3)

Figma: file **"Leo's team library"**, Page 1.

**Numbering:** GitHub shares one counter between issues and PRs, so numbers drift
as PRs merge. Rule: a backlog item gets its real number only when the GitHub
issue is created (create each issue just before starting it). Items below without
a number use a working ID (M2-x, M3-x, …) until then. Branch names and
`Closes #N` always use the **GitHub** number.

---

## Milestone 1 — Foundation ✅ DONE

| # | Issue | Status |
|---|-------|--------|
| #1 | Project scaffold + CI | ✅ merged |
| #2 | Supabase wiring + app bootstrap | ✅ merged |
| #3 | Theme from Figma tokens | ✅ merged |
| #4 | Migration: profiles + signup trigger | ✅ merged |
| #5 | Auth + guest landing + routing | ✅ merged |

(PRs #6–#10 consumed the intermediate numbers.)

---

## Milestone 2 — Memories & planning (in progress)

### #11 Migration: trips + trip_card_view — CREATED
trips per data-model: vibes text[] (no count check), country_code nullable,
client uuid PK, date check; RLS owner-only; grants; trip_card_view with derived
status/photo count/stars/duration/expense total (stars & expense columns return
0 until later migrations) + security_invoker; db reset.

### #12 Home screen — CREATED
Figma: `Home screen 1`, `Home screen 2`.
Greeting + avatar + stars badge (stub until points migration); stats bar from
stubbed profileStatsProvider; current-memory hero card (day X of Y,
Plan/Expenses/Journal shortcuts); Coming up row; Memories grid (Recap badge,
duration, photo count); bottom nav Home · ➕ · Expenses via shell route
(Expenses placeholder); empty/loading/error states; TripCreatedDispatched
subscription; tests.

### #13 Create memory (single screen) — CREATED
Figma: `Add trip`.
One screen: name (required), where, start/end dates, vibe chips (10, no hard
cap). Create mutation, client-generated uuid, TripCreatedDispatched on success;
app-side 3-memory free-tier check; tests.

### #14 Migration: quests — CREATED
quests per data-model incl. completed_at; RLS via parent trip (first child-table
pattern); grants; index (trip_id, day_date); db reset.

### #15 Plan (day quests) — CREATED
Figma: `current trip - plan`. Add/edit sheets not in new file — reuse old-design
pattern. Day timeline with check circles (writes completed_at; stars TODO until
points RPC), "X quests planned / Y days total", day arrows clamped to range,
add/edit/delete sheets with validation, empty day state, undated-memory UX
proposed in plan comment; route /memory/:tripId/plan; tests.

### M2-6 Migration: checklist + seed
checklist_items with `category` + `is_essential`; checklist_suggestions seeded
per category with essential flags; RLS + grants; db reset.

### M2-7 Checklist UI
Figma: `current trip - checklist`. Category tabs with per-category progress,
overall "X of Y packed" bar, essential tags, check-off, custom add input; tests.

---

## Milestone 3 — During the trip

### M3-1 Migration: day_notes + photos + storage bucket
Both tables per data-model; trip-photos bucket + path-owner policies
(`{user_id}/{trip_id}/{photo_id}.{ext}`); RLS + grants; db reset.

### M3-2 Journal screen
Figma: `current trip - journal`.
Day tabs with photo thumbs; NO locked days, NO "starts today" screens; per-day
long-form note (1/day; stars via RPC — stub until points migration); photos
strip + add; To Do sheet (day's quests, check-off + stars); View wrap-up button
(disabled until wrap-up issues); delete memory (keeps stars); tests.

### M3-3 Migration: points_ledger + bonus tasks + achievements + RPCs
points_ledger + award_points RPC (note 1 / photo 2 / quest 1 / bonus per
template); bonus_task_templates + seed; bonus_task_assignments;
achievement_templates + seed (8 badges) + user_achievements +
check_achievements RPC; profile_stats_view; update trip_card_view stars +
expense totals; RLS + grants; db reset.

### M3-4 Migration: expenses + expense_summary_view
expenses table per data-model (category + amount checks); RLS via parent;
grants; expense_summary_view; db reset.

### M3-5 Expenses feature
Figma: `expenses`, `add expenses`.
Expenses tab: per-memory totals list with spend bars, search, sort; add-expense
sheet (memory selector, title, amount, category chips, date). Compare button
hidden/disabled (screen not designed). Tests.

### M3-6 Photo capture & upload
Pick/take photo, compression, EXIF geotag/taken_at, upload → row insert,
caption/place tag, stars; photos render in Journal (no standalone gallery);
tests with fake storage.

### M3-7 Bonus tasks
Figma: `bonus tasks`, `new bonus`. Issuing from templates, countdown, list +
popup, completion via photo, expiry; per-memory stars summary header; tests.

---

## Milestone 4 — Wrap-up & profile

### M4-1 Migration: wrap_ups + edge function generate_wrap_up
wrap_ups table; edge function: gather memory data → Anthropic → screenplay
JSONB; JWT + ownership validation; idempotent; secrets in function config;
CI deploy post-merge; RLS + grants; db reset.

### M4-2 Wrap-up playback screen — design pending, coordinate first
Generation trigger + progress UI; screenplay playback (Mapbox route, photo
sequence, narrative); fallback for no-location memories; mapbox_maps_flutter
dep (justify); screenplay parsing tests.

### M4-3 Wrap-up editing + publish
Edit blocks (reorder/remove/edit text), save to content; publish sets
published_at; tests.

### M4-4 Profile & achievements
Figma: `profile`.
Avatar, name/@handle, editable bio, joined date; stats row from
profile_stats_view; achievements grid (earned/unearned, progress from stats);
logout; tests.

---

## Backlog notes

- Design gaps blocking issues: M4-2 (wrap-up screen), expenses Compare (future
  issue when designed), photo detail/tagging (future issue).
- Gallery removed from MVP — photos live in Journal + wrap-up.
- MP4 export, social feed, shared memories: post-MVP.
