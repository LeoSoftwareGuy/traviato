# Journal Day — Bottom Action Bar (Balloon Bar)

Replaces the previous pill-shaped FAB on the Journal Day screen (Option B, "One timeline"). Shown only when the day has content (hidden on the empty-day state, which has its own CTA).

## Layout

- Position: floating, `bottom: 30px`, `left: 20px`, `right: 20px` (full width minus 20px side insets). Above scroll content (z-index over feed). Add bottom padding to the feed so the last item isn't covered (~110px).
- Bar: height `60px`, corner radius `14px`.
- Background: horizontal gradient `#F28A12 → #E07A00` (left → right).
- Shadow: `0 16px 34px rgba(0,0,0,.45), 0 8px 22px rgba(242,149,32,.28)`, inner highlight `inset 0 1px 0 rgba(255,255,255,.28)`.
- Three columns in a row:
  1. **Photo** button — flex: 1
  2. **Balloon cut-out** — fixed `84px` wide
  3. **Note** button — flex: 1

## Buttons (Photo / Note)

- Vertical stack, centered: icon `24×24`, gap `3px`, label below.
- Icon: stroke `#0C0F27`, stroke-width `2`, round caps/joins.
  - Photo: outline camera (body + lens circle).
  - Note: rounded-rect document (`14×18`, radius `3.5`) with two horizontal lines.
- Label: "Photo" / "Note", Roboto 600, `10px`, letter-spacing `.04em`, colour `#0C0F27`.
- Whole half is the tap target (≥44pt).
- Hover: `rgba(255,255,255,.14)` overlay on that half. Pressed: `rgba(12,15,39,.10)`.
- Outer corners follow the bar radius (Photo: left corners 14px; Note: right corners 14px).
- Actions:
  - Photo → open camera / add photo.
  - Note → open the page-turn notebook with a new empty page stamped `NEW NOTE · {time}`.

## Balloon cut-out (centre)

An SVG `84×76`, positioned so it **sticks out 16px above the top edge** of the bar (`top: -16px`), and its bottom (basket) lines up with the bar's bottom edge.

### 1. Silhouette (the "hole")
Filled with the app background colour `#07091A` so it looks cut out of the bar. Wide flat dome on top, sides tapering straight down into a narrow neck — **not** a circle.

```
M42 1C17 1 4 11 4 25c0 11 9 19 20 33l6 17h24l6-17c11-14 20-22 20-33C80 11 67 1 42 1z
```

### 2. Balloon outline (inside the silhouette)
Stroke `#F2852A`, width `2.2`, no fill, round caps/joins.

- Envelope:
  `M42 9C26 9 18 16 18 26c0 9 8 16 15 26h18c7-10 15-17 15-26C66 16 58 9 42 9z`
- Stripes (3) — **evenly spaced**: equal gaps between border, side stripes and centre line at the widest point:
  - Left: `M42 9C28 12 25.5 36 37.5 52`
  - Centre: `M42 9v43`
  - Right: `M42 9C56 12 58.5 36 46.5 52`
- Ropes: `M36 52l1 6`, `M48 52l-1 6`
- Basket: rect `x=36 y=58 w=12 h=8 rx=1.6`

### 3. Hover / press fill (half balloon)
When the user hovers (web) or presses (mobile) a button, the matching **half** of the balloon fills with orange:

- Photo → **left** half (clip `x 0–42`)
- Note → **right** half (clip `x 42–84`)

Implementation: two overlay groups on top of the outline, each clipped to its half, opacity `0` by default → `1` when active, `transition: opacity 180ms ease`.

Each overlay contains:
- Envelope path filled + stroked `#F2852A` (2.2).
- That half's stripes + the centre line in `#07091A`, width `2` (so they stay visible on the fill).
- That half's rope in `#F2852A`.
- Basket rect filled + stroked `#F2852A` (clipped, so only its half shows).

Only one half can be active at a time; clear on pointer leave / release.

## Colours

| Token | Hex |
|---|---|
| Bar gradient start | `#F28A12` |
| Bar gradient end | `#E07A00` |
| Icons / labels | `#0C0F27` |
| Balloon cut-out (app bg) | `#07091A` |
| Balloon outline / hover fill | `#F2852A` |

## Notes

- No star count on the bar.
- Balloon is decorative (not tappable); `aria-hidden`.
- Buttons need accessible labels: "Add a photo", "Add a note".
- Reference prototype: `JournalDayPhone.dc.html` (timeline variant).
