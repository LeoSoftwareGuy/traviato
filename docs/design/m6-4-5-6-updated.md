# M6-4, M6-5, M6-6 — updated with design spec

Supersedes the versions in milestone-6-monetization-issues.md. Spec:
docs/design/M6_MONETIZATION_SPEC.md (copy it there before creating these).
Depends on M6-1 (entitlements/is_pro), M6-2 (RevenueCat), M6-3 (enforcement)
— none of these three render anything without real entitlement data behind
them.

## Color/token reconciliation (do this first in EVERY one of these issues,
## not just once — plan comment must state the mapping before frame work)

| Spec token | Spec value | Use this app token instead |
|---|---|---|
| `primary` | #F29520 | `AppColors.primaryLight` (#F2A65A — close but not identical; use the app's real token, not the spec's hex) |
| `canvas` | #0C0F27 | the app's actual background token (#07091A) — do not introduce a second dark background color |
| `fg` / `fg2` / `fg3` | #FBFAF6 / #AEACB7 / #6D6D7A | `ink` / `dim` / `faint` — exact matches, reuse directly |
| `dare` | #4FB0D8 | `AppColors.accentBlue` — exact match, reuse directly |
| `coral` | #FF6D79 | NOT an existing token. Propose in plan comment: closest existing warning/error color, or a new approved token — do not silently add an unreviewed color |
| `purple` (base) | #8962C5 | NOT an existing token — same treatment as coral. NOTE: the glyph tint `#C9A9F5` DOES match `accentPurpleLight` exactly — reuse that one directly |
| `surf` / `bd` | rgba(19,23,54,.7) / rgba(29,34,72,.9) | check against existing card-fill/border tokens for near-duplicates before adding these as new ones |

Animation: spec's `pulseGlow` / `twinkle` "keyframes" are CSS — implement as a
repeating `AnimationController`, same technique already built for the R-1 star
toast and the guest-landing CTA pulse. Reuse that pattern, don't rebuild it.

`hover` states throughout the spec (buttons, links) don't apply to touch —
map every `hover` to a pressed/tap-down visual state instead.

**Platform note (applies to all three issues):** the spec says "StoreKit" /
"Apple IAP" / "Opens the App Store" throughout, written Apple-only. This app
ships on both stores via RevenueCat (M6-2). Read every such reference as
"the platform's store via RevenueCat" — "Manage subscription" deep-links to
the App Store on iOS and the Play Store on Android; purchase/restore flows
go through the RevenueCat SDK, never StoreKit directly.

---

## M6-4 — Wrap-up content gate + Journal nudge (M6-4a + M6-4b)

Spec: M6_MONETIZATION_SPEC.md §0, §4 is wrap-up-adjacent context, §6, §7, §8
(test matrix), §3 (derived state).

## The one rule that must never break (§0)
Two SEPARATE reasons the wrap-up might be unavailable, and they must never
merge into one screen or share language: the CONTENT gate (this issue — not
enough logged yet, identical for free and Pro, no price ever shown) and the
PLAN LIMIT (M6-5/6-6 — the paywall). A Pro user with 3 photos and 1 note
must see the SAME locked state as a free user in that situation — paying
never bypasses this gate. This is explicitly in the test matrix (§8) and
must be its own test case.

## Acceptance criteria
Derived state (§3) — build once, both M6-4a and M6-4b read it
- [ ] `wrapReady = photosInMemory >= 5 && notesInMemory >= 1` — single
      source of truth (repository method or provider), no duplicated logic
      between the Journal button and the explainer card

M6-4a — Locked wrap-up entry (§6)
- [ ] When `!wrapReady`, the "View wrap-up ▸" gradient button is REPLACED
      (not just disabled/greyed in place) with the inert-styled variant per
      spec: muted fill, muted border, lock glyph + "View wrap-up" text, no
      tap navigation — tapping surfaces the requirement info instead of
      navigating
