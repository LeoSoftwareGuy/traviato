# Trevy — Issue Backlog (MVP, v5)

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

### M3-7a Migration: bonus tables reshape + template seed
Amends M3-3 tables per data-model v4: templates gain code/phase/kind, drop
duration_hours/trigger; assignments gain day_date, drop status/expires_at
(+ unique constraint). Reseed ~30–35 templates (≥20 anytime+middle, 3–4
arrival, 2–3 departure, 1 starter, 2–3 stretch, 3 milestone, 1 streak-saver).
Update award RPC seam if it read dropped columns. RLS/grants; db reset.

### M3-7b Bonus tasks feature (daily tray)
Handoff §10 layout with intentional deviations (no countdowns/urgency).
Deterministic 2-per-day draw (day-one 3 + starter), phase filter, 10-day
no-repeat, idempotent assignment insert; slot filling from trip context;
tray UI + earned state + opt-in stretch; streak-saver condition (2 quiet
days); milestone days 7/14/21; completion via photo capture → RPC + toast;
COMPLETED section with day. Entry: Home stars badge + Journal contexts.
Tests: draw determinism/no-repeat/phase rules, day-one composition,
streak-saver + milestone triggers, completion flow.

### M3-7c Bonus notifications (local)
flutter_local_notifications (justify dep). Morning 9:00 if yesterday had
activity; evening 19:00 if undone AND app opened today; arrival-day from
start_date; never after 21:00; skip when tray complete; mute after 3
ignored (approximation documented). Permission prompt UX; scheduling on
app lifecycle events; tests for the rule matrix (time-injectable).

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


## Milestone 5 — Monetization (post-MVP, not yet scoped into issues)

Parked here so it isn't lost. Needs real product/pricing decisions before it
becomes issues — each bullet below is a question to answer first, not a task.

### Open decisions (answer before drafting M5 issues)
1. **Price & tiers.** Confirmed direction so far: free tier capped at 3
   memories + basics; paid tier unlocks unlimited memories + full features +
   export. Still needed: actual price point(s), monthly vs. annual, and
   whether there's more than one paid tier (e.g. a higher tier for the
   future MP4 export once that exists).
2. **Enforcement points** — where limits are actually checked:
   - Memories per account (already noted app-side in data-model.md; needs
     moving server-side — a client-only check is trivially bypassed)
   - Photos per memory (NEW — not yet in data-model; needs a limit value
     decided, e.g. free = N photos/memory, paid = unlimited or a much
     higher cap)
   - Possibly: wrap-up generations, since each one costs a real Anthropic
     API call (a free-tier cap here directly protects your margin)
3. **Billing platform.** In-app purchase / subscription via
   RevenueCat (recommended — handles both App Store + Play Store receipt
   validation and entitlement state in one place) vs. rolling your own
   StoreKit/Play Billing integration. RevenueCat is the standard choice for
   a solo/small team; flag if you want to evaluate alternatives.
4. **Entitlement source of truth** — server-side, not client-side. A
   `subscriptions` or `entitlements` table (or RevenueCat's own webhook
   updating one) that RLS/RPCs check before allowing an over-limit action —
   never trust the app's own "am I premium" flag for anything that gates a
   write.

### Anticipated issues (draft once the above is decided)
- M5-1 Migration: subscription/entitlement tracking (table + RLS + a
  `has_active_subscription()` or tier-check helper used by other RPCs)
- M5-2 RevenueCat (or chosen platform) integration + purchase flow UI
- M5-3 Server-side enforcement: memories-per-account limit moved from
  app-side check to a DB-level guard (RPC or trigger)
- M5-4 Photo-per-memory limit: schema + enforcement + UI (upload blocked/
  upsell prompt at the cap)
- M5-5 Paywall / upgrade screens (design not started)
- M5-6 Restore purchases, subscription management entry point (links to
  App Store/Play Store subscription settings — cannot be built custom,
  platform policy)

---

## Notes
- Copy the handoff into the repo: `docs/design/` (README + dc.html + assets;
  incl. `journal/balloons_wide.png` into `assets/images/journal/`).
- Suggested weave: R-1 → M3-1 → M3-3 → R-3/R-5 → M3-2 → M3-6 → M3-8 →
  M3-4 → M3-5 → M3-9 → M3-7 → R-2/R-4/R-6 anytime → M4.
- Residual design gaps: wrap-up EDIT mode; cover upload pill.
