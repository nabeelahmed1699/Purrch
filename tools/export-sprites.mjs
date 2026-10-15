#!/usr/bin/env node
// Exports the browser sprite data into one JSON file for the Mac app.
//
//   node tools/export-sprites.mjs
//
// Reads (source of truth, edited in the browser previews):
//   cats.js          palettes, one per cat
//   play-frames.js   side-view cat frames (+ per-cat markings), the ball, and HD sitting
//                    frames for the hover view
//   play.js          the ball game choreography
//   hungry.js        the hungry / feeding routines, the food bowl and the "meow" text
//   parts.js, markings.js, idle.js the big chair cat, shown while the notch is hovered
//   petting.js       petting the chair cat: its frames, the hearts and the hand cursor
//   wander.js        the cat hopping off the chair and wandering the hover view
//   sleep.js         naps: the bed in the hover view, the sleeping frames and the floating "z"s
// Writes:
//   app/Resources/sprites.json
//
// The big chair cat (parts.js, idle.js) is the hover view: 128 px = 64 pt, drawn below the notch.
// The 64 px parts (without the chair) are the hungry cat's facing-you frames.
//
// No npm packages: each file declares a top-level `const`, so we evaluate it and return it.

import { readFileSync, writeFileSync, mkdirSync } from 'node:fs';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = resolve(dirname(fileURLToPath(import.meta.url)), '..');

function load(file, names) {
  const source = readFileSync(join(root, file), 'utf8');
  return new Function(`${source}\nreturn { ${names.join(', ')} };`)();
}

const { CATS } = load('cats.js', ['CATS']);
const { PLAY_FRAMES, PLAY_MARKINGS, BALL, PLAY_FRAMES_HD, PLAY_MARKINGS_HD } =
  load('play-frames.js', ['PLAY_FRAMES', 'PLAY_MARKINGS', 'BALL', 'PLAY_FRAMES_HD', 'PLAY_MARKINGS_HD']);
const { PLAY } = load('play.js', ['PLAY']);
const { HUNGRY } = load('hungry.js', ['HUNGRY']);
const { PARTS: CHAIR_PARTS } = load('parts.js', ['PARTS']);
const { MARKINGS: CHAIR_MARKINGS } = load('markings.js', ['MARKINGS']);
const { IDLE } = load('idle.js', ['IDLE']);
const { PETTING } = load('petting.js', ['PETTING']);
const { WANDER } = load('wander.js', ['WANDER']);
const { SLEEP } = load('sleep.js', ['SLEEP']);

// ---------- the chair cat's layers, back to front (as sprite.js) ----------
const CAT_LAYERS = [
  { part: 'tail', variant: (f) => f.tail },
  { part: 'torso', variant: (f) => f.torso },
  { part: 'haunches', variant: () => 'default' },
  { part: 'legs', variant: () => 'default' },
  { part: 'ears', variant: (f) => f.ears, head: true },
  { part: 'head', variant: () => 'default', head: true },
  { part: 'eyes', variant: (f) => f.eyes, head: true },
];

// Pastes part grids (then the cat's marking overlays) back to front; head parts move up by headUp.
function compose({ parts, markings, layers, size }, recipe, catId) {
  const grid = Array.from({ length: size }, () => Array(size).fill('.'));
  const paste = (layer, dy) => {
    if (!layer) return;
    layer.rows.forEach((row, ry) => {
      const y = layer.y + ry + dy;
      if (y < 0 || y >= size) return;
      for (let rx = 0; rx < row.length; rx++) if (row[rx] !== '.') grid[y][layer.x + rx] = row[rx];
    });
  };
  for (const { part, variant, head } of layers) {
    const dy = head ? -(recipe.headUp || 0) : 0;
    paste(parts[part][variant(recipe)], dy);
    if (catId) paste(markings[catId]?.[part]?.[variant(recipe)], dy);
  }
  return grid;
}

