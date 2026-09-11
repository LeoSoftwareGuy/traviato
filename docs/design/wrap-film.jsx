/* wrap-film.jsx — "Dolomites, slowly" wrap-up film.
   Continuous composition: one tree, everything keyed to authored T / CUES.

   SHAPE: the unit is a MOMENT — one photograph, held long enough to actually
   look at, captioned with the traveller's OWN words. Between chapters, one
   AI-written bridge line. Statistics are a single footnote near the end, not
   a chapter.

   SCALING: length is FIXED (~79s) no matter the library size. Moments are a
   curated handful; the two flurries absorb everything else. A 20-photo trip
   and a 200-photo trip run identically, at different densities.

   ─── WHAT FEEDS EACH FRAME ─────────────────────────────────────────────
   Dust       trip dates only, start–end from the trip record ("12–16 August
              2026"). No photograph, no copy.
   Invitation cover photo = the journal's hero image. "Five days" is computed
              from the dates; the second card is AI, written from trip type
              and destination.
   Bridges    AI text, never a photograph. The journal notes are read in
              order and split into three arcs; one line opens each.
              Bridge1 ← the M1–M3 notes, Bridge2 ← M4–M6, Bridge3 ← M7–M8.
   Moments    one photograph each, captioned with the traveller's OWN note —
              never AI. Slot assignment:
                M1, M3, M4  bonus-task photos, in completion order, badged
                            with the dare and its star value.
                M2, M5–M8   journal photographs, not already used.
              FALLBACK: with fewer bonus tasks than slots, the unfilled ones
              become ordinary journal photographs — same frame, no badge.
              Zero tasks completed means all eight slots are journal.
   Flurries   everything NOT shown as a moment. Flurry1 takes up to 15 (a 3×5
              grid, filled bottom row upward so a short trip never leaves a
              hole at the bottom); Flurry2 takes up to 15 of what remains.
              Both counts are PACING caps, not photo counts — the leftover
              total is spoken instead ("And eighty-four more").
   Footnote   photographs taken · bonus tasks completed · stars earned. No
              distance, no step count: a trip that never left one room still
              has all three.
   ───────────────────────────────────────────────────────────────────── */

const { useComposition, Shot, Easing, animate, clamp, CompositionStage,
        useTweaks, TweaksPanel, TweakSection, TweakSlider, TweakToggle, TweakColor } = window;

const W = 1080, H = 1920;

const INK = '#FBFAF6';
const DIM = '#AEACB7';
const FAINT = '#6D6D7A';
const CORAL = '#FF6D79';
const PURPLE = '#8962C5';

const SERIF = "'Fraunces',Georgia,serif";
const SANS = "'Roboto',system-ui,sans-serif";
const MONO = "'JetBrains Mono',ui-monospace,monospace";

const COVER = 'journal/balloon_1.jpg';

const POOL = [
  'journal/balloon_1.jpg', 'journal/balloon_2.jpg', 'journal/balloon_3.jpg',
  'journal/balloons_wide.png', 'guest/hero.png', 'guest/honeymoon_escape.png',
  'guest/solo_getaway.png', 'guest/food_lovers_weekend.png', 'guest/family_adventure.png',
  'guest/bucket_list_moment.png', 'guest/epic_milestone.png', 'trip/new_memory.png',
  'trip/planner.png',
];

/* the plain journal, used whenever a bonus-task slot has nothing to fill it */
const JOURNAL = POOL.filter((p) => p.indexOf('journal/') === 0);
const journalPick = (i) => JOURNAL[i % JOURNAL.length];

/* The eight moments. `note` is the traveller's own words — kept short, uneven,
   fragmentary. `tag` is the app's own knowledge of why this frame earned a slot. */
const REST_OF_MOMENTS = [
  { cue: 'M2', to: 'M3', src: 'journal/balloon_3.jpg',
    note: 'Sam rowed badly. We went in a circle for a while and neither of us minded.' },
  { cue: 'M4', to: 'M5', src: 'guest/food_lovers_weekend.png',
    tag: 'Dare · something that reflects · ✦2', tagColor: '#4FB0D8',
    note: 'A puddle outside the bakery. Counts double, apparently.' },
  { cue: 'M5', to: 'M6', src: 'guest/hero.png',
    note: 'Ten kilometres and one sandwich. Too windy to talk, so we just laughed.' },
  { cue: 'M6', to: 'Flurry2', src: 'guest/solo_getaway.png',
    note: 'The thermos. Carried it the whole way and never once filled it.' },
  { cue: 'M7', to: 'M8', src: 'guest/epic_milestone.png',
    note: 'Stopped the car in the middle of the pass. Nobody was coming.' },
  { cue: 'M8', to: 'Footnote', src: 'guest/family_adventure.png',
    note: 'He pushed us out of the mud and waved us off. We never got his name.' },
];

