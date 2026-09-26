# Wrap-Up Film — Flutter implementation spec

A generated, ~88-second vertical film that plays back a finished trip. One
continuous composition: a single clock drives every element, elements persist
across scene boundaries and move by interpolation. There is no per-scene
teardown and no page transitions.

Reference implementation: `wrap-film.jsx` (web prototype, React/DOM — useful
for reading the animation math only; do not port its JS/CSS mechanics
literally, translate to Flutter idioms). Color tokens below are reconciled
against this app's actual theme in the accompanying issue — where this spec's
token names differ from `lib/core/theme/`, the theme wins, not the prototype.

---

## 1. Canvas and playback

| | |
|---|---|
| Design canvas | **1080 × 1920** logical px (9:16) |
| Scaling | uniform `FittedBox` / scale factor; never reflow. All values below are canvas px. |
| Background | `#07091A` |
| Total length | **87.9s** |
| Clock | one `AnimationController` (unbounded, 87.9s) → `T` in seconds. Everything reads `T`. |
| Loop | restart at 0 |

Do **not** build this as 18 sequential widgets/pages. Build one `Stack` whose
children each compute their own opacity/transform from `T`. That is what makes
photographs carry over from one scene to the next.

### Scene table (cue → absolute start)

| Scene | Start (s) | Dur (s) |
|---|---|---|
| Dust | 0.0 | 3.2 |
| Invitation | 3.2 | 4.2 |
| Bridge1 | 7.4 | 3.4 |
| M1 | 10.8 | 5.5 |
| M2 | 16.3 | 5.2 |
| M3 | 21.5 | 5.1 |
| Flurry1 | 26.6 | 6.3 |
| Bridge2 | 32.9 | 3.2 |
| M4 | 36.1 | 5.0 |
| M5 | 41.1 | 5.0 |
| M6 | 46.1 | 5.0 |
| Flurry2 | 51.1 | 7.0 |
| Bridge3 | 58.1 | 4.2 |
| M7 | 62.3 | 5.0 |
| M8 | 67.3 | 5.0 |
| Footnote | 72.3 | 4.2 |
| Unlock | 76.5 | 4.6 |
| Keepsake | 81.1 | 6.8 |

Durations are **fixed regardless of library size**. A 20-photo trip and a
200-photo trip run identically, at different densities.

---

## 2. Design tokens

```dart
const ink    = Color(0xFFFBFAF6);  // primary text / card stock
const dim    = Color(0xFFAEACB7);  // secondary text
const faint  = Color(0xFF6D6D7A);  // labels
const bg     = Color(0xFF07091A);
const accent = AppColors.primaryLight;   // RECONCILED: reuse existing token
const amber  = AppColors.primaryLight;   // RECONCILED: identical to spec's #F2A65A
const dare   = AppColors.accentBlue;     // RECONCILED: identical to spec's #4FB0D8
```

Fonts: **Fraunces** (serif — all display copy and captions, weight 300, italic
used heavily), **Roboto** (sans — one subtitle), **JetBrains Mono** (labels:
uppercase, letter-spacing 0.26em, 19–28px). All three already present in this
app since R-1 — no new font dependency.

---

## 3. Easing

Five curves cover the whole film. Implement once as pure functions of `T`.

```dart
double rise(T, start, dur, {lift = 38})   // easeOutCubic; returns 0→1
                                          // opacity = e, translateY = (1-e)*lift
double fade(T, start, dur, from, to)      // easeInOutSine
double swell(T, start, dur, from, to)     // LINEAR (not eased) — slow pushes
double toss(T, start, dur)                // easeOutBack — cards thrown in
double band(T, inAt, inDur, outAt, outDur) // fade-in × fade-out, for groups
```

`band` is the workhorse: it gives an element a visible window with soft edges
and is what lets one element span several scenes.

Deterministic jitter (so every playback is identical):

```dart
double rnd(int i, int salt) {
  final x = math.sin(i * 12.9898 + salt * 78.233) * 43758.5453;
  return x - x.floorToDouble();
}
```

---

## 4. What feeds each frame (the data contract)

This is the part that matters most for the real app. Supplied by the
`wrap_ups.content` screenplay (see the companion "screenplay schema" issue) —
not hardcoded.

