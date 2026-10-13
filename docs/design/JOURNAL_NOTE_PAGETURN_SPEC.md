# Journal — "Add notes" Book Page-Turn (handoff)

Scope: replace the current inline textarea on the Journal page with a full-screen **notebook page** that opens with a 3D page-turn, supports **voice and typing**, and saves into the day's entry with a **+1 star** award.

Out of scope: full-screen photo viewer (already implemented).

Reference design: `Wander - Travel Memory Journal.dc.html` → Journal screen, block `<!-- note page · book page-turn -->`, logic `openNote / shutNote / startRec / stopRec`.

---

## 1. Entry points (change)

Today, tapping the entry card puts the user straight into an inline textarea. **Remove that.** These now open the note page:

| Trigger | Where |
|---|---|
| "✎ Add notes about today" / "Continue entry" link | Today's entry card |
| "Write a note" button | Empty-day nudge card |

The entry card on the Journal page becomes **read-only** (text + "EDITED hh:mm · N WORDS").

```dart
onTap: () => Navigator.of(context).push(NotePageRoute(day: day));
```

Use a custom `PageRouteBuilder` with `opaque: false`, `transitionDuration: Duration.zero`. The page-turn is animated **inside** the route (§3), not by the route transition.

---

## 2. Screen anatomy

Full screen, background `#07091A`. The book sits under the status bar.

```
┌ status bar (dark bg, white icons stay legible) ┐
│ ┌────────────────────────────────────────┐╮╮  │  top: 54
│ │▒ Cancel     DAY 2 · 13 AUG       Done  │││  │  ← 3 page layers (edges)
│ │▒ the lake before the buses             │││  │
│ │▒ ─────────────────────────────────── ─ │││  │  ruled lines every 30px
│ │▒ existing entry (faded ink) …          │││  │
│ │▒ new text (dark ink) | caret           │││  │
│ │▒                                       │││  │
│ │▒ ────────────────────────────────────  │││  │
│ │▒  [Aa]        ( 🎙 )          +12 words │││  │  dock
│ │▒           Tap to talk                  │││  │
│ └────────────────────────────────────────┘╯╯  │  bottom: 14
└───────────────────────────────────────────────┘
▒ = spine gutter shadow on the left edge
```

### Geometry (402 × 874 reference; scale proportionally)

| Layer | top | bottom | left | right | radius | colour |
|---|---|---|---|---|---|---|
| Page edge 3 (back) | 60 | 20 | 0 | 4 | `0 16 16 0` | `#CFC5B0` |
| Page edge 2 | 57 | 17 | 0 | 8 | `0 16 16 0` | `#E1D8C4` |
| **Writing page** | 54 | 14 | 0 | 12 | `0 16 16 0` | `#F3EDE0` |
| **Turning page** | 54 | 14 | 0 | 12 | same | same |

Spine gutter (on both pages): 28px wide, left edge, `LinearGradient(left→right, rgba(30,27,58,.22) → transparent)`.

### Colours (paper theme)

| Token | Hex | Use |
|---|---|---|
| paper | `#F3EDE0` | page |
| paperDock | `#ECE5D5` | dock bg |
| ink | `#1E1B3A` | new text, title |
| inkOld | `#625D7A` | existing entry text |
| inkMuted | `#6B6680` | Cancel, stamp, counters |
| rule | `rgba(30,27,58,.10)` | ruled lines, dock divider |
| doneInk | `#B4600A` | "Done" (4.5:1 on paper) |
| micGrad | `#F29520 → #FF6D79` (135°) | mic idle |
| micRec | `#FF6D79` | mic recording |
| wave | `#E2525F` | waveform bars |
| listenInk | `#A2343F` | "LISTENING · 0:07" |

### Type

- Stamp: JetBrains Mono 500, 9.5px, letter-spacing .14em, uppercase.
- Title: Fraunces 400, 23px / 1.2.
- Body (old + new): Fraunces 400 *italic*, 15px, **line-height exactly 30px** so text sits on the rules.
- Ruled lines: `repeating-linear-gradient` equivalent — a `CustomPainter` drawing a 1px line every 30px, **scrolling with the content** (paint inside the scroll view, not behind it).

---

## 3. Page-turn — timing & 3D setup

### Layers (bottom → top)
1. Backdrop `#07091A` (fades in 0 → 1 over **250ms**, easeOut)
2. Page edges ×2
3. **Writing page** (fully built and interactive underneath)
4. **Shade on writing page** — `LinearGradient(left→right, rgba(7,9,26,.6) → rgba(7,9,26,.2))`
5. **Turning page** — a two-sided card hinged at its **left** edge

