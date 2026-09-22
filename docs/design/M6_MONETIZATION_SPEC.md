# M6 — Monetization & gating: implementation spec

Four pieces, all visible in the prototype `Wander - Travel Memory Journal.dc.html`:

| Ref | Piece | Where |
|---|---|---|
| M6-5 | Paywall | new full screen, screen 13 in the prototype picker |
| M6-6 | Subscription section | Profile, directly above Achievements |
| M6-4a | Locked wrap-up entry | Journal, the "View wrap-up" button + explainer card |
| M6-4b | Empty-day nudge | Journal, inside a day that has no content |

Where this document and the prototype disagree, **the prototype is correct**.

---

## 0. Two gates that must never be confused

The single most important thing in this spec. The app has two separate reasons
the wrap-up film might not be available, and they must look and read
differently:

1. **Content gate (M6-4)** — the memory doesn't have enough in it yet. This is
   *not* a paywall. It has no price, no upgrade button, and it says so out loud:
   "Nothing to buy — this one's the same on every plan." Free and Pro users see
   the identical gate.
2. **Plan limit (M6-5/M6-6)** — the user has used their 3 free memories and
   wants a 4th. This is the paywall.

If these two ever get merged into one "unlock" screen, the design is broken. A
user who hasn't taken five photos yet must never be shown a price.

---

## 1. Tokens

Already in the app; repeated so nothing is guessed.

```
primary  #F29520   amber — CTAs, Pro accents, met-requirement ticks
coral    #FF6D79   at/over limit only
purple   #8962C5   secondary perk icons (#C9A9F5 for the glyph itself)
dare     #4FB0D8   bonus-task blue (not used in M6)
fg       #FBFAF6   primary text
fg2      #AEACB7   secondary text
fg3      #6D6D7A   labels, disabled
muted    #92909E   sub-copy
surf     rgba(19,23,54,.7)    card fill
bd       rgba(29,34,72,.9)    card border
canvas   #0C0F27
```

Type: **Fraunces** 400 (display + italic sub-copy), **Roboto** (UI text, 600 for
buttons/labels), **JetBrains Mono** 500 (uppercase micro-labels, letter-spacing
.14–.18em).

Radii: cards 16–18, buttons 13–17, icon tiles 9–12, pills 999.

---

## 2. Pricing model (source of truth)

| | |
|---|---|
| Free tier | **3 memories, lifetime** — not per month. Also 40 photos per memory. |
| Pro annual | **$44.99/year**, presented as "$3.75 a month", badged **SAVE 63%**, preselected |
| Pro monthly | **$9.99/month** |
| Trial | **7 days free**, both plans |
| Store | Apple IAP / StoreKit. Cancellation and plan changes happen in the App Store, never in-app. |

**Copy rules, non-negotiable:**
- Free memories are **never** deleted or locked when the user declines to
  upgrade. Say it explicitly on the paywall.
- Trial terms always state the price that follows and that cancelling is
  possible: "Free for 7 days, then $44.99/year. Cancel anytime in Settings."
  The string changes with the selected plan.
- "Manage subscription" must warn it leaves the app.
- HD export and priority generation are marked **coming soon** — do not imply
  they ship today.

---

## 3. State the app must expose

```
plan            'free' | 'pro'
memoriesKept    int        // lifetime count
memoryCap       int = 3    // free cap
photosInMemory  int
photoCap        int = 40   // free cap
notesInMemory   int
selectedPlan    'year' | 'month'   // paywall only, default 'year'
restoreState    'idle' | 'restored' | 'nothing-to-restore'
renewalDate     date       // Pro only
```

Derived:

```
isPro        = plan === 'pro'
atMemoryCap  = !isPro && memoriesKept >= memoryCap
atPhotoCap   = !isPro && photosInMemory >= photoCap
wrapReady    = photosInMemory >= 5 && notesInMemory >= 1
```

Everything below reads from these. **Do not hardcode counts anywhere** — the
prototype originally showed "12 memories" on Profile next to "3 of 3" in the
usage meter, which is exactly the bug to avoid. One source, every surface.

---

## 4. M6-5 · Paywall

Full screen, own route. Reached from: Profile → Upgrade to Pro; attempting to
create a memory while `atMemoryCap`; attempting to add a photo while
`atPhotoCap`.