/* M1 and M3 are reserved for bonus tasks. With none completed they quietly
   become ordinary journal photographs — same frame, no badge, softer line. */
const BONUS_SLOTS = [
  { cue: 'M1', to: 'M2',
    bonus: { src: 'journal/balloon_2.jpg', tag: 'Dare · before the sun · ✦2', tagColor: '#4FB0D8',
      note: 'Up at five for it. Worth it.' },
    plain: { src: journalPick(1), note: 'Up at five. Worth it.' } },
  { cue: 'M3', to: 'Flurry1',
    bonus: { src: 'trip/planner.png', tag: 'Dare · one photo, both of you · ✦1', tagColor: '#4FB0D8',
      note: 'Blurred, both of us blinking. Keeping it anyway.' },
    plain: { src: journalPick(2), note: 'Blurred, both of us blinking. Keeping it anyway.' } },
];

function buildMoments(bonusDone) {
  const slots = BONUS_SLOTS.map((s) => Object.assign({ cue: s.cue, to: s.to },
    bonusDone > 0 ? s.bonus : s.plain));
  const order = ['M1', 'M2', 'M3', 'M4', 'M5', 'M6', 'M7', 'M8'];
  const all = slots.concat(REST_OF_MOMENTS);
  return order.map((c) => all.filter((m) => m.cue === c)[0]).filter(Boolean);
}

const BRIDGES = [
  { cue: 'Bridge1', line: 'It began before either of you\nwas properly awake.' },
  { cue: 'Bridge2', solid: true, line: 'Then it turned into a routine,\nwhich is its own kind of good.' },
  { cue: 'Bridge3', line: 'And then, far too quickly,\nit was the last road down.' },
];

const GRAIN = (function () {
  const c = document.createElement('canvas');
  c.width = c.height = 180;
  const ctx = c.getContext('2d');
  const d = ctx.createImageData(180, 180);
  let s = 1337;
  for (let i = 0; i < d.data.length; i += 4) {
    s = (s * 1103515245 + 12345) & 0x7fffffff;
    const v = 96 + ((s >> 16) & 127);
    d.data[i] = d.data[i + 1] = d.data[i + 2] = v;
    d.data[i + 3] = 255;
  }
  ctx.putImageData(d, 0, 0);
  return 'url(' + c.toDataURL('image/png') + ')';
})();

const rnd = (i, salt) => {
  const x = Math.sin(i * 12.9898 + salt * 78.233) * 43758.5453;
  return x - Math.floor(x);
};

/* ── all easing lives here ──────────────────────────────────── */
const MOTION = {
  rise: (start, dur, lift) => (T) => {
    const e = Easing.easeOutCubic(clamp((T - start) / dur, 0, 1));
    return { opacity: e, transform: 'translateY(' + ((1 - e) * (lift == null ? 38 : lift)) + 'px)' };
  },
  fade: (start, dur, from, to) => (T) =>
    from + (to - from) * Easing.easeInOutSine(clamp((T - start) / dur, 0, 1)),
  swell: (start, dur, from, to) => (T) =>
    from + (to - from) * clamp((T - start) / dur, 0, 1),
  toss: (start, dur) => (T) => Easing.easeOutBack(clamp((T - start) / dur, 0, 1)),
};

const band = (T, inAt, inDur, outAt, outDur) =>
  MOTION.fade(inAt, inDur, 0, 1)(T) * MOTION.fade(outAt, outDur, 1, 0)(T);
const mix = (a, b, p) => a + (b - a) * p;

/* ── chrome ─────────────────────────────────────────────────── */