### Turning page faces
- **Front** (visible at 0°…−90°): the day's title page
  - Stamp `DAY 2 · 13 AUG` (Mono 10px, .2em)
  - Title, Fraunces 32px / 1.15, centred, max-width 270
  - Polaroid: 150×172, white, padding 8/8/30, rotated −4°, shadow `0 12 26 rgba(30,27,58,.22)`, inner = day's first photo
  - Meta line: "128 words · 5 photos" (Fraunces italic 13, inkMuted)
  - **Hand-drawn balloons**: three ink-sketch hot-air balloons with colour wash — export from the design as SVG assets:
    - large, top 46 / right 34, 70px wide, rot +7°, wash `rgba(242,149,32,.28)`, band `#D9821A`
    - small, top 128 / left 48, 36px, rot −9°, wash `rgba(255,109,121,.24)`, band `#D9525E`
    - tiny, bottom 78 / right 70, 28px, rot +4°, wash `rgba(137,98,197,.24)`, band `#7C58B5`
    - dotted flight trail (stroke-dasharray 2 5, opacity .45) and a small cloud (opacity .55)
    - Stroke `#2A2547`, 1.4px, round caps. The wash is offset (+2.5, +2) from the outline for the hand-painted look.
  - Front shade overlay: `LinearGradient(right→left, rgba(7,9,26,.5) → rgba(7,9,26,.1))`
  - Drop shadow `6 0 18 rgba(0,0,0,.25)`
- **Back** (visible at −90°…−180°): plain paper, `LinearGradient(right→left, #CFC5B0 → #EAE2D0 @70%)`, radius `16 0 0 16`.