function cropGrid(grid, keep) {
  let x0 = Infinity, y0 = Infinity, x1 = -1, y1 = -1;
  grid.forEach((row, y) => row.forEach((ch, x) => {
    if (keep(ch, x, y)) { x0 = Math.min(x0, x); y0 = Math.min(y0, y); x1 = Math.max(x1, x); y1 = Math.max(y1, y); }
  }));
  if (x1 < 0) return null;
  return { x0, y0, rows: grid.slice(y0, y1 + 1).map((row, ry) =>
    row.slice(x0, x1 + 1).map((ch, rx) => (keep(ch, x0 + rx, y0 + ry) ? ch : '.')).join('')) };
}

// Side-view and sitting (facing-you) frames all come from play-frames.js.
const allFrames = PLAY_FRAMES.frames;

// ---------- the chair cat: idle.js frames, composed like sprite.js (chair included) ----------
const CHAIR = {
  parts: CHAIR_PARTS, markings: CHAIR_MARKINGS, size: 128,
  layers: [{ part: 'chair', variant: () => 'default' }, ...CAT_LAYERS],
};
// The chair on its own, for when the cat has hopped down.
const emptyChair = (() => {
  const c = cropGrid(compose({ ...CHAIR, layers: [CHAIR.layers[0]] }, {}), (ch) => ch !== '.');
  return { x: c.x0, y: c.y0, rows: c.rows };
})();
const chairFrames = [];
const chairMarkings = Object.fromEntries(CATS.map((cat) => [cat.id, []]));
// idle.js frames first, then petting.js frames (indexed after them).
const petNames = Object.keys(PETTING.frames);
for (const recipe of [...IDLE.frames, ...Object.values(PETTING.frames)]) {
  const base = compose(CHAIR, recipe);
  const b = cropGrid(base, (ch) => ch !== '.');
  chairFrames.push({ x: b.x0, y: b.y0, rows: b.rows });
  for (const cat of CATS) {
    const o = cropGrid(compose(CHAIR, recipe, cat.id), (ch, x, y) => ch !== '.' && ch !== base[y][x]);
    chairMarkings[cat.id].push(o ? { x: o.x0, y: o.y0, rows: o.rows } : null);
  }
}

// ---------- choreography: normalise play.js into one simple shape for Swift ----------
// play.js allows shorthand (x: 12 or x: [a, b], frame: 'run' | 'stand' | [[frame, ms, facing]]).
// The app gets every value spelled out: x is always { from, to }, frames are always a list.
const span = (v) => (Array.isArray(v) ? { from: v[0], to: v[1] } : { from: v, to: v });

function catTrack(cat, segmentMs) {
  if (!cat) return null;
  const facing = cat.facing || 'right';
  let frames;
  if (cat.frame === 'run') {
    frames = { run: true, steps: [] };
  } else if (Array.isArray(cat.frame)) {
    frames = { run: false, steps: cat.frame.map(([frame, ms, f]) => ({ frame, ms, facing: f || facing })) };
  } else {
    frames = { run: false, steps: [{ frame: cat.frame, ms: segmentMs ?? 0, facing }] };
  }
  return { x: span(cat.x), ease: cat.ease || 'linear', facing, ...frames };
}

// ms: n, or [min, max] for a random length (hungry.js). `ms` is then the shortest it can be.
const segment = (s) => ({
  name: s.name,
  ms: s.tunnel ? 0 : Array.isArray(s.ms) ? s.ms[0] : s.ms,
  msRange: Array.isArray(s.ms) ? s.ms : null,
  tunnel: !!s.tunnel,
  cat: catTrack(s.cat, Array.isArray(s.ms) ? s.ms[1] : s.ms),
  ball: s.ball ? { x: span(s.ball.x), ease: s.ball.ease || 'linear' } : null,
  bowl: s.bowl ? { x: span(s.bowl.x), frame: s.bowl.frame, ease: s.bowl.ease || 'linear' } : null,
  wings: { left: span(s.wings.left), right: span(s.wings.right), ease: s.wings.ease || 'linear' },
});

const segments = PLAY.segments.map(segment);

