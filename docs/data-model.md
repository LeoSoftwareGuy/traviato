# Trevy — Data Model (MVP, v2 post-redesign)

Derived from `functionality.md` v3. Postgres (Supabase) — all schema changes ship as
migrations in `supabase/migrations/`, RLS enabled on every table, **explicit grants
required** (project has auto-expose disabled).

Naming: the DB keeps the technical term **`trips`** (UI copy says "memory") to avoid
colliding with the wrap-up artifact. The generated screenplay lives in **`wrap_ups`**
(renamed from the old `memories` table).

## Design decisions (unchanged unless noted)

1. **No `trip_days` table** — child records carry `day_date date`; "Day N" =
   `day_date - start_date + 1`.
2. **No stored trip status** — derived from dates in `trip_card_view`/client.
3. **Points are a ledger** (UI: "stars") — balance is a SUM; awards via RPC only.
4. **Owner-only access** — every policy reduces to the trip's owner.
5. **Vibes as `text[]`** on the trip (was `goals`; new fixed list of 10).
6. **NEW: achievements are server-awarded** — clients never insert their own.
7. **NEW: expenses are plain owner rows** — no server logic needed in MVP.

## Tables

### `profiles`
| column | type | notes |
|---|---|---|
| `id` | `uuid` PK | = `auth.users.id`, signup trigger |
| `username` | `text` | nullable |
| `bio` | `text` | nullable — NEW (profile screen) |
| `avatar_url` | `text` | nullable |
| `created_at` | `timestamptz` | "Joined March 2024" on profile |

RLS: select/update own row. Insert via trigger only.

### `trips`
| column | type | notes |
|---|---|---|
| `id` | `uuid` PK | client-generated |
| `user_id` | `uuid` FK → profiles | owner |
| `name` | `text` | |
| `destination` | `text` | "Where did it happen?" free text |
| `country_code` | `text` | nullable, ISO-3166-1 alpha-2 — feeds Countries stat & Globetrotter (see open questions) |
| `start_date` | `date` | nullable |
| `end_date` | `date` | nullable, `check (end_date >= start_date)` |
| `vibes` | `text[]` | default `{}` — fixed list of 10 (Romantic, Adventure, Cultural, Chill, Foodie, Road trip, Wellness, Wildlife, Nightlife, Photography) |
| `cover_image_path` | `text` | nullable |
| `created_at` / `updated_at` | `timestamptz` | |

RLS: all ops `user_id = auth.uid()`. Grants: select/insert/update/delete to
`authenticated`. Free-tier 3-memory limit: app-side for MVP.

### `quests` — unchanged
`id, trip_id (cascade), day_date, time, title, place_text, position, completed_at,
created_at`. RLS via parent trip (pattern for all child tables):
`exists (select 1 from trips t where t.id = trip_id and t.user_id = auth.uid())`.

### `day_notes` — unchanged
`id, trip_id (cascade), day_date, content, created_at/updated_at`,
`unique (trip_id, day_date)`.

### `photos` — unchanged
`id (client-generated), trip_id (cascade), day_date, storage_path, caption, lat/lng,
place_text, people_tags text[], taken_at, created_at`.

### `checklist_items` — upgraded
| column | type | notes |
|---|---|---|
| `id` | `uuid` PK | |
| `trip_id` | `uuid` FK → trips (cascade) | |
| `title` | `text` | |
| `category` | `text` | NEW — e.g. `travel_essentials`, `clothing_shoes` (check constraint; list per seeded categories) |
| `is_essential` | `bool` | NEW — default false ("Essential" tag) |
| `is_checked` | `bool` | default false |
| `position` | `int` | |

### `checklist_suggestions` (global, seeded) — upgraded
`id, title, category, is_essential`. Select for authenticated; no client writes.

### `expenses` — NEW
| column | type | notes |
|---|---|---|
| `id` | `uuid` PK | |
| `trip_id` | `uuid` FK → trips (cascade) | |
| `title` | `text` | "Sunset dinner in Oia" |
| `amount` | `numeric(10,2)` | `check (amount > 0)`; EUR only in MVP |
| `category` | `text` | check: `food_drinks` / `transport` / `accommodation` / `activities` / `shopping` / `other` |
| `spent_on` | `date` | |
| `created_at` | `timestamptz` | |