function Photo({ src, opacity, scale, dx, dy, blur }) {
  if (opacity <= 0.002) return null;
  return (
    <img src={src} alt="" style={{
      position: 'absolute', left: '-8%', top: '-8%', width: '116%', height: '116%',
      objectFit: 'cover', opacity: opacity,
      transform: 'scale(' + scale + ') translate3d(' + dx + '%,' + dy + '%,0)',
      filter: blur ? 'blur(' + blur + 'px)' : 'none',
      willChange: 'transform, opacity',
    }} />
  );
}

/* a print with a real white border */
const PLATE_W = 720, PLATE_PHOTO_H = 860, PLATE_H = 11 + PLATE_PHOTO_H + 96;

/* The print lands face-DOWN — blank card stock — holds a beat, then turns
   over to show the photograph. `flip` runs 0 (back) → 1 (front). */
function Plate({ src, cx, cy, scale, rot, opacity, lift, flip }) {
  if (opacity <= 0.004) return null;
  const f = flip == null ? 1 : flip;
  const face = {
    width: PLATE_W, padding: '11px 11px 96px', background: '#FBFAF6', borderRadius: 5,
    boxSizing: 'border-box', backfaceVisibility: 'hidden', WebkitBackfaceVisibility: 'hidden',
  };
  return (
    <div style={{
      position: 'absolute', left: cx - PLATE_W / 2, top: cy - PLATE_H / 2,
      width: PLATE_W, height: PLATE_H, opacity: opacity, perspective: '2200px',
      transform: 'scale(' + scale + ') rotate(' + rot + 'deg)',
      transformOrigin: '50% 50%', willChange: 'transform, opacity',
    }}>
      <div style={{
        position: 'relative', width: PLATE_W, height: PLATE_H,
        transformStyle: 'preserve-3d', transformOrigin: '50% 50%',
        transform: 'rotateY(' + (180 - 180 * f) + 'deg)',
        boxShadow: '0 ' + (30 * lift) + 'px ' + (64 * lift) + 'px rgba(0,0,0,.6)',
        borderRadius: 5,
      }}>
        <div style={Object.assign({ position: 'absolute', inset: 0 }, face)}>
          <img src={src} alt="" style={{
            display: 'block', width: '100%', height: PLATE_PHOTO_H, objectFit: 'cover', borderRadius: 2,
          }} />
        </div>
        <div style={Object.assign({}, face, {
          position: 'absolute', inset: 0, transform: 'rotateY(180deg)',
          background: 'linear-gradient(150deg,#F4F1E8,#E4DFD2 62%,#D9D3C4)',
        })} />
      </div>
    </div>
  );
}

/* Flurry 1 — a card dropped flat onto a table: edge-on first (you see the
   white sliver, no image), then it falls, lands low in frame and faces up. */
function DropCard({ T, src, at, x, landY, w, h, rotZ, opacity }) {
  const fall = Easing.easeOutCubic(clamp((T - at) / 1.05, 0, 1));
  const settle = Easing.easeOutCubic(clamp((T - (at + 0.3)) / 0.85, 0, 1));
  const o = clamp((T - at) / 0.14, 0, 1) * opacity;
  if (o <= 0.004) return null;
  const y = mix(landY - 760, landY, fall);
  const tilt = 86 * (1 - settle);
  return (
    <div style={{
      position: 'absolute', left: 0, top: 0, width: w,
      padding: '9px 9px ' + Math.round(w * 0.15) + 'px',
      background: '#FBFAF6', borderRadius: 4, opacity: o,
      boxShadow: '0 ' + (10 + 26 * settle) + 'px ' + (24 + 44 * settle) + 'px rgba(0,0,0,.55)',
      transform: 'translate3d(' + x + 'px,' + y + 'px,0) rotate(' + (rotZ * settle) + 'deg) rotateX(' + tilt + 'deg)',
      transformOrigin: '50% 100%', willChange: 'transform, opacity',
    }}>
      <img src={src} alt="" style={{ display: 'block', width: '100%', height: h, objectFit: 'cover', borderRadius: 2 }} />
    </div>
  );
}

/* Flurry 2 — face-up prints crossing the frame, unhurried. The first few run
   corner to corner; the later ones bend away and leave through the top. */
