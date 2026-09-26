# Wrap-Up Film — Collage Moments (v2 addendum)

Addendum to `WRAP_UP_FILM_FLUTTER_SPEC.md`. Everything there still applies; this doc only adds **collage moments** — full-screen multi-photo layouts that replace the single card-flip on selected moments.

Reference implementation: `wrap-film.jsx` → `COLLAGES`, `tornPoly()`, `collagePhotos()`, `Collage`.

---

## 1. What changes

| Moment | Before | Now | Layout |
|---|---|---|---|
| M1 | card flip (bonus) | unchanged | — |
| M2 | card flip | **collage** | `stack3` |
| M3 | card flip (bonus) | unchanged | — |
| M4 | card flip (bonus) | unchanged | — |
| M5 | card flip | **collage** | `torn4` |
| M6 | card flip | unchanged | — |
| M7 | card flip | **collage** | `tilt6` |
| M8 | card flip | **collage** | `torn6` |

- Bonus-task moments (M1/M3/M4) stay card flips — their fallback logic is untouched.
- Cue times, scene durations and total length (~88s) do **not** change.
- Collage moments do **not** drop into the card pile. They fade out on their own (see §4). The pile only receives card-flip moments.
- Feature flag: `collages` (default `true`). When `false`, every moment renders as a card flip exactly as v1.

Model change — add one optional field per moment:

```dart
class FilmMoment {
  final String cue;        // 'M2'
  final String to;         // next cue, e.g. 'M3'
  final String src;        // primary photo
  final String note;       // traveller's caption
  final CollageLayout? layout; // null = card flip
}
enum CollageLayout { stack3, torn4, tilt6, torn6 }
```

---

## 2. Coordinate space

All geometry is in the film's **1080 × 1920** design space, scaled uniformly to the device (same as v1). Origin top-left. Tiles may extend past the frame; clip the whole film to the frame.

---

## 3. Layouts

Tile tuple: `[x, y, w, h, rotationDeg, tornEdges, enterFrom]`

- `tornEdges`: any of `t r b l` — which edges get a torn-paper outline. Empty = plain rectangle.
- `enterFrom`: `l` `r` `t` `b` (slide in from that side) or `z` (zoom-pop in place).
- Tiles are painted **in array order** (later = on top).

### stack3 — three full-width strips (bg `#07091A`)
```
[0,    0, 1080, 636, 0, '', 'l']
[0,  642, 1080, 636, 0, '', 'r']
[0, 1284, 1080, 636, 0, '', 'l']
```
6px dark gaps between strips. No drop shadow.

### torn4 — 2×2 with torn seams (bg `#EFECE4`)
```
[  0,   0, 572, 968, 0, 'rb', 't']
[560,   0, 520, 952, 0, 'lb', 'r']
[  0, 958, 462, 962, 0, 'tr', 'l']
[448, 944, 632, 976, 0, 'tl', 'b']
```
Pieces overlap slightly at the seams on purpose.

### tilt6 — six tilted overlapping tiles (bg `#EFECE4`)
```
[-30,  -30, 560, 600, -1.6, '', 't']
[500,  -50, 620, 820,  2.2, '', 'r']
[-40,  540, 620, 620,  1.2, '', 'l']
[520,  720, 600, 780, -2.6, '', 'r']
[-50, 1140, 720, 820, -1.0, '', 'b']
[640, 1460, 480, 500,  2.4, '', 'b']
```

### torn6 — torn centre piece over five (bg `#EFECE4`)
```
[  0,    0, 586, 760, 0, 'rb',  't']
[576,    0, 504, 860, 0, 'lb',  'r']
[560,  850, 520, 820, 0, 'tl',  'r']
[  0, 1660, 590, 260, 0, 'tr',  'b']
[580, 1650, 500, 270, 0, 'tl',  'b']
[  0,  720, 780, 960, 0, 'trb', 'z']   // hero, on top, GRAYSCALE + contrast 1.1
```

Paper layouts (`torn4`, `tilt6`, `torn6`) get a drop shadow per tile: `offset (0,10)`, `blur 22`, `rgba(0,0,0,.28)`.

---

## 4. Timing

Let `at = CUES[m.cue]`, `to = CUES[m.to]`.

| Element | Start | Duration | Curve | Effect |
|---|---|---|---|---|
| Background colour | `at − 0.45` | 0.35s | linear | opacity 0→1 |
| Tile *i* | `at − 0.45 + i × 0.20` | 0.80s | easeOutCubic | slide/zoom in, see below |
| Ken Burns (every tile) | tile start | until `to` | linear | image scale 1.14 → 1.00 |
| Bottom scrim | `at + 0.6` | 0.9s | linear | opacity 0→1 |
| Caption | `at + 1.0` | 1.25s | easeOutCubic | rise 28px + fade in |
| Exit (whole collage) | `to − 0.85` | 0.85s | linear | opacity 1→0, scale 1.00→1.05 (centre) |

