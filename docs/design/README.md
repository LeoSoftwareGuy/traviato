# Handoff: Traviato — Memory Journal Redesign (13 screens)

## Overview

A redesign proposal for **Traviato**, the travel memory journal app. Users create *memories* (trips), plan them day by day as *quests*, log notes and photos while travelling, and at the end get a cinematic wrap-up. Stars (✦) and achievements reward logging.

This handoff covers **13 screens**, including three that did not exist before:
- **Wrap-up playback** — the emotional payoff, a scrollable cinematic recap
- **Expenses · Compare** — two-memory financial comparison
- **Photo detail** — place + people tagging

It also reworks **Expenses** (memory list → selected-memory breakdown) and the **Guest landing** copy.

Target repo: `LeoSoftwareGuy/traviato` (Flutter, branch `main`).

## About the Design Files

The file in this bundle — `Wander - Travel Memory Journal.dc.html` — is a **design reference created in HTML**. It is a prototype showing intended look and behaviour. It is **not production code to copy**.

The task is to **recreate these designs in the existing Flutter codebase**, using its established patterns: the theme constants in `lib/core/theme/`, the feature-folder structure under `lib/features/`, and whatever widget and state conventions the repo already uses (Riverpod/BLoC/etc. — follow what is there). Every colour, radius, spacing and text style below is expressed as the existing Flutter token where one exists, so the implementation should reference `AppColors.x` / `AppRadius.y` rather than hard-coded literals.

Where a value has **no existing token** (noted inline), add it to the theme file rather than inlining it.

## Fidelity

**High-fidelity.** Final colours, typography, spacing, radii, copy and interactions. Recreate pixel-accurately at a 402×874 logical viewport (iPhone 14 Pro class). All type sizes, paddings and radii below are logical px = Flutter logical pixels, 1:1.

---

## Design Tokens

### Colours — all map to existing `lib/core/theme/app_colors.dart`