function WaveCard({ T, src, at, dur, w, h, amp, toX, toY, opacity }) {
  const p = clamp((T - at) / dur, 0, 1);
  if (p <= 0 || p >= 1) return null;
  const e = Easing.easeInOutSine(p);
  const o = clamp(p / 0.12, 0, 1) * clamp((1 - p) / 0.16, 0, 1) * opacity;
  if (o <= 0.004) return null;
  const x = mix(-420, toX, e) + Math.sin(e * Math.PI) * (toX < W * 0.6 ? 150 : 0);
  const y = mix(H - 40, toY, e) + Math.sin(e * Math.PI * 2) * amp;
  const rot = mix(-13, toX < W * 0.6 ? 4 : 13, e);
  return (
    <div style={{
      position: 'absolute', left: 0, top: 0, width: w,
      padding: '9px 9px ' + Math.round(w * 0.15) + 'px',
      background: '#FBFAF6', borderRadius: 4, opacity: o,
      boxShadow: '0 26px 54px rgba(0,0,0,.5)',
      transform: 'translate3d(' + x + 'px,' + y + 'px,0) rotate(' + rot + 'deg)',
      willChange: 'transform, opacity',
    }}>
      <img src={src} alt="" style={{ display: 'block', width: '100%', height: h, objectFit: 'cover', borderRadius: 2 }} />
    </div>
  );
}

function Vignette() {
  return (
    <div style={{
      position: 'absolute', inset: 0, pointerEvents: 'none',
      background: 'radial-gradient(80% 58% at 50% 44%, rgba(7,9,26,0) 32%, rgba(7,9,26,.58) 76%, rgba(7,9,26,.92) 100%)',
    }} />
  );
}

function Grain({ T, amount }) {
  if (amount <= 0) return null;
  return (
    <div style={{
      position: 'absolute', inset: '-90px', pointerEvents: 'none', backgroundImage: GRAIN,
      backgroundPosition: (Math.floor(T * 61) % 180) + 'px ' + (Math.floor(T * 83) % 180) + 'px',
      opacity: amount, mixBlendMode: 'overlay',
    }} />
  );
}

function Letterbox({ T, on }) {
  if (!on) return null;
  const h = MOTION.swell(3.0, 1.6, 0, 96)(T);
  const bar = { position: 'absolute', left: 0, right: 0, height: h, background: '#000', zIndex: 40 };
  return (
    <React.Fragment>
      <div style={Object.assign({ top: 0 }, bar)} />
      <div style={Object.assign({ bottom: 0 }, bar)} />
    </React.Fragment>
  );
}

const Mono = ({ style, children }) => (
  <div style={Object.assign({
    font: '500 24px ' + MONO, letterSpacing: '.26em', color: FAINT, textTransform: 'uppercase',
  }, style)}>{children}</div>
);

/* ── opening ────────────────────────────────────────────────── */

function Dust({ T, CUES, accent }) {
  const specks = [
    [214, 470, 2.4, 0.5], [820, 372, 3.2, 1.1], [318, 1276, 2.6, 1.7],
    [742, 1420, 3.0, 0.9], [540, 236, 2.2, 2.1],
  ];
  const line = MOTION.swell(1.2, 1.9, 0, 168)(T);
  return (
    <React.Fragment>
      {specks.map((s, i) => (
        <div key={i} style={{
          position: 'absolute', left: s[0], top: s[1], width: s[2] * 2.6, height: s[2] * 2.6,
          borderRadius: '50%', background: i % 2 ? accent : INK,
          opacity: band(T, s[3], 1.4, CUES.Keepsake - 1.4, 1.8) * 0.7,
        }} />
      ))}
      <div style={{
        position: 'absolute', left: '50%', top: 1040, width: line * 2, height: 1, marginLeft: -line,
        background: 'linear-gradient(90deg,transparent,' + accent + ',transparent)',
        opacity: band(T, 1.2, 1.0, 2.7, 0.7),
      }} />
      <div style={{
        position: 'absolute', left: 0, right: 0, top: 900, textAlign: 'center',
        opacity: band(T, 0.6, 1.4, 2.5, 0.9),
      }}><Mono style={{ fontSize: 28, color: DIM }}>12–16 August 2026</Mono></div>
    </React.Fragment>
  );
}

