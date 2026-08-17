# Trevy — MVP Functionality (v3, post-redesign)

> One-liner: the place where your travel life lives — plan your memory, log it as you
> go, and it becomes a beautiful journal you keep forever.

Source of truth for screens: Figma file **"Leo's team library"**, Page 1 (14 frames).
This version supersedes the beautify/journey designs entirely.

## Product language (use in ALL UI copy)

- A trip is called a **memory** ("New memory", "17 Memories", "memories in the making").
- Points are called **stars** ⭐ in the UI (DB keeps the points ledger).
- The generated cinematic output is the **wrap-up** ("View wrap-up", "Recap" badge).
- App name: **Trevy** (repo/codename stays `traviato`).

## 1. Guest mode / landing ✅ — in MVP

- Unauthenticated users land on a marketing screen: value proposition ("Every memory
  beautifully captured"), how-it-works steps (Capture the moment / Plan your trips /
  Relive it all), sample memory cards, testimonial, "Start now" CTA + "Log in".
- Purpose: show new users why to register before asking them to.
- Static content in MVP (no browsing real app data as guest).

## 2. Auth & profile ✅

- Register / Log in screens designed. Supabase Auth email/password.
- `profiles` row via signup trigger. Profile now includes an editable **bio**.
- Profile screen ("You"): avatar, name, @handle, bio, joined date, stats row
  (Memories · Countries · Days · Stars), and the **Achievements** grid.

## 3. Achievements ✅ — in MVP

- Badge system on the profile, "6/8 earned" style. Seeded set incl.: First Adventure
  (first memory), Globetrotter (visit 10 countries, shows progress 11/18), Century
  (100 days capturing), Star Collector, Shutterbug, Storyteller.
- Each achievement: icon, title, description, earned/unearned state, progress where
  applicable. Earned server-side (no client self-award).

## 4. Home ✅

- Greeting ("Hello, Ada"), top-right: profile avatar + stars badge.
- Stats bar: Memories / Places / Days totals.
- **Current memory hero card** (only while a trip runs): cover, name, place, dates,
  "day X of Y" chip, shortcut buttons **Plan · Expenses · Journal**.
- **Coming up**: upcoming memories ("3 memories in the making") with vibe chip and
  countdown ("in 26d").
- **Memories** grid: finished memories with Recap badge, duration badge, photo count,
  dates.
- No search field on home in this design (dropped from MVP).
- **Bottom nav: Home · ➕ (new memory) · Expenses.** Profile lives top-right.

## 5. Create memory ✅ — single screen (replaces the 3-step flow)

- "New memory": name ("e.g. Summer in Tokyo"), where ("Where did it happen?"),
  start + end dates, **vibe** tags from a fixed list of 10: Romantic, Adventure,
  Cultural, Chill, Foodie, Road trip, Wellness, Wildlife, Nightlife, Photography.
- Fields optional (dates nullable); everything editable later.
- Plan and checklist are reached from the memory afterwards (hero card shortcuts),
  not steps of creation.

## 6. Plan (day quests) ✅ — unchanged concept

- Per-day screen: date + "Day N", arrows between days, "X quests planned / Y days
  total".
- Quests: time + title + detail line (e.g. 08:00 Pack the car — Cooler, blankets,
  hiking boots), check-off circles.
- Add/edit via sheets. Empty state for unplanned days.

## 7. Checklist ✅ — upgraded

- Per-memory checklist with **categories** (tabs: Travel essentials 5/7, Clothing &
  shoes 7/…), overall progress ("26 of 38 packed", 68% bar).
- Items can be flagged **Essential**.
- Suggestions seeded per category; custom "Add an item…" input at the bottom.

## 8. Journal (during-trip logging) ✅

- Day tabs with photo thumbnails (Aug 18 · Aug 19 · …), "Day N", "Journal started".
- Per day: long-form **notes** ("Add notes about today"), **Photos** strip (count +
  add), **To Do** button (the day's quests, check-off), **View wrap-up** button.
- DROPPED from old design: locked future days and the "Your trip starts TODAY!"
  screens — any day within the memory is accessible.

## 9. Expenses ✅ — NEW feature, in MVP

- Dedicated bottom-nav tab. "Your spending" overview: list of memories with total
  spent (€), duration, item count, relative spend bar; search; sort ("Biggest
  spender"); **Compare** action (screen not yet designed).
- **Add expense** sheet: memory selector, what was it ("e.g. Sunset dinner in Oia"),
  amount, **category** (Food & Drinks, Transport, Accommodation, Activities,
  Shopping, Other), date.
- Single currency (EUR) in MVP.

## 10. Bonus tasks ✅ — unchanged concept

- Per-memory list ("Bonus tasks — Cabin 2026"): stars earned summary ("10 stars
  earned, 3 of 8 tasks done"), available-now count, tasks with star value and expiry
  countdown ("Expires in 12h"), Completed section.
- Single new-task popup (photo CTA / Later).
- Examples: Pack your bags on camera, Share with a friend, Snap your first meal
  there, Document your outfit, Capture the best view.

## 11. Stars (points) 🟡

- Earned for logging (notes, photos, quest completion) and bonus tasks; stored as a
  server-side ledger; shown on profile + per-memory.
- No spending/redemption in MVP.

## 12. Location capture — backend functionality (unchanged)

- Photos: auto geotag on upload (with permission). Quests & photos: optional place
  text. Collected points power the wrap-up map and the Places/Countries stats.
- Memory's "where" field feeds the Countries stat (see data-model open question on
  country derivation).

## 13. Wrap-up (generated memory) 🟡 — in MVP, screen not designed yet

Architecture unchanged: **one screenplay, two renderers.**

1. **Generation (once)** — edge function gathers the memory's data (notes, quests,
   places, photo metadata) → Anthropic API for creative direction → screenplay JSONB
   saved in `wrap_ups.content`.
2. **Viewing (MVP)** — app plays the screenplay live: Flutter animations, Mapbox
   route, cached photos, narrative text. Entry points: "View wrap-up" in Journal and
   the Recap badge on finished memories. Editable before private publish.
3. **MP4 export (post-MVP, paid)** — same screenplay → template-video API → file in
   storage; the future feed plays this file.

## Out of scope for MVP

Social feed, follows/likes/comments, public profiles, shared memories, star
redemption, video export, interactive route planner, multi-currency expenses,
real guest browsing of app content, web app.

## Design gaps

1. Wrap-up playback screen — ❌ (biggest gap; coordinate with designer).
2. Expenses **Compare** screen — ❌ (button exists, screen doesn't).
3. Photo detail / place & people tagging — ❌ (photos strip only).
4. Add/edit quest sheets, bonus-task popup states — partially inferred from old
   design; confirm final sheets.
5. Standalone gallery — REMOVED (photos live inside Journal days + wrap-up).

## Monetization (context)

Freemium: free = 3 memories & basics; paid = unlimited memories, full features,
beautiful export.