| Design use | Value | Flutter token |
| --- | --- | --- |
| App background / scaffold | `#0C0F27` | `AppColors.background` |
| Card / surface | `#131736` at 70% opacity | `AppColors.surface.withOpacity(.7)` |
| Surface (solid, sheets) | `#131736` | `AppColors.surface` |
| Border / divider | `#1D2248` at 90% | `AppColors.border.withOpacity(.9)` |
| Primary accent | `#F29520` | `AppColors.primary` |
| Primary — warm light variant (serif emphasis, headings' italic) | `#F2A65A` | **new** — add as `AppColors.primaryLight` |
| Secondary / coral | `#FF6D79` | `AppColors.secondary` |
| Purple accent | `#8962C5` | `AppColors.accentPurple` |
| Purple — light (compare column B text) | `#C9A9F5` | **new** — add as `AppColors.accentPurpleLight` |
| Success / positive | `#5FBF8E` | `AppColors.success` |
| Blue (Shopping category) | `#4FB0D8` | **new** — add as `AppColors.accentBlue` |
| Text primary | `#FBFAF6` | `AppColors.textPrimary` |
| Text secondary | `#AEACB7` | `AppColors.textSecondary` |
| Text muted | `#92909E` | `AppColors.textMuted` |
| Text faint / mono labels | `#6D6D7A` | `AppColors.textFaint` |
| Scrim (modal barrier) | `#07091A` at 72% + 7px blur | **new** — `AppColors.scrim` |

**Tinted fills** used for icon chips and status cards — always the accent at 10–18% alpha over the surface:
- primary tint `rgba(242,149,32,.16)`, primary card wash `.10`, primary border `.32`–`.55`
- coral tint `rgba(255,109,121,.16)`, card wash `.10`, border `.30`
- purple tint `rgba(137,98,197,.16)`, card wash `.10`, border `.30`
- success tint `rgba(95,191,142,.16)`, blue tint `rgba(79,176,216,.16)`
- neutral tint `rgba(174,172,183,.14)`

### Gradients

Only three gradient recipes exist in this design. Do not invent more.

1. **Screen ground** — radial, from the top centre, navy → background:
   `RadialGradient(center: Alignment(0, -1.1), radius: 1.2, colors: [#1E1B45, #111436, #0C0F27], stops: [0, .44, 1])`
   Variants per screen swap the first colour: Home `#1E1B45`; Landing/Auth/New `#241C4E`; Bonus/Profile `#2A1E52`; Plan/Checklist/Expenses use a simple vertical `[#141238 → #0C0F27]` with the stop at 34–38%; Journal `[#181541 → #0C0F27]` at 40%.
2. **Photo scrim** — vertical, for text over imagery:
   `LinearGradient(begin: bottomCenter, end: topCenter, colors: [#0C0F27 @ .88–.94, #0C0F27 @ .05–.15, transparent])`. On the Home hero the top adds a warm lift: final stop `rgba(255,200,140,.16)`.
3. **Primary CTA / star bar** — `LinearGradient(135°, [#F29520, #FF6D79])`. The plain primary button is **flat `AppColors.primary`**, not a gradient; the gradient is reserved for the FAB, the packing-progress bar, and the "View wrap-up" button.

### Typography

Two families, matching `app_typography.dart`:
- **Display / serif — Fraunces.** Weight 400 only. Used for every heading, every number that is a *quantity the user cares about* (totals, stats, day counts), and italic pull-quotes. Optical sizing on. Letter-spacing `-0.4px` at 36px, `-1px` at 46px, otherwise 0.
- **Body — Roboto.** Weights 400/500/600. Never 700.
- **Mono — JetBrains Mono**, weight 500, for eyebrow labels and metadata. Always uppercase with `letter-spacing: .10–.18em`. This is a *label* voice — dates, counts, category names, section headers. **This is new**; add to `pubspec.yaml` fonts and expose as `AppTypography.mono`.

| Role | Font | Size / line-height | Weight | Colour |
| --- | --- | --- | --- | --- |
| Hero headline (landing, wrap-up) | Fraunces | 36–46 / 1.02–1.1 | 400 | textPrimary; emphasis span in primaryLight, italic |
| Screen title | Fraunces | 26–30 / 1.15 | 400 | textPrimary |
| Card title | Fraunces | 15–21 / 1.2 | 400 | textPrimary |
| Big number (total, stat) | Fraunces | 21–42 / 1 | 400 | textPrimary or primary |
| Pull-quote / narrative | Fraunces italic | 14–17 / 1.65–1.75 | 400 | textSecondary |
| Body | Roboto | 11.5–13.5 / 1.5–1.65 | 400 | textSecondary / textMuted |
| Body emphasis, list item | Roboto | 12.5–14 | 500 | textPrimary |
| Button label | Roboto | 12.5–15 | 600 | `#0C0F27` on primary fill |
| Eyebrow / metadata | JetBrains Mono | 8.5–10 | 500 | textFaint (or primary when active) |
| Chip label | Roboto | 12–12.5 | 500 | textSecondary → primary when selected |

### Spacing

Screen horizontal padding is **22px** everywhere except the Landing and Wrap-up, which use **24–26px**. Top padding below the status bar is **58px** (Landing 56px). Vertical rhythm between sections: **16 / 18 / 20 / 22 / 24px** — use the 2px-step scale in `app_spacing.dart`; nothing off-scale.

Gaps: 7px between chips, 8–9px between cards in a row, 9–11px between stacked list rows, 10–12px in grids.

### Radii — from `app_radius.dart`

| Element | Value | Token |
| --- | --- | --- |
| Chips, pills, badges, progress bars | fully rounded | `999` / `StadiumBorder` |
| Small icon tile (22–30px) | 7–10 | `AppRadius.small` (8) |
| Input, list row, stat card, button | 16 | `AppRadius.medium` (16) |
| Photo tile, day tab | 16 | `AppRadius.medium` |
| Hero card, banner, table, FAB | 20–24 | `AppRadius.large` (24) |
| Bottom sheet | 26 top corners only | `AppRadius.large` |
| Avatar, check circle | 50% | circle |

### Shadows

Sparingly. Only three:
- Hero card: `0 20px 46px rgba(0,0,0,.45)`
- Polaroid / floating photo: `0 16px 34px rgba(0,0,0,.6)`
- FAB and pulsing CTA: `0 10px 26px rgba(242,149,32,.34)`

### Motion

| Name | Spec | Where |
| --- | --- | --- |
| `riseIn` | 300–350ms, `cubic-bezier(.2,.8,.2,1)`, opacity 0→1 + translateY 16→0 | Bottom sheets, comparison table appearing, wrap-up hero text (staggered 0/150/300ms) |
| `awardPop` | 1650ms total, ease-out; opacity + translateY -6→-22 + scale .9→1.04→1 | Star award toast |
| `barFill` | 1600ms ease-out, width 0→target | Wrap-up stat bars |
| `progress` | 400–450ms `cubic-bezier(.2,.8,.2,1)` on width | Checklist / expense bars when values change |
| `kenburns` | 16–18s ease-out, infinite alternate; scale 1.03→1.18 + translate(-2%,-2%) | Wrap-up photo beats, hero |
| `drawRoute` | 4500ms ease-out forwards, stroke-dashoffset 900→0 | Wrap-up map route |
| `twinkle` | 2.6–4.2s ease-in-out infinite, staggered delays; opacity .12→.85, scale .7→1.15 | Star specks on Landing / wrap-up map |
| `floatY` | 5–7s ease-in-out infinite; translateY 0→-7 | Polaroids, empty-state ✦ |
| `pulseGlow` | 3.6s ease-in-out infinite; box-shadow spread 0→14px, primary at .32→0 | Landing CTA only |

Hover/press states (translate to Flutter `InkWell` / `AnimatedContainer`): a tappable card lightens its border to `primary @ .5`; a nav/menu row gets `primary @ .10` background; the primary button brightens 8%.

---

## Screens / Views

Order below matches the in-prototype rail. Bottom nav (Home · ➕ · Expenses) is present on Home, Plan, Checklist, Journal, Expenses, Compare, Bonus, Profile — absent on Landing, Auth, New memory, Wrap-up, Photo detail.

### 1. Guest landing
**Purpose:** pre-auth marketing page.
**Layout:** scrolls; sticky CTA footer.
- **Nav bar** — 25px rounded-9 logo mark with `✦` on a `[#F29520 → #FF6D79]` 150° gradient, "Traviato" in Fraunces 20; right-aligned "Log in" (Roboto 600/12.5, textSecondary → primary on hover). Padding 0 24.
- **Star specks** — 4 absolutely-positioned dots, 2–3px, alternating `#F29520`/`#F6C77A`/white, each with a different `twinkle` delay.
- **Hero** — 286px tall, `assets/images/guest/hero.png` at `center 28%`, cover. Scrim: vertical `[#0C0F27 @ .55, transparent @ 34%, #0C0F27 @ .7 at 82%, #0C0F27]`. Two "polaroids" overhang the bottom edge: left 104×124 rotated -8°, right 96×114 rotated +7°, both `#FBFAF6` frames with 6px padding / 20px bottom lip, holding `guest/honeymoon_escape.png` and `guest/solo_getaway.png`, each on `floatY`.
- **Value block** (padding 46 26 0):
  - Eyebrow: `YOUR MEMORY COMPANION` — mono 9.5, `.18em`, primary
  - Headline: "Every memory," / *"beautifully captured"* — Fraunces 36/1.1, second line italic in primaryLight
  - Body: "No more messy folders. Weddings, trips, birthday weekends — your moments deserve more than a desktop dump." — Roboto 13.5/1.65, textSecondary, max-width 300
  - Occasion chips, wrapping row gap 7: **Weddings · Trips · Birthdays · Milestones** — 8×14 padding, stadium, surface fill, border, Roboto 500/12, textSecondary
- **How it works** (padding 32 26 0) — "How it works" Fraunces 22, then three stacked cards, gap 10, each 15×16 padding, radius 16:
  1. **Capture the moment** — "Photos, notes, and highlights — drop them in as you go. Works for a wedding weekend, a birthday trip, or just a really good Tuesday."
  2. **Stay organized, effortlessly** — "For multi-day events, we'll keep each day tidy with prompts and structure. For single moments, jump right in — no folders needed."
  3. **Relive it all** — "At the end, watch your entire memory line replay on a beautiful timeline — every photo, every note, every moment, in order."
  Each has a 26px rounded-9 numeral tile (primary tint fill, primary text, Roboto 600/12) at left, title Fraunces 17/1.2, body Roboto 12/1.6 textMuted. **Card 3 is highlighted**: primary wash `.10` + primary border `.35`.
- **Sample memories** — horizontal scroller, 132px cards, 88px image, name in Fraunces 13 over scrim, meta row in mono 9.5 on surface.
- **Testimonial** — purple wash `.10`, purple border `.32`, radius 16: italic Fraunces 15/1.55 "I stopped losing my trips to the camera roll. The wrap-up made me cry a little." + 21px avatar and "Mira K. · 14 memories".
- **Sticky CTA** — footer with `[transparent → #0C0F27 @ 42%]` fade; button flat primary, radius 16, padding 16, label **"Start capturing your moments"** Roboto 600/15 on `#0C0F27`, `pulseGlow`.

### 2. Register / Log in
**Purpose:** auth.
Back link; headline "Begin your" / *"collection."* Fraunces 32/1.15. A 2-up segmented toggle (Create account | Log in) in a 5px-padded stadium track on surface — active segment is flat primary with `#0C0F27` text, radius 10. Fields are 12×15 radius-16 surface cards with a mono 9.5 label above a Roboto 500/14 value; the **focused field's border is primary and its label turns primary**. Name field only in signup mode. Password strength: three 3px stadium segments, 2 filled primary, + "Good" Roboto 500/10. Primary CTA label switches "Create my account" / "Log in". Footer note mono-free, Roboto 400/11 textFaint: "Your memories stay yours — nothing is ever published." Below it a dashed-border card teases the reward: 34px `✦` tile + "Your first memory earns **10 stars** — and the Storyteller badge is only three notes away."

### 3. Home
**Purpose:** hub.
- **Header** — left: mono eyebrow `MON · 24 AUG` in primary, then "Hello, Ada" Fraunces 29/1.1. Right: **stars badge** — stadium, primary tint `.15`, primary border `.35`, `✦` + count Roboto 600/12 primary; **tappable → Bonus tasks** (hover deepens fill to `.28`, border to solid primary). Then 38px circular avatar with a primary `.5` 1.5px ring → Profile.
- **Stats bar** — three equal cards, gap 8, 11×12 padding, radius 16: value Fraunces 23, key mono 9 textFaint. `12 MEMORIES · 7 PLACES · 64 DAYS`.
- **Happening now** — mono section label, then the hero card: radius 24, primary border `.28`, surface fill, hero shadow.
  - 206px cover (`journal/balloon_1.jpg` at `center 40%`) with the warm photo scrim. Top-left chips on a blurred `#0C0F27 @ .62`: "Day 2 of 5" (primary-light text) and the vibe "Road trip". Bottom: title Fraunces 26/1.12 white, subtitle Roboto 500/11 white `.7` (`{place} · {dates}`), then a 4px trip-progress bar — white `.2` track, primary fill at `day/total`.
  - Action row, gap 7: **Plan** and **Expenses** on `#1D2248 @ .7` radius 12; **Journal** flat primary with `#0C0F27` label. Beneath, full-width **Checklist** row — dashed border, label left, "26 of 38 packed →" in primary right.
- **Coming up** — horizontal scroller of 150px cards, radius 20. 92px image + scrim; countdown badge top-right in flat primary (`in 26d`). Body: name Fraunces 16, dates mono 9.5, then a row with **planning state** in primary Roboto 600/9.5 ("6 quests planned" / "Nothing planned yet") and "Plan →" in textFaint. **Whole card is tappable → Plan** (border → primary `.55` on hover) so a user can plan months ahead.
- **Kept forever** — 2-col grid, gap 11, radius 20 cards: 106px image, "▸ Recap" badge top-left on blurred dark, name Fraunces 15/1.2, meta mono 9.5 (`9 DAYS · 214 PHOTOS`). Tap → Wrap-up.

### 4. New memory
**Purpose:** create a memory in one screen.
- Header: "✕ Cancel" left, mono `NEW MEMORY` right.
- **Cover picker** (this is new): a 150px radius-24 slot.
  - *Empty state*: fill `LinearGradient(160°, [primary @ .14, purple @ .14])`, dashed-feel border `rgba(174,172,183,.28)`; centred floating `✦`, "Choose a cover" Fraunces 16, "or we'll pick one that suits the vibe" Roboto 10.5 textMuted. Bottom-left mono tag reads `SUGGESTED: {FIRST VIBE}`.
  - *Chosen state*: the image with the standard photo scrim, primary `.4` border, mono tag `YOUR COVER`.
  - Bottom-right always: "↑ Upload photo" pill on blurred dark.
  - Below, a horizontal strip of 60×46 radius-12 thumbnails (8 options). Selected gets a 2px primary border **and** a primary `.28` overlay with a white `✓`.
  - **Auto-selection rule:** if the user picks no cover, choose the first option whose `vibe` is among the selected vibe chips; fall back to the first option. Cover option → vibe mapping used: balloons→Slow, balloon1→Road trip, hero→Adventure, honeymoon→Romantic, food→Foodie, solo→Solo, family→Nature, bucket→Culture.
- Title "What deserves" / *"a memory?"* Fraunces 30/1.15.
- Fields: **Name it** (focused: primary border, value in Fraunces 19 with a primary caret), **Where did it happen?** (with a `◎` locate affordance), then **Starts** / **Ends** side by side.
- **The vibe** — label + "{n} chosen"; 10 wrapping chips, stadium, 9×14: unselected surface/border/textSecondary, selected primary `.18` fill, primary `.55` border, primary text. Fixed set: Romantic, Adventure, Foodie, Road trip, Slow, Solo, City, Nature, Culture, Budget.
- Reward nudge card (purple wash): "Creating this earns **10 stars**. Log a note each day and you'll unlock **Storyteller**."
- CTA: "Create memory".

### 5. Plan
**Purpose:** per-day quest timeline.
- Header: back, mono `THE PLAN`, then two 32px radius-11 icon buttons — **☑ Checklist** (primary glyph) and **⋯ Manage** (textSecondary → primary on hover).
- Trip name Fraunces 27/1.15 with an "Edit" link right → manage sheet.
- **Banner** (new): 118px radius-24, `journal/balloons_wide.png` cover, scrim; bottom-left mono dates in primary-light + "Cortina d'Ampezzo" Fraunces 16, bottom-right "Day 2 of 5" pill on blurred dark.
- Summary line: "25 quests planned · 5 days total · ✦46 to earn" Roboto 500/11 textMuted.
- **Day pager** — 34px radius-12 arrow buttons flanking a centred "Day 3" Fraunces 19 + "24 Aug · 2 of 5 done" mono 9.5. Below, 5 tappable 3px segments; active is primary, rest border-colour.
- **Quest timeline** — a 1px vertical rail at x=39 running `[primary @ .5 → border]`, behind the rows. Each quest: radius-16 row, 13×14 padding; 22px check circle (unchecked: 1.5px `rgba(174,172,183,.4)`; checked: filled primary with a `#0C0F27` ✓); time in mono 11 primary; title Fraunces 16 (checked → textSecondary + line-through); detail Roboto 11.5/1.45 textMuted; right-aligned `✦{n}` in mono 10. Checked rows get primary `.09` fill and primary `.4` border. **Tapping awards the quest's stars.**
- Footer: dashed "+ Add a quest to Day 3".

### 6. Checklist
Title "Pack for the mountains" Fraunces 26. Overall bar: 7px stadium track, fill `[primary → coral]` with the 450ms width transition, plus "26 of 38 packed" primary label. Category tabs: horizontal stadium chips carrying an inline count (`5/7`) at 80% opacity. Items: radius-16 rows, 20px rounded-6 checkbox, label Roboto 500/13.5 (checked → strikethrough textSecondary), optional **Essential** badge — coral tint fill, coral `.32` border, Roboto 600/9. Custom add row: dashed border, primary `+`, "Add something of your own…". Categories & item counts: Travel essentials 7, Clothing & shoes 6, Toiletries & health 4, Gadgets & tech 4, Nice-to-haves 4.

### 7. Journal
Header: back, mono `JOURNAL`, per-memory stars badge (informational).
- **Day tabs** — five 62px columns: a 62px radius-16 image tile (the three balloon photos, distinct per day) with scrim and "Day 1" label; active tile gets a 1.5px primary border and its date below turns primary. Dates mono 9.
- Title "Day 2 — the lake before the buses" Fraunces 26/1.15; sub-line "Lago di Braies · 14 km walked · 3 quests done".
- **Note card** — radius 16, surface: italic Fraunces 14.5/1.7 body, then a footer row `EDITED 21:04 · 128 WORDS` (mono 9.5) and "Add notes about today" in primary.
- **Photos strip** — "TODAY'S PHOTOS · 6" + "Select". First tile is the **add tile**: 88×110, dashed primary `.5` border, primary `.08` fill, `＋` + "Add ✦1" — **tapping awards 1 star**. Then photo tiles 88×110 radius 16 with scrim and a mono timestamp bottom-left; tap → Photo detail.
- Two buttons: "To Do · 3 left" (surface, → Plan) and "View wrap-up ▸" (the `[primary → coral]` gradient, → Wrap-up).
- **Achievement nudge** — purple wash card: 30px `✦` circle, "Two more notes and **Storyteller** is yours.", and a 34px conic-gradient ring (`purple 75%`, rest border) with a `6/8` inner disc.

### 8. Expenses (reworked)
**Purpose:** spending across all memories, then one memory in depth.
- Header: back, mono `EXPENSES`, "Compare" link in primary.
- **Search + sort row** — search pill "Search memories" (non-functional in the prototype) and a sort pill "⇅ Latest first" ⇄ "⇅ Biggest spender". Active sort = primary tint fill/border/text.
- **MEMORIES list** — label + "3 OF 8" count right. Rows (radius 16, 13×14): 26px selection circle (selected → primary `.28` fill, primary border, white ✓), name Roboto 500/13.5, location Roboto 400/11 textMuted, right-aligned total Fraunces 18 and meta mono 9 (`11d · 6 items`), then a 5px relative-spend bar (width = total ÷ largest total across all memories) in the memory's own accent colour. Selected row: primary `.08` fill, primary `.55` border.
- **"Load 3 more"** dashed button while more remain. Page size 3, +3 per tap. **Ordering is latest-first by default** — do not sort by amount unless the sort pill is toggled.
- **Selected memory block** — separated by a top border, headed by a mono `{NAME} · {LOCATION}` in primary. Then:
  - Two cards: **TOTAL SPENT** (flex 1.25, primary wash, value Fraunces 29 primary) and **PER DAY AVG** (surface, Fraunces 22).
  - **BIGGEST CATEGORY** card — coral wash, 32px category-icon tile, mono label, "Accommodation — €312" Fraunces 16, share % right.
  - **BY CATEGORY** — per category: 22px rounded-7 icon tile, label, share % in mono, amount Fraunces 15 right-aligned in a 50px column; below, a 5px bar inset 31px whose width is `catTotal ÷ largestCatTotal`, in the category colour. Sorted descending.
  - **ALL EXPENSES** — label + "10 ITEMS · 5 DAYS"; rows of 28px icon tile, title, `{DAY} · {CATEGORY}` in mono 9, amount Fraunces 16. **Zebra striping**: even rows `surface @ .55`, odd transparent. Sorted by amount descending.
- **Empty state** (nothing selected) — dashed radius-20 panel, floating `✦`, "Pick a memory above", "You'll see the total, where it went, and every expense as you logged it."
- CTA "+ Add expense" opens the sheet.
- **Categories** (6, fixed): Food & drinks `✱` coral · Transport `⛢` purple · Accommodation `⌂` primary · Activities `▲` success · Shopping `◇` blue · Other `·` neutral.

### 9. Expenses · Compare (new)
**Purpose:** put two memories' spending side by side.
- Header: back, mono `COMPARE`, and a right-hand action pill that reads **"Pick two"** (inert, faint) when nothing is selected and **"✕ Done comparing"** (coral tint fill, coral border, coral text) once anything is — tapping clears both.
- Title "Which trip cost" / *"what, really?"*; hint line below changes with state: "Pick two memories to put their spending side by side." → "Now pick a second one." → "{A} vs {B} — tap either to swap it out."
- **MEMORIES list** — same row component as Expenses, but selection is a *pair*: **first pick is primary/orange, second is purple**; the row border and check-circle follow that colour.
  - Selection rules: tap an unselected row → fills A, then B. Tap A → B is promoted to A, B clears. Tap B → clears B. Tapping a third row when both are full → it becomes A and B clears.
- **FINANCIAL COMPARISON table** (appears with `riseIn` once both are chosen) — radius 20, surface, bordered:
  - Header strip: mono `FINANCIAL COMPARISON`.
  - Column header row: `CATEGORY` left; then two 80px right-aligned columns with each memory's name — A in primary, B in purple-light, Roboto 600/10 with 1.25 line-height so long names wrap rather than truncate.
  - One row per category present in either memory: icon + label left; A and B amounts in Fraunces 15, right-aligned, 80px columns. **The larger of the two is textPrimary; the smaller is textFaint** — that contrast is the comparison. Missing category renders `—`.
  - **Total** row on `#1D2248 @ .5`: label Roboto 600/12.5, amounts Fraunces 17 in each column's accent.
  - **Per day** row, same wash: label Roboto 500/11.5 textMuted, amounts Fraunces 14 textMuted.
- **Verdict card** below — primary wash, Roboto 12/1.6: computed sentence, e.g. "Iceland ring road cost €939 more overall, but Santorini blues ran €16/day higher. Santorini blues was the cheaper trip per day."

### 10. Bonus tasks
Header with stars badge. Title "Little dares," / *"while you're there."* + intro. Task rows: 44px radius-14 icon tile in the task's tint, title Fraunces 16/1.2, then `✦{n}` in primary and an expiry in mono — **coral when urgent (< 24h), textFaint otherwise**. Completed tasks use the success tint, a `✓` glyph, textSecondary title, and read `COMPLETED · DAY 2`. Haul card: "46 / 70 ✦" + a `[primary → coral]` bar at 66%.
**Task popup** (bottom sheet): 40×4 grab handle, 50px radius-16 `◉` tile, title Fraunces 21, expiry in coral mono; detail Roboto 13/1.6; two stat tiles (REWARD `✦n`, PHOTO NEEDED `1`); primary CTA "◉ Open camera" — **awards the task's stars and dismisses**; "Maybe later" text button.
Content: *Snap your first meal there* ✦1, 4h, urgent · *Something that reflects* ✦2, 19h · *A stranger who helped* ✦3, 2d · *Sunrise before anyone else* ✦2, completed.

### 11. Profile ("You")
Centred column: 86px avatar with a 2px primary `.55` ring and an overlapping `✦ 318` pill (flat primary) at bottom-right; name Fraunces 25; `@adawanders` mono 11 primary; bio Roboto 12.5/1.6 max-width 270; `JOINED MARCH 2024` mono 9.5.
Stats row of four (Memories 12 · Countries 10 · Days 64 · **Stars 318 in primary**), values Fraunces 21, keys mono 8.5.
**Achievements** — "6/8 earned" in primary; 2-col grid, radius 16, 14×13. Earned: surface fill, primary `.28` border, primary-tint 38px rounded-13 icon tile, name Fraunces 15/1.2 textPrimary. Locked: surface `.45`, dim border, neutral tile, **textFaint name**, plus a 4px purple progress bar and a mono progress line (`9 OF 14 DAYS`). Set: Globetrotter, Shutterbug, Storyteller, Early riser, Trailblazer, Completionist (earned); Nomad 64%, Cartographer 40% (locked).

### 12. Wrap-up playback (new — the payoff)
**Purpose:** the cinematic recap. **Shape: one long controlled scroll**, not autoplay — the user drives the pace.
- **Hero, 640px** — full-bleed cover on `kenburns`; scrim `[#07091A @ 2%, .35 @ 46%, .55]`. A `✕` on blurred dark closes to Home; "SCROLL TO RELIVE ↓" in mono top-right. Bottom stack, each on `riseIn` staggered 0 / 150 / 300ms: mono `THE WRAP-UP · AUG 2026` in primary-light; title "Dolomites," / *"slowly"* Fraunces 46/1.02, `-1px` tracking; italic Fraunces 15/1.6 "Five days of thin air, cold lakes and bread eaten standing up."
- **Chapter one · The route** — a 260px radius-24 panel, `[#141238 → #0C0F27]` 170°, two twinkling specks. An SVG route on a 320×260 viewBox: the path `M46 214 C 96 176, 84 128, 138 118 S 214 96, 232 52 S 268 34, 286 44` drawn twice — a `primary @ .22` 8px casing beneath, and a 2.5px primary stroke on `drawRoute`. Node dots: 5.5r primary at the start, 4r coral at the two waypoints, 5.5r white at the end. Place labels in mono (`VENICE` textSecondary, `CORTINA` white). Bottom-right: `312 KM` and `4 STOPS` — Fraunces 15 value + mono 9 unit.
- **Chapter two · What you saw** — for each of 3 beats: a 300px full-bleed photo on `kenburns` with a bottom scrim, captioned with mono `DAY 2 · 06:12` in primary-light and the place in Fraunces 25/1.15 white; then, on the dark ground below, the AI narrative in **italic Fraunces 15/1.75 textSecondary**. Narratives are second-person and specific — "You were the first ones there. The lake held the mountain upside down and neither of you said anything for ten minutes."
- **Chapter three · By the numbers** — 2-col grid of radius-16 surface cards: value Fraunces 30, key mono 9.5, and a 3px bar animating with `barFill`. `312 KILOMETRES DRIVEN` (primary) · `41 ON FOOT` (coral) · `84 PHOTOS KEPT` (purple) · `✦46 STARS EARNED` (primary).
- **Achievement moment** — radius-24 card, `LinearGradient(150°, [primary @ .16, purple @ .14])`, primary `.35` border, centred: floating `✦`, "Globetrotter unlocked" Fraunces 22, "Italy was your tenth country. You also earned **46 stars** on this trip."
- **Close** — centred italic Fraunces 17/1.65 "Some trips you finish. This one you'll keep."; then "Open journal" (surface) and "Keep forever" (primary).

### 13. Photo detail + tagging (new)
- **492px photo** with a top-and-bottom scrim. `←` back, `♡` and `⋯` on blurred dark circles. Bottom-left: mono `DAY 2 · 07:12` primary-light + place Fraunces 24 white. Bottom-right: 6 pager dots, active white, rest white `.35`.
- **Place row** — radius-16 surface card: primary `◎`, "Lago di Braies, Italy" Roboto 500/13 over `46.6946° N, 12.0851° E` in mono 9.5, "Change" in primary.
- **WHO WAS THERE** — label + "Tap a face to tag"; wrapping person chips: 22px gradient avatar + name, stadium, 7px left / 12px right padding. Tagged = primary `.18` fill, primary `.55` border, primary text. A dashed "+ Add" chip closes the row. People: Sam (tagged), Nora, Jonas, Me.
- **Caption card** — italic Fraunces 14/1.7 body + `CAPTION · TAP TO EDIT` in mono.
- **Actions** — "Set as cover" (surface) and "Use in wrap-up" (primary tint fill, primary border, primary text).

### Shared: Add-expense sheet
Bottom sheet, `[#1A1742 → #0F1230]`, radius 26 top, primary `.35` top border, `riseIn`. Grab handle; "New expense" Fraunces 22 + "Cancel". Memory selector row (26px cover thumb, name, `▾`). Then Description (flex 1.6) and **Amount** (flex 1, focused → primary border, value Fraunces 19) side by side. `CATEGORY` label + 6 chips with glyphs. Date row "Today · 24 Aug". CTA "Save expense".

### Shared: Manage memory sheet (new)
Opened from Plan (⋯ or "Edit"). Same sheet chrome; "Edit this memory" + "Done".
- **NAME** field, primary-bordered, value Fraunces 18, "Rename" action.
- **STARTS** / **ENDS** tappable cards side by side; helper line "Tap a date to shift it a day — quests move with it."
- **COVER** — the same 58×44 thumbnail strip with the selected-state treatment.
- **Delete** — two-step. Resting: coral `.10` fill, coral `.35` border, coral text, "Delete this memory". Armed: **solid coral fill with `#0C0F27` text**, "Yes — delete it forever", and a warning line "This removes 18 photos, 5 days of notes and 46 stars. It can't be undone." Confirming closes the sheet and returns to Home.

### Shared: Star award toast
Absolutely positioned, 104px from the top, centred, `pointer-events: none`, z above everything. Stadium, `primary @ .94` fill, `#0C0F27` text Roboto 600/13, shadow `0 14px 34px rgba(242,149,32,.35)`, `awardPop` then auto-dismiss at 1650ms. Copy pattern: `✦ +2 stars · quest done`, `✦ +1 star · photo logged`, `✦ Packed — nice`, `✦ +1 star · challenge done`.

### Shared: Bottom nav
Sticky, with a `[transparent → #0C0F27 @ 55%]` fade above it. Bar: `surface @ .92` + 14px blur, radius 22, bordered, 10×8 padding. Home and Expenses are 66px-min columns (15px glyph + Roboto 600/9.5 label), active in primary and inactive in textFaint. Centre **FAB**: 52px, radius 18, `[primary → coral]` 140°, `#0C0F27` `＋` at 22px, pulled up 16px, with the primary shadow. → New memory.

---

## Interactions & Behaviour

**Navigation graph.** Landing ⇄ Auth → Home. Home → Plan / Expenses / Journal / Checklist / Profile / Bonus (via the stars badge) / New memory (FAB) / Wrap-up (finished cards) / Plan (coming-up cards). Plan → Checklist, manage sheet. Journal → Photo detail, Plan, Wrap-up. Expenses → Compare, add-expense sheet. Photo detail → Journal, Wrap-up.

**Star economy.** Every logging action awards stars and fires the toast: quest check-off (1–3 per quest, per its own value), photo add (1), bonus task completion (its reward), packing an item (no stars, but a "Packed — nice" toast). Unchecking never removes stars. The Home and Profile counters read the same running total.

**Optimistic + instant.** All of these are local-state toggles with no spinner: quest checks, packing checks, vibe chips, cover selection, person tags, memory selection, compare pairing, sort, load-more. Progress bars animate to their new width over 400–450ms; the toast is the only "success" affordance — no snackbars, no dialogs.

**Two-step destructive action.** Delete arms on first tap (revealing consequences) and executes on second. Closing the sheet disarms it.

**Scroll behaviour.** Every screen is a single vertical scroll. Landing has a sticky CTA footer; the nav bar is sticky on the 8 screens that have it; Wrap-up and Photo detail are full-bleed with no nav.

**Not built (intentionally out of scope for the prototype):** live search filtering, real date pickers, camera/photo picker, actual upload. The affordances are present and positioned — wire them to the platform pickers.

## State Management

Screen-level state needed per feature (names from the prototype, map to your notifier/bloc of choice):

| State | Type | Notes |
| --- | --- | --- |
| `screen` | enum | routing in the prototype only — use real routes |
| `authMode` | `signup \| login` | segmented toggle |
| `day` | int 0–4 | Plan day pager; wraps at both ends |
| `jDay` | int 0–4 | Journal day tabs (independent of `day`) |
| `cat` | int | Checklist active category |
| `vibes` | `Set<String>` | New memory chips |
| `cover` | `String?` | chosen cover id; null → vibe-derived suggestion |
| `done` | `Map<String,bool>` | quest completion, keyed `"{day}-{index}"` |
| `packed` | `Map<String,bool>` | keyed `"{category}-{index}"`; drives both per-category and overall counts |
| `people` | `Set<String>` | photo tags |
| `stars` | int | running total |
| `award` | `String?` + a generation key | toast text; the key prevents an earlier timer clearing a newer toast |
| `selMem` | `String?` | Expenses selected memory |
| `shown` | int | Expenses page size, starts 3, +3 |
| `sortBig` | bool | false = latest-first, true = biggest-spender |
| `cmpA`, `cmpB` | `String?` | compare pair, with the promote/clear rules above |
| `sheet`, `manage`, `deleteArmed`, `bonusOpen` | bool / id | overlays |
| `tripName`, `startShift`, `endShift` | String / int | manage-sheet edits |

**Derived, never stored:** memory total (sum of items), per-day average (total ÷ days), category totals, biggest category, all bar widths (always a ratio against the max in the visible set), packed counts, quest done-counts.

## Assets

All imagery comes from **the repo's own `assets/images/`** — nothing external, nothing generated:
- `guest/hero.png` — landing hero
- `guest/honeymoon_escape.png`, `guest/solo_getaway.png` — landing polaroids, sample cards, compare thumbs
- `guest/food_lovers_weekend.png`, `guest/family_adventure.png`, `guest/bucket_list_moment.png`, `guest/epic_milestone.png` — memory covers, photo detail
- `journal/balloon_1.jpg`, `journal/balloon_2.jpg`, `journal/balloon_3.jpg` — Home hero, Journal day tabs, wrap-up beats
- `trip/new_memory.png`, `trip/planner.png` — cover options, photo detail
- `journal/balloons_wide.png` — **user-supplied**, added for the Plan banner; copy it into the repo's assets

Icons are single Unicode glyphs in the prototype (`✦ ✓ ◎ ⌂ ✱ ⛢ ▲ ◇ ☑ ⋯ ＋ ⇅ ▸ ♡ ◉ ☺ ◍ ✎ ☀`). **Replace each with the repo's existing icon set** at the same optical size; do not ship glyphs. `✦` is the star/reward mark and appears throughout — it deserves a proper asset.

Fonts: Fraunces + Roboto are already in use; **JetBrains Mono is new** and must be added.

## Files

- `Wander - Travel Memory Journal.dc.html` — the design reference. All 13 screens in one file with a left-hand rail to jump between them; every interaction listed above is live and tappable.
- `traviato-figma-import.html` — the same design as a single self-contained file, for importing into Figma via the html.to.design plugin if a Figma copy is wanted.
- `github.md` — records the repo association, the theme files the tokens came from, and a screen → source-file map.

## Suggested implementation order

1. Theme additions first — the 5 new colours, JetBrains Mono, the mono text style. Everything else depends on them.
2. Shared pieces — star award toast, bottom nav + FAB, bottom-sheet chrome, the memory-row widget (used by both Expenses and Compare), the photo-scrim helper.
3. Expenses rework, then Compare (Compare reuses the memory row and the category totals).
4. Plan banner + manage sheet; New memory cover picker.
5. Journal day tabs; Photo detail.
6. Wrap-up last — it is the most animation-heavy and depends on nothing else.