const routines = Object.fromEntries(Object.entries(HUNGRY.routines).map(([name, r]) => [name, {
  segments: r.segments.map(segment),
  sounds: (r.sounds ?? []).map((s) => ({ at: s.at, ms: s.ms, x: span(s.x), y: span(s.y), ease: s.ease || 'linear' })),
}]));

// wander.js hop moves: [frame, ms, x, y, ease] → { frame, ms, x: {from, to}, y: {from, to}, ease }.
const move = ([frame, ms, x, y, ease]) => ({ frame, ms, x: span(x), y: span(y), ease: ease || 'linear' });

// ---------- checks: fail loudly instead of shipping broken data ----------
const problems = [];
const knownFrames = new Set(Object.keys(allFrames));
for (const f of PLAY.run.frames) if (!knownFrames.has(f)) problems.push(`play.js run cycle uses unknown frame '${f}'`);
const allSegments = [...segments, ...Object.values(routines).flatMap((r) => r.segments)];
for (const s of allSegments) {
  for (const step of s.cat?.steps ?? []) {
    if (!knownFrames.has(step.frame)) problems.push(`segment '${s.name}' uses unknown frame '${step.frame}'`);
  }
  if (s.bowl && !(s.bowl.frame in HUNGRY.bowl.frames)) problems.push(`segment '${s.name}' uses unknown bowl frame '${s.bowl.frame}'`);
}
for (const name of ['comeOut', 'meow', 'wait', 'eat', 'goHome', 'attention']) {
  if (!routines[name]) problems.push(`hungry.js is missing the '${name}' routine`);
}
// The notch is 32 pt tall; a sound must never poke out above it.
const meowHeight = (HUNGRY.meow.rows.length * HUNGRY.meow.pixelScale) / 2;
for (const [name, r] of Object.entries(routines)) {
  for (const s of r.sounds) {
    if (Math.max(s.y.from, s.y.to) + meowHeight > 32) problems.push(`routine '${name}': a sound rises above the notch`);
  }
}
const wanderFrames = [...WANDER.chairSit.map(([f]) => f), ...WANDER.walk.frames, ...WANDER.hop.map(([f]) => f), ...WANDER.hopUp.map(([f]) => f),
  ...WANDER.pauses.flatMap((p) => (p.steps ?? []).map(([f]) => f)), ...WANDER.pettedSide.map(([f]) => f),
  ...WANDER.pettedSitting.map(([f]) => f), ...WANDER.pettedFront.map(([f]) => f), ...WANDER.sittingFrames,
  ...WANDER.hungry.steps.map(([f]) => f), ...WANDER.attention.steps.map(([f]) => f), ...WANDER.eating.steps.map(([f]) => f), ...WANDER.chase.frames, ...WANDER.chase.pounce.map(([f]) => f), ...WANDER.chase.holdFrames, WANDER.chase.kickFrame,
  ...WANDER.tiredChase.frames, ...WANDER.tiredChase.pounce.map(([f]) => f), WANDER.tiredChase.kickFrame];
for (const f of wanderFrames) if (!knownFrames.has(f)) problems.push(`wander.js uses unknown frame '${f}'`);
const sleepFrames = [...SLEEP.steps.map(([f]) => f), ...SLEEP.ballReactions.flatMap((r) => r.steps.map(([f]) => f)),
  ...SLEEP.sleepyChase.frames, ...SLEEP.sleepyChase.pounce.map(([f]) => f), ...SLEEP.sleepyChase.holdFrames, SLEEP.sleepyChase.kickFrame];