function Invitation({ T, CUES }) {
  const a = CUES.Invitation;
  const l1 = MOTION.rise(a + 0.4, 1.8, 46)(T);
  const l2 = MOTION.rise(a + 1.6, 1.8, 46)(T);
  const out = MOTION.fade(a + 3.2, 1.0, 1, 0)(T);
  return (
    <div style={{ position: 'absolute', left: 110, right: 110, top: 760, opacity: out }}>
      <div style={Object.assign({ font: '300 132px/0.98 ' + SERIF, color: INK, letterSpacing: '-3px' }, l1)}>Five days.</div>
      <div style={Object.assign({
        font: '300 italic 132px/1.0 ' + SERIF, color: '#F2A65A', letterSpacing: '-3px', marginTop: 14,
      }, l2)}>One long road.</div>
    </div>
  );
}

/* One photograph: thrown in, held centre-frame while its caption is read,
   then it slides down into the pile and the next one takes its place. */
function Moment({ T, CUES, m, index, pileFade }) {
  const at = CUES[m.cue], to = CUES[m.to];
  const inAt = at - 0.45;
  const goAt = to - 0.85;

  if (!(T >= inAt) || !(T <= CUES.Footnote + 0.2)) return null;
  const thrown = MOTION.toss(inAt, 0.75)(T);

  // journey to the pile
  const gone = MOTION.fade(goAt, 0.85, 0, 1)(T);

  const pileCx = 300 + (index % 5) * 118 + (index > 4 ? 26 : 0);
  const pileCy = 1824 + (index % 3) * 7;
  const pileRot = (rnd(index, 9) - 0.5) * 22;

  const cx = mix(540, pileCx, gone);
  const cy = mix(mix(880, 782, thrown), pileCy, gone);
  const scale = mix(mix(0.86, 1, thrown) * MOTION.swell(at - 0.5, 5.4, 1, 1.035)(T), 0.4, gone);
  const rot = mix((1 - thrown) * -5, pileRot, gone);

  const live = 1 - gone;
  /* face-down on arrival, a held beat, then the turn */
  const flip = Easing.easeInOutCubic(clamp((T - (at + 0.3)) / 0.58, 0, 1));
  const tagRise = MOTION.rise(at + 0.82, 1.0, 22)(T);
  const noteRise = MOTION.rise(at + 1.0, 1.25, 28)(T);
  const capOut = MOTION.fade(goAt - 0.15, 0.6, 1, 0)(T);

  return (
    <React.Fragment>
      <Plate src={m.src} cx={cx} cy={cy} scale={scale} rot={rot}
        opacity={pileFade} lift={mix(thrown, 0.35, gone)} flip={flip} />
      <div style={{
        position: 'absolute', left: 108, right: 108, top: 1330,
        opacity: live * capOut * pileFade, textAlign: 'center',
      }}>
        {m.tag ? (
          <div style={Object.assign({}, tagRise)}>
            <Mono style={{ fontSize: 21, color: m.tagColor, letterSpacing: '.22em' }}>{m.tag}</Mono>
          </div>
        ) : null}
        <div style={Object.assign({
          font: '300 italic 50px/1.5 ' + SERIF, color: INK, marginTop: m.tag ? 24 : 0, textWrap: 'pretty',
        }, noteRise)}>{m.note}</div>
      </div>
    </React.Fragment>
  );
}

/* AI-written line between chapters — no photograph, just the thought */
function Bridge({ T, CUES, b }) {
  const a = CUES[b.cue];
  const rise = MOTION.rise(a + 0.5, 2.0, 34)(T);
  const grp = band(T, a + 0.2, 1.1, a + 2.3, 1.0);
  if (grp <= 0.004) return null;
  return (
    <div style={{ position: 'absolute', inset: 0 }}>
    <div style={{ position: 'absolute', inset: 0, background: '#07091A', opacity: grp * (b.solid ? 1 : 0.88) }} />
    <div style={{
      position: 'absolute', left: 120, right: 120, top: 780, opacity: grp, textAlign: 'center',
    }}>
      <div style={Object.assign({
        font: '300 italic 62px/1.42 ' + SERIF, color: 'rgba(251,250,246,.9)', whiteSpace: 'pre-line',
      }, rise)}>{b.line}</div>
    </div>
    </div>
  );
}

