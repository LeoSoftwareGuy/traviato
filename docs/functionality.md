# TripJ (working title) — MVP Functionality

> One-liner: the place where your travel life lives — plan your trip, log it as you go,
> and it becomes a beautiful journal you keep forever.

Source of truth for screens: Figma file `beautify`, page **journey**.
Status legend: ✅ designed · 🟡 partially designed / in progress · ❌ not designed yet

## 1. Auth & profile 🟡 (designer working on registration/login pages)

- Supabase Auth: email/password (+ providers per final design).
- `profiles` row created via trigger on signup.
- Profile screen shows user info and **points balance**.
- No public profiles in MVP.

## 2. Home ✅

- Trip list grouped into sections: **New** (add-new card), **Current** (active trip,
  shown only while a trip is running), **Upcoming**, **Latest** (finished).
- Search field filters the user's trips by name.
- Trip card: cover image, name, date range.
- Bottom navigation (proposal, not yet designed): **Trips** · **Quick-log camera**
  (center action, jumps into logging for the current trip) · **Profile**.

## 3. Create trip ✅ (3-step flow)

1. **Basics** — trip name, destination (single free-text/place field), start & end dates.
   Steps are skippable; everything editable later.
2. **Goals** — pick up to 3 tags from a fixed list (~17: road trip, honeymoon, solo trip,
   girls trip, city break, camping, cruise, spa retreat, festival/concert, business trip,
   family vacation, beach trip, educational, romantic trip, bachelorette, bachelor party,
   trip with friends). Skippable.
3. **Plan overview** — ring showing trip length; the number of days inside the ring is
   **computed from the trip's start and end dates** (e.g. "8 days"). Day cards (Day 1,
   Day 2, …, "Plan more"), entry point to the checklist. Save.
- A first-time-only onboarding variant of this flow exists ("Only 1st time" in Figma).

## 4. Day planning ✅

- Per-day screen (date + "Day N"), arrows to move between days.
- A day holds ordered, timed **quests** (plan items): time + title + optional
  location/details (e.g. 08:00 Departure — Tallinn Airport).
- Add quest via bottom sheets: name → time → Add. Edit sheet with Save / Delete.
- Empty state: "No quests added yet".

## 5. Checklist 🟡

- One checklist per trip: check items off; suggestions/search for common items.
- Users can also **add their own custom items** — the predefined list can never cover
  everything. (Designer adding this during MVP.)
- Reachable from plan overview ("Create checklist" / "Edit checklist").

## 6. Trip start & during-trip logging ✅

- On start date: "Your trip starts TODAY!" update screen(s).
- **Current trip day view**: day tabs with photo thumbnails; only days up to *today*
  are open — future days are locked ("Oops, this day will be unlocked later").
- Per open day the user can: add **notes** about the day, add **photos**, and view the
  day's **To Do** (its planned quests).
- Trip can be deleted (bin icon); star icon shows points earned for this trip.

## 7. Bonus tasks (gamification core) ✅

- Time-limited prompt tasks with countdown (12h/7h/4h) and star rewards, e.g.
  "Take a photo of yourself packing", "photo of today's food", "photo of your outfit",
  "photo of the best view today", "share your trip with your travel buddy".
- Surfaces: task list sheet (badge with count) + single-task popup (camera / Later).
- Completing tasks and logging (photos, notes, full days) earns **points**.

## 8. Points 🟡

- MVP: points are **earned and stored** per user (and visible per trip / on profile).
- No spending/redemption in MVP. Future idea: visibility boost in the social feed.

## 9. Gallery ✅

- Per-trip photo gallery: masonry grid, caption per photo.
- Planned per-photo metadata: **location tag** and **people tag** (Figma note).
- Empty state encourages adding photos.

## 10. Location capture — backend functionality

Mostly data work, not screens: each photo and quest stores location data in the DB,
and the memory generator consumes all collected points at the end of the trip.

- Photos: auto-capture geotag on upload (with OS permission). Quests & photos:
  optional user-entered place tag.
- No interactive route planner in MVP.
- Design touchpoints only (inside existing screens): when the location permission is
  requested, the small "add place" affordance in photo/quest forms, and how a place
  tag is displayed on a gallery photo.

## 11. Generated memory 🟡 — in MVP (designer working on the finished-trip screen)

Opened by tapping a **finished trip**. Architecture: **one screenplay, two renderers.**

1. **Generation (once, on first open)** — an edge function gathers the trip's data
   (notes, quests, places, photo metadata/images) and calls the **Anthropic API** for
   creative direction: photo selection & ordering, emotional arc, chapter titles,
   narrative text, pacing, mood. The result is saved as a **screenplay** — ordered
   blocks (map segment, photo, narrative text…) in `memories.content` (JSONB).
2. **Viewing (every time, MVP)** — the app plays the screenplay live: Flutter
   animations, Mapbox camera moving along the route day by day, photos (cached via
   `cached_network_image`) popping up in sequence, AI narrative typography. Looks like
   a video; rendered on-device at native resolution. User can edit the screenplay
   before "publishing" (privately); edits update the JSONB.
3. **MP4 export (post-MVP, paid)** — the same screenplay is sent through an edge
   function to a template-video API (Shotstack/Creatomate class); the rendered MP4 is
   stored in a `memories` storage bucket. This file is what users share externally and
   what a future social feed plays. No generative-AI video (no invented footage) —
   AI writes the story, the template engine renders the user's real photos.

Requires internet on first playback of a trip (photos then cached on-device).

## Out of scope for MVP

Social feed, discovery, follows/likes/comments, public profiles, shared/collaborative
trips (multi-user trips), point redemption, video export, interactive route planner,
web app.

## Design gaps / in progress

1. Auth screens (registration/login) — 🟡 in progress.
2. Bottom navigation bar (3-tab proposal above) — ❌.
3. Finished-trip / generated memory screen — 🟡 in progress.
4. Photo add/detail flow incl. location & people tagging — ❌.
5. Checklist custom-item input — 🟡 planned during MVP.
6. Points balance presentation (profile + per-trip) — ❌.

## Monetization (context, not MVP work)

Freemium subscription: free = 3 trips & basics; paid = unlimited trips, full features,
beautiful export.
