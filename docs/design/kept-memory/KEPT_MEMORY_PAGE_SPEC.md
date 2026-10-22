# Kept Memory Page (1b): Implementation Spec

**For:** coding agent working in `LeoSoftwareGuy/traviato` (Flutter, branch `main`)
**Design source:** `Kept Memory.dc.html`, option **1b** (right-hand phone). Open it in a browser.
**Related:** the wrap-up film is the real one (`Wrap-Up Film.dc.html` / `WRAP_UP_FILM_COLLAGE_SPEC.md`). Don't change it. This spec only adds a way in and a way out.
**Depends on (soft):** `LOCALIZATION_IMPLEMENTATION_SPEC.md`. If it's merged, put every string in ARB. If not, use a single strings file that's easy to migrate.

---

## Why

At the moment, tapping a kept memory on Home always plays the wrap-up film. The film only shows a curated handful of photos (8 moments plus up to 30 in the flurries), so people have no way to look through **all** the photos and notes from a memory. This adds a lasting **Memory page** with the film at the top and the rest of the memory below it, laid out day by day.

## How to work through this

1. Read the whole spec and open the design file first.
2. Do the phases in order and commit after each one.
3. Reuse the tokens in `lib/core/theme/` (colors, radii, Fraunces/Literata, JetBrains Mono, Roboto). Only add a token if it's missing, and list any you add.
4. **User content (notes, photo captions, memory title) is shown exactly as written.** Never translate, rewrite or shorten it.
5. If names differ from what's assumed here (tables, routes, widgets), use the nearest equivalent and note it in your final report. Don't stop to ask.

---

## Phase 1: Routing and first-tap behaviour

- New route: `/memory/:tripId` → `KeptMemoryPage`.
- Home "Kept forever" card tap:
  - If `trips.film_seen_at` is **null**: open the wrap-up film. When the film ends, its final card shows a primary button **"Open memory"** that replaces the route with `/memory/:tripId`. Set `film_seen_at = now()` when the film reaches the end, or when the user leaves after more than 50% of it has played.
  - Otherwise: open `/memory/:tripId` directly.
- Add the migration: `alter table trips add column film_seen_at timestamptz;`. Backfill `now()` for trips already marked kept (those users have already seen their film).
- Closing the film any other way (✕, back) returns to wherever it was opened from.
- The Home card badge `▸ Recap` stays as it is.
- Long-press on the Home card (rename / let go) is unchanged.

**Done when:** a new kept memory plays the film first, "Open memory" lands on the page, and every tap after that opens the page directly.

---

## Phase 2: Data

`keptMemoryProvider(tripId)` returns:

```
trip      { title, coverUrl, startDate, endDate, keptAt, starTotal }
days[]    { dayIndex (1-based), date, title?, photos[], notes[] }
photos[]  { id, url, thumbUrl, takenAt, dayIndex, note?, bonusTask? { prompt, stars } }
notes[]   { id, text, createdAt, dayIndex, photoId? }
plan[]    { id, name, dayIndex, done }
counts    { photos, notes, planDone, planTotal }
```

- **Day assignment:** by local date of `takenAt` / `createdAt` relative to `trip.startDate`. Anything before day 1 goes into day 1, anything after the last day goes into the last day.
- **Order within a day:** by `takenAt` ascending.
- **Day title:** use the journal page's day title if one exists. Otherwise leave it out (don't generate one). In the mock, the titles are the journal day headings.
- **Note ↔ photo link:** if a note is attached to a photo, it's that photo's caption in the viewer.
- **Bonus-task photos:** photos from a completed bonus task carry `{ prompt, stars }`.
- `starTotal` comes from `points_ledger` for that trip, the same source as the bonus spec.
- Use thumbnails (`thumbUrl`, roughly 400px) in strips and full images in the viewer. Pre-cache the next 2 full images.

---

## Phase 3: Page layout (top to bottom)

Background: the app's standard radial (`#241C4E` → `#0F1230` → `#0C0F27`). Horizontal padding is **22**. The whole page is one `CustomScrollView`.

### 3.1 Hero (330 tall)
- Cover image, `BoxFit.cover`, with a scrim gradient from the bottom up: `#0C0F27` at 4% → `rgba(12,15,39,.55)` at 46% → `.15` at the top.
- Top row at the safe area plus 10: two 38px round buttons, `rgba(12,15,39,.6)` with blur 8. Back `←` on the left, `⋯` on the right. The ⋯ menu is the same as the Home long-press sheet (rename, save film, let go).
- At the bottom left, 16 from the bottom:
  - Eyebrow: `KEPT FOREVER · 12–16 AUG 2026`, mono 9.5, tracking .15em, `#F2A65A`. Date range via `intl`.
  - Title: serif 34/1.05 `#FBFAF6`.
  - Meta: `5 DAYS · 84 PHOTOS · 9 NOTES · ✦46`, mono 10 `#AEACB7`. Hide any segment whose count is 0.

