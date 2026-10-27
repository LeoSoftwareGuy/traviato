# Journal Photo Carousel: "In the film" Control (Issue #294, part 1)

**For:** coding agent working in `LeoSoftwareGuy/traviato` (Flutter, branch `main`)
**Issue:** #294 *Wrap-Up Film: let the user choose which photos become the main moments*
**Design source:** `Wander - Travel Memory Journal.dc.html` → Journal screen → tap any photo in the day strip.
**Scope of this part:** per-photo film control in the **existing** journal day carousel, plus markers on the strip. The separate "Choose photos" screen (all days, M1–M8 slots, reachable from the film and the Kept Memory page) is **part 2** and has its own spec.

---

## How to work through this

1. Read the whole spec first, then open the design and tap through the carousel.
2. **Don't restructure the existing carousel.** It stays: the day's photos, swipe between them, ✕ on the left, delete on the right. You're adding one bottom panel and the strip markers.
3. Reuse the tokens in `lib/core/theme/`. Only add a token if it's missing, and list any you add.
4. Photo selection is **not** an AI call. Changing it never triggers AI on its own (see Phase 4).
5. If names differ from what's assumed here, use the nearest equivalent and note it in your final report. Don't stop to ask.

---

## Phase 1: Data model

The generator already reads `photos.use_in_wrap_up`. Extend it to three states without breaking existing rows.

| UI label | Meaning | Stored value |
|---|---|---|
| **Auto** | Generator decides (current behaviour) | `null` |
| **Always** | Must be in the film. Gets a main moment (M1–M8) before automatic picks do | `true` |
| **Leave out** | Never appears anywhere in the film (moments or flurries) | `false` |

- If `use_in_wrap_up` is currently a non-null `bool` defaulting to `false`, add a migration that makes it **nullable**, sets the default to `null`, and turns existing `false` → `null`. Leave existing `true` as is, unless `true` was being set automatically by the generator. In that case, null those too and only keep true values the user set.
- Add `use_in_wrap_up_set_at timestamptz` (nullable). It's needed in Phase 4 to tell whether the film is out of date.
- Repository: `setFilmPick(photoId, FilmPick.auto | always | never)` writes both columns. It updates optimistically, with rollback and an error toast if the write fails.

### Generator rules (update the selection step)
1. Drop every `false` photo from **all** pools (moments and flurries).
2. Fill M1–M8 with `true` photos first, in chronological order (see the ordering bug issue). Bonus-task slots (M1, M3, M4) accept any `true` photo. If a slot has no `true` candidate, keep the current fallback.
3. If more than 8 photos are `true`, the extras go into the flurries, **never dropped**. Leave the UI copy as it is. "Gets a main moment" is the norm; overflow is the rare case.
4. Fill the remaining slots with the current automatic logic (`null` photos only).
5. The flurries take everything else that isn't `false`, as they do today.

Expose a read-only `autoPickedPhotoIds(tripId)` (the photos the generator *would* choose for moments with every photo on Auto). The UI uses it to show the faint "film chose this" marker. Compute it locally from the same selection function. Don't call the network or AI for it.

---

## Phase 2: Carousel bottom panel

Sits above the page dots and below the photo. Everything already in the carousel stays where it is.

- **Container:** full width minus 18 on each side, padding 10, radius 18, bg `rgba(7,9,26,.62)` + blur 12, 1px border `rgba(255,255,255,.1)`. 14 above the dots. Dots stay 34 from the bottom safe area.
- **Header row** (4px side padding):
  - Left: `▸ IN THE FILM`, JetBrains Mono 500 9.5, tracking .12em, `#AEACB7`, uppercase in code.
  - Right: hint, Roboto 500 10.5, right-aligned, may wrap:

    | State | Hint | Colour |
    |---|---|---|
    | Auto, generator picked it | Film chose this one | `#F2A65A` |
    | Auto, not picked | Not picked right now | `#6D6D7A` |
    | Always | Your pick · gets a main moment | `#F2A65A` |
    | Leave out | Won't appear anywhere | `#6D6D7A` |

- **Segmented control:** 3 equal segments `Auto · Always · Leave out`. Track `rgba(255,255,255,.06)`, padding 3, radius 12, gap 3. Segment min height **38** (the hit area extends to ≥44 with padding), radius 9, Roboto 600 12.
  - Selected Auto / Always: bg primary `#F29520`, text `#0C0F27`.
  - Selected Leave out: bg `rgba(174,172,183,.22)`, text `#FBFAF6`.
  - Unselected: transparent, text `#AEACB7`. Background transition 150ms.