### 3D transform
```dart
Matrix4.identity()
  ..setEntry(3, 2, 1 / 1600)        // perspective 1600px
  ..rotateY(angle);                 // radians; 0 → -π
// alignment: Alignment.centerLeft (hinge on the spine)
```
Show front when `angle > -π/2`, else show back (pre-rotated by π so it isn't mirrored). This replaces CSS `backface-visibility`.

### Open timeline (one `AnimationController`, 1170ms total)

| t (ms) | What |
|---|---|
| 0 | Route pushed. Backdrop starts fading in (250ms). Turning page at **0°**, covering the writing page. |
| 60 | Controller starts (lets the first frame paint). |
| 60 → 180 | **Delay 120ms** — the closed page sits still for a moment. |
| 180 → 1230 | Rotate **0° → −180°**, **1050ms**, `Cubic(.55, .06, .24, 1)` (slow lift, fast sweep, soft land). |
| 180 → 1130 | Writing-page shade opacity **1 → 0**, 950ms, easeOut. |
| 180 → 1080 | Front-face shade opacity **0 → 1**, 900ms, easeIn (page darkens as it lifts away from light). |
| ≥ 1230 | Turning page off-screen (lies to the left of the spine, clipped). Remove it from the tree. Writing page becomes interactive. |

Block pointer input on the writing page until the turn completes. Do **not** auto-open the keyboard; the user chooses voice or type.

### Close timeline (Done or Cancel) — 880ms

| t (ms) | What |
|---|---|
| 0 | Stop recording if active (§4). Dismiss keyboard. Re-insert turning page at −180°. |
| 0 → 850 | Rotate **−180° → 0°**, 850ms, same cubic, **no delay**. Shades reverse (writing-page shade 0→1, front shade 1→0). |
| 880 | Pop route. Apply save (§5). Fire star toast if saved. |

Android back / swipe-back = **Cancel** if the draft is empty. Otherwise show a small confirm: "Discard what you added?" (Keep writing / Discard).

`prefers-reduced-motion` (MediaQuery `disableAnimations`): skip rotation. Crossfade writing page in/out over 200ms instead.

---

## 4. Voice & typing states

### Page content
- Scrollable column (padding `0 22 20 30`):
  1. **Existing entry** — read-only, inkOld. Includes anything previously added.
  2. **New text field** — multiline `TextField`, no border, transparent, ink, min height 240, placeholder:
     *"Keep going — type, or tap the mic and just talk."*
- New text is **appended** to the entry. Existing text is never edited here.

### Dock (bg paperDock, top divider rule, padding `12 22 18 30`)

| Slot | Element |
|---|---|
| Left | **Aa** button, 48px circle, 1px border `rgba(30,27,58,.2)`, Fraunces 600 15 |
| Centre | **Mic** button, 68px circle + label below (Roboto 600 11, `#4A4566`) |
| Right | Draft counter `+N words` (Mono 10, inkMuted). Hidden when 0. |

### State machine

```
            tap mic                 tap mic / silence 8s / 90s cap
  IDLE ───────────────▶ LISTENING ─────────────────────────────▶ IDLE
   │  ▲                     │
   │  └── tap Aa ───────────┘   (stops recording, then focuses field)
   └── tap Aa / tap field ──▶ TYPING (keyboard up)
TYPING ── tap mic ──▶ dismiss keyboard ─▶ LISTENING
```

| State | Mic button | Label | Extras |
|---|---|---|---|
| **Idle** | micGrad, mic glyph (dark `#0C0F27`), shadow `0 10 24 rgba(242,149,32,.35)` | "Tap to talk" | — |
| **Listening** | solid micRec, **stop square** 20×20 r5 `#0C0F27`, pulsing ring (box-shadow 0→13px, 1.4s loop) | "Tap to stop" | Waveform row + "LISTENING · 0:07" above the dock buttons |
| **Typing** | as Idle | "Tap to talk" | Keyboard up. Dock rides above the keyboard (`viewInsets`). |

**Waveform**: 24 bars, 3px wide, gap 3, height 30, radius 2. Each bar's `scaleY` animates .3 ↔ 1 (900ms, easeInOut, loop). In production, drive bar height from **live mic amplitude** (RMS → 0.3…1.0). Use the staggered loop only as a fallback.

**Timer**: `m:ss` from recording start, Mono 10, .12em, listenInk.

### Speech-to-text
- Use the platform recogniser (`speech_to_text` package), locale = device locale, **partial results on**.
- Partial results stream **into the field at the cursor**, word by word. Show the latest partial in ink at 60% opacity; set full ink when the result is final.
- Join rule: insert a single space if the field doesn't already end in whitespace.
- Auto-stop: 8s of silence, or 90s maximum.
- Permission denied: show inline under the dock — "Microphone is off. Turn it on in Settings, or just type." Mic button stays tappable (re-requests), and **Aa** stays primary.
- Recogniser unavailable/offline: same pattern — "Voice isn't available right now — typing works."

### Aa button
1. If listening → stop.
2. Focus the field and **move the caret to the end** of the text.

---

## 5. Saving & star award

### Done
1. `draft = field.text.trim()`
2. Run the close animation (§3).
3. On route pop:
   - **If draft is non-empty:**
     - `entry.text = entry.text + ' ' + draft` (or just `draft` if the entry was empty)
     - `entry.editedAt = now`, recompute `wordCount`
     - Persist (local first, then sync)
     - Award **+1 star** → `stars += 1`, show toast **"✦ +1 star · note saved"**
   - **If empty:** no write, no star, no toast.

### Cancel
Close animation. Discard the draft (with confirm if non-empty, §3). No star.

### Star rules
- **One star per save that adds text.** Several saves in a day can each earn a star. Cap at **3 note-stars per day** to prevent farming — saves beyond the cap still save, with toast "Note saved" and no star.
- Saved notes count toward:
  - the **Storyteller** progress (journal card "Two more notes and Storyteller is yours").
  - the wrap-up gate rule "≥1 note" (M6 monetization spec).

### Toast
Existing star toast component: pill `rgba(242,149,32,.94)`, ink `#0C0F27`, Roboto 600 13, at top 104. Animation `awardPop` (rise 6px + scale .9 → 1.04 → 1, hold, fade), ~2.2s. Shown on the Journal page **after** the book closes, so the user sees it land.

### Journal page after save
- The entry card shows the appended text immediately (optimistic).
- Footer updates: `EDITED hh:mm · N WORDS`.

---

## 6. Suggested widget tree

```
NotePageRoute
└─ Stack
   ├─ FadeTransition(backdrop #07091A)
   ├─ PageEdges (2 Positioned containers)
   ├─ Positioned(writing page)
   │   └─ ClipRRect
   │      └─ Stack
   │         ├─ Column[ Header, Title, Expanded(RuledScroll[OldText, TextField]), Dock ]
   │         ├─ SpineGutter
   │         └─ IgnorePointer(Opacity(shade))
   └─ if (!turnDone) Positioned(turning page)
       └─ AnimatedBuilder(controller)
          └─ Transform(alignment: centerLeft, matrix: perspective+rotateY)
             └─ angle > -π/2 ? FrontFace(withShade) : Transform.flip(BackFace)
```

- One controller for the turn. Derive both shades from it with `Interval`s, so the timings stay in sync.
- Put a `RepaintBoundary` around the turning page.
- Precache the polaroid photo before pushing the route.

---

## 7. Test cases

1. Tapping "Add notes about today" opens the book with the turn. **No inline textarea** appears on the Journal page.
2. "Write a note" on an empty day opens the same page.
3. The turn finishes in ~1.23s. The writing page isn't tappable before that.
4. The front face shows until 90°, then the back face, which isn't mirrored.
5. Reduced motion → crossfade, no rotation.
6. Tap mic → waveform + timer. Words appear live. Tap again → stops and the text stays.
7. Tap **Aa** while listening → recording stops, keyboard opens, caret at the end.
8. Mic permission denied → inline message, typing still works.
9. Done with text → book closes, entry updated, word count updated, +1 star toast after close.
10. Done with an empty draft → closes, no star, no toast.
11. Cancel with text → confirm. Discard → nothing saved.
12. 4th save in one day → saved, toast "Note saved", no star.
13. Saved note ticks Storyteller progress and satisfies the wrap-up "≥1 note" rule.
14. Keyboard open → dock stays visible above it. Ruled lines stay aligned while scrolling.