/* Everything the film didn't stop on — a breath, not a chapter */
function Flurry1({ T, CUES }) {
  const a = CUES.Flurry1, next = CUES.Bridge2;
  const grp = band(T, a + 0.05, 0.5, next - 1.0, 0.8);
  /* laid out on a loose grid so the pile fills the whole frame and each print
     stays readable — rows land bottom first, then upward */
  const COLS = 3, ROWS = 5, colW = W / COLS, top = 210, rowH = (H - top - 340) / ROWS;
  const cards = [];
  for (let r = 0; r < ROWS; r++) {
    for (let c = 0; c < COLS; c++) {
      const i = r * COLS + c;
      const w = Math.round(colW * 0.82 + rnd(i, 31) * 46);
      cards.push({
        src: POOL[(i * 5 + 31) % POOL.length],
        at: a + 0.15 + (ROWS - 1 - r) * 0.46 + c * 0.13 + rnd(i, 34) * 0.12,
        x: Math.round(c * colW + (colW - w) * (0.2 + rnd(i, 32) * 0.6)),
        landY: Math.round(top + r * rowH + (rnd(i, 33) - 0.5) * rowH * 0.3),
        w: w, h: Math.round(w * (0.66 + rnd(i, 35) * 0.2)),
        rotZ: (rnd(i, 36) - 0.5) * 18,
      });
    }
  }
  cards.sort((p, q) => p.landY - q.landY);
  return (
    <Shot from={a - 0.6} to={next + 0.6}>
      <div style={{ position: 'absolute', inset: 0, perspective: '1500px' }}>
        {cards.map((c, i) => (
          <DropCard key={i} T={T} src={c.src} at={c.at} x={c.x} landY={c.landY}
            w={c.w} h={c.h} rotZ={c.rotZ} opacity={grp} />
        ))}
      </div>
    </Shot>
  );
}

function Flurry2({ T, CUES, label }) {
  const a = CUES.Flurry2, next = CUES.Bridge3;
  const grp = band(T, a + 0.05, 0.5, next - 0.25, 0.7);
  const N = 15;
  const cards = [];
  for (let i = 0; i < N; i++) {
    const w = 240 + Math.round(rnd(i, 57) * 120);
    /* the run starts corner-to-corner and bends toward the top centre */
    const bend = Easing.easeInOutSine(clamp((i - 2) / (N - 3), 0, 1));
    cards.push({
      src: POOL[(i * 7 + 57) % POOL.length],
      at: a + 0.1 + i * 0.16,
      dur: 3.0 + rnd(i, 58) * 0.6,
      w: w, h: Math.round(w * (0.74 + rnd(i, 59) * 0.4)),
      amp: (120 + rnd(i, 60) * 200) * (1 - bend * 0.6),
      toX: mix(W + 160, W * 0.5 - w / 2, bend),
      toY: mix(-360, -520, bend),
    });
  }
  const lab = MOTION.rise(a + 0.5, 1.0, 22)(T);
  return (
    <Shot from={a - 0.6} to={next + 0.6}>
      <div style={{ position: 'absolute', inset: 0 }}>
        {cards.map((c, i) => (
          <WaveCard key={i} T={T} src={c.src} at={c.at} dur={c.dur}
            w={c.w} h={c.h} amp={c.amp} toX={c.toX} toY={c.toY} opacity={grp} />
        ))}
        <div style={{
          position: 'absolute', left: 0, right: 0, bottom: 0, height: 360,
          background: 'linear-gradient(to top,rgba(7,9,26,.72) 18%,rgba(7,9,26,0))', opacity: grp,
        }} />
        <div style={{ position: 'absolute', left: 110, top: 300, opacity: grp, zIndex: 5 }}>
          <div style={lab}><Mono style={{ color: DIM }}>{label}</Mono></div>
        </div>
      </div>
    </Shot>
  );
}

