# TripJ — Data Model (MVP)

Derived from `functionality.md`. Postgres (Supabase) — all schema changes ship as
migrations in `supabase/migrations/`, RLS enabled on every table.

## Design decisions (read first)

1. **No `trip_days` table.** Days are derived from the trip's date range. Child records
   (quests, notes, photos) carry a `day_date date` column instead of a FK to a days
   table. Editing trip dates never requires re-syncing day rows; the UI computes
   "Day N" as `day_date - start_date + 1`.
2. **No stored trip status.** Upcoming / current / finished is derived from
   `start_date` / `end_date` vs today, in a view (`trip_card_view`) or client-side.
3. **Points are a ledger, not a counter.** Every earn event is a row; the balance is a
   SUM. Auditable, idempotent, and ready for future spending.
4. **Owner-only access.** No sharing in MVP, so every RLS policy reduces to "the trip's
   owner". Child tables check ownership via the parent trip.
5. **Goals as `text[]`** on the trip (checked ≤ 3) rather than a join table — the list
   is a fixed app-level enum; a join table adds nothing while there's no discovery.

## Tables

### `profiles`
| column | type | notes |
|---|---|---|
| `id` | `uuid` PK | = `auth.users.id`, created via signup trigger |
| `username` | `text` | nullable for MVP |
| `avatar_url` | `text` | nullable |
| `created_at` | `timestamptz` | default `now()` |

RLS: select/update own row (`id = auth.uid()`). Insert via trigger only.

### `trips`
| column | type | notes |
|---|---|---|
| `id` | `uuid` PK | client-generated (uuid pkg) so storage paths can exist pre-insert |
| `user_id` | `uuid` FK → profiles | owner |
| `name` | `text` | |
| `destination` | `text` | single free-text field (MVP) |
| `start_date` | `date` | nullable (steps are skippable) |
| `end_date` | `date` | nullable, `check (end_date >= start_date)` |
| `goals` | `text[]` | default `{}`, `check (cardinality(goals) <= 3)` |
| `cover_image_path` | `text` | storage path, nullable |
| `created_at` / `updated_at` | `timestamptz` | |

RLS: all four operations `user_id = auth.uid()`.
Free-tier 3-trip limit: enforced in app for MVP (revisit server-side before launch).

### `quests` (plan items)
| column | type | notes |
|---|---|---|
| `id` | `uuid` PK | |
| `trip_id` | `uuid` FK → trips (cascade) | |
| `day_date` | `date` | which day of the trip |
| `time` | `time` | nullable |
| `title` | `text` | |
| `place_text` | `text` | optional location/details line |
| `position` | `int` | order within the day |
| `completed_at` | `timestamptz` | nullable — set when checked off during the trip (To Do) |
| `created_at` | `timestamptz` | |

RLS (all ops): `exists (select 1 from trips t where t.id = trip_id and t.user_id = auth.uid())`.
Same pattern for every trip-child table below.

### `day_notes`
| column | type | notes |
|---|---|---|
| `id` | `uuid` PK | |
| `trip_id` | `uuid` FK → trips (cascade) | |
| `day_date` | `date` | |
| `content` | `text` | |
| `created_at` / `updated_at` | `timestamptz` | |
| | | `unique (trip_id, day_date)` — one note per day, edited in place |

### `photos`
| column | type | notes |
|---|---|---|
| `id` | `uuid` PK | client-generated before upload |
| `trip_id` | `uuid` FK → trips (cascade) | |
| `day_date` | `date` | nullable (gallery uploads without a day) |
| `storage_path` | `text` | in `trip-photos` bucket |
| `caption` | `text` | nullable |
| `lat` / `lng` | `double precision` | nullable — auto geotag |
| `place_text` | `text` | nullable — user-entered place tag |
| `people_tags` | `text[]` | default `{}` — free-text names (no user linking in MVP) |
| `taken_at` | `timestamptz` | from EXIF when available |
| `created_at` | `timestamptz` | |

### `checklist_items`
| column | type | notes |
|---|---|---|
| `id` | `uuid` PK | |
| `trip_id` | `uuid` FK → trips (cascade) | |
| `title` | `text` | from suggestion or custom |
| `is_checked` | `bool` | default false |
| `position` | `int` | |

### `checklist_suggestions` (global, seeded)
| column | type | notes |
|---|---|---|
| `id` | `bigint` PK | |
| `title` | `text` | e.g. Passport, Swimsuit… |

