# Trevy — Issue Backlog (MVP, v2 post-redesign)

Order = dependency order. Figma: file **"Leo's team library"**, Page 1.
Issues #1 (done) and #2–#5 keep their GitHub numbers; content below is the
updated scope for anything not yet started. New issues appended.

---

## Milestone 1 — Foundation

### #1 Project scaffold + CI — ✅ DONE

### #2 Supabase wiring + app bootstrap — unchanged
supabase init committed; main.dart skeleton (dotenv, Supabase.initialize,
ProviderScope retry off); supabaseClientProvider; core/errors files;
supabase_constants stub.

### #3 Theme from Figma tokens — UPDATED
Tokens from the NEW design: dark navy background, orange primary, serif display
font for headings (e.g. "New memory") + sans body, card/chip styles. Pull exact
values via Figma MCP from "Leo's team library". No inline colors; golden/widget
test.

### #4 Migration: profiles + signup trigger — UPDATED
profiles per data-model v2 **incl. `bio`**; RLS own-row; explicit grants;
handle_new_user() trigger; db reset passes.

### #5 Auth + guest landing + routing — UPDATED
Figma: `Guest mode screen`, `Register`, `Log in`.
- Guest landing = the unauthenticated entry (marketing content, Start now → 
  Register, Log in link). Static content in MVP.
- Auth vertical slice per guidelines (datasource canonical ladder, UserModel,
  AuthRepository, AuthController unknown/authed/unauthed, mutations, pages).
- Router: unknown → splash; unauthenticated → guest landing (not straight to
  login); authenticated → home. Route constants; tests.

---

## Milestone 2 — Memories & planning

### #6 Migration: trips + trip_card_view — UPDATED
trips per data-model v2: `vibes text[]` (10-item list, no count check for now),
`country_code` nullable, client uuid PK, date check; RLS owner-only; grants;
trip_card_view (status, photo count, stars, duration, expense total — stars/
expenses columns may return 0 until later migrations); db reset.

### #7 Home screen — UPDATED
Figma: `Home screen 1`, `Home screen 2`.
- Greeting + avatar + stars badge (stars value may be stubbed until #15).
- Stats bar (Memories/Places/Days) from profile_stats_view (view arrives in #15 —
  stub provider until then).
- Current-memory hero card (day X of Y, Plan/Expenses/Journal shortcuts),
  Coming up row, Memories grid (Recap badge, duration, photo count).
- Bottom nav: Home · ➕ · Expenses (Expenses tab may be a placeholder until #16).
- No search. Empty states; loading/error/data; tests.

### #8 Create memory (single screen) — UPDATED
Figma: `Add trip`.
One screen: name, where, start/end dates, vibe chips (10). All optional.
Create mutation with client uuid; TripCreatedDispatched event; tests.
Fold in the free-tier 3-memory app-side check.

### #9 Migration: quests — unchanged

### #10 Plan (day quests) — UPDATED (visual only)
Figma: `current trip - plan`. Timeline layout with check circles, "X quests
planned / Y days total" header; add/edit sheets (final sheet designs pending —
reuse old-design interaction pattern); tests.

### #11 Migration: checklist + seed — UPDATED
checklist_items with `category` + `is_essential`; checklist_suggestions seeded
per category with essential flags; RLS + grants; db reset.

### #12 Checklist UI — UPDATED
Figma: `current trip - checklist`. Category tabs with per-category progress,
overall "X of Y packed" bar, essential tags, check-off, custom add input; tests.

---

## Milestone 3 — During the trip

### #13 Migration: day_notes + photos + storage bucket — unchanged

### #14 Journal screen — UPDATED (was current-trip day view)
Figma: `current trip - journal`.
Day tabs with photo thumbs; NO locked days, NO "starts today" screens; per-day
long-form note (1/day, stars via RPC — RPC arrives in #15, stub until then);
photos strip + add; To Do sheet (day's quests, check-off + stars); View wrap-up
button (disabled until #19); delete memory (keeps stars); tests.

### #15 Migration: points_ledger + bonus tasks + achievements + RPCs — UPDATED
points_ledger + award_points RPC (note 1/photo 2/quest 1/bonus per template);
bonus_task_templates + seed; bonus_task_assignments;
**achievement_templates + seed (8 badges) + user_achievements +
check_achievements RPC**; profile_stats_view; update trip_card_view stars +
expense totals; RLS + grants; db reset.

### #16 Migration: expenses + expense_summary_view — NEW
expenses table per data-model v2 (category check, amount check); RLS via parent;
grants; expense_summary_view; db reset.

### #17 Expenses feature — NEW
Figma: `expenses`, `add expenses`.
Expenses tab: per-memory totals list with spend bars, search, sort; add-expense
sheet (memory selector, title, amount, category chips, date). Compare button
hidden/disabled (screen not designed). Tests.

### #18 Photo capture & upload — unchanged scope
Pick/take photo, compression, EXIF geotag/taken_at, upload → row insert, caption/
place tag, stars; photos render in Journal (no standalone gallery — REMOVED);
tests with fake storage.

### #19 Bonus tasks — unchanged scope
Figma: `bonus tasks`, `new bonus`. Issuing from templates, countdown, list +
popup, completion via photo, expiry; per-memory stars summary header; tests.

---

## Milestone 4 — Wrap-up & profile

### #20 Migration: wrap_ups + edge function generate_wrap_up — RENAMED
wrap_ups table (was memories); edge function: gather memory data → Anthropic →
screenplay JSONB; JWT + ownership validation; idempotent; secrets in function
config; CI deploy post-merge; RLS + grants; db reset.

### #21 Wrap-up playback screen — screen NOT designed, coordinate first
Generation trigger + progress UI; screenplay playback (Mapbox route, photo
sequence, narrative); fallback for no-location memories; mapbox_maps_flutter
dep (justify); screenplay parsing tests.

### #22 Wrap-up editing + publish — unchanged

### #23 Profile & achievements — UPDATED
Figma: `profile`.
Avatar, name/@handle, editable bio, joined date; stats row from
profile_stats_view; achievements grid (earned/unearned, progress from stats);
logout; tests.

---

## Backlog notes

- Design gaps blocking issues: #21 (wrap-up screen), expenses Compare (future
  issue when designed), photo detail/tagging (future issue).
- Old #16/#17 gallery issues are superseded — gallery removed from MVP.
- MP4 export, social feed, shared memories: post-MVP.
