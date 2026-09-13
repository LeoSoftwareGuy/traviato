# Trevy — Database & Backend Reference

Generated from the actual migrations in `supabase/migrations/` and the
`supabase/functions/generate_wrap_up/` edge function (source of truth), not
from the planning docs — where those disagree, a note says so.

## Entity relationship diagram

```mermaid
erDiagram
    AUTH_USERS ||--|| PROFILES : "id = id"
    PROFILES ||--o{ TRIPS : "user_id"
    TRIPS ||--o{ QUESTS : "trip_id"
    TRIPS ||--o{ CHECKLIST_ITEMS : "trip_id"
    TRIPS ||--o{ DAY_NOTES : "trip_id"
    TRIPS ||--o{ PHOTOS : "trip_id"
    TRIPS ||--o{ EXPENSES : "trip_id"
    TRIPS ||--o{ BONUS_TASK_ASSIGNMENTS : "trip_id"
    TRIPS |o--o| WRAP_UPS : "trip_id (1:1)"
    TRIPS |o--o{ POINTS_LEDGER : "trip_id (nullable, SET NULL)"

    PROFILES ||--o{ POINTS_LEDGER : "user_id"
    PROFILES ||--o{ USER_ACHIEVEMENTS : "user_id"

    BONUS_TASK_TEMPLATES ||--o{ BONUS_TASK_ASSIGNMENTS : "template_id"
    PHOTOS |o--o{ BONUS_TASK_ASSIGNMENTS : "photo_id (nullable)"

    ACHIEVEMENT_TEMPLATES ||--o{ USER_ACHIEVEMENTS : "template_id"

    CHECKLIST_SUGGESTIONS {
        bigint id PK
        text title
        text category
        bool is_essential
    }

    PROFILES {
        uuid id PK
        text username
        text bio
        text avatar_url
    }

    TRIPS {
        uuid id PK
        uuid user_id FK
        text name
        date start_date
        date end_date
        text[] vibes
        text cover_image_path
    }

    QUESTS {
        uuid id PK
        uuid trip_id FK
        date day_date
        text title
        int position
        timestamptz completed_at
    }

    CHECKLIST_ITEMS {
        uuid id PK
        uuid trip_id FK
        text category
        bool is_essential
        bool is_checked
    }

    DAY_NOTES {
        uuid id PK
        uuid trip_id FK
        date day_date
        text content
    }

    PHOTOS {
        uuid id PK
        uuid trip_id FK
        date day_date
        text storage_path
        text[] people_tags
    }

    EXPENSES {
        uuid id PK
        uuid trip_id FK
        numeric amount
        text category
        date spent_on
    }

    POINTS_LEDGER {
        bigint id PK
        uuid user_id FK
        uuid trip_id FK
        text source
        uuid source_id
        int points
    }

    BONUS_TASK_TEMPLATES {
        bigint id PK
        text code
        text phase
        text kind
        int points
    }

    BONUS_TASK_ASSIGNMENTS {
        uuid id PK
        uuid trip_id FK
        bigint template_id FK
        date day_date
        uuid photo_id FK
        timestamptz completed_at
    }

    ACHIEVEMENT_TEMPLATES {
        bigint id PK
        text code
        text metric
        int target
    }

    USER_ACHIEVEMENTS {
        uuid user_id FK
        bigint template_id FK
        timestamptz earned_at
    }

    WRAP_UPS {
        uuid trip_id PK_FK
        jsonb content
        timestamptz generated_at
        timestamptz published_at
    }
```

**Global catalog tables** (no FK in, select-only for clients, seeded):
`checklist_suggestions`, `bonus_task_templates`, `achievement_templates`.
They're read by feature code but never referenced by FK from other tables —
shown unattached above except where a real FK exists
(`bonus_task_templates`/`achievement_templates` are FK'd *from*
`bonus_task_assignments`/`user_achievements`).

---

## Tables

### `profiles`
`id` PK (FK → `auth.users.id` cascade) · `username` · `bio` · `avatar_url` ·
`created_at`.
RLS: select/update own only. No insert/delete policy — rows are created only
by the `handle_new_user()` trigger.

### `trips`
`id` (client-generated) · `user_id` FK → profiles cascade · `name` · `destination` ·
`country_code` (ISO-3166-1 alpha-2) · `start_date`/`end_date` (check end≥start) ·
`vibes text[]` default `{}` · `cover_image_path` (`asset:<id>` bundled cover,
or a `trip-photos` storage path — see Storage section) ·
`created_at`/`updated_at` (auto via trigger).
RLS: full owner-only CRUD. Index: `trips_user_id_idx` on `user_id` (#131 —
added 2026-09-13; every RLS-filtered read of this table was previously an
unindexed sequential scan, unlike every child table).

### `quests`
`id` · `trip_id` FK cascade · `day_date` · `time` · `title` · `place_text` ·
`position` · `completed_at`. No per-quest points column — stars are flat via
`award_points`. Index (trip_id, day_date). RLS: owner-via-parent-trip, all ops.