- **On change:** save immediately (no save button) + light haptic. **No confirmation toast** (#300 — the selected segment already shows it); only a failed save shows an error.
- **Leave-out state in the carousel:** the photo renders at **45% opacity** (200ms fade) and a centred pill shows 110 from the top: `Left out of the film`, Roboto 600 11, `#AEACB7` on `rgba(7,9,26,.7)`, 1px `rgba(174,172,183,.3)`, radius 999. It isn't tappable.
- The panel shows the state of the **current page**. Swiping updates it with no animation.
- Swiping between photos still works over the panel area? **No.** The panel absorbs horizontal drags so the segments are easy to hit. Swiping works everywhere else.

---

## Phase 3: Journal day strip markers

On the journal page "Today's photos" strip:

- **Header:** keep `TODAY'S PHOTOS · 5` on the left. On the right add `▸ 3 IN THE FILM` (mono 9.5, tracking .1em, `#F2A65A`) = the number of that day's photos that are Always **plus** Auto-and-picked. Hide it when the count is 0.
- **Thumb badges** (top-left, 7px inset; the existing ♥ stays top-right):

| State | Badge | Thumb |
|---|---|---|
| Auto, picked | `▸`, `#F2A65A` on `rgba(7,9,26,.6)`, 1px `rgba(242,149,32,.45)` | normal |
| Auto, not picked | none | normal |
| Always | `▸ Your pick`, `#0C0F27` on primary | 1.5px primary border |
| Leave out | `Left out`, `#AEACB7` on `rgba(7,9,26,.7)`, 1px `rgba(174,172,183,.3)` | 45% opacity |

  Badge: padding 3/7, radius 999, Roboto 600 9.
- The markers update straight away when the carousel closes (shared provider/state, no refetch).

---

## Phase 4: Keeping the film in sync

- If the film hasn't been generated yet, nothing extra is needed. The generator reads the flags when it runs.
- If a film already exists and any `use_in_wrap_up_set_at` is newer than `films.generated_at`, mark the film as **out of date**:
  - Wherever the film is shown (wrap-up entry, Kept Memory page), add a small `Photos changed · Rebuild film` chip. Tapping it rebuilds the film with the new picks.
  - Rebuilding re-runs photo selection locally. **Only regenerate the 4 AI lines if the moments they describe changed**. Otherwise reuse the existing lines.
  - Never rebuild automatically on every toggle.
- The free-plan gate (≥5 photos, ≥1 note) is unchanged. Leave-out photos **still count** toward the gate.

---

## Phase 5: Delete interaction

Keep your existing delete behaviour and confirmation exactly as they are. Extra rule: deleting a photo removes its pick. If it was in an existing film, that marks the film out of date (Phase 4).

---

## Copy

| Key | EN |
|---|---|
| film_inTheFilm | In the film |
| film_pickAuto / Always / Never | Auto / Always / Leave out |
| film_hintAutoPicked | Film chose this one |
| film_hintAutoNot | Not picked right now |
| film_hintAlways | Your pick · gets a main moment |
| film_hintNever | Won't appear anywhere |
| film_leftOutPill | Left out of the film |
| film_stripCount | {n} in the film |
| film_badgeYourPick | Your pick |
| film_badgeLeftOut | Left out |
| film_outOfDate | Photos changed · Rebuild film |

RU/ET go into ARB marked `"x-review": "pending"`. Eyebrows are uppercased in code. On a 360pt-wide screen in RU, the hint may wrap to 2 lines, but the segment labels must not truncate (shrink to a 10.5px floor, per the localization spec).

---

## Acceptance checklist
- [ ] The existing carousel layout is unchanged (✕ left, delete right, swipe, dots). Only the panel and the Leave-out pill are added.
- [ ] The segmented control saves immediately, updates optimistically and fires a haptic (no toast, #300).
- [ ] Migration: `use_in_wrap_up` is nullable and three-state, and `use_in_wrap_up_set_at` exists. Existing data is mapped as described.
- [ ] Generator: false photos are excluded everywhere, true photos fill M1–M8 first in chronological order, overflow goes to the flurries, and bonus-slot fallback is kept.
- [ ] Strip header count and thumb badges match the carousel state, and update when the carousel closes.
- [ ] An existing film shows "Photos changed · Rebuild film" after any pick change. The rebuild only calls AI when the described moments changed.
- [ ] The free-plan gate is unchanged.
- [ ] Unit tests for the selection rules (all-auto, 3 always, 10 always, all-but-4 left out, bonus-slot fallback). Widget tests for the panel states and strip badges.

## Final report back
Files changed, migration added, how existing `use_in_wrap_up` values were mapped, and any items you swapped for a nearest equivalent.
