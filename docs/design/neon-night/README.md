# Neon Night — reference (#363)

- `NEON_NIGHT_SPEC.md` — the full spec. The prototype it names (`Neon Night Film.dc.html` + `neon-night.jsx`) was not provided, so **the spec and the MP4 are the reference**.
- `NeonNight.mp4` — reference render of the 3-chapter film, 64.77 s at 30 fps. It is **608 × 1080 with no audio**, not 1080 × 1920: compare frames scaled, and music sync can't be checked against it.
- `stills/` — frames from the MP4 at every §5 cue (`cueNN_…`) plus one or two in-scene beats per scene (`…_lbN` = local beat N), named by film time. Use them for side-by-side checks.

Regenerate a still: `ffmpeg -ss <seconds> -i NeonNight.mp4 -frames:v 1 -q:v 3 stills/<name>.jpg`

## Decisions that override the spec

- **Every long chapter card plays its three laser zooms**, however few photos the chapter has (overrides §8's "needs ≥ 4 tiles; fewer → no zooms"). With 2 tiles the zooms alternate; with 1 tile it is zoomed three times. See `NeonZoomPicks`.
- **A card's length depends only on its position** (first and last chapter: 16 beats, middle: 8), never on its photos.
- **Film lengths for 1 and 2 chapters follow the scene rules** (23 and 30 bars), not §9's table (24 and 29).
