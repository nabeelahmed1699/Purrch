// Vector source for the side-view Purrch cat (viewBox -50 0 250 200, facing right).
// Used for the ball game: the 80 x 64 px frames in play-frames.js are generated from this
// by vector/build-play.html. At 64 px tall the frame is 32 pt — exactly the notch height.
// The extra 50 units on the left give the tail room when it streams back.
//
// catSideSVG(cat, opts)
//   opts.pose      a SIDE_POSES entry (or any object with the same fields)
//   opts.markings  false to draw the bare shared shape with no cat-specific markings
//   opts.pixel     true when rasterising: crisp edges, strokes at least ~1 pixel wide
//   opts.spriteSize  pixel height being rasterised to (default 64)
//
// A pose is a small skeleton:
//   y      body raise/drop (+ = down), tilt  body rotation in degrees (+ = nose down)
//   len    torso length factor, head  extra head rotation, tail  tail angle (+ = up)
//   legs   { nf, ff, nb, fb } = near/far front/back legs as [upper angle, bend], degrees,
//          optionally [upper angle, bend, length factor] for a longer leg.
//          Angles are from straight down, + = forward. Front legs bend forward at the
//          elbow, back legs bend backward at the hock.
//   eyes   'open' | 'half' | 'closed'
//   rise   extra height of the back, for breathing while lying down (default 0)
//   headShift  [dx, dy] extra head offset (e.g. dropped down and back towards the hip)
//   scratch  { at: [x, y], k }: the near back leg folds up and its paw lands on point (x, y)
//            of the head drawing (the ear), solved like a two-joint arm; k = leg length
//            factor. The leg runs behind the head and the paw is drawn on top of it.

// x, y, width, height of the side-view drawing area (4:5.12 = 80 x 64 px at 64 px tall).
const SIDE_VIEWBOX = [-50, 0, 250, 200];

