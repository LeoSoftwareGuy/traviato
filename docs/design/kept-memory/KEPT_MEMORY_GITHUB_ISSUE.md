**Title:** Kept Memory page: browse every photo and note, with the film on top

**Labels:** `feature`, `ui`, `memories`

---

### Problem
Tapping a kept memory on Home always plays the wrap-up film. The film shows a curated selection, so there's no way to see **all** the photos and notes from a finished memory.

### Solution
Add a lasting **Memory page** (`/memory/:tripId`) that's laid out day by day:
- A hero with the cover, title, dates and counts, plus **Play the film** and **Slideshow** buttons.
- One chapter per day: a horizontal photo strip and that day's notes in full.
- The plan, read-only and collapsed, at the end.
- A full-screen photo viewer covering every photo across all days, with an autoplay slideshow (3.2s, crossfade + slow zoom).

**First-tap behaviour:** the first open of a newly kept memory still plays the film, and the film ends on "Open memory". Every open after that goes straight to the page.

### Spec & design
- Spec: `KEPT_MEMORY_PAGE_SPEC.md` (follow it phase by phase, committing after each one)
- Design: `Kept Memory.dc.html`, option **1b** (open in a browser; tap photos and Slideshow to see the behaviour)
- Don't change the wrap-up film itself beyond its end-card button.

### Tasks
- [ ] Phase 1: `/memory/:tripId` route, `trips.film_seen_at` migration + backfill, Home tap logic, film end-card "Open memory" / "Back to memory"
- [ ] Phase 2: `keptMemoryProvider` (photos and notes grouped by day, plan, counts, stars from `points_ledger`)
- [ ] Phase 3: page UI (hero, actions, day chapters, collapsible plan, footer)
- [ ] Phase 4: full-screen viewer + slideshow (extend the journal carousel viewer if there is one)
- [ ] Phase 5: strings in ARB (EN + RU/ET marked pending review)
- [ ] Tests listed in the spec's acceptance checklist

### Acceptance
Every checkbox in the **Acceptance checklist** section of `KEPT_MEMORY_PAGE_SPEC.md` passes.

### Out of scope
Editing photos or notes from this page, sharing individual photos, changes to the film's content or timing.
