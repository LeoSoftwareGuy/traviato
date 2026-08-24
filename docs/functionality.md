# Trevy — MVP Functionality (v4, redesign handoff)

> One-liner: the place where your travel life lives — plan your memory, log it as you
> go, and it becomes a beautiful journal you keep forever.

Source of truth for screens: the **redesign handoff** (`docs/design/` — 13-screen
design reference `Wander - Travel Memory Journal.dc.html` + README with tokens,
interactions, motion). Supersedes the "Leo's team library" Figma file. A Figma copy
can be made via `traviato-figma-import.html` (html.to.design).

**Canonical values note:** where the design mockup's sample values conflict with our
data model, the data model wins: quest completion = 1 star flat (no per-quest
values), photo = 2 stars, the existing 10-vibe list, and the existing 8-achievement
set. Mockup copy showing other numbers is adjusted at implementation.

## Product language (ALL UI copy)

- Trip = **memory** · points = **stars ✦** · generated recap = **wrap-up**.
- App name: **Trevy** (design files say "Traviato"/"Wander" — implement as Trevy;
  repo/codename stays `traviato`).

## 1. Guest landing ✅

- Pre-auth marketing screen: star specks, hero image with overhanging polaroids,
  eyebrow + serif headline ("Every memory, *beautifully captured*"), occasion chips
  (Weddings · Trips · Birthdays · Milestones — positioning beyond travel),
  how-it-works cards (third card highlighted), sample memories scroller,
  testimonial, sticky pulsing CTA ("Start capturing your moments") + Log in.
- Static content in MVP.

## 2. Auth ✅ — redesigned

