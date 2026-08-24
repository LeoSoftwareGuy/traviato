# Trevy — Issue Backlog (MVP, v4 — post-redesign-handoff)

Design source: `docs/design/` handoff (13 screens). Numbering rule unchanged:
real numbers at issue creation; working IDs until then.

---

## Milestone 1 — Foundation ✅ DONE (#1–#5)
## Milestone 2 — Memories & planning ✅ DONE (#11–#15 + checklist pair)

---

## Milestone R — Redesign alignment (new; can interleave with M3)

Built screens predate the handoff. Tokens already match the repo, so this is
layout/component work, not a re-theme. Do R-1 first; the rest in any order.

### R-1 Theme additions + shared redesign components
JetBrains Mono font + `AppTypography.mono`; new colors (primaryLight,
accentPurpleLight, accentBlue, scrim) + tinted-fill helpers; the three gradient
recipes; **star award toast** (awardPop, single success affordance);
bottom nav + gradient FAB restyle; bottom-sheet chrome (riseIn); photo-scrim
helper; motion constants. Tests for toast + nav.

### R-2 Guest landing + auth restyle
Handoff §1–2: polaroid hero, occasion chips, how-it-works, testimonial, pulsing
CTA; auth segmented toggle, focus states, reward-tease card. Copy says Trevy.

### R-3 Home restyle
Handoff §3: mono eyebrow header, tappable stars badge → Bonus, hero card with
trip-progress bar + dashed Checklist row, Coming up cards with planning state
(whole card → Plan), Kept forever grid → Wrap-up (route stub until M4).

### R-4 Create memory: cover picker (+restyle)
Handoff §4: 8 bundled cover options, vibe-based auto-suggestion (mapping per
handoff), selected/empty states; `cover_image_path = asset:<id>`; upload pill
deferred (open question). Reward-nudge card.

### R-5 Plan: banner + manage-memory sheet (+restyle)
Handoff §5 + manage sheet: cover banner, day pager segments, timeline rail;
⋯/Edit → sheet: rename, date shift ±1d (re-dates quests/notes/photos in one
repo operation + event), cover change, two-step delete (copy: stars are KEPT).
Quest ✦ badge: uniform ✦1 or none — decide in plan comment.

### R-6 Checklist restyle
Handoff §6: gradient overall bar, tab inline counts, Essential coral badges,
packed toast (no stars).

---

## Milestone 3 — During the trip

### M3-1 Migration: day_notes + photos + storage bucket
As before **plus `photos.use_in_wrap_up bool default false`**.

### M3-2 Journal screen
Handoff §7: photo day tabs, day title/sub-line, note card (serif italic body,
EDITED/WORDS footer, ✦1 via RPC seam), photos strip (add tile ✦2 copy),
To Do → Plan, wrap-up gradient button (disabled until M4), achievement-nudge
card (stub until M3-3). Delete moved to manage sheet (R-5) — not here.

### M3-3 Migration: points_ledger + bonus + achievements + RPCs
Unchanged from v3 draft (canonical values; 8 badges; profile_stats_view;
trip_card_view stars).

### M3-4 Migration: expenses + expense_summary_view — unchanged

### M3-5 Expenses feature — EXPANDED per handoff §8
Overview (search, sort latest-first⇄biggest, relative bars, load-3-more) +
**selected-memory breakdown** (total/per-day cards, biggest category, by-category
bars, all-expenses zebra list, empty state) + add-expense sheet. Compare link
present → M3-9.

### M3-6 Photo capture & upload
As before; award ✦2; success toast; feeds Journal strips/tabs.

### M3-7 Bonus tasks
Handoff §10: haul card, urgency-coral countdowns, completed-with-day rows,
popup sheet with reward/photo tiles, camera CTA → capture → completion.
Entry: Home stars badge (wired in R-3).

### M3-8 Photo detail + tagging — NEW (handoff §13)
Full-bleed pager, place row (+coords), people chips (free-text tag/untag),
caption edit, **Set as cover** (writes cover_image_path storage path),
**Use in wrap-up** toggle (use_in_wrap_up). From Journal photo tap.

### M3-9 Expenses · Compare — NEW (handoff §9)
Pair selection (A orange / B purple, promote/swap rules), comparison table
(larger-value emphasis, — for missing, total + per-day rows), computed verdict
card, done-comparing reset. Pure client-side derivation; tests for pairing
rules + verdict math.

---

## Milestone 4 — Wrap-up & profile

### M4-1 Migration: wrap_ups + edge function generate_wrap_up
Unchanged; generator prioritizes `use_in_wrap_up` photos.

### M4-2 Wrap-up playback — NOW DESIGNED (handoff §12)
Controlled-scroll recap: ken-burns hero + staggered reveal, route-draw chapter,
photo beats + second-person narrative, animated number cards, achievement
moment, close CTAs. Mapbox route per screenplay; fallback for no-location
memories; mapbox_maps_flutter dep justified.

### M4-3 Wrap-up publish (editing TBD)
Playback ships with "Keep forever" → published_at. Block editing UI is NOT in
the handoff — design it or defer editing post-MVP (open decision).

### M4-4 Profile & achievements — handoff §11
Avatar + stars pill, @handle, bio, joined, stats row, achievements grid with
locked-state progress bars (our seeded 8); logout.

---

## Notes
- Copy the handoff into the repo: `docs/design/` (README + dc.html + assets;
  incl. `journal/balloons_wide.png` into `assets/images/journal/`).
- Suggested weave: R-1 → M3-1 → M3-3 → R-3/R-5 → M3-2 → M3-6 → M3-8 →
  M3-4 → M3-5 → M3-9 → M3-7 → R-2/R-4/R-6 anytime → M4.
- Residual design gaps: wrap-up EDIT mode; cover upload pill.
