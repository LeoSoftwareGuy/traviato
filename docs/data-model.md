# Trevy — Data Model (MVP, v4)

Derived from `functionality.md` v4. Postgres (Supabase) — migrations only, RLS on
every table, explicit grants (auto-expose disabled). DB keeps `trips` (UI:
"memory"); screenplay lives in `wrap_ups`.

**v3 note:** the redesign handoff changed NO schema. Its sample star values
(per-quest ✦, photo ✦1) were rejected — canonical economy stands: note 1 ·
photo 2 · quest 1 (flat) · bonus per template. Vibes and achievement seeds stay
as below. Compare and the expenses breakdown are fully derived client-side.

## Design decisions

1. No `trip_days` table — children carry `day_date`; "Day N" computed.
2. No stored trip status — derived from dates.
3. Points are a ledger (UI: stars); balance = SUM; writes only via RPCs.
4. Owner-only access everywhere (no sharing in MVP).
5. Vibes as `text[]` (fixed 10: Romantic, Adventure, Cultural, Chill, Foodie,
   Road trip, Wellness, Wildlife, Nightlife, Photography).
6. Achievements server-awarded (`check_achievements` RPC), idempotent.
7. Expenses are plain owner rows; totals/compare derived, not stored.
8. **Cover images**: `trips.cover_image_path` holds either a bundled-asset id
   (`asset:<name>` — MVP cover picker) or a storage path (photo "Set as cover").
   App interprets by prefix.

## Tables (unchanged from v2 except where noted)

### `profiles`
`id (=auth.users.id), username?, bio?, avatar_url?, created_at`.
RLS: select/update own; insert via trigger.

### `trips`
`id uuid PK (client-generated), user_id FK, name, destination?, country_code?
(ISO-3166-1 alpha-2), start_date?, end_date? (check >= start), vibes text[]
default {}, cover_image_path?, created_at, updated_at`.
RLS owner-only, all ops. Free-tier 3-memory limit app-side.
**Manage sheet date-shift**: shifting dates re-dates child rows (quests, notes,
photos day_date) app-side in the same operation — no schema support needed.

### `quests`
`id, trip_id (cascade), day_date, time?, title, place_text?, position,
completed_at?, created_at`. **No per-quest points column** (flat ✦1 rejected the
mockup's variable values). RLS via parent trip; index (trip_id, day_date).

### `day_notes`
`id, trip_id (cascade), day_date, content, created_at, updated_at`,
unique (trip_id, day_date).

### `photos`
`id (client-generated), trip_id (cascade), day_date?, storage_path, caption?,
lat?, lng?, place_text?, people_tags text[] default {}, taken_at?, created_at`.
Photo detail's tagging edits `place_text` / `people_tags` / `caption` — no new
columns. **"Use in wrap-up"**: add `use_in_wrap_up bool default false` — the only
schema addition from the redesign (generator prioritizes flagged photos).

### `checklist_items` / `checklist_suggestions`
As v2: category check over `travel_essentials, clothing_shoes, toiletries_health,
gadgets_tech, nice_to_haves`; `is_essential`; suggestions seeded per category.

### `expenses`
As v2: `amount numeric(10,2) > 0`, category check (`food_drinks, transport,
accommodation, activities, shopping, other`), `spent_on`, EUR-only.
Breakdown (per-day avg, biggest category, per-category bars) and Compare are
all client-side derivations; `expense_summary_view` supplies per-trip totals.

### `bonus_task_templates` — RESHAPED (v4; migration amends the M3-3 tables)
`id bigint PK, code text unique, title (the prompt, slot-filled client-side),
detail?, points int (regular 1–3 · starter 1 · stretch 3 · milestone 5 ·
streak_saver 2), phase check (arrival/middle/departure/anytime), kind check
(regular/starter/stretch/milestone/streak_saver)`.
Dropped: `duration_hours`, `trigger`. Seed ~30–35 with **≥ 20 in
anytime+middle** (2/day × 10-day no-repeat window must not run dry).
Select-only for clients.

### `bonus_task_assignments` — RESHAPED (v4)
`id uuid PK, trip_id (cascade), template_id FK, day_date date, completed_at?,
photo_id?, created_at`, **unique (trip_id, template_id, day_date)**.
Dropped: `status`, `expires_at`. Expiry is DERIVED: expired ⇔ `day_date <
today AND completed_at IS NULL` — never stored, never rendered as failure.
Exception: `streak_saver` assignments stay live past their day until
completed. The daily draw is computed deterministically client-side
(hash(trip_id, day_date) over eligible templates, phase-filtered, minus the
10-day repeat set) and inserted idempotently via the unique constraint.
### `points_ledger` — unchanged (values in `award_points` RPC)
### `achievement_templates` / `user_achievements` — unchanged (seeded 8:
first_adventure, globetrotter, century, star_collector, shutterbug, storyteller
+ 2 per design; `check_achievements` RPC)

### `wrap_ups` — unchanged
`trip_id PK/FK cascade, content jsonb (screenplay), generated_at, published_at?`.
Post-MVP: `video_path`, `video_status`.

## Views — unchanged
`trip_card_view` (+stars, +expense_total as later migrations land),
`profile_stats_view`, `expense_summary_view`. All `security_invoker`.

## Storage — unchanged
`trip-photos` `{user_id}/{trip_id}/{photo_id}.{ext}` owner-only; `avatars`.

## Seeds — unchanged
Checklist suggestions (5 categories, essentials flagged); bonus templates;
8 achievement templates.

## Open questions

1. Country derivation for `country_code` (free-text "where" → code): user picks /
   geocode / nullable-MVP fallback. Globetrotter counts non-null codes.
2. Cover photo upload at creation (design's "Upload photo" pill) — in MVP or
   bundled-assets-only + "Set as cover" later?
3. EUR-only confirmed acceptable for launch market?

## Resolved (v4 additions first)

- Bonus mechanic v2: daily tray (2/day, day-one 3 + starter), silent expiry,
  opt-in stretch, streak-saver ✦2, milestones ✦5 — tables reshaped.
- Weather template slots: post-MVP. No daily bonus-star cap in MVP.
- Notifications: local-only (flutter_local_notifications), no push in MVP.

## Resolved (earlier)

- Redesign's variable quest stars → REJECTED (flat 1, no column).
- Redesign's photo ✦1 → REJECTED (photo = 2).
- Redesign's alternate vibes + achievement names → REJECTED (v2 lists stand).
- Quests checkable (`completed_at`); deletion keeps stars (trip_id set null).
- Compare + Photo detail: in MVP, no schema impact beyond `use_in_wrap_up`.