- Single screen, segmented toggle Create account | Log in; mono field labels,
  focus states, password-strength segments; reward-tease card ("first memory earns
  10 stars"). Supabase email/password unchanged.

## 3. Home ✅ — redesigned

- Header: mono date eyebrow, "Hello, {name}"; **stars badge (tappable → Bonus
  tasks)**; avatar → Profile.
- Stats bar: Memories · Places · Days.
- **Happening now** hero card: cover, Day X of Y + vibe chips, title, place/dates,
  thin trip-progress bar; actions Plan · Expenses · **Journal (primary)**; dashed
  full-width **Checklist** row with packed count.
- **Coming up**: cards with countdown badge, planning state ("6 quests planned" /
  "Nothing planned yet"), **whole card taps into Plan** (plan months ahead).
- **Kept forever**: finished-memory grid, ▸ Recap badge, days + photo count,
  tap → Wrap-up.
- Bottom nav: Home · **FAB ➕** · Expenses.

## 4. Create memory ✅ — redesigned, + cover picker

- One screen: name, where, start/end dates, **vibe chips** (canonical 10:
  Romantic, Adventure, Cultural, Chill, Foodie, Road trip, Wellness, Wildlife,
  Nightlife, Photography), reward-nudge card, Create CTA.
- **NEW — cover picker**: 8 bundled cover options as thumbnails; explicit choice,
  or **auto-suggestion from the first selected vibe** (mapping in handoff);
  empty-state slot shows "Choose a cover / or we'll pick one that suits the vibe".
  Custom photo upload for covers: see open questions.

## 5. Manage memory ✅ — NEW (sheet, from Plan)

- Rename; **shift start/end by a day — quests move with it** (app-side re-date);
  change cover (same thumbnail strip); **two-step delete** (armed state shows
  consequences: "removes N photos, N days of notes and N stars… can't be undone" —
  per data model, earned stars are actually KEPT; fix the copy at implementation).

## 6. Plan (day quests) ✅ — redesigned

- Cover **banner** with dates + Day X of Y pill; summary line ("25 quests planned ·
  5 days total"); day pager with segment dots; **timeline rail** with check
  circles, mono times, quest titles + detail lines; check-off awards ✦1 (flat) via
  RPC + star toast; dashed "+ Add a quest to Day N"; top-right ☑ Checklist and
  ⋯ Manage buttons.

## 7. Checklist ✅ — redesigned

- Overall gradient progress bar + "X of Y packed"; category tabs with inline
  counts (5 categories: travel_essentials, clothing_shoes, toiletries_health,
  gadgets_tech, nice_to_haves); Essential badges (coral); check-off (toast, no
  stars); dashed custom-add row.

## 8. Journal ✅ — redesigned

- Day tabs as photo tiles (active = primary border); day title + sub-line; note
  card (italic serif body, "EDITED · N WORDS" footer, one note/day, ✦1 via RPC);
  photos strip ("TODAY'S PHOTOS · N", **add tile awards ✦2** on successful photo,
  tiles → Photo detail); "To Do · N left" → Plan; **"View wrap-up ▸"** gradient
  button; achievement-nudge card with progress ring.
- All days in range accessible (no locking).

## 9. Photo detail + tagging ✅ — NEW, in MVP

- Full-bleed photo, day/time + place overlay, pager dots.
- Place row (place text + coordinates when geotagged, "Change").
- **WHO WAS THERE**: person chips (free-text people, tag/untag), + Add.
- Caption card (tap to edit).
- Actions: **Set as cover** · **Use in wrap-up** (marks photo for the generator).

## 10. Expenses ✅ — reworked

- Overview: search, sort toggle (**latest-first default** ⇄ biggest spender),
  memory rows with total, meta, **relative spend bar** (÷ max), "Load 3 more"
  pagination (page size 3).
- **Selected-memory breakdown**: TOTAL SPENT + PER DAY AVG cards, BIGGEST
  CATEGORY card, BY CATEGORY bars (÷ largest category), ALL EXPENSES list
  (zebra rows, sorted by amount desc). Empty state prompts selection.
- Add-expense sheet: memory selector, description, amount (€), 6 category chips
  (Food & drinks, Transport, Accommodation, Activities, Shopping, Other), date.
- EUR only in MVP.

## 11. Expenses · Compare ✅ — NEW, in MVP

- Pick a pair (A = orange, B = purple; promote/swap rules per handoff).
- FINANCIAL COMPARISON table: per-category amounts side by side (**larger value
  emphasized**), missing = "—", Total + Per-day rows; computed **verdict card**
  ("X cost €N more overall, but Y ran €N/day higher…").
- "Done comparing" clears. All values derived client-side — no schema impact.

## 12. Bonus tasks ✅ — redesigned

- Per-memory list: haul card (stars earned / possible + bar), task rows with tint
  icon tiles, star value, expiry countdown (**coral when < 24h**), COMPLETED
  section with day earned.
- Task popup sheet: reward + photo-needed tiles, "Open camera" CTA → capture →
  completion + stars, "Maybe later".
- Entry: stars badge on Home header (+ journal contexts).

## 13. Stars ✅

- Ledger server-side; values: note 1 · photo 2 · quest 1 · bonus per template.
- **Star award toast** (shared component): "✦ +2 stars · photo logged" etc.,
  auto-dismiss ~1.65s; the only success affordance (no snackbars for awards).
  Unchecking never removes stars.

## 14. Location capture — backend (unchanged)

- Auto geotag on photo upload (permission-gated, never blocks); optional place
  text on quests/photos; feeds wrap-up map + Places/Countries stats.

## 15. Wrap-up playback ✅ — NOW DESIGNED

- One long controlled scroll (user-driven, not autoplay):
  **Hero** (ken-burns cover, staggered title reveal) → **Chapter one · The route**
  (animated route draw, node dots, place labels, KM/stops stats) → **Chapter two ·
  What you saw** (photo beats with ken-burns + second-person AI narrative in
  italic serif) → **Chapter three · By the numbers** (stat cards with animating
  bars) → **Achievement moment** (badge unlocked card) → close line + "Open
  journal" / "Keep forever".
- Generation pipeline unchanged: edge function → Anthropic → screenplay JSONB in
  `wrap_ups.content`; app renders live; MP4 export post-MVP.

## 16. Profile ("You") ✅ — redesigned

- Avatar with stars pill, name, @handle, bio, joined date; stats row (Memories ·
  Countries · Days · Stars); achievements 2-col grid — earned vs locked with
  progress bar + mono progress line ("9 OF 14 DAYS"). Canonical badge set: our
  seeded 8 (design's sample names are placeholders where they differ).

## Out of scope for MVP

Social feed, follows/likes/comments, public profiles, shared memories, star
redemption, video export, route planner, multi-currency, web app.

## Design gaps (residual)

1. Wrap-up **edit** mode (reorder/remove blocks) — playback is designed, editing
   UI is not. Decide: design it, or ship publish-only first.
2. Cover **photo upload** (design shows an "Upload photo" pill) — MVP could ship
   bundled covers + "Set as cover" from Photo detail only. Confirm.
3. Quest rows in the mockup show per-quest ✦ values — with our flat ✦1, show a
   uniform ✦1 badge or none. Pick at implementation.

## Monetization (context)

Freemium: free = 3 memories & basics; paid = unlimited, full features, export.