for (const f of sleepFrames) if (!knownFrames.has(f)) problems.push(`sleep.js uses unknown frame '${f}'`);
for (const [name, grid, palette] of [['bed back', SLEEP.bed.back.rows, SLEEP.bed.palette],
  ['bed front', SLEEP.bed.front.rows, SLEEP.bed.palette], ['z', SLEEP.z.rows, SLEEP.z.palette]]) {
  for (const row of grid) for (const key of row) {
    if (key !== '.' && !(key in palette)) problems.push(`sleep.js ${name}: unknown key '${key}'`);
  }
}
for (const [name] of PETTING.timeline) {
  if (!petNames.includes(name)) problems.push(`petting.js timeline uses unknown frame '${name}'`);
}
for (const grid of [PETTING.heart.rows, PETTING.cursor.open, PETTING.cursor.stroke]) {
  for (const row of grid) for (const key of row) {
    if (key !== '.' && !(key in PETTING.palette)) problems.push(`petting.js: unknown key '${key}'`);
  }
}
for (const name of Object.keys(PLAY_FRAMES_HD.frames)) {
  if (!knownFrames.has(name)) problems.push(`HD frame '${name}' has no 64 px frame`);
}
const groups = [allFrames, ...Object.values(PLAY_MARKINGS), PLAY_FRAMES_HD.frames, ...Object.values(PLAY_MARKINGS_HD), { ...chairFrames },
  ...Object.values(chairMarkings).map((list) => ({ ...list.filter(Boolean) }))];
for (const group of groups) {
  for (const [name, layer] of Object.entries(group)) {
    for (const row of layer.rows) {
      for (const key of row) if (key !== '.' && !(key in CATS[0].palette)) problems.push(`frame ${name}: unknown key '${key}'`);
    }
  }
}
if (problems.length) {
  console.error([...new Set(problems)].join('\n'));
  process.exit(1);
}