RLS: select for any authenticated user; no writes from clients. Seeded by migration.

### `bonus_task_templates` (global, seeded)
| column | type | notes |
|---|---|---|
| `id` | `bigint` PK | |
| `title` | `text` | "Take a photo of yourself packing…" |
| `points` | `int` | star reward |
| `duration_hours` | `int` | countdown window (12/7/4) |
| `trigger` | `text` | when it's issued (e.g. `pre_trip`, `trip_day`) — app-interpreted |

RLS: select authenticated; no client writes.

### `bonus_task_assignments`
| column | type | notes |
|---|---|---|
| `id` | `uuid` PK | |
| `trip_id` | `uuid` FK → trips (cascade) | |
| `template_id` | `bigint` FK → bonus_task_templates | |
| `issued_at` | `timestamptz` | |
| `expires_at` | `timestamptz` | issued_at + duration |
| `status` | `text` | `pending` / `completed` / `dismissed` / `expired`, check constraint |
| `photo_id` | `uuid` FK → photos | nullable — proof photo |
| `completed_at` | `timestamptz` | nullable |

### `points_ledger`
| column | type | notes |
|---|---|---|
| `id` | `bigint` PK | |
| `user_id` | `uuid` FK → profiles | |
| `trip_id` | `uuid` FK → trips (set null) | survives trip deletion |
| `source` | `text` | `bonus_task` / `photo` / `note` / `day_logged` / … check constraint |
| `source_id` | `uuid` | nullable — the row that earned it (idempotency guard) |
| `points` | `int` | positive in MVP |
| `created_at` | `timestamptz` | |
| | | `unique (user_id, source, source_id)` — no double-earning |

Awarding goes through an **RPC** (`award_points`) or trigger, not direct client inserts —
clients must not write their own point values. RLS: select own rows only.

**Point values (MVP):**

| action | source | points |
|---|---|---|
| Add a day note | `note` | 1 |
| Add a photo | `photo` | 2 — photos are weighted higher on purpose: more photos → better memory |
| Complete a quest | `quest` | 1 (proposal — confirm) |
| Complete a bonus task | `bonus_task` | per `bonus_task_templates.points` (varies by task) |

Values live server-side (inside the `award_points` RPC / a config table), never in the
client, so they can be tuned without an app release.

### `memories`
| column | type | notes |
|---|---|---|
| `trip_id` | `uuid` PK, FK → trips (cascade) | one memory per trip |
| `content` | `jsonb` | the **screenplay**: ordered blocks (map segment, photo, narrative text, chapter title…) produced by the AI generation edge function; user edits update it |
| `generated_at` | `timestamptz` | |
| `published_at` | `timestamptz` | nullable — "published" privately |

Generation: edge function `generate_memory` (trip data + photo metadata → Anthropic
API → screenplay JSONB). API keys live in the edge function only. The app renders
`content` live (Flutter + Mapbox + cached photos) — no video file in MVP.

Post-MVP (paid MP4 export — columns added by a future migration, listed here so the
shape is known): `video_path text` (in a `memories` bucket,
`{user_id}/{trip_id}.mp4`), `video_status text` (`rendering` / `ready` / `failed`),
rendered by an edge function calling a template-video API from the same `content`.

## Views

- `trip_card_view` — trips + derived `status` (`upcoming`/`current`/`finished`),
  photo count, points earned for the trip. Home screen reads this instead of joining
  client-side.

## Storage (buckets)

| bucket | path pattern | policy |
|---|---|---|
| `trip-photos` | `{user_id}/{trip_id}/{photo_id}.{ext}` | owner-only read/write via first path segment = `auth.uid()` |
| `avatars` | `{user_id}/avatar.{ext}` | owner write, public read (or owner-only in MVP) |

Client compresses images before upload; `photo_id` generated client-side so the
storage path exists before the DB insert (per coding guidelines doc 04).

## Signup trigger

Migration creates `handle_new_user()` on `auth.users` insert → inserts `profiles` row.

## Seed data (in migrations)

- `checklist_suggestions`: the common-items list.
- `bonus_task_templates`: initial task set from functionality.md §7.

## Open questions

1. Quest completion points = 1 is a proposal — confirm or adjust.

## Resolved

- Quests can be checked off during the trip → `quests.completed_at` added.
- Point values: note = 1, photo = 2 (weighted to encourage photos), bonus tasks per
  template.
- Deleting a trip **keeps** earned points — ledger rows survive with `trip_id` set to
  null.