/* the numbers, demoted to one breath */
function Footnote({ T, CUES, accent, bonusDone }) {
  const a = CUES.Footnote;
  const grp = band(T, a + 0.3, 1.2, a + 3.0, 1.0);
  const rise = MOTION.rise(a + 0.5, 1.6, 26)(T);
  const bits = [['174', 'photographs'], [String(bonusDone), bonusDone === 1 ? 'bonus task' : 'bonus tasks'], ['✦46', 'stars']];
  return (
    <div style={{ position: 'absolute', left: 90, right: 90, top: 880, opacity: grp, textAlign: 'center' }}>
      <div style={Object.assign({
        display: 'flex', justifyContent: 'center', alignItems: 'baseline', gap: 44, flexWrap: 'wrap',
      }, rise)}>
        {bits.map((b, i) => (
          <div key={i} style={{ textAlign: 'center' }}>
            <div style={{ font: '300 76px/1 ' + SERIF, color: i === 2 ? accent : INK, letterSpacing: '-2px' }}>{b[0]}</div>
            <Mono style={{ fontSize: 19, color: FAINT, marginTop: 12, letterSpacing: '.2em' }}>{b[1]}</Mono>
          </div>
        ))}
      </div>
      <div style={Object.assign({
        font: '300 italic 40px/1.5 ' + SERIF, color: DIM, marginTop: 64,
      }, MOTION.rise(a + 1.6, 1.6, 24)(T))}>None of which is the reason you'll remember it.</div>
    </div>
  );
}

function Unlock({ T, CUES, accent }) {
  const a = CUES.Unlock;
  const grp = band(T, a + 0.2, 1.0, a + 3.8, 0.9);
  const pop = MOTION.toss(a + 0.4, 1.1)(T);
  const ringA = MOTION.swell(a + 0.6, 2.4, 0.4, 2.5)(T);
  const ringB = MOTION.swell(a + 1.1, 2.4, 0.4, 2.5)(T);
  const name = MOTION.rise(a + 1.3, 1.5, 34)(T);
  const sub = MOTION.rise(a + 2.0, 1.6, 30)(T);
  const ring = (s, o) => ({
    position: 'absolute', left: '50%', top: 0, width: 300, height: 300, marginLeft: -150,
    borderRadius: '50%', border: '1px solid ' + accent,
    transform: 'scale(' + s + ')', opacity: clamp(o, 0, 1),
  });
  return (
    <div style={{ position: 'absolute', left: 110, right: 110, top: 740, opacity: grp, textAlign: 'center' }}>
      <div style={{ position: 'relative', height: 300 }}>
        <div style={ring(ringA, 0.5 - ringA * 0.2)} />
        <div style={ring(ringB, 0.4 - ringB * 0.16)} />
        <div style={{
          position: 'absolute', left: 0, right: 0, top: 62, font: '300 168px/1 ' + SERIF,
          color: accent, transform: 'scale(' + pop + ')', opacity: pop,
        }}>✦</div>
      </div>
      <div style={Object.assign({ font: '300 96px/1.06 ' + SERIF, color: INK, letterSpacing: '-2px', marginTop: 40 }, name)}>Globetrotter</div>
      <div style={Object.assign({ font: '400 38px/1.6 ' + SANS, color: DIM, marginTop: 26 }, sub)}>Italy was your tenth country.</div>
    </div>
  );
}

function Keepsake({ T, CUES, accent }) {
  const a = CUES.Keepsake;
  const t1 = MOTION.rise(a + 0.6, 1.9, 46)(T);
  const t2 = MOTION.rise(a + 1.4, 1.9, 46)(T);
  const q = MOTION.rise(a + 2.6, 2.0, 34)(T);
  const mark = MOTION.rise(a + 3.9, 1.7, 26)(T);
  const out = MOTION.fade(a + 5.2, 1.3, 1, 0)(T);
  return (
    <div style={{ position: 'absolute', left: 110, right: 110, bottom: 268, opacity: out }}>
      <div style={Object.assign({ font: '300 138px/0.98 ' + SERIF, color: INK, letterSpacing: '-4px' }, t1)}>Dolomites,</div>
      <div style={Object.assign({ font: '300 italic 138px/1.0 ' + SERIF, color: '#F2A65A', letterSpacing: '-4px' }, t2)}>slowly</div>
      <div style={Object.assign({
        font: '300 italic 44px/1.6 ' + SERIF, color: 'rgba(251,250,246,.8)', marginTop: 44, textWrap: 'pretty',
      }, q)}>“Some trips you finish. This one you’ll keep.”</div>
      <div style={Object.assign({ display: 'flex', alignItems: 'center', gap: 18, marginTop: 64 }, mark)}>
        <div style={{
          width: 52, height: 52, borderRadius: 18, background: accent,
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          font: '400 26px ' + SERIF, color: '#0C0F27',
        }}>✦</div>
        <div style={{ font: '400 40px ' + SERIF, color: INK }}>Traviato</div>
      </div>
    </div>
  );
}