### 3.2 Actions row (14 below the hero)
- **Play the film** (flex 1): bg `#F29520`, text `#0C0F27` Roboto 600 14, radius 16, padding 14, `▶` + label + mono 10.5 duration at 70% opacity (from the film's length, e.g. `1:19`). It opens the wrap-up film. On this path the film ends with **"Back to memory"**, not "Open memory".
- **Slideshow** (hugs its content): 1px border `rgba(174,172,183,.28)`, radius 16, Roboto 600 13. It opens the viewer at photo 1 with autoplay on.

### 3.3 Day chapters (30 below actions, 34 between chapters)
For each day that has at least 1 photo or note:
- Header row: mono 9.5 tracking .14em `#6D6D7A` `DAY 1 · TUE 12 AUG` (left) · mono 10 `#F29520` `18 PHOTOS ›` (right, tap → viewer at that day's first photo).
- Day title (if present): serif 22/1.2.
- **Photo strip:** a horizontal `ListView`, 168 tall, 5 gap, 22 side padding, snapping to items. Item widths cycle `200, 124, 124, 168, 124, 200` for rhythm (thumbs are cropped with `BoxFit.cover`, radius 14). Bonus-task photos get a small `✦` pill at the top right (`rgba(12,15,39,.72)`, primary text). Tap → viewer at that photo.
- **Notes** below the strip, 14 apart: time in mono 9 `#6D6D7A` (`05:48`), then the text in serif *italic* 16/1.5 `#E8E5DD`, wrapped in curly quotes “ ”. Show **all** of that day's notes in full. Notes with no photo still appear here.
- A day with notes but no photos: leave out the strip and the "PHOTOS ›" link.

### 3.4 The plan (34 below the last chapter)
- A card (radius 18, bg `rgba(19,23,54,.7)`, 1px `rgba(29,34,72,.9)`), **collapsed by default**.
- Header: `The plan` serif 17 + `7 OF 9 DONE` mono 9.5. Chevron `⌄` rotates 180° on expand (200ms).
- Expanded rows: a 20px circle (done: ✓ on primary at 16% with a 50% primary border; skipped: empty, `rgba(174,172,183,.3)` border) · name Roboto 500 12.5 (skipped rows are `#6D6D7A`, no strikethrough) · `D2` mono on the right.
- Read-only: no taps on the rows.
- If the trip had no plan, leave the card out.

### 3.5 Footer
`KEPT FOREVER · SINCE 17 AUG 2026`, centred mono 9.5 tracking .14em `#6D6D7A`, 26 above and 48 below plus the safe area.

---

## Phase 4: Full-screen viewer

A single `PhotoViewer` route, opened with `(tripId, startIndex, autoplay)`. It covers **all photos across all days** in day order. If the journal page carousel already has a viewer, **extend that one** rather than building a second.

- Background `#05060F`. It fades in over 200ms.
- **Top bar:** ✕ (38px round, `rgba(251,250,246,.08)`) · centre mono 10 `#AEACB7` `DAY 2 · 24 / 84` · right pill `▶ Slideshow` / `❚❚ Pause` (playing: primary bg, `#0C0F27` text).
- **Progress line** under the top bar: one 2px segment per day, `flex = that day's photo count`, gap 3, track `rgba(251,250,246,.14)`, fill `#F29520` up to the current photo.
- **Photo:** `BoxFit.contain` when paused, `cover` when playing. Swiping left or right moves between photos (`PageView`). Tapping the left third goes back and the right two-thirds goes forward. Pinch to zoom when paused. Swiping down closes it.
- **Caption block** (min height 120, padding 16/24/38): bonus-task pill if there is one (`Dare · before the sun · ✦2`, info blue `#4FB0D8` on 14% with a 35% border), then the attached note in serif italic 17/1.45, then mono 9.5 `TUE 12 AUG · Before either of us was awake` (date · day title).
- **Slideshow:** advances every **3.2s**. Each photo crossfades over 800ms and slowly zooms from 1.02 to 1.12 over 3.4s. It loops at the end. Any manual swipe or tap restarts the 3.2s timer. Keep the screen awake while it plays. It pauses when the app goes to the background.
- **Reduced motion** (`MediaQuery.disableAnimations`): no zoom, just the crossfade.
- Don't bother remembering the last position. Every open starts where you tapped.

---

## Phase 5: Copy

| Key | EN |
|---|---|
| memory_keptForever | Kept forever |
| memory_meta | {days} days · {photos} photos · {notes} notes · ✦{stars} (ICU plurals, segments hidden at 0) |
| memory_playFilm | Play the film |
| memory_slideshow | Slideshow |
| memory_dayPhotos | {n} photos › |
| memory_plan | The plan |
| memory_planDone | {done} of {total} done |
| memory_since | Kept forever · since {date} |
| film_openMemory | Open memory |
| film_backToMemory | Back to memory |
| viewer_slideshow / pause | Slideshow / Pause |

Add RU/ET versions marked `"x-review": "pending"`. Eyebrows go through `toUpperCase()` in code.

---

## Acceptance checklist
- [ ] First tap on a newly kept memory plays the film, and its final card has "Open memory" → page. After that, every tap opens the page.
- [ ] `film_seen_at` migration added and backfilled.
- [ ] The page shows every photo and every note for the trip, grouped by day, in time order. The counts match the hero meta.
- [ ] Bonus-task photos are marked in the strips and show their prompt and ✦ in the viewer.
- [ ] Plan is collapsed by default, read-only, and hidden when the trip has no plan.
- [ ] Viewer: swipe, tap zones, pinch, swipe-down to close, progress split by day, caption and note.
- [ ] Slideshow: 3.2s auto-advance, crossfade and zoom, timer resets on manual input, screen stays awake, honours reduced motion.
- [ ] "Play the film" from the page returns via "Back to memory".
- [ ] Thumbnails in strips, full images in the viewer, the next 2 pre-cached. Smooth scrolling with 200+ photos.
- [ ] Widget tests: page with plan / without plan / a day with notes only. Viewer index and progress maths.

## Final report back
Files changed, migration added, whether you extended the journal carousel viewer or built a new one, and any items you swapped for a nearest equivalent.