- [ ] Explainer card beneath, per spec: composed lead line depends on what's
      missing (both missing / photos only / notes only — three distinct
      copy variants, exact wording per spec §6), a 2-row checklist (photos
      met/unmet, notes met/unmet) with met=filled+check, unmet=hollow ring,
      and the closing line "Nothing to buy — this one's the same on every
      plan." verbatim — that line is load-bearing, don't paraphrase it
- [ ] Counts pluralise correctly ("1 more photo" vs "2 more photos"); never
      display a count above what's needed
- [ ] Card and button both driven by `wrapReady` + the underlying counts —
      Pro status has NO effect on this gate

M6-4b — Empty-day nudge (§7)
- [ ] A Journal day with zero photos AND zero notes replaces its photo
      grid/timeline with the nudge card per spec: dashed border (the ONLY
      dashed border in the app — confirm no other screen still has one from
      before R-6's dashed-border removal), amber-tint icon tile, "Nothing
      from Day N yet" + the reassuring sub-copy (quiet days still work),
      two half-width actions (Add a photo / Write a note)
- [ ] Day title/subtitle change to the "a quiet one" / "No photos, no notes
      yet" variants per spec, day header and action row stay
- [ ] Day-strip thumbnail gets the small dot indicator (fg3, with a dark
      ring so it reads over any photo) for empty days
- [ ] Nudge NEVER appears on a day with any content, and NEVER on a locked/
      future day (per the earlier day-locking fix) — both are explicit
      spec rules, both need explicit tests
- [ ] Never a modal, never blocks navigation — purely inline/passive

Tests (§8's matrix — implement as literal test cases, not just "similar to")
- [ ] 3 photos/1 note → locked, checklist 3/5 unmet + 1/1 met, ask = "Add 2
      more photos to unlock it."
- [ ] 6 photos/0 notes → locked, ask = "Write one note to unlock it."
- [ ] 6 photos/1 note → unlocked, no explainer card
- [ ] Pro, 3 photos/1 note → STILL LOCKED (the critical case)
- [ ] Empty day → nudge + dot; empty day for Pro → identical nudge, no
      upsell content anywhere in it
- [ ] Day with any content → no nudge; future/locked day → no nudge
```

---

## M6-5 — Paywall screen

Spec: M6_MONETIZATION_SPEC.md §2 (pricing/copy rules), §4 (full layout),
§8 (test matrix), §3 (derived state). Depends on M6-2 (purchase flow to
call), M6-3 (the cap checks that trigger this screen).

## Acceptance criteria
Entry points (all three, each with contextual sub-copy per spec §4)
- [ ] Profile → "Upgrade to Pro" (M6-6)
- [ ] Creating a 4th memory while `atMemoryCap` — memory-cap copy variant
- [ ] Adding a photo while `atPhotoCap` (40/40) — photo-cap copy variant
      ("This memory is full at 40 photos…")

Layout per spec §4 (full screen, own route)
- [ ] Background gradient + star specks reusing the existing twinkle
      animation pattern (reconciled colors per the table above)
- [ ] Top bar: close (×) left — must always work, never trap the user;
      "Restore purchases" text-button right → RevenueCat restore (NOT
      StoreKit-only)
- [ ] Header: Pro mark tile + "TRAVIATO PRO" label, two-line headline
      (second line italic), contextual sub-copy per entry point
- [ ] 4-row perk list exactly as spec'd: 2 shipped perks (amber, full-
      strength text) + 2 "coming soon" perks (purple/reconciled-purple,
      muted text) — HD export and priority generation MUST read as
      not-yet-available, never implied as shipping today
- [ ] Plan cards: annual preselected, "SAVE 63%" pill, radio-style
      selected/unselected states per spec; monthly $9.99, annual $44.99
      shown as "$3.75 a month"
- [ ] CTA: "Start 7-day free trial", gradient, slow pulse (the only
      glowing element on the screen); trial terms line below that CHANGES
      with the selected plan (exact copy per spec §2 — price + "Cancel
      anytime in Settings")
- [ ] Terms · Privacy links, centred
- [ ] Reassurance card (verbatim per spec): "Your three free memories stay
      yours either way — nothing is deleted or locked if you don't
      upgrade." — this must be TRUE, i.e. verify M6-3's enforcement never
      deletes/hides existing free-tier memories, only blocks NEW ones over
      cap

Behavior
- [ ] Plan selection is local UI state only; nothing purchased until CTA
      tapped
- [ ] CTA → RevenueCat purchase flow (platform-appropriate store
      underneath); success → entitlement refreshed, dismiss, existing
      award-style toast pattern reused for "Trial started · 7 days free"
- [ ] Restore → RevenueCat restore; three distinct outcomes per spec:
      success ("Purchases restored"), nothing-to-restore ("Nothing to
      restore on this account"), and a failure/error state
- [ ] Loading/error states on purchase per existing mutation pattern
      (presentationFailureMessage)

Tests
- [ ] Each entry point shows its correct contextual sub-copy
- [ ] Plan selection toggles trial-terms copy correctly
- [ ] Purchase success updates entitlement + dismisses; each restore
      outcome renders its correct message
- [ ] Close always dismisses regardless of state
```

---

## M6-6 — Profile subscription section

Spec: M6_MONETIZATION_SPEC.md §5, §8 (test matrix), §3 (derived state).
Depends on M6-1 (entitlement data), M6-2 (restore action), M6-5 (upgrade
destination). Extends the Profile screen built in M4-4.

## Acceptance criteria
- [ ] New section between the stats row and Achievements, under a
      `SUBSCRIPTION` mono label — placement matches spec exactly, don't
      relocate it
- [ ] Tier pill under `@handle` at the top of Profile: Pro = amber-tint,
      ✦ glyph, "PRO · ANNUAL" (or "· MONTHLY" per actual plan — spec shows
      annual as the example, both must render correctly); Free = neutral
      fill, ○ glyph, "FREE PLAN"
- [ ] Card: Pro gets the amber-tinted fill/border variant, Free gets the
      neutral surf/bd variant, per spec
- [ ] Title + meta line per tier: Pro → "Traviato Pro" + "Renews {date} ·
      {price}/{period}" (real renewal date from entitlements, real price
      from the actual plan — don't hardcode annual's price if the user is
      on monthly); Free → "Free plan" + "{kept} of {cap} memories kept.
      Upgrade for room to keep going."
- [ ] Tier tile top-right of the card, same color logic as the pill
- [ ] Two usage meters (memories kept, photos in the CURRENT/most-recent
      memory — clarify which memory if ambiguous, propose in plan comment):
      Free shows "{n} of {cap}" with a fillable bar that turns coral
      (reconciled token) ONLY at/over the cap, otherwise primary; Pro shows
      "Unlimited" / "{n} · no limit" with a full primary bar — no warning
      state at any intermediate percentage, exactly as spec insists
- [ ] Actions: Free → "Upgrade to Pro" gradient button → M6-5, plus the
      trial/price terms line beneath; Pro → "Manage subscription" → deep
      link to the platform-appropriate store subscription settings (iOS:
      App Store, Android: Play Store — NOT hardcoded to one platform),
      with copy warning it leaves the app
- [ ] "Restore purchases" text link below the card, both tiers, same
      RevenueCat restore action as M6-5

One source of truth (§3's explicit warning)
- [ ] `memoriesKept` and all other counts are read from ONE place (the
      same repository/provider M6-4 and M6-3 use) — do not let Profile
      compute or cache its own separate count; this is the exact bug the
      spec calls out as something to avoid

Tests
- [ ] Free tier: correct pill/card/meters/actions; bar turns coral only at
      cap (test at 2/3 = primary, 3/3 = coral)
- [ ] Pro tier: correct pill/card/meters/actions, no Upgrade CTA anywhere
      on the screen
- [ ] Manage-subscription deep link targets the correct store per platform
- [ ] Restore purchases wired identically to M6-5's implementation
```
