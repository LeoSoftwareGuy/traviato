# Neon Night — reference (#363)

- `NEON_NIGHT_SPEC.md` — the full spec. The prototype it names (`Neon Night Film.dc.html` + `neon-night.jsx`) was not provided, so **the spec and the MP4 are the reference**.
- `NeonNight.mp4` — reference render of the 3-chapter film, 64.77 s at 30 fps. It is **608 × 1080 with no audio**, not 1080 × 1920: compare frames scaled, and music sync can't be checked against it.
- `stills/` — frames from the MP4 at every §5 cue (`cueNN_…`) plus one or two in-scene beats per scene (`…_lbN` = local beat N), named by film time. Use them for side-by-side checks.

Regenerate a still: `ffmpeg -ss <seconds> -i NeonNight.mp4 -frames:v 1 -q:v 3 stills/<name>.jpg`