const SIDE_POSES = {
  stand: { y: 0, tilt: 0, len: 1, head: 0, tail: 10, eyes: 'open',
    legs: { nf: [-3, 3], ff: [4, -2], nb: [16, 30], fb: [8, 26] } },
  // Gallop, six frames.
  run1: { y: -6, tilt: 0, len: 1.06, head: 3, tail: -60, eyes: 'open',
    legs: { nf: [55, 10], ff: [45, 15], nb: [-50, -5], fb: [-40, 0] } },
  run2: { y: -2, tilt: 4, len: 1.02, head: 2, tail: -55, eyes: 'open',
    legs: { nf: [25, -5], ff: [10, 5], nb: [-30, 10], fb: [-15, 20] } },
  run3: { y: 3, tilt: 2, len: 0.94, head: 0, tail: -45, eyes: 'open',
    legs: { nf: [-25, 40], ff: [-15, 30], nb: [35, 50], fb: [25, 45] } },
  run4: { y: 1, tilt: -3, len: 0.96, head: -1, tail: -45, eyes: 'open',
    legs: { nf: [-40, 70], ff: [-30, 60], nb: [20, 30], fb: [10, 25] } },
  run5: { y: -3, tilt: -5, len: 1, head: 0, tail: -55, eyes: 'open',
    legs: { nf: [10, 60], ff: [0, 50], nb: [-20, 10], fb: [-10, 15] } },
  run6: { y: -5, tilt: -2, len: 1.03, head: 2, tail: -60, eyes: 'open',
    legs: { nf: [40, 30], ff: [30, 30], nb: [-40, 0], fb: [-30, 5] } },
  // Hunting the ball.
  crouch: { y: 12, tilt: 5, len: 1, head: 6, tail: -30, eyes: 'open',
    legs: { nf: [-30, 80], ff: [-20, 75], nb: [35, 90], fb: [30, 85] } },
  pounce: { y: -16, tilt: -10, len: 1.1, head: -4, tail: -70, eyes: 'open',
    legs: { nf: [70, 0], ff: [60, 5], nb: [-60, 0], fb: [-50, 5] } },
  catch: { y: 6, tilt: 8, len: 1, head: 10, tail: -20, eyes: 'open',
    legs: { nf: [30, 20], ff: [20, 20], nb: [25, 70], fb: [20, 65] } },
  // Paw swipe.
  kick1: { y: 4, tilt: 3, len: 1, head: 6, tail: 0, eyes: 'open',
    legs: { nf: [80, 70], ff: [0, 5], nb: [20, 40], fb: [10, 35] } },
  kick2: { y: 4, tilt: 2, len: 1, head: 4, tail: 5, eyes: 'half',
    legs: { nf: [85, -5], ff: [0, 5], nb: [20, 40], fb: [10, 35] } },
  kick3: { y: 3, tilt: 1, len: 1, head: 2, tail: 8, eyes: 'open',
    legs: { nf: [50, 20], ff: [0, 5], nb: [18, 36], fb: [9, 30] } },
  // Looking around.
  lookUp: { y: 0, tilt: -2, len: 1, head: -14, tail: 22, eyes: 'open',
    legs: { nf: [-3, 3], ff: [4, -2], nb: [16, 30], fb: [8, 26] } },
  lookDown: { y: 1, tilt: 2, len: 1, head: 12, tail: 6, eyes: 'half',
    legs: { nf: [-3, 3], ff: [4, -2], nb: [16, 30], fb: [8, 26] } },
  // Being petted where it stands: eyes shut, head pushing up into the hand, tail up.
  petSide1: { y: 1, tilt: -2, len: 1, head: -8, tail: 24, eyes: 'closed',
    legs: { nf: [-3, 3], ff: [4, -2], nb: [16, 30], fb: [8, 26] } },
  petSide2: { y: 0, tilt: -3, len: 1, head: -13, tail: 30, eyes: 'closed',
    legs: { nf: [-3, 3], ff: [4, -2], nb: [16, 30], fb: [8, 26] } },
  // Sitting side-on.
  sitSide: { y: 18, tilt: -40, len: 0.85, head: 38, tail: -50, eyes: 'open',
    legs: { nf: [20, -12], ff: [24, -12], nb: [85, 175], fb: [80, 170] } },
  sitSidePet: { y: 18, tilt: -40, len: 0.85, head: 24, tail: -40, eyes: 'closed',
    legs: { nf: [20, -12], ff: [24, -12], nb: [85, 175], fb: [80, 170] } },
  // Ear scratch: reaching (head going down, paw on its way up), then two strokes: head tilted down into the leg, paw on the ear then lower.
  scratchReach: { y: 18, tilt: -34, len: 0.85, head: 44, headShift: [-5, 8], tail: -50, eyes: 'half',
    scratch: { at: [128, 112], k: 2.0 }, legs: { nf: [20, -12], ff: [24, -12], nb: [85, 175], fb: [80, 170] } },
  scratch1: { y: 18, tilt: -28, len: 0.85, head: 50, headShift: [-10, 16], tail: -50, eyes: 'closed',
    scratch: { at: [147, 78], k: 2.3 }, legs: { nf: [20, -12], ff: [24, -12], nb: [85, 175], fb: [80, 170] } },
  scratch2: { y: 18, tilt: -28, len: 0.85, head: 46, headShift: [-10, 15], tail: -50, eyes: 'closed',
    scratch: { at: [141, 88], k: 2.3 }, legs: { nf: [20, -12], ff: [24, -12], nb: [85, 175], fb: [80, 170] } },
  // Asleep in the bed: lying flat, front paws out, head resting on them, tail tucked under.
  // Two frames: breathing out, then in (the back rises).
  sleep1: { y: 32, tilt: 0, len: 0.98, head: 22, headShift: [4, 22], tail: 150, eyes: 'closed',
    legs: { nf: [88, 4], ff: [84, 6], nb: [80, 170], fb: [76, 166] } },
  sleep2: { y: 32, tilt: 0, len: 0.98, head: 21, headShift: [4, 21], tail: 150, eyes: 'closed', rise: 4,
    legs: { nf: [88, 4], ff: [84, 6], nb: [80, 170], fb: [76, 166] } },
  // Woken in the bed: head lifting drowsily (eyes half open), then up and looking.
  sleepDrowsy: { y: 32, tilt: 0, len: 0.98, head: 6, headShift: [2, 12], tail: 150, eyes: 'half',
    legs: { nf: [88, 4], ff: [84, 6], nb: [80, 170], fb: [76, 166] } },
  sleepLookUp: { y: 32, tilt: 0, len: 0.98, head: -4, headShift: [-2, 4], tail: 150, eyes: 'open',
    legs: { nf: [88, 4], ff: [84, 6], nb: [80, 170], fb: [76, 166] } },
};