**Background** `radial-gradient(125% 58% at 50% -6%, #2A1E52 0%, #141238 44%, #0C0F27 100%)`
plus three twinkling star specks (reuse the existing `twinkle` keyframes;
3px/#F29520, 2px/#fff, 2.5px/#F6C77A at staggered delays).

**Top bar** — 30px circular `×` close button left (surf fill, bd border);
"Restore purchases" text-button right.

**Header** (padding 26)
- Pro mark: 25px rounded-9 tile, `linear-gradient(150deg,#F29520,#FF6D79)`, ✦ in
  `#0C0F27`, next to `TRAVIATO PRO` in mono 9.5px / .18em / primary.
- Headline: Fraunces 34px/1.12, two lines, second line italic in `#F2A65A`:
  "Room for every / *memory you make*"
- Sub-copy: Roboto 13px/1.65 fg2, max-width 296: explains that the three free
  memories are full and what Pro changes. **This line is contextual** — write a
  variant for the photo-cap entry point ("This memory is full at 40 photos…").

**Perk list** — 4 rows, 26px rounded-9 icon tile + title (Roboto 600 13px) +
detail (Roboto 11.5px/1.5 fg3):

| Icon | Title | Detail | Tint |
|---|---|---|---|
| ∞ | Unlimited memories | Keep every trip instead of choosing three. | amber .15 / primary |
| ▣ | Unlimited photos per memory | No 40-photo ceiling on a good week. | amber .15 / primary |
| ▸ | HD film export | Save the wrap-up in full quality. Coming soon. | purple .16 / #C9A9F5 |
| ↯ | Priority wrap-up generation | Your film jumps the queue. | purple .16 / #C9A9F5 |

The two shipped perks use amber and full-strength titles; the two upcoming ones
use purple and `fg2` titles. That colour split *is* the "coming soon" signal —
keep it.

**Plan cards** — 2 rows, radio-style. Selected: fill `rgba(242,149,32,.1)`,
1.5px border `rgba(242,149,32,.6)`, filled amber ring with `✓`, price in
primary. Unselected: surf/bd, hollow ring, price in fg. Annual is
preselected and carries the `SAVE 63%` pill (amber .18 fill, .45 border, mono
8.5px). Price Fraunces 20px, unit label mono 9px fg3 beneath.

**CTA block**
- "Start 7-day free trial" — full width, 17px vertical padding, radius 17,
  `linear-gradient(135deg,#F29520,#FF6D79)`, text `#0C0F27` Roboto 600 15px,
  slow `pulseGlow` 3.6s. This is the only glowing element on the screen.
- Trial terms beneath, centred, Roboto 11px/1.6 fg3, switches with the plan.
- Terms · Privacy, centred, 10.5px, separated by a 3px dot.

**Reassurance card** (surf .55 / bd, radius 16) — Fraunces italic 12.5px/1.6
fg2: "Your three free memories stay yours either way — nothing is deleted or
locked if you don't upgrade."

**Behaviour**
- Plan selection is local state; nothing is purchased until the CTA.
- CTA → StoreKit purchase flow. On success: set `plan = 'pro'`, dismiss,
  show the existing toast ("Trial started · 7 days free").
- Restore → StoreKit restore. Distinguish the three outcomes; when there is
  nothing to restore the prototype shows "Nothing to restore on this account"
  and the button label becomes "Purchases restored" once it succeeds.
- Close must always work. Never trap the user on this screen.

---

## 5. M6-6 · Profile subscription section

Sits between the stats row and Achievements, under a `SUBSCRIPTION` mono label.

**Tier pill** — also added under the `@handle` at the top of Profile. Pro:
amber .14 fill, .45 border, ✦ glyph, `PRO · ANNUAL`. Free: `rgba(19,23,54,.8)`
fill, bd border, ○ glyph, `FREE PLAN` in fg3.

**Card** — Pro: fill `rgba(242,149,32,.07)`, border `rgba(242,149,32,.28)`.
Free: surf / bd. Radius 18.

- Title Fraunces 21px: "Traviato Pro" / "Free plan"
- Meta Roboto 11.5px/1.55 muted:
  - Pro → `Renews {date} · $44.99/year`
  - Free → `{kept} of {cap} memories kept. Upgrade for room to keep going.`
- 34px rounded-12 tier tile top-right, same colours as the pill.

**Usage meters** — two, stacked, gap 13. Each: label (Roboto 11.5px fg2) +
value (mono 10.5px, right-aligned) over a 5px rounded track
(`rgba(29,34,72,.9)`) with a filled bar.

| Meter | Free value | Pro value |
|---|---|---|
| Memories kept | `{kept} of {cap}` | `Unlimited` |
| Photos in this memory | `{photos} of 40` | `{photos} · no limit` |

Bar is `primary`, and flips to `coral` **only when at or over the cap** — that
is the entire colour story; don't add a warning state at 80%. Pro renders both
bars full-width in primary.

**Actions**
- Free → "Upgrade to Pro" gradient button + "7 days free, then $44.99/year.
  Cancel anytime." beneath.
- Pro → "Manage subscription" (surf/bd, hover border primary) + "Opens the App
  Store. Changes and cancellations happen there."
- Below the card, centred: "Restore purchases" in fg3, → fg2 on hover.

---

## 6. M6-4a · Locked wrap-up entry

In the Journal action row, the gradient "View wrap-up ▸" button is replaced —
not disabled-in-place, replaced — when `!wrapReady`:

```
fill    rgba(19,23,54,.5)      // half the normal surface: visibly inert
border  1px rgba(29,34,72,.9)
text    Roboto 600 12.5px #5A5A68
content 🔒 View wrap-up        // 11px lock glyph, gap 6
cursor  default
```

Tapping it does not navigate — it surfaces the requirement toast.

**Explainer card** directly beneath (margin-top 11, surf/bd, radius 16):

- Lead, Roboto 13px/1.55 fg2: `Your film needs a little more to work with. {ask}`
  where `{ask}` is composed from what's actually missing:
  - both → `Add {n} more photos and one note to unlock it.`
  - photos only → `Add {n} more photo(s) to unlock it.`
  - notes only → `Write one note to unlock it.`
- Checklist, 2 rows, gap 9. Each row: 17px ring + label + `have / need` counter.
  - Met: filled amber ring with `✓`, label fg2, counter primary.
  - Unmet: hollow ring `rgba(174,172,183,.35)`, label fg (brighter than met —
    it's the thing still to do), counter fg3.
  - Row 1 `Five photos in this memory` / need 5. Row 2 `At least one note
    written` / need 1.
- Divider, then Roboto 10.5px/1.5 fg3: **"Nothing to buy — this one's the same
  on every plan."**

Pluralise properly. Never show a negative or a count above the requirement
(clamp `have` display at `need` if you prefer, but the prototype shows the true
count).

---

## 7. M6-4b · Empty-day nudge

Shown inside a Journal day with no photos and no notes. Replaces the photo grid
and timeline for that day; the day header and action row stay.

- Day title becomes `Day {n} — a quiet one`; sub-line becomes
  `No photos, no notes yet · 0 quests done`.
- Card: `rgba(19,23,54,.7)` fill, **1px dashed** `rgba(174,172,183,.26)`,
  radius 16, padding 17. The dashed border is the only dashed border in the app
  — it reads as "a slot waiting to be filled" rather than an error.
- 30px rounded-10 amber-tint tile with ✦, then:
  - Fraunces 17px/1.25: `Nothing from Day {n} yet`
  - Roboto 12px/1.6 muted: "Even one photo helps your wrap-up. Quiet days still
    make the film — this one will just pass through it."
- Two half-width buttons, gap 8: `＋ Add a photo` (amber .14 fill, .4 border,
  primary text) and `Write a note` (surf, bd, fg2 → fg on hover).

**Tone rule:** this is a nudge, never a scold. It does not block navigation,
does not appear as a modal, and does not appear on a day that has *any* content.
It also must not appear on future days of an in-progress trip.

**Day chip indicator** — a day with no content gets a 5px `fg3` dot at the
top-right of its thumbnail in the day strip, with a 2px `rgba(12,15,39,.8)` ring
so it reads against any photo. Subtle by design.

---

## 8. Test matrix

| Case | Expected |
|---|---|
| Free, 3 of 3 memories | coral memory bar, Upgrade visible, new-memory attempt → paywall |
| Free, 1 of 3 | primary bar, Upgrade still visible, creation allowed |
| Free, 40 of 40 photos | coral photo bar, add-photo → paywall with the photo-cap copy |
| Pro | both bars full/primary, Manage subscription, no Upgrade anywhere |
| 3 photos, 1 note | wrap-up locked, checklist `3 / 5` met=no, `1 / 1` met=yes, ask = "Add 2 more photos to unlock it." |
| 6 photos, 0 notes | locked, ask = "Write one note to unlock it." |
| 6 photos, 1 note | gradient wrap-up button, no explainer card |
| **Pro, 3 photos, 1 note** | **still locked** — paying does not bypass the content gate |
| Empty day | nudge card, dot on day chip, no grid |
| Empty day, Pro | identical nudge — no upsell in it |
| Restore, nothing to restore | "Nothing to restore on this account", plan unchanged |

---

## 9. Build order

1. The derived-state layer in §3, with `memoriesKept` wired to the real store.
   Verify Profile and Home read the same number.
2. Profile subscription section (both tiers) — it's the simplest full surface
   and proves the state layer.
3. Locked wrap-up entry + explainer card. Confirm it's plan-independent.
4. Empty-day nudge.
5. Paywall, presentation-only with a stubbed purchase.
6. StoreKit: purchase, trial, restore, renewal date, receipt validation.