### `checklist_items`
`id` · `trip_id` FK cascade · `title` · `category` (5-way check:
travel_essentials/clothing_shoes/toiletries_health/gadgets_tech/nice_to_haves) ·
`is_essential` · `is_checked` · `position`. Owner-via-parent-trip, all ops.

### `checklist_suggestions` (global, seeded)
`id` · `title` · `category` (same check) · `is_essential`. Select-only for
authenticated. Seeded: 35 rows (8/7/8/7/7 across the 5 categories).

### `day_notes`
`id` · `trip_id` FK cascade · `day_date` · `content` · `created_at`/`updated_at`.
**unique(trip_id, day_date)** — one note per day. Owner-via-parent-trip, all ops.

### `photos`
`id` (client-generated, drives storage path `{user_id}/{trip_id}/{photo_id}.{ext}`) ·
`trip_id` FK cascade · `day_date` · `storage_path` · `caption` · `lat`/`lng` ·
`place_text` · `people_tags text[]` · `taken_at` · `created_at`.
Owner-via-parent-trip, all ops.
> No `use_in_wrap_up` column exists — that M3-8 idea was abandoned (see
> memory), docs describing it are stale.

### `expenses`
`id` · `trip_id` FK cascade · `title` · `amount numeric(10,2) > 0` (EUR-only,
no currency column) · `category` (6-way check) · `spent_on`. Owner-via-parent-trip.

### `points_ledger`
`id` bigint · `user_id` FK → profiles cascade · `trip_id` FK → trips **SET NULL**
on delete · `source` (note/photo/quest/bonus_task) · `source_id` · `points > 0`.
**unique(user_id, source, source_id)** — idempotency guard.
RLS: select-own only. **No write policy/grant at all** — writable only through
`award_points()`.

### `bonus_task_templates` (global, seeded) — reshaped 2026-08-29
`id` · `code` unique · `title` · `detail` (nullable, renamed from `description`) ·
`points > 0` · `phase` (arrival/middle/departure/anytime) · `kind`
(regular/starter/stretch/milestone/streak_saver).
Dropped from original shape: `duration_hours`, `trigger`.
Seeded: 35 templates — 13 anytime, 8 middle, 3 arrival, 3 departure, 2 starter,
3 stretch, 3 milestone, 1 streak_saver.

### `bonus_task_assignments` — reshaped 2026-08-29
`id` · `trip_id` FK cascade · `template_id` FK → bonus_task_templates ·
`day_date` · `photo_id` FK → photos **SET NULL** on delete · `completed_at` ·
`created_at`.
Dropped from original shape: `status`, `expires_at` — expiry is now **derived**:
`expired ⇔ day_date < today AND completed_at IS NULL` (never stored/rendered
as a failure state; streak_saver assignments stay live past their day).
**unique(trip_id, template_id, day_date)** supports the idempotent client-side
deterministic daily draw.

### `achievement_templates` (global, seeded)
`id` · `code` unique · `title` · `description` · `metric` (trips/countries/
days_logged/stars/photos/notes) · `target > 0` · `position`.
Seeded — all 8: `first_adventure` (trips≥1) · `globetrotter` (countries≥10) ·
`century` (days_logged≥100) · `star_collector` (stars≥250) · `shutterbug`
(photos≥50) · `storyteller` (notes≥20) · `jetsetter` (trips≥5) · `legend`
(stars≥1000).

### `user_achievements`
`user_id` FK → profiles cascade · `template_id` FK → achievement_templates ·
`earned_at`. PK (user_id, template_id). Select-own only — written only via
`check_achievements()`.

### `wrap_ups`
`trip_id` PK/FK → trips cascade (1:1) · `content jsonb` · `generated_at` ·
`published_at`.
RLS: select-own; update-own grant is **column-scoped to `published_at` only**
— clients can toggle publish state but never write `content`/`generated_at`
(those are edge-function/service-role only; no client insert at all).

---

## Views (all `security_invoker = true`, select → authenticated)

- **`trip_card_view`** — every `trips` column + computed `status`
  (undated/upcoming/current/finished from dates vs. today) + `duration_days` +
  `photo_count` + `stars` (SUM points_ledger) + `expense_total` (SUM expenses)
  + `wrap_up_published_at` (left join wrap_ups) + `quest_count` (COUNT quests
  — #131, added at the end since `create or replace view` can't insert a
  column mid-list without renaming every column after it; replaced Home's
  per-card `questCountForTripProvider`, which fetched every full quest row
  just to count them).
- **`profile_stats_view`** — per profile: `memories_count`, `places_count`
  (distinct place_text across quests ∪ photos), `countries_count`,
  `days_logged` (distinct day_date across day_notes ∪ photos), `stars_total`,
  `photos_count`, `notes_count`.
- **`expense_summary_view`** — per trip: `total_amount`, `item_count`.

---

## RPCs / functions

- **`handle_new_user()`** — trigger (`after insert on auth.users`), SECURITY
  DEFINER. Creates the `profiles` row; sources username/avatar from
  email/password, Google, or Apple OAuth metadata shapes.