// Casual walk, six frames (walk1..walk6). Each leg swings forward and back on its own beat
// (a lateral-sequence walk: back leg, then the front leg on the same side), and lifts its
// paw while it swings forward. The body bobs a touch and the tail is held up.
(() => {
  const TAU = Math.PI * 2;
  // phase: where in the stride this leg is. base/swing: angles. lift: extra bend while
  // swinging forward. Front legs bend forward at the elbow, back legs backward at the hock.
  const leg = (p, phase, base, swing, baseBend, lift) => {
    const t = p + phase * TAU;
    return [base + swing * Math.sin(t), baseBend + lift * Math.max(0, Math.cos(t))];
  };
  // Tired walk (tiredWalk1..6): too hungry to bother. Shorter steps, head hanging low,
  // tail down, body sagging.
  for (let i = 0; i < 6; i++) {
    const p = (i / 6) * TAU;
    SIDE_POSES[`tiredWalk${i + 1}`] = {
      y: 3 + Math.abs(Math.sin(p)) * 1, tilt: 3, len: 0.98, head: 24 + Math.sin(p * 2), tail: -48 + 3 * Math.sin(p),
      eyes: 'half',
      legs: {
        nb: leg(p, 0, 16, 9, 30, 12),
        nf: leg(p, 0.25, 0, 10, 4, 20),
        fb: leg(p, 0.5, 12, 9, 28, 12),
        ff: leg(p, 0.75, 2, 10, 2, 20),
      },
    };
  }
  for (let i = 0; i < 6; i++) {
    const p = (i / 6) * TAU;
    SIDE_POSES[`walk${i + 1}`] = {
      y: Math.abs(Math.sin(p)) * 1.5 - 0.5, tilt: 0, len: 1, head: 1 + Math.sin(p * 2), tail: 18 + 4 * Math.sin(p),
      eyes: 'open',
      legs: {
        nb: leg(p, 0, 16, 14, 28, 22),
        nf: leg(p, 0.25, 0, 16, 2, 34),
        fb: leg(p, 0.5, 12, 14, 26, 22),
        ff: leg(p, 0.75, 2, 16, 0, 34),
      },
    };
  }
})();