| Frame | Data source |
|---|---|
| **Dust** | Trip start/end dates only, formatted `12–16 August 2026`. No photo, no copy. |
| **Invitation** | Cover photo = journal hero image. Line 1 = day count computed from the dates ("Five days."). Line 2 = **AI**, written from trip type + destination ("One long road."). |
| **Bridges 1–3** | **AI text, never a photograph.** Journal notes are read in chronological order and split into three arcs. Bridge1 ← the M1–M3 notes, Bridge2 ← M4–M6, Bridge3 ← M7–M8. Two lines max, `\n` split. |
| **Moments M1–M8** | One photo each, captioned with the traveller's **OWN note** — never AI. See slot rules below. |
| **Flurry1 / Flurry2** | Everything NOT shown as a moment. Caps are pacing limits, not photo counts. |
| **Footnote** | photographs taken · bonus tasks completed · stars earned. **No distance, no step count** — a trip that never left one room still has all three. |
| **Unlock** | The achievement unlocked by this trip (name + one-line reason). |
| **Keepsake** | Trip title, AI closing line, app mark. |

### Moment slot rules

```
M1, M3, M4   → bonus-task photos, in completion order,
               badged "Dare · {task name} · ✦{stars}" in `dare` blue
M2, M5–M8    → journal photographs not already used
```

**Fallback:** with fewer completed bonus tasks than slots, the unfilled slots
become ordinary journal photographs — same frame, no badge. Zero tasks
completed ⇒ all eight slots are journal photos. Never show an empty badge and
never skip a slot.

**Captions:** if a photo has no note, use the frame without a caption rather
than generating one. The traveller's voice is the point.

### Flurry fill rules

- Flurry1: up to **15** leftover photos on a 3 × 5 grid, filled **bottom row
  upward** so a short trip never leaves a hole at the bottom of frame.
- Flurry2: up to **15** of what remains after Flurry1.
- The true leftover count is spoken in the label: "And eighty-four more."
  (If fewer than ~10 remain, suppress the label.)

---

## 5. Frame specs

### Dust (0.0–3.2)
Black. Five star specks at fixed positions `(214,470) (820,372) (318,1276)
(742,1420) (540,236)`, radius 2.2–3.2, alternating `accent`/`ink`, opacity 0.7,
each `band`-faded in at its own offset (0.5/1.1/1.7/0.9/2.1, dur 1.4). **The
specks persist until near the end of the film** (`band` out at Keepsake−1.4).

A 1px hairline at `top: 1040` grows from the centre outward to 336px wide
(`swell(1.2, 1.9, 0, 168)` half-width), gradient `transparent → accent →
transparent`, `band(1.2, 1.0, 2.7, 0.7)`.

Dates at `top: 900`, centred, mono 28px `dim`, `band(0.6, 1.4, 2.5, 0.9)`.

### Invitation (3.2–7.4)
Cover photo behind everything at low opacity (see §6). Two lines at `left/right:
110, top: 760`:
- "Five days." — Fraunces 300, 132px, line-height 0.98, letter-spacing −3, `ink`,
  `rise(a+0.4, 1.8, 46)`
- "One long road." — Fraunces 300 **italic**, 132px, `amber`, margin-top 14,
  `rise(a+1.6, 1.8, 46)`
- Both fade out together: `fade(a+3.2, 1.0, 1, 0)`

### Bridges (7.4 / 32.9 / 58.1)
A dark plate over the whole frame at `grp × 0.88` opacity (**Bridge2 is fully
opaque — `× 1.0` — nothing shows behind it**), plus the line at `left/right:
120, top: 780`, centred, Fraunces 300 italic 62px/1.42, `rgba(251,250,246,.9)`,
preserving `\n`. `grp = band(a+0.2, 1.1, a+2.3, 1.0)`, text `rise(a+0.5, 2.0, 34)`.

### Moments (the core frame)

**The print.** 720px wide, white border: padding `11px 11px 96px` (the wide
bottom border is the Polaroid chin), photo area 860px tall, `BoxFit.cover`,
radius 5 (photo radius 2), stock `#FBFAF6`. Total height `11 + 860 + 96 = 967`.

**Arrival.** Enters at `at − 0.45` with `toss(inAt, 0.75)` (easeOutBack):
- centre y: `mix(880, 782, thrown)` — settles upward
- scale: `mix(0.86, 1, thrown)`, then a slow `swell(at−0.5, 5.4, 1, 1.035)` push
- rotation: `(1 − thrown) × −5°`
- shadow: `0 {30×lift}px {64×lift}px rgba(0,0,0,.6)`, lift = `thrown`

**The flip — card lands face-down, holds, then turns.**
```
flip = easeInOutCubic(clamp((T - (at + 0.30)) / 0.58, 0, 1))   // 0 = back, 1 = front
```
Two faces on one 3D-transformed wrapper, `rotateY(180° − 180°×flip)`:
- **front**: the photograph, `backfaceVisibility: hidden`
- **back**: blank card stock, `rotateY(180°)`, gradient `150deg #F4F1E8 → #E4DFD2
  62% → #D9D3C4`, also `backfaceVisibility: hidden`