// ---------- write ----------
const out = {
  cats: CATS.map((cat) => ({
    id: cat.id,
    name: cat.name,
    palette: Object.fromEntries(Object.entries(cat.palette).filter(([, hex]) => hex)),
  })),
  play: {
    frameWidth: PLAY_FRAMES.width,
    frameHeight: PLAY_FRAMES.height,
    frames: allFrames,
    markings: Object.fromEntries(CATS.map((cat) => [cat.id, PLAY_MARKINGS[cat.id] ?? {}])),
    ball: BALL,
    hd: {
      frameWidth: PLAY_FRAMES_HD.width,
      frameHeight: PLAY_FRAMES_HD.height,
      frames: PLAY_FRAMES_HD.frames,
      markings: Object.fromEntries(CATS.map((cat) => [cat.id, PLAY_MARKINGS_HD[cat.id] ?? {}])),
    },
    run: PLAY.run,
    tunnelMs: PLAY.tunnelMs,
    everySeconds: PLAY.everySeconds,
    segments,
  },
  chair: {
    size: CHAIR.size,
    frames: chairFrames,
    markings: chairMarkings,
    timeline: IDLE.timeline,
    empty: emptyChair,
  },
  wander: {
    afterMs: WANDER.afterMs,
    pixelScale: WANDER.pixelScale,
    seatY: WANDER.seatY,
    chairX: WANDER.chairX,
    chairSit: WANDER.chairSit.map(([frame, ms]) => ({ frame, ms })),
    rangeX: WANDER.rangeX,
    clearOfChair: WANDER.clearOfChair,
    walk: WANDER.walk,
    minWalk: WANDER.minWalk,
    maxWalk: WANDER.maxWalk,
    hop: WANDER.hop.map(move),
    hopUp: WANDER.hopUp.map(move),
    chairMs: WANDER.chairMs,
    pauses: WANDER.pauses.map((p) => ({
      name: p.name, weight: p.weight ?? 1, chair: !!p.chair, inFront: !!p.inFront,
      steps: (p.steps ?? []).map(([frame, ms]) => ({ frame, ms })),
    })),
    pettedSide: WANDER.pettedSide.map(([frame, ms]) => ({ frame, ms })),
    pettedSitting: WANDER.pettedSitting.map(([frame, ms]) => ({ frame, ms })),
    pettedFront: WANDER.pettedFront.map(([frame, ms]) => ({ frame, ms })),
    sittingFrames: WANDER.sittingFrames,
    hungry: {
      steps: WANDER.hungry.steps.map(([frame, ms]) => ({ frame, ms })),
      sounds: WANDER.hungry.sounds.map((s) => ({ at: s.at, ms: s.ms, dx: span(s.dx), y: span(s.y) })),
      textScale: WANDER.hungry.textScale,
    },
    eating: { steps: WANDER.eating.steps.map(([frame, ms]) => ({ frame, ms })) },
    attention: {
      steps: WANDER.attention.steps.map(([frame, ms]) => ({ frame, ms })),
      sounds: WANDER.attention.sounds.map((s) => ({ at: s.at, ms: s.ms, dx: span(s.dx), y: span(s.y) })),
      textScale: WANDER.attention.textScale,
    },
    ball: WANDER.ball,
    chase: { ...WANDER.chase, pounce: WANDER.chase.pounce.map(([frame, ms, dx]) => ({ frame, ms, dx })) },
    tiredChase: { ...WANDER.tiredChase, pounce: WANDER.tiredChase.pounce.map(([frame, ms, dx]) => ({ frame, ms, dx })) },
    behindChance: WANDER.behindChance,
    switchSidesClear: WANDER.switchSidesClear,
  },
  sleep: {
    everyMinutes: SLEEP.everyMinutes,
    napMinutes: SLEEP.napMinutes,
    steps: SLEEP.steps.map(([frame, ms]) => ({ frame, ms })),
    ballReactions: SLEEP.ballReactions.map((r) => ({
      name: r.name, weight: r.weight ?? 1, wakes: !!r.wakes, steps: r.steps.map(([frame, ms]) => ({ frame, ms })),
    })),
    sleepyChase: { ...SLEEP.sleepyChase, pounce: SLEEP.sleepyChase.pounce.map(([frame, ms, dx]) => ({ frame, ms, dx })) },
    bed: {
      ...SLEEP.bed,
      // The back grid is the whole bed: its size is the bed's size.
      width: SLEEP.bed.back.rows[0].length,
      height: SLEEP.bed.back.rows.length,
    },
    z: { ...SLEEP.z, floats: SLEEP.z.floats.map((z) => ({ at: z.at, ms: z.ms, dx: span(z.dx), y: span(z.y), size: z.size })) },
  },
  petting: {
    ms: PETTING.ms,
    timeline: PETTING.timeline.map(([name, ms]) => ({ frame: IDLE.frames.length + petNames.indexOf(name), ms })),
    hearts: PETTING.hearts.map((h) => ({ at: h.at, ms: h.ms, x: span(h.x), y: span(h.y), ease: h.ease || 'linear' })),
    palette: PETTING.palette,
    heart: PETTING.heart,
    cursor: PETTING.cursor,
  },
  hungry: {
    hungryAfterMinutes: HUNGRY.hungryAfterMinutes,
    attentionEveryMinutes: HUNGRY.attentionEveryMinutes,
    attentionLoops: HUNGRY.attentionLoops,
    routines,
    bowl: HUNGRY.bowl,
    meow: HUNGRY.meow,
  },
};

const target = join(root, 'app', 'Resources', 'sprites.json');
mkdirSync(dirname(target), { recursive: true });
writeFileSync(target, JSON.stringify(out));
const total = segments.reduce((t, s) => t + s.ms, 0);
console.log(`wrote ${target}`);
console.log(`  cats: ${out.cats.map((c) => c.id).join(', ')}`);
console.log(`  play: ${knownFrames.size} frames (${PLAY_FRAMES.width}x${PLAY_FRAMES.height}px), ball ${BALL.size}px, ` +
  `${segments.length} segments, ${total} ms + tunnel ${PLAY.tunnelMs.join('-')} ms`);
console.log(`  hungry: ${Object.keys(routines).join(', ')}`);
console.log(`  petting: ${petNames.length} frames, ${PETTING.hearts.length} hearts per click`);
console.log(`  sleep: bed ${out.sleep.bed.width}x${out.sleep.bed.height}px, ${SLEEP.steps.length} steps, ${SLEEP.z.floats.length} z's`);
console.log(`  chair: ${chairFrames.length} frames (${CHAIR.size}px), ${IDLE.timeline.length} timeline steps`);