Render the collage only while `at − 0.55 ≤ T ≤ to + 0.1`.

### Tile entrance (progress `e = easeOutCubic(p)`, `p = clamp((T − start)/0.8)`)
- `l`: `dx = −(x + w + 80) × (1 − e)`
- `r`: `dx = (1080 − x + 80) × (1 − e)`
- `t`: `dy = −(y + h + 80) × (1 − e)`
- `b`: `dy = (1920 − y + 80) × (1 − e)`
- `z`: `scale = lerp(1.25, 1.0, easeOutBack(p))`
- Rotation: `rot + (1 − e) × (i odd ? +6 : −6)` degrees
- Opacity: `clamp(e × 1.6, 0, 1)`
- Transform origin: tile centre.

### Ken Burns
Image is drawn `cover`-fit into a box **120px larger** than the tile (60px bleed each side), then scaled from 1.14 to 1.00 over `to − (at − 0.45)` seconds, starting at the tile's own start time. Clipped to the tile.

---

## 5. Torn-paper edge

Each torn tile is two layers:

1. **Paper backing** — colour `#F6F4EE`, torn outline with `seed = i + 17`, `amp = 7`, `pad = +11` (sticks out past the photo → white rim).
2. **Photo** — torn outline with `seed = i + 3`, `amp = 5`, `pad = −2` (sits just inside).

Outline algorithm (build once per tile, cache):

```
E = 60   // straight edges extend 60px off-tile so rotation never shows a gap
corners: TL=(l?0:-E, t?0:-E)  TR=(r?w:w+E, t?0:-E)
         BR=(r?w:w+E, b?h:h+E) BL=(l?0:-E, b?h:h+E)
walk edges TL→TR (normal 0,-1), TR→BR (1,0), BR→BL (0,1), BL→TL (-1,0)

for each edge:
  if not torn: emit start point only
  else:
    n = max(2, round(edgeLength / 13))
    for k in 0..n-1:
      p = k / n
      jitter = k==0 ? 0 : (rnd(k + seed*31, s) − .5)*2*amp + (rnd(k*3 + seed, s+7) − .5)*amp*.8
      emit start + (end−start)*p + normal*(jitter + pad)
```

`rnd(a, b)` = the same deterministic hash used in v1 (`wrap-film.jsx` → `rnd`). `s` is the edge index 1–4. Output is a closed polygon → Flutter `ClipPath` with a custom `CustomClipper<Path>`.

Deterministic seeds matter: the tear must look identical every frame and every replay.

---

## 6. Photo selection

```
photos = [m.src] + journalPool.without(m.src) rotated by (momentIndex × 3), take tiles.length
```

- Tile 0 always gets the moment's own photo.
- **Fallback:** if the journal has fewer photos than the layout needs, downgrade: `torn6/tilt6 → torn4 → stack3 → card flip`. With < 3 photos, always card flip.
- Never repeat a photo within one collage.

---

## 7. Caption

- Position: `left 108, right 108, bottom 250`, centred.
- Font: display serif (same as v1), weight 300 italic, 50px, line-height 1.5, colour `INK` (v1 constant), `text-wrap: pretty`.
- Shadow: `0 2 18 rgba(0,0,0,.5)`.
- Scrim behind it: bottom 760px, gradient to top: `rgba(7,9,26,.92)` 0% → `rgba(7,9,26,.7)` 45% → transparent 100%.

---

## 8. Flutter implementation notes

- One `Collage` widget driven by the film's single clock `T` — no independent `AnimationController`s, so scrubbing/seek works.
- Stack order: background → tiles (array order) → scrim → caption.
- Per tile: `Transform` (translate, rotate, scale) → `ClipPath` (paper) + `ClipPath` (photo) → `Transform.scale` (Ken Burns) → `Image` with `BoxFit.cover`.
- Shadows on clipped shapes: use `PhysicalShape` or paint the shadow with the same `Path` in a `CustomPainter`. Don't use `BoxShadow` — it ignores the torn outline.
- Precache every collage photo before the film starts (up to 6 per moment).
- Use `RepaintBoundary` per tile. Cache torn `Path`s per tile size + seed.

---

## 9. Test cases

1. `collages = false` → film identical to v1 output frame-for-frame.
2. Seek to `CUES.M5 + 0.5` → 4 torn tiles present, tiles 0–3 all fully settled by `at + 0.95`.
3. Seek to `CUES.M8 + 1.5` → hero tile grayscale and on top; caption fully visible.
4. Same seek twice → identical torn outlines (determinism).
5. Journal with 4 photos → M7/M8 downgrade to `torn4`; with 2 photos → all collage moments become card flips.
6. No tile repeats a photo within the same collage.
7. At `to` the collage is fully transparent and the next moment's entry is unobstructed.
8. Collage moments never appear in the card pile at the Footnote.
9. Bonus-task moments (M1/M3/M4) and their zero-task fallback unchanged.
10. Small device (375×667 scaled): nothing inside the caption box clipped.