- perspective **2200px** on the parent; the outer scale/rotate must sit on an
  ancestor of the flipping element, not on it.

In Flutter: `Transform(transform: Matrix4.identity()..setEntry(3, 2, -1/2200)
..rotateY(angle))`, and render only the face whose side is toward the camera
(Flutter has no `backface-visibility` — branch on `flip < 0.5`).

**Caption** at `left/right: 108, top: 1330`, centred, timed to land *after* the
turn:
- badge (bonus tasks only): mono 21px, `dare` blue, letter-spacing 0.22em,
  `rise(at+0.82, 1.0, 22)`
- note: Fraunces 300 italic 50px/1.5, `ink`, margin-top 24 when badged,
  `rise(at+1.0, 1.25, 28)`
- both fade at `fade(goAt−0.15, 0.6, 1, 0)` where `goAt = to − 0.85`

**Exit to the pile.** `gone = fade(goAt, 0.85, 0, 1)`; the print travels to
`(300 + (i%5)×118 + (i>4 ? 26 : 0), 1824 + (i%3)×7)`, scale → 0.4, rotation →
`(rnd(i,9) − 0.5) × 22°`. **Prints stay in the pile at the bottom of frame for
the rest of the middle section** — they are not destroyed. The pile clears via
`pileFade = band(Bridge1, 0.8, Footnote−0.9, 1.0)`.

### Flurry1 (26.6–32.9) — dropped onto a table
15 prints on a 3 × 5 grid: `colW = 1080/3`, `top = 210`, `rowH = (1920 − 210 −
340)/5 = 274`.

Per card `i = row×3 + col`:
```
w      = colW*0.82 + rnd(i,31)*46        (~295–341)
h      = w * (0.66 + rnd(i,35)*0.20)
x      = col*colW + (colW - w) * (0.2 + rnd(i,32)*0.6)
landY  = top + row*rowH + (rnd(i,33) - 0.5)*rowH*0.3
at     = a + 0.15 + (4 - row)*0.46 + col*0.13 + rnd(i,34)*0.12   // BOTTOM ROW FIRST
rotZ   = (rnd(i,36) - 0.5) * 18
```
Animation — a card dropped flat onto a table:
```
fall   = easeOutCubic(clamp((T - at)/1.05, 0, 1))
settle = easeOutCubic(clamp((T - at - 0.30)/0.85, 0, 1))
y      = mix(landY - 760, landY, fall)
rotateX = 86° * (1 - settle)     // edge-on first: you see the white sliver, no image
rotateZ = rotZ * settle
shadow  = 0 {10+26×settle}px {24+44×settle}px rgba(0,0,0,.55)
transformOrigin: 50% 100%,  perspective 1500px
```
Sort by `landY` so lower cards paint on top. **No text on this frame.**
Group `band(a+0.05, 0.5, Bridge2−1.0, 0.8)`.

### Flurry2 (51.1–58.1) — face-up prints crossing the frame
15 prints, **face up from the start**, entering bottom-left, one after another:
```
N      = 15
w      = 240 + rnd(i,57)*120
at     = a + 0.1 + i*0.16
dur    = 3.0 + rnd(i,58)*0.6          // deliberately unhurried
bend   = easeInOutSine(clamp((i - 2)/(N - 3), 0, 1))   // first 2 run corner-to-corner
amp    = (120 + rnd(i,60)*200) * (1 - bend*0.6)
toX    = mix(1080 + 160, 540 - w/2, bend)   // later cards exit TOP CENTRE
toY    = mix(-360, -520, bend)

p = clamp((T - at)/dur, 0, 1);  e = easeInOutSine(p)
x = mix(-420, toX, e) + sin(e*π) * (toX < 648 ? 150 : 0)
y = mix(1880, toY, e) + sin(e*2π) * amp      // the wave
rot = mix(-13°, toX < 648 ? 4° : 13°, e)
opacity = clamp(p/0.12,0,1) * clamp((1-p)/0.16,0,1)
```
Bottom veil: 360px tall, `linear-gradient(to top, rgba(7,9,26,.72) 18%,
transparent)`. Label "And eighty-four more" at `left: 110, top: 300` (mono,
`dim`) — **must sit above the cards in z-order and outside the flight lane.**
Group `band(a+0.05, 0.5, Bridge3−0.25, 0.7)`.

### Footnote (72.3)
Three stats in a centred wrap row, gap 44: `{photoCount} photographs`,
`{bonusDone} bonus task(s)`, `✦{stars} stars`. Numbers Fraunces 300 76px/1,
letter-spacing −2 (the **third** one is `accent`, the rest `ink`); labels mono
19px `faint`, margin-top 12, letter-spacing 0.2em. Then, margin-top 64, Fraunces
300 italic 40px/1.5 `dim`: "None of which is the reason you'll remember it."
(`rise(a+1.6, 1.6, 24)`). Pluralise "bonus task".

