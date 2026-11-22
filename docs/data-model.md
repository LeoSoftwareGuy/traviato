# Storyni — Data Model (MVP, v4)

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
`id (=auth.users.id), username?, bio?, avatar_url?, created_at, language?,
dictation_language?` (`language` is `en`/`ru` — no Estonian UI, #245 —
NULL = follow the device, #236; `dictation_language` is `en`/`ru`/`et`, NULL
= not chosen yet, #218).
RLS: select/update own; insert via trigger.

### `trips`
`id uuid PK (client-generated), user_id FK, name, destination?, country_code?
(ISO-3166-1 alpha-2), start_date, end_date (required since #270; check >= start), vibes text[]
default {}, cover_image_path?, created_at, updated_at`.
RLS owner-only, all ops. Free-tier 3-memory limit app-side.
**Manage sheet edit dates** (#271): `set_trip_dates` RPC — quests move with the
start date; notes/photos/bonus assignments keep their `day_date`; rows outside
the new range are deleted after a two-step warning. No schema change.

### `quests`
`id, trip_id (cascade), day_date, time?, title, place_text?, position,
completed_at?, created_at`. **No per-quest points column** (flat ✦1 rejected the
mockup's variable values). RLS via parent trip; index (trip_id, day_date).

### `journal_notes` (#397, #400)
`id uuid PK (client-generated), trip_id (cascade), day_date (logical day),
taken_at, edited_at, content (non-blank), dictated bool, photo_id? → photos
(on delete set null; same trip, checked in RLS), legacy bool, created_at`.
Many notes per day, each saved by its own Done and shown at `taken_at`.
`day_date` is decided by the app when the note is saved, with the shared
**logical-day rule** (`lib/core/utils/logical_day.dart`): an item from
00:00 to before 08:00 stays on the previous item's day unless there was a
gap of ≥ 4 h. Stats, achievements and the film just read `day_date`.
An update trigger keeps `trip_id`, `taken_at` and `legacy`, and stamps
`edited_at`. RLS owner-only via the trip; indexes (trip_id, taken_at) and
photo_id. Stars: ✦1 per new note, at most 3 per day (counted in
`points_ledger.day_date`); edits and deletes never change stars.

### `day_notes` — dropped (#406)
The old one-note-per-day table (`unique (trip_id, day_date)`). #400 copied
every non-empty row into `journal_notes` as one `legacy` note **with the
same id** (ledger rows, director plans and kept films keep pointing at it),
`taken_at = edited_at = updated_at`, and made it read-only; #406 dropped it.

### `photos`
`id (client-generated), trip_id (cascade), day_date?, storage_path, caption?,
lat?, lng?, place_text?, people_tags text[] default {}, taken_at?, created_at`.
Photo detail's tagging edits `place_text` / `people_tags` / `caption` — no new
columns. **Film pick** (#294): `use_in_wrap_up bool?` — null = Auto (the
generator decides), true = Always (a main moment first), false = Leave out
(never in the film) — plus `use_in_wrap_up_set_at timestamptz?`, stamped by a
trigger when the pick changes; newer than a kept film's `generated_at` means
"Photos changed · Rebuild film".

### `checklist_items` / `checklist_suggestions`
As v2: category check over `travel_essentials, clothing_shoes, toiletries_health,
gadgets_tech, nice_to_haves`; `is_essential`; suggestions seeded per category.
Items seeded from a suggestion carry its `suggestion_code` (#285) and render in
the current UI language; custom items (code null) keep their `title`.

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
### `points_ledger` — values in `award_points` RPC; `trip_id` cascades, so deleting a memory deletes its stars (#247)
`day_date?` (#400): a note row's day, for the 3-note-stars-a-day cap. A
deleted note's row stays, so deleting and rewriting can't farm stars;
`set_trip_dates` removes note stars by this day.
### `achievement_templates` / `user_achievements` — unchanged (seeded 8:
first_adventure, globetrotter, century, star_collector, shutterbug, storyteller
+ 2 per design; `check_achievements` RPC). Storyteller's `notes` metric (and
`profile_stats_view.notes_count`) counts **days with at least one note**
since #400, not notes.

### `wrap_ups` — draft vs frozen (#187)
`trip_id PK/FK cascade, content jsonb (assembled film), generated_at,
published_at?, ai_fields jsonb? (the 4 AI-written fields), ai_input_hash?,
ai_generation_count int default 0`.
- `published_at IS NULL` = **draft**: `generate_wrap_up` rebuilds `content`
  from current photos/notes on every open (no AI cost). Anthropic is called
  only when `ai_input_hash` (name, destination, vibes, day notes, earned
  achievement) changes — at most **4 calls per memory** (1 initial + 3
  regenerations, free and Pro alike); after the cap the last `ai_fields` are
  reused. The row is updated in place, never deleted (that would reset the
  counter).
- `published_at` set = **frozen**: returned as stored, never rebuilt. The
  client prunes references to since-deleted photos at playback. Clients can
  only set `published_at` (column grant), and never back to NULL.
Post-MVP: `video_path`, `video_status`.
- `director jsonb?` (#328, Wrap-Up Film v2): the last director run — the
  `plan_version: 2` film plan or why it fell back, token usage + estimated
  cost. Service-role writes, owner reads (debug Plan inspector). Since
  #380 the plan is two strict Anthropic calls: `emit_film_plan` (classic
  plan, Sky Story, and `special_film`: golden_vows / neon_night / none),
  then — only for golden_vows or neon_night — that film's section alone
  (`section_attempts`; usage `call: "section"`). One tool with every
  film's section compiled to a grammar Anthropic rejected as too large.
  Since #382 code repairs what it can before checking a section instead
  of discarding it: Sky Story Always picks the director left off go into
  free slots, then onto continuation pages (headline null), then in place
  of Auto photos; Neon Night moment photos from another chapter are
  dropped, a moment whose count no longer fits takes a type that does, and
  Always picks join a moment of their chapter. A draft's
  `content` carries `plan_version` + `plan` while that plan still fits.
  Since #345 the record also holds the Sky Story pages (`sky_story`,
  `sky_problems`), every analysed photo's `hero_scores`, and `photo_days` +
  `run_count`: the director re-runs on its own when a memory's photo days
  change, up to 4 runs. It is on for everyone; `WRAP_UP_DIRECTOR_USER_IDS=off`
  switches it off.
- `content.sky` (#345, no schema change): Sky Story's pages on every draft
  with photos — per page its days, photo count, headline (null = the app
  shows the place or "Day N"), hero + up to 4 extra photo ids, the note's id
  and text, and a director's sky line; plus title, first name (signature),
  moment count and up to 60 mosaic photo ids. A page may repeat the
  previous page's days: a continuation page for a day with more Always
  photos than one page shows (#378). The mosaic is Auto photos plus Always
  photos without a page, topped up with Always photos below 12. The
  director's pages while they
  still fit the memory, else built by code. The app plays Sky Story whenever
  it's there. A film kept as a Sky Story keeps it, and "Rebuild film"
  rebuilds its pages too (no AI call); a film kept before Sky Story never
  gains it.
- **Film from the vibes** (#433, no schema change): `film_templates.json`
  (shared with the app's `FilmTemplate`) maps vibes to the played film;
  `content.film_style` names it and `content.film_report`
  (`{source: director|code, repairs[]}`) says how its section was made.
  `director.template`, `<film>_source` and `<film>_repairs` record the
  same for the run; `special_film` is gone from the plan tool (older
  records keep it). One call per memory after the analysis: Sky Story
  memories the plan call, Golden Vows / Neon Night memories their section
  call. A Golden Vows or Neon Night memory always gets its section —
  stored, healed, repaired, else built by code (`codeGoldenVows`,
  `codeNeonNight`) — also with the director off; Sky pages are still built
  for every memory as the app's safety net. Golden Vows gains the
  `romance` occasion. `filmPhotoIds` keeps the film to 60 photos (15+
  Always picks are exactly the film's). `DIRECTOR_VERSION` 3: older
  records re-run once, within the cap.
- **Film length** (#434, no schema change): `content.film_seconds` —
  `filmSeconds(photos)` from `wrap_up_limits.json` (30 s at
  `shortestFilmPhotos` 15 → 75 s at `longestFilmPhotos` 40, shared with
  `WrapUpLimits`) over the film's photos. The content is built to fit it
  (`film_length.ts`: Sky pages capped by length and told to the director
  as `sky_max_pages`; Neon Night chapters, moments, Plan/Note scenes and
  lines; Golden Vows pages by priority, every photo in the heart) and the
  app fits its timelines to it. Written for drafts and rebuilt kept
  films; a kept film without it plays its old pacing.
  `film_lengths.json` holds a 15/25/40-photo memory of each film for the
  app's length test (`write_film_lengths.ts` regenerates it).
- `content.golden_vows` (#346, no schema change): the Golden Vows wedding
  album, only when the director read the memory as a wedding, engagement,
  anniversary or date night and its `golden_vows` section (in `director`,
  with the photos' `orientations`) still fits. It holds the occasion line,
  names (memory title), dates, place, the packing card (up to 5 checked
  checklist items with their `suggestion_code`, else planned quests, else
  none), 2–6 heroes (photo, label, `taken_at`, note = caption or an exact
  excerpt of that day's note), 1–4 chapters of 3 photos with an A/B/C
  layout, a carousel of 6–12 unused photos (or none), up to 200 heart
  photos (#378: those without a hero, chapter or carousel slot, Always
  photos only to top up below 12), the moment count and the end line. Every
  Always photo is a hero, a chapter photo or on the carousel. No section = Sky Story plays.
  A film kept as Golden Vows rebuilds it while the section fits, else plays
  its Sky Story; no kept film gains one. The edge function reads
  `checklist_items` for this (service-role select grant).
- `content.neon_night` (#363, no schema change): the Neon Night party film,
  only when the director read the memory as a party, rave, club night,
  festival, concert or night out and its `neon_night` section (in
  `director`) still fits. It holds the title, start date, place, the plan
  rows (the user's quests with a time: HH:MM, title, done), 1–5 chapters
  (title, photos with `taken_at` — each chapter runs from its first photo
  to the next one's, so new photos join a chapter — the card's typed line as
  an exact excerpt of a note or null, 1–2 moments: split / burst / timeline
  with their photos and a split's place — no peak since #386: an older
  plan's peak plays as a split, burst or timeline, and a timeline is
  filled up to 6 with its chapter's unused photos). Since #390 the content
  merges neighbouring chapters until each has ≥ 8 photos (the first
  one's title, first note line; its first moment plus one timeline of the
  others'), gives each card its own `card_photo_ids` (up to 4, captioned
  first — never a moment's photo), plays a timeline only with ≥ 5 photos
  (else a split or burst), and keeps plan rows only when there are ≥ 3.
  Each chapter photo carries its trimmed `caption` (#387) for the zoom and
  timeline labels, the note scene (an exact
  excerpt, its number among the notes, when written, a background photo) or
  null, the director's headline or null, the first name, the totals and
  `heart_photo_ids` (#378: the Finale's heart, photos without a moment,
  Always photos only to top up below 12; absent in older content = every
  chapter photo). Every Always photo is in a moment or is the note scene's
  photo. Up to 200 photos (more are sampled evenly). The app sends
  `utc_offset_minutes` so the director reads photo times as local times.
  Kept films follow Golden Vows' rules.
- **The real story** (#398, no schema change): notes reach the director
  whole (up to 4000 characters, was 500), and photos and notes carry their
  **logical day** — recomputed from their times on the phone's clock with
  the journal's rule (`logical_day.ts`, a port of the app's), so after
  midnight stays on the evening's day even for rows saved with their
  calendar date. A memory over several days gets **one Neon Night chapter
  per logical day** (neighbouring days grouped past 5) — since #426 one
  per *part* of a day: `nnChapterStarts` also starts a chapter after a
  break of ≥ 2 h within a day when both sides keep ≥ 4 photos (longest
  breaks first, up to 5 chapters); the director sees these as
  `chapter_start` on its photos. Repair rebuilds a plan that folded days
  or parts, keeping the director's titles, moments and lines per part (an
  untitled part: its place, else its first photo's `HH:MM`), and those
  chapters never merge. In content a chapter's card and moments are dealt
  its shown photos in time order (card first), so no scene goes back in
  time; the app plays the excerpts on the moments' photos (#426). Each chapter carries
  `excerpts` (0–4 `{note_id, text, photo_id}` in the plan; in content
  `chapters[].excerpts: [{text, note_id, photo_id, source, score}]`, plus
  `days` and `rejected_excerpts` for the inspector): exact sentences or
  clauses of its notes, scored for detail (numbers, names, food, firsts,
  feelings) over generic summaries ("it was fun", "все устали"), which a
  specific line replaces; code fills up to 2. Each plays over its note's
  photo, else the chapter's photo nearest in time. `note` stays the card's
  line. Strict chronology: moments and their photos in time order, card
  photos are the chapter's earliest free ones. Drug references and
  profanity (EN/RU) never become a title, the headline, the note scene or
  a code-picked line. `director.director_version` (2): an older record
  re-runs once, within the 4-run cap. `journal_notes.legacy` is read so a
  legacy note's edit time never places it.
- **Chosen lines in Sky Story and Golden Vows** (#419, no schema
  change): `content.sky.pages[].excerpts: [{note_id, text}]` — on a page
  with a note, the best lines of its days' notes (`bestLines` in
  `excerpts.ts`: specific only, nothing sensitive, `SKY_LINES_PER_PAGE` ×
  the days' pages, in note order); the app flows them over the days'
  pages instead of the note's leading sentences, and empty means the note
  plays as before. Golden Vows: a hero without a caption or a director's
  excerpt gets its day's best line (`MAX_GV_HERO_LINE_CHARS` 90) in its
  `note`, from a note on that photo first, else its logical day's notes;
  never a line another hero shows. Since #422 a run of Sky pages for the
  same days shares their notes: each line goes on the page whose photos
  are nearest its note in time, best 2 a page, so `excerpts` can be on
  any page of the run. Sky Story groups photos and notes by logical day
  (`onLogicalDays`: a stored day moves at most one day back, onto the
  evening); an untimed photo keeps its stored day; a Neon day chapter
  keeps at most 2 moments (the rest become one timeline).
- **Healing a stored section** (#393, no schema change): when a photo is
  deleted or left out, or a note reworded, after the director ran, the
  `golden_vows` / `neon_night` section is fitted to the memory in code on
  open (no AI call) instead of being discarded — which used to switch the
  film to Sky Story for good, as the director only re-runs when photo days
  change. Neon Night: gone photos leave their moments (which retype), a
  chapter whose first photo is gone starts at its earliest remaining
  moment photo, an emptied chapter folds into the one before, the note
  scene loses a gone photo. Golden Vows: a gone hero is dropped, a gone
  chapter photo is replaced by an unused one that keeps time order, else
  the chapter goes. Lines whose note no longer says those words are
  dropped. Only a section that still breaks the rules falls back.

- **Neon Night dealt by code** (#444, no schema change): `dealChapter`
  fills `card_photo_ids` (4–6, or every photo of a chapter of ≤ 6 with
  `moments: []` — the app plays the card alone) and 1–2 moments typed by
  time spread (`momentFor`); `nnChaptersFor` is gone (length never
  merges chapters). `snapToNote` (excerpts.ts) snaps director lines to the
  note's words; `bringLinePhotos` puts each line's photo in a moment;
  `fallbackNoteMoment` fills the Note scene; a long headline is null.
  `DIRECTOR_VERSION` 4, and `directorIsStale` also when `photo_paths`
  misses a film photo (below the film's photo cap).

- **Neon Night pacing** (#448, no schema change): each moment carries
  `words: [{photo_id, text}]` (at most 3 — the only words it shows; older
  content without it shows every caption) and each chapter `card_zooms`
  (0–2; absent = 2). `note` is the chapter's best line. Timelines hold 6
  (`NN_TIMELINE_ROOM`). `film_lengths.json` gains an ADE-shaped case
  (`ade_fixture.ts`, `case: "ade"`). Since #450 that case plays the
  director's plan as it came back (`adeDirectorPlan`), and the app holds
  every Neon film to 75 s on its own timeline (`NnFit`) whatever the
  content says.

- **Neon Night: code cuts, the director picks** (#454, no schema change;
  replaces #444's director plan and the copy/snap/repair code of
  #382–#452): code builds the film (`neon_slots.ts`, `neon_film.ts`) —
  chapters by logical day and part, every scene's photos, the length
  trims — and lists candidates with stable ids for every slot (`note`,
  `chN.card`, `chN.mK`, `chN.title`, `headline`; up to 8 each, a card
  keeps one line of each note it owns). One `pick_neon_lines` call only
  picks ids; each id is shown with its slot's name (`ch2.card/n:…`) and
  holds only there. `free_title` lets the director write a title (≤ 22)
  or the headline (≤ 18, upbeat), checked for length, language, clock
  times, "Day N", drugs and banned words; it wins over its ids when it
  holds. Anything else takes the slot's top candidate; a title nothing
  fits is "День N" (a later part "День N · вечер"). No words twice in a
  film; the headline may share a name with a title ("Куко Unreal" under
  "На Куко Unreal"), never its whole words, and is never a first name
  alone. `director.neon_night` = `{picks_version: 2, picks}` (older plans
  aren't read) and `director.neon_slots` = per slot its candidates, the
  pick, what plays, `source` (director/code/none) and the reason — the
  Plan inspector shows them. `DIRECTOR_VERSION` 5: older records re-run
  once. `content.neon_night` keeps its shape. Real-data tests:
  `fixtures/ade_amsterdam.json` (exported by
  `tools/export_director_input.ts`) and the director's recorded picks
  (`tools/record_neon_picks.ts`), which also make `film_lengths.json`'s
  `ade` case; `ade_fixture.ts` is gone. Golden Vows follows the same
  pattern later.

- **Neon Night lines on their own photos** (#456, no schema change):
  `buildNeonSlots` gives each note one scene of its chapter (its photo's,
  else the largest share of a scene's photos within 90 min, then the
  nearest photo; the card on a tie or without a time) and lists its lines
  only there — a hard filter, not a score. `MAX_NN_CARD_NOTE_CHARS` 72.
  A moment's words always keep its best caption (`captionRank`: Always,
  then hero score), on top of `maxWords`; for length its line gives way
  to a shorter line of its note, else goes. `NnShape.quietMoments` (the
  last trim step): that many moments, the last chapter's first, show no
  note line. In the app `NnPhoto.captionHidden` keeps a quiet photo's
  caption known, so it never shows its time; NnFit adds steps 8–9 (a
  moment's line to its short clause, then gone) and never drops a
  moment's last caption; extra bars for the target stop at a bar per
  photo. `film_lengths.json` regenerated; the ADE length test loads the
  film's fonts and compares the player's loop with NnFit's measure.

- **Golden Vows: code cuts, the director picks** (#458, no schema
  change; replaces #346's `emit_golden_vows` section and the repair /
  heal / ensure code of #382–#433): `gv_skeleton.ts` cuts the album
  (chapters by logical day and part, never dropped; main pages; prints;
  carousel; the occasion with the word that set it), `gv_slots.ts` lists
  candidates per slot (`occasion`, `mainK.label`, `mainK.note` — fixed to
  a caption —, `chN.title`, `carousel.title`, `finale`), `gv_film.ts`
  builds `content.golden_vows` (same shape) and trims it past 75 s.
  Shared with Neon in `film_slots.ts`: ids, lines, names, a note's scene,
  picks, the chooser, day titles. One `pick_golden_vows_lines` call;
  `director.golden_vows = {picks_version: 2, picks}` (older sections
  aren't read), plus `gv_slots`, `gv_trims`, `gv_shown`, `gv_unlisted`
  and `gv_trigger` (the inspector). On open the picks are re-applied by id
  to the album cut from the memory now; a photo summary that set the
  occasion comes back from `gv_trigger`. `DIRECTOR_VERSION` 6. In the app
  `GvFit` holds the album to 75 s on its own timeline (carousel, packing,
  main pages, then `chapterDwellScale`). `tools/record_gv_picks.ts`
  records a real answer for an exported memory.

- **Limits** (#432, no schema change): `generate_wrap_up/wrap_up_limits.json`
  (minPhotos 15, maxFilmPhotos 60, minNotes 1, maxNoteLines 12, maxVibes 3)
  is shared with the app's `WrapUpLimits` (a Dart test checks they agree).
  An unkept draft below the minimum gets `422 not_eligible` before any AI
  call; kept films are returned as stored.

### `photo_analysis` (#328)
`photo_id PK/FK photos cascade, trip_id FK cascade, storage_path (the file
analysed — a new path means re-analyse), summary (≤12 words, visible only),
setting, people (0/1/2/small_group/crowd — a count, never identities),
energy, quality, orientation, hero_score 1–5, dup_group?, model,
analysed_at`. Cache of the director's vision call; owner select only,
service-role writes.

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
- Quests checkable (`completed_at`). Deleting a memory **removes its stars**
  (ledger `trip_id` cascades, #247; was set null). Unlocked achievements stay;
  rows orphaned before #247 stay too.
- Compare + Photo detail: in MVP, no schema impact beyond `use_in_wrap_up`.