RLS via parent trip. Totals/compare aggregate client-side or via
`expense_summary_view` (per-trip totals — used by the Expenses tab list).

### `bonus_task_templates` / `bonus_task_assignments` — unchanged
Templates seeded (title, points, duration_hours, trigger). Assignments per trip with
`status` (pending/completed/dismissed/expired), `expires_at`, proof `photo_id`,
`completed_at`.

### `points_ledger` — unchanged (UI term: stars)
`id, user_id, trip_id (set null), source (note/photo/quest/bonus_task), source_id,
points, created_at`, `unique (user_id, source, source_id)`.
Values (server-side, in `award_points` RPC): note 1 · photo 2 · quest 1 ·
bonus per template.

### `achievement_templates` (global, seeded) — NEW
| column | type | notes |
|---|---|---|
| `id` | `bigint` PK | |
| `code` | `text` unique | `first_adventure`, `globetrotter`, `century`, `star_collector`, `shutterbug`, `storyteller`, … |
| `title` / `description` | `text` | |
| `metric` | `text` | what's counted: `trips` / `countries` / `days_logged` / `stars` / `photos` / `notes` |
| `target` | `int` | e.g. Globetrotter = 10 countries |
| `position` | `int` | display order |

RLS: select authenticated; no client writes.

### `user_achievements` — NEW
| column | type | notes |
|---|---|---|
| `user_id` | `uuid` FK → profiles | PK part |
| `template_id` | `bigint` FK → achievement_templates | PK part |
| `earned_at` | `timestamptz` | |

Composite PK. Awarded by a server-side `check_achievements` RPC (called after
point-earning actions; compares metrics vs targets and inserts earned rows —
idempotent via PK). Progress toward unearned achievements is computed from a
`profile_stats_view`, not stored. RLS: select own rows; no client insert.

### `wrap_ups` — renamed from `memories`
| column | type | notes |
|---|---|---|
| `trip_id` | `uuid` PK, FK → trips (cascade) | one wrap-up per memory |
| `content` | `jsonb` | the screenplay (ordered blocks) from the `generate_wrap_up` edge function (Anthropic API; keys in function secrets only) |
| `generated_at` | `timestamptz` | |
| `published_at` | `timestamptz` | nullable |

Post-MVP export columns (future migration): `video_path`, `video_status`.

## Views

- `trip_card_view` — trips + derived status, photo count, stars, duration; NEW:
  expense total. Feeds Home + Expenses list.
- `profile_stats_view` — per-user: memories count, places count (distinct place
  tags), countries count (distinct `country_code`), days logged, stars total.
  Feeds Home stats bar, profile stats, and achievement progress.
- `expense_summary_view` — per-trip totals + item counts for the Expenses tab.

## Storage — unchanged
`trip-photos` bucket `{user_id}/{trip_id}/{photo_id}.{ext}` (owner-only via first
path segment); `avatars` bucket.

## Signup trigger — unchanged
`handle_new_user()` → profiles row.

## Seed data (migrations)
- `checklist_suggestions` with categories + essential flags.
- `bonus_task_templates` per functionality.md §10.
- `achievement_templates`: the 8 designed badges.

## Open questions

1. **Country derivation**: `country_code` from the free-text "where" field — user
   picks country in UI later, or geocode? MVP fallback: nullable, filled when the
   place field gets structured input; Globetrotter progress counts non-null codes.
2. Vibe count limit — old design capped goals at 3; new single-screen form shows no
   cap. Currently NO db check; confirm desired UX.
3. Expense currency symbol is € in design — confirm EUR-only MVP is acceptable for
   launch market.

## Resolved (carried over)

- Quests checkable during the trip (`completed_at`).
- Star values: note 1 / photo 2 / quest 1 / bonus per template; server-side only.
- Deleting a memory keeps earned stars (`trip_id` set null in ledger).