### Unlock (76.5)
At `left/right: 110, top: 740`. A 300px-tall badge area: two expanding rings
(`swell(a+0.6, 2.4, 0.4, 2.5)` and `swell(a+1.1, …)`, 300px circles, 1px
`accent` border, opacity `0.5 − s×0.2` / `0.4 − s×0.16`), and a ✦ glyph
Fraunces 300 168px `accent` at `top: 62`, scaled by `toss(a+0.4, 1.1)`.
Achievement name Fraunces 300 96px `ink` (`rise(a+1.3, 1.5, 34)`); reason Roboto
400 38px/1.6 `dim` (`rise(a+2.0, 1.6, 30)`). Group `band(a+0.2, 1.0, a+3.8, 0.9)`.

### Keepsake (81.1–87.9)
Cover photo returns full-bleed (`band(a−0.6, 2.3, a+5.3, 1.3)`) with a slow
`swell(a−1.0, 9.0, 1.02, 1.16)` push and a top-to-bottom scrim
`rgba(7,9,26,.94) 6% → rgba(7,9,26,.34) 46% → rgba(7,9,26,.72) 100%`.
At `left/right: 110, bottom: 268`: trip title in two lines — Fraunces 300 138px
`ink` / Fraunces 300 italic 138px `amber`, letter-spacing −4
(`rise(a+0.6/a+1.4, 1.9, 46)`); AI closing quote Fraunces 300 italic 44px/1.6
`rgba(251,250,246,.8)` margin-top 44 (`rise(a+2.6, 2.0, 34)`); then the app mark
— 52px rounded-18 `accent` square with ✦ in `#0C0F27`, gap 18, wordmark Fraunces
400 40px (`rise(a+3.9, 1.7, 26)`). Everything fades on `fade(a+5.2, 1.3, 1, 0)`.

---

## 6. Persistent chrome (drawn over/under everything)

**Background photo washes** — the cover image, blurred 7px, scaled by
`swell(3.0, 40.0, 1.04, 1.28)` across the whole film, at summed opacity:
```
coverEarly × 0.22 + routeWash × 0.07 + roomTone × 0.10
coverEarly = band(Invitation−0.2, 2.0, Bridge1−0.3, 1.5)
routeWash  = band(Invitation+1.4, 1.3, Bridge1−0.2, 1.1)
roomTone   = band(Bridge1−0.4, 1.6, Footnote−0.6, 1.4)
```

**Vignette** — `radial-gradient(80% 58% at 50% 44%, transparent 32%,
rgba(7,9,26,.58) 76%, rgba(7,9,26,.92) 100%)`, always on.

**Grain** — 180×180 tiling noise PNG (generate once with a seeded LCG, values
96–223 grey), `mixBlendMode: overlay`, opacity 0.07, position jittered per frame
by `(T×61 mod 180, T×83 mod 180)` px. In Flutter: an `ImageFilter`/shader or a
pre-baked tiling asset with a `BlendMode.overlay` layer.

**Letterbox** — black bars top and bottom growing to 96px over
`swell(3.0, 1.6, 0, 96)`, z-index above all.

---

## 7. Performance notes for Flutter

- One `AnimationController` + `AnimatedBuilder` at the root. Do not give each
  element its own controller.
- `RepaintBoundary` around each print; the flurries put 15 shadowed cards on
  screen at once.
- Decode and cache all photos **before** playback starts — a decode stall mid-
  flurry is very visible. Show the Dust frame while precaching.
- Shadows are the main cost. Consider a pre-baked shadow asset (9-patch) rather
  than `BoxShadow` on 15 simultaneous moving cards.
- Export/share (rendering off-screen to a video file): explicitly OUT of
  scope for the initial build — post-MVP, tracked as a separate issue. The
  film plays live/in-app only until then.

---

## 8. Build order

1. Clock + scene table + the five easing functions. Verify `T` scrubs.
2. The `Plate` widget (border, flip, shadow) — the single most reused piece.
3. One `Moment` end-to-end: arrival → flip → caption → exit to pile.
4. The remaining seven moments + the persistent pile.
5. Bridges, Dust, Invitation, Footnote, Unlock, Keepsake.
6. Flurry1, then Flurry2.
7. Chrome: washes, vignette, grain, letterbox.
8. Swap hardcoded content for the data contract in §4, sourced from
   `wrap_ups.content` (screenplay schema issue), including every fallback.

Test cases that must look right: **zero bonus tasks completed**, **fewer than 8
journal photos**, **fewer than 15 leftovers for a flurry**, and **a photo with
no note**.