- **`set_updated_at()`** — generic trigger, sets `updated_at = now()` (used by
  `trips`, `day_notes`).
- **`award_points(p_source, p_source_id, p_trip_id) → int`** — SECURITY
  DEFINER. Verifies trip ownership + that the source row is real, derives the
  point value **server-side** (note=1, photo=2, quest=1 flat, bonus_task=
  template.points — never trusts the client), idempotent insert
  (`on conflict do nothing`), returns the trip's new star total.
- **`check_achievements() → text[]`** — SECURITY DEFINER. Computes all 8
  metrics for the caller, idempotently inserts newly-earned
  `user_achievements`, returns the newly-earned codes.
- **`shift_trip_dates(p_trip_id, p_delta_days) → trips`** — SECURITY DEFINER.
  Atomically shifts the trip's start/end dates and every quest's `day_date`
  by the same delta. **Does not re-date `day_notes` or `photos`** — a known
  gap, not yet scoped into an issue.

---

## Edge function: `generate_wrap_up`

Files: `index.ts` (bootstrap) · `handler.ts` (request logic) · `gather.ts`
(data fetch) · `ai_fields.ts` (AI output schema) · `anthropic.ts` (LLM call) ·
`assemble.ts` (deterministic content builder) · `content.ts` (types).

1. POST-only; requires `Authorization` header; requires `trip_id` in body.
2. Verifies the caller's JWT via an anon-key client (`auth.getUser()`).
3. Looks up the trip via a **service-role** client; 403 if not the owner.
4. **Idempotent short-circuit**: if `wrap_ups.content` already exists, returns
   it without calling Anthropic.
5. `gather.ts` fetches: trip fields, day_notes, up to 500 photos, up to 500
   completed bonus_task_assignments (joined with template title/points), all
   points_ledger rows (summed → `starsEarned`), and the most recent
   achievement earned since trip start. **Quests are deliberately never
   fetched** (no route/map chapter — see "no Mapbox, ever" decision).
6. Calls Anthropic (`claude-sonnet-5`, forced structured tool-call output, 1
   retry) with only trip name/destination/vibes, day count, truncated day
   notes, and the latest achievement — it generates just 4 narrative fields
   (`invitation.line2`, 3 `bridges`, nullable `unlock.reason`,
   `keepsake.closing_quote`). No photo bytes/vision — metadata-only.
7. `assemble.ts` deterministically builds the rest of `WrapUpContent`
   (dates, moments from bonus/journal photos taken essentially at random —
   no curation step, `use_in_wrap_up` was abandoned — flurry leftovers,
   footnote counts, unlock block, keepsake title split). No randomness, so
   reruns are stable.
8. Upserts `wrap_ups` (content + generated_at) via service client; returns
   `{content, generated_at}`.

---

## Storage buckets

Two buckets, both private, both RLS-gated purely on the first path segment
being the caller's own `auth.uid()` — no dependency on `public.trips` rows,
so an upload never races the trip/photo row existing. Owner-only
select/insert/delete; **no update policy on either** — a replace is always
delete-then-reupload, never an in-place mutation.

- **`trip-photos`** (private) — two path shapes share this one bucket:
  - `{user_id}/{trip_id}/{photo_id}.{ext}` — a journal photo (`photos.storage_path`).
  - `{user_id}/{trip_id}/cover.jpg` — a **custom-uploaded trip cover**
    (`_coverStoragePath()` in `supabase_trip_remote_data_source.dart`). Fixed,
    reserved filename per trip so a re-upload overwrites in place rather than
    accumulating objects; `uploadCoverImage()` does a best-effort delete of
    the old object first, then uploads the new bytes. Read back via
    `createSignedUrl(..., 3600)` (1-hour TTL, re-signed per screen load) —
    never a public URL, since the bucket is private.
  - Bundled covers (`trips.cover_image_path = 'asset:<id>'`) **never touch
    this bucket at all** — they render from a local Flutter asset by id.
- **`avatars`** (private) — `{user_id}/avatar.jpg`, one stable object per
  user, same replace-by-reupload convention.

---

## `service_role` grants

By default this project grants access only to `authenticated` (auto-expose
disabled) — `service_role` bypasses RLS but **not** Postgres's own GRANT
system, so the edge function's service-role client needs explicit grants:

- **2026-09-05** — select on `trips`, `quests`, `day_notes`, `photos`,
  `user_achievements`, `achievement_templates`; select+insert+update on
  `wrap_ups`. (`quests` grant is unused — `gather.ts` never queries it.)
- **2026-09-12** — select on `bonus_task_assignments`,
  `bonus_task_templates`, `points_ledger` (added for `gather.ts`'s bonus-task
  and stars queries, incl. the embedded-join requirement that both sides of a
  PostgREST join have SELECT).

**Recurring gotcha**: any future PR that adds a new table to `gather.ts`'s
queries must add a matching `grant select on public.<table> to service_role;`
migration in the *same* PR, or `generate_wrap_up` fails with a
"permission denied for table X" error.