function catSideSVG(cat, opts = {}) {
  const c = cat.colors;
  const m = opts.markings === false ? NO_MARKINGS : cat.markings;
  const pose = opts.pose || SIDE_POSES.stand;
  const pixel = !!opts.pixel;
  const spriteSize = opts.spriteSize || 64;
  const minStroke = pixel ? (1.05 * 200) / spriteSize : 0;
  const strokeW = (w) => Math.max(w, minStroke).toFixed(2);
  const SW = Number(strokeW(3));
  const O = c.outline;
  const f = (n) => n.toFixed(2);
  const rad = (d) => (d * Math.PI) / 180;

  // ---------- skeleton ----------
  const L1 = 17, L2 = 19; // upper / lower leg lengths
  const shoulder = [132, 152 + pose.y];
  const hip = [72, 150 + pose.y];
  const bodyCenter = [100, 138 + pose.y];

  // Rotate a point around the body centre by the body tilt.
  const tiltPt = ([x, y]) => {
    const a = rad(pose.tilt), dx = x - bodyCenter[0], dy = y - bodyCenter[1];
    return [bodyCenter[0] + dx * Math.cos(a) - dy * Math.sin(a), bodyCenter[1] + dx * Math.sin(a) + dy * Math.cos(a)];
  };
  // Stretch along the body (gallop reach / gather).
  const stretch = ([x, y]) => [bodyCenter[0] + (x - bodyCenter[0]) * pose.len, y];

  function legPath(joint, [a, bend, scale = 1], front) {
    const k = [joint[0] + L1 * scale * Math.sin(rad(a)), joint[1] + L1 * scale * Math.cos(rad(a))];
    const b = front ? a + bend : a - bend;
    const p = [k[0] + L2 * scale * Math.sin(rad(b)), k[1] + L2 * scale * Math.cos(rad(b))];
    return { d: `M ${f(joint[0])} ${f(joint[1])} L ${f(k[0])} ${f(k[1])} L ${f(p[0])} ${f(p[1])}`, paw: p, angle: b };
  }

  const sh = tiltPt(stretch(shoulder));
  const hp = tiltPt(stretch(hip));
  const legs = {
    nf: legPath(sh, pose.legs.nf, true),
    ff: legPath([sh[0] - 6, sh[1] - 2], pose.legs.ff, true),
    nb: legPath(hp, pose.legs.nb, false),
    fb: legPath([hp[0] - 6, hp[1] - 2], pose.legs.fb, false),
  };

  const legSVG = (leg, color, pawFill, width) => `
    <path d="${leg.d}" fill="none" stroke="${O}" stroke-width="${f(width + SW * 2)}" stroke-linecap="round" stroke-linejoin="round"/>
    <path d="${leg.d}" fill="none" stroke="${color}" stroke-width="${f(width)}" stroke-linecap="round" stroke-linejoin="round"/>
    <ellipse cx="${f(leg.paw[0] + 2)}" cy="${f(leg.paw[1])}" rx="8" ry="5.5" fill="${pawFill}" stroke="${O}" stroke-width="${f(SW)}"/>`;

  const pawNear = m.whitePaws ? c.white : c.fur;
  const pawFar = m.whitePaws ? c.whiteShadow : c.furShadow;
  const legNear = m.whiteLegs ? c.white : c.fur;
  const legFar = m.whiteLegs ? c.whiteShadow : c.furShadow;

  // ---------- torso ----------
  const rx = 52 * pose.len;
  const rise = pose.rise || 0;
  const bodyTransform = `rotate(${f(pose.tilt)} ${bodyCenter[0]} ${bodyCenter[1]})`;
  const torso = `M ${f(100 - rx)} ${f(bodyCenter[1] + 2)} C ${f(100 - rx)} ${f(bodyCenter[1] - 30 - rise)} ${f(100 + rx)} ${f(bodyCenter[1] - 32 - rise)} ` +
    `${f(100 + rx + 4)} ${f(bodyCenter[1] - 2)} C ${f(100 + rx + 6)} ${f(bodyCenter[1] + 20)} ${f(100 - rx + 6)} ${f(bodyCenter[1] + 30)} ` +
    `${f(100 - rx)} ${f(bodyCenter[1] + 2)} Z`;

  // ---------- head (attached at the neck, follows the body) ----------
  const neck = tiltPt(stretch([142, 124 + pose.y]));
  const headDx = neck[0] - 142, headDy = neck[1] - 124;
  // Slightly oversized head: reads better (and cuter) at 32 pt.
  const [shiftX, shiftY] = pose.headShift || [0, 0];
  const headTransform = `translate(${f(headDx + shiftX)} ${f(headDy + shiftY)}) rotate(${f(pose.tilt + pose.head)} 142 124) translate(142 124) scale(1.14) translate(-142 -124)`;

  // Scratching: fold the near back leg so its paw lands on the ear (two-joint solve).
  if (pose.scratch) {
    const [px, py] = pose.scratch.at;
    // The head drawing's transform, applied to a point: scale about the neck, rotate, move.
    const a = rad(pose.tilt + pose.head);
    const sx = 142 + (px - 142) * 1.14, sy = 124 + (py - 124) * 1.14;
    const target = [
      142 + (sx - 142) * Math.cos(a) - (sy - 124) * Math.sin(a) + headDx + shiftX,
      124 + (sx - 142) * Math.sin(a) + (sy - 124) * Math.cos(a) + headDy + shiftY,
    ];
    const k = pose.scratch.k || 1;
    const l1 = L1 * k, l2 = L2 * k;
    const dx = target[0] - hp[0], dy = target[1] - hp[1];
    const d = Math.min(Math.hypot(dx, dy), (l1 + l2) * 0.999);
    const base = Math.atan2(dy, dx);
    const off = Math.acos((l1 * l1 + d * d - l2 * l2) / (2 * l1 * d));
    // Two possible knees; a scratching cat's knee points forward (towards the face).
    const knees = [base + off, base - off].map((t) => [hp[0] + l1 * Math.cos(t), hp[1] + l1 * Math.sin(t)]);
    const knee = knees[0][0] > knees[1][0] ? knees[0] : knees[1];
    const paw = [hp[0] + (dx / Math.hypot(dx, dy)) * d, hp[1] + (dy / Math.hypot(dx, dy)) * d];
    legs.nb = { d: `M ${f(hp[0])} ${f(hp[1])} L ${f(knee[0])} ${f(knee[1])} L ${f(paw[0])} ${f(paw[1])}`, paw };
  }
  // Round face with a short, soft snout (a long one reads as a beak at 32 pt).
  const head = 'M 128 106 C 128 90 140 84 154 84 C 168 84 176 94 177 103 C 181 106 182 114 178 119 ' +
    'C 172 126 164 128 158 128 C 146 129 134 128 130 122 L 124 128 L 127 118 C 127 114 128 110 128 106 Z';
  const earNear = 'M 136 98 L 141 72 Q 143 67 147 71 L 160 89 Z';
  const earFar = 'M 151 90 L 161 70 Q 164 66 167 70 L 173 96 Z';
  const innerEar = 'M 140 93 L 143.5 77 L 154 89 Z';

  const eyeX = 163, eyeY = 105;
  let eye;
  if (pose.eyes === 'closed') {
    eye = `<path d="M ${eyeX - 6} ${eyeY} Q ${eyeX} ${eyeY + 5} ${eyeX + 6} ${eyeY}" fill="none" stroke="${O}" stroke-width="${strokeW(3)}" stroke-linecap="round"/>`;
  } else {
    eye = `
      <ellipse cx="${eyeX}" cy="${eyeY}" rx="6.5" ry="8" fill="url(#gsIris)" stroke="${O}" stroke-width="${f(SW)}"/>
      <ellipse cx="${eyeX + 1.5}" cy="${eyeY + 1}" rx="2.4" ry="5.8" fill="${O}"/>
      <circle cx="${eyeX - 2}" cy="${eyeY - 3.5}" r="2.3" fill="#ffffff"/>`;
    if (pose.eyes === 'half') {
      eye += `<path clip-path="url(#csEyeTop)" d="${head}" fill="url(#gsHead)"/>
        <path d="M ${eyeX - 7.5} ${eyeY} L ${eyeX + 7.5} ${eyeY}" stroke="${O}" stroke-width="${strokeW(3)}" stroke-linecap="round"/>`;
    }
  }

  // ---------- tail ----------
  const tailBase = tiltPt(stretch([50, 130 + pose.y]));
  const tailD = `M ${f(tailBase[0])} ${f(tailBase[1])} C ${f(tailBase[0] - 22)} ${f(tailBase[1] - 4)} ` +
    `${f(tailBase[0] - 32)} ${f(tailBase[1] - 28)} ${f(tailBase[0] - 24)} ${f(tailBase[1] - 54)}`;
  const tailTransform = `rotate(${f(pose.tail - 10)} ${f(tailBase[0])} ${f(tailBase[1])})`;

  // ---------- markings ----------
  const stripesBody = m.stripes
    ? `<g clip-path="url(#csTorso)" fill="${c.stripe}">
        ${[70, 88, 106, 124].map((x) => `<path d="M ${x * pose.len + 100 * (1 - pose.len)} ${bodyCenter[1] - 30} l 8 0 l -3 20 l -4 0 Z"/>`).join('')}
      </g>`
    : '';
  const stripesHead = m.stripes
    ? `<g clip-path="url(#csHead)" fill="${c.stripe}">
        <path d="M 146 84 L 151 84 L 149 96 Z"/><path d="M 155 84 L 160 85 L 156 95 Z"/>
        <path d="M 128 112 L 140 113 L 128 116 Z"/>
      </g>`
    : '';
  const belly = m.whiteChest
    ? `<g clip-path="url(#csTorso)" fill="url(#gsWhite)">
        <ellipse cx="${f(100 + 4 * pose.len)}" cy="${f(bodyCenter[1] + 22)}" rx="${f(40 * pose.len)}" ry="11"/>
        <ellipse cx="${f(100 + 46 * pose.len)}" cy="${f(bodyCenter[1] + 6)}" rx="12" ry="18"/>
      </g>`
    : '';
  const muzzle = m.whiteMuzzle
    ? `<g clip-path="url(#csHead)" fill="url(#gsWhite)">
        <ellipse cx="173" cy="116" rx="7" ry="6"/><ellipse cx="165" cy="125" rx="10" ry="4"/>
      </g>`
    : '';

  const outlineAgain = (d, transform = '') =>
    `<path d="${d}" fill="none" stroke="${O}" stroke-width="${f(SW)}" stroke-linejoin="round" ${transform}/>`;

  return `<svg xmlns="http://www.w3.org/2000/svg" viewBox="${SIDE_VIEWBOX.join(' ')}"${pixel ? ' shape-rendering="crispEdges"' : ''}>
  <defs>
    <radialGradient id="gsBody" cx="0.4" cy="0.15" r="0.9">
      <stop offset="0" stop-color="${c.furLight}"/><stop offset="0.45" stop-color="${c.fur}"/>
      <stop offset="0.85" stop-color="${c.furShadow}"/><stop offset="1" stop-color="${c.furDeep}"/>
    </radialGradient>
    <radialGradient id="gsHead" cx="0.4" cy="0.2" r="0.85">
      <stop offset="0" stop-color="${c.furLight}"/><stop offset="0.5" stop-color="${c.fur}"/>
      <stop offset="1" stop-color="${c.furShadow}"/>
    </radialGradient>
    <radialGradient id="gsWhite" cx="0.4" cy="0.3" r="0.9">
      <stop offset="0" stop-color="${c.white}"/><stop offset="0.65" stop-color="${c.white}"/>
      <stop offset="1" stop-color="${c.whiteShadow}"/>
    </radialGradient>
    <radialGradient id="gsIris" cx="0.5" cy="0.8" r="0.8">
      <stop offset="0" stop-color="${c.irisLight}"/><stop offset="0.5" stop-color="${c.iris}"/>
      <stop offset="1" stop-color="${c.irisDark}"/>
    </radialGradient>
    <linearGradient id="gsTail" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0" stop-color="${c.fur}"/><stop offset="1" stop-color="${c.furShadow}"/>
    </linearGradient>
    <clipPath id="csTorso"><path d="${torso}" transform="${bodyTransform}"/></clipPath>
    <clipPath id="csHead"><path d="${head}"/></clipPath>
    <clipPath id="csEyeTop"><rect x="${eyeX - 9}" y="${eyeY - 11}" width="18" height="11"/></clipPath>
  </defs>

  <!-- everything nudged so whiskers and paws stay inside the frame -->
  <g transform="translate(-16 -5)">
  <!-- tail -->
  <g transform="${tailTransform}">
    <path d="${tailD}" fill="none" stroke="${O}" stroke-width="${f(11 + SW * 2)}" stroke-linecap="round"/>
    <path d="${tailD}" fill="none" stroke="url(#gsTail)" stroke-width="11" stroke-linecap="round"/>
    ${m.stripes ? `<path d="${tailD}" pathLength="100" fill="none" stroke="${c.stripe}" stroke-width="11" stroke-dasharray="9 13" stroke-dashoffset="-8"/>` : ''}
    ${m.whiteTailTip ? `<path d="${tailD}" pathLength="100" fill="none" stroke="${c.white}" stroke-width="11" stroke-linecap="round" stroke-dasharray="0 76 24 1"/>` : ''}
  </g>

  <!-- far legs, behind the body -->
  ${legSVG(legs.fb, legFar, pawFar, 12)}
  ${legSVG(legs.ff, legFar, pawFar, 10)}

  <!-- torso -->
  <path d="${torso}" transform="${bodyTransform}" fill="url(#gsBody)" stroke="${O}" stroke-width="${f(SW)}" stroke-linejoin="round"/>
  <g transform="${bodyTransform}">${stripesBody}</g>
  <g transform="${bodyTransform}">${belly}</g>
  ${outlineAgain(torso, `transform="${bodyTransform}"`)}

  <!-- near legs -->
  ${legSVG(legs.nb, legNear, pawNear, 13)}
  ${legSVG(legs.nf, legNear, pawNear, 11)}

  <!-- head -->
  <g transform="${headTransform}">
    <path d="${earFar}" fill="${c.furShadow}" stroke="${O}" stroke-width="${f(SW)}" stroke-linejoin="round"/>
    <path d="${earNear}" fill="${c.fur}" stroke="${O}" stroke-width="${f(SW)}" stroke-linejoin="round"/>
    <path d="${innerEar}" fill="${c.innerEar}"/>
    <path d="${head}" fill="url(#gsHead)" stroke="${O}" stroke-width="${f(SW)}" stroke-linejoin="round"/>
    ${stripesHead}
    ${muzzle}
    ${outlineAgain(head)}
    ${eye}
    <path d="M 177 108 L 181.5 109 L 179.5 112.5 Z" fill="${c.nose}" stroke="${c.noseShadow}" stroke-width="${strokeW(1)}" stroke-linejoin="round"/>
    <path d="M 179.5 112.5 Q 179 117 174 118" fill="none" stroke="${O}" stroke-width="${strokeW(2)}" stroke-linecap="round"/>
    ${pixel ? '' : `<path d="M 172 116 L 188 113 M 172 119 L 188 121" fill="none" stroke="${c.whisker}" stroke-width="1.2" stroke-linecap="round" opacity="0.9"/>`}
  </g>

  <!-- scratching: the leg runs up behind the head; the paw shows on top, at the ear -->
  ${pose.scratch ? `<ellipse cx="${f(legs.nb.paw[0] + 2)}" cy="${f(legs.nb.paw[1])}" rx="8" ry="5.5" fill="${pawNear}" stroke="${O}" stroke-width="${f(SW)}"/>` : ''}
  </g>
</svg>`;
}