/* ── the one composition ────────────────────────────────────── */

function Piece({ grain, letterbox, accent, bonusDone }) {
  const { T, CUES } = useComposition();
  const moments = buildMoments(bonusDone);

  const coverEarly = band(T, CUES.Invitation - 0.2, 2.0, CUES.Bridge1 - 0.3, 1.5);
  const routeWash = band(T, CUES.Invitation + 1.4, 1.3, CUES.Bridge1 - 0.2, 1.1);
  const roomTone = band(T, CUES.Bridge1 - 0.4, 1.6, CUES.Footnote - 0.6, 1.4);
  const coverLate = band(T, CUES.Keepsake - 0.6, 2.3, CUES.Keepsake + 5.3, 1.3);
  // the pile survives the whole middle, then clears for the ending
  const pileFade = band(T, CUES.Bridge1, 0.8, CUES.Footnote - 0.9, 1.0);

  return (
    <div data-screen-label={'wrap-up ' + Math.floor(T) + 's'}
      style={{ position: 'absolute', inset: 0, background: '#07091A', overflow: 'hidden' }}>

      <Photo src={COVER} opacity={coverEarly * 0.22 + routeWash * 0.07 + roomTone * 0.1}
        scale={MOTION.swell(3.0, 40.0, 1.04, 1.28)(T)} dx={0} dy={0} blur={7} />
      <Photo src={COVER} opacity={coverLate}
        scale={MOTION.swell(CUES.Keepsake - 1.0, 9.0, 1.02, 1.16)(T)} dx={0} dy={-0.6} />

      <div style={{
        position: 'absolute', inset: 0,
        background: 'linear-gradient(to top,rgba(7,9,26,.94) 6%,rgba(7,9,26,.34) 46%,rgba(7,9,26,.72) 100%)',
        opacity: clamp(coverLate, 0, 1),
      }} />

      <Dust T={T} CUES={CUES} accent={accent} />
      <Invitation T={T} CUES={CUES} />
      {moments.map((m, i) => (
        <Moment key={m.cue} T={T} CUES={CUES} m={m} index={i} pileFade={pileFade} />
      ))}
      {BRIDGES.map((b) => <Bridge key={b.cue} T={T} CUES={CUES} b={b} />)}

      <Flurry1 T={T} CUES={CUES} />
      <Flurry2 T={T} CUES={CUES} label="And eighty-four more" />

      <Footnote T={T} CUES={CUES} accent={accent} bonusDone={bonusDone} />
      <Unlock T={T} CUES={CUES} accent={accent} />
      <Keepsake T={T} CUES={CUES} accent={accent} />

      <Vignette />
      <Grain T={T} amount={grain} />
      <Letterbox T={T} on={letterbox} />
    </div>
  );
}

function WrapFilm() {
  const [t, setTweak] = useTweaks(window.TWEAK_DEFAULTS);
  return (
    <React.Fragment>
      <CompositionStage width={W} height={H} bg="#07091A"
        scenes={window.OM_SCENES} playback={window.OM_PLAYBACK}>
        <Piece grain={t.grain} letterbox={t.letterbox} accent={t.accent}
          bonusDone={t.bonusDone == null ? 6 : Math.round(t.bonusDone)} />
      </CompositionStage>
      <TweaksPanel>
        <TweakSection label="This trip" />
        <TweakSlider label="Bonus tasks done" value={t.bonusDone} min={0} max={12} step={1}
          onChange={(v) => setTweak('bonusDone', v)} />
        <TweakSection label="Film" />
        <TweakSlider label="Grain" value={t.grain} min={0} max={0.3} step={0.01}
          onChange={(v) => setTweak('grain', v)} />
        <TweakToggle label="Letterbox" value={t.letterbox}
          onChange={(v) => setTweak('letterbox', v)} />
        <TweakColor label="Accent" value={t.accent}
          options={['#F29520', '#E8734A', '#D8A24C', '#C9A9F5']}
          onChange={(v) => setTweak('accent', v)} />
        <TweakSection label="Editing" />
        <TweakToggle label="Motion editor" value={t.motionEditor}
          onChange={(v) => setTweak('motionEditor', v)} />
      </TweaksPanel>
    </React.Fragment>
  );
}

window.WrapFilm = WrapFilm;