// The ball the cat chases. Same shape for every cat; its own small palette.
const BALL_COLORS = { outline: '#24161a', base: '#e8454f', dark: '#a8243a', band: '#ffd23e', shine: '#ffffff' };

function ballSVG(angle = 0, opts = {}) {
  const C = opts.colors || BALL_COLORS;
  return `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100"${opts.pixel ? ' shape-rendering="crispEdges"' : ''}>
  <defs>
    <radialGradient id="gBall" cx="0.38" cy="0.32" r="0.75">
      <stop offset="0" stop-color="${C.base}"/><stop offset="0.7" stop-color="${C.base}"/><stop offset="1" stop-color="${C.dark}"/>
    </radialGradient>
    <clipPath id="cBall"><circle cx="50" cy="50" r="40"/></clipPath>
  </defs>
  <circle cx="50" cy="50" r="40" fill="url(#gBall)"/>
  <g clip-path="url(#cBall)" transform="rotate(${angle} 50 50)">
    <rect x="-10" y="42" width="120" height="16" fill="${C.band}"/>
  </g>
  <circle cx="50" cy="50" r="40" fill="none" stroke="${C.outline}" stroke-width="10"/>
  <circle cx="36" cy="34" r="8" fill="${C.shine}"/>
</svg>`;
}
