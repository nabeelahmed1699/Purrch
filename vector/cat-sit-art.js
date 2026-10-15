// Vector source for the sitting Purrch cat, three-quarter view (viewBox 0 0 250 200).
// The classic upright sit: tall chest, two straight front legs side by side, the back curving
// down to a big haunch behind, head up and turned to you. Used for every "sitting facing you"
// frame (front, frontBlink, frontMeow1, ...): vector/build-play.html rasterises it to 80 x 64 px
// alongside the side-view frames. The head sits over the frame's centre; the body goes right.
//
// catSitSVG(cat, opts)
//   opts.pose      a SIT_POSES entry (or any object with the same fields)
//   opts.markings  false to draw the bare shared shape with no cat-specific markings
//   opts.pixel     true when rasterising: crisp edges, strokes at least ~1 pixel wide
//   opts.spriteSize  pixel height being rasterised to (default 64)
//
// A pose:
//   eyes     'open' | 'calm' (relaxed, a little narrowed) | 'half' | 'closed'
//   mouth    'closed' | 'open' (meowing)
//   headTilt head rotation in degrees (+ = towards the right), headDy head drop (+ = down)
//   ear      'rest' | 'flick' (the right ear turned out)
//   tail     'wrap' (round the front paws) | 'flickLeft' | 'flickRight' (tip lifted)
//   breathe  0..2: chest rise
//   paw      null | 'up1' | 'up2': the near front paw raised, pawing at you (up1 higher)

const SIT_VIEWBOX = [0, 0, 250, 200];
// Drawn at this size so a sitting cat matches the walking cat (a touch taller than standing,
// same head size) instead of growing when it sits down.
const SIT_SCALE = 0.72;

// Named like the app's facing-you frames, so every behaviour that uses them gets this cat.
const SIT_POSES = {
  front: { eyes: 'calm', mouth: 'closed', headTilt: 0, headDy: 0, ear: 'rest', tail: 'wrap', breathe: 0, paw: null },
  frontBreathe: { eyes: 'calm', mouth: 'closed', headTilt: 0, headDy: 0, ear: 'rest', tail: 'wrap', breathe: 1, paw: null },
  frontTailLeft: { eyes: 'calm', mouth: 'closed', headTilt: 0, headDy: 0, ear: 'rest', tail: 'flickLeft', breathe: 0, paw: null },
  frontTailRight: { eyes: 'calm', mouth: 'closed', headTilt: 0, headDy: 0, ear: 'rest', tail: 'flickRight', breathe: 0, paw: null },
  frontBlink: { eyes: 'closed', mouth: 'closed', headTilt: 0, headDy: 0, ear: 'rest', tail: 'wrap', breathe: 0, paw: null },
  frontEarFlick: { eyes: 'calm', mouth: 'closed', headTilt: 0, headDy: 0, ear: 'flick', tail: 'wrap', breathe: 0, paw: null },
  // Meowing: looks up at you, mouth open (then eyes squeezed shut).
  frontMeow1: { eyes: 'open', mouth: 'open', headTilt: -4, headDy: 1, ear: 'rest', tail: 'flickRight', breathe: 1, paw: null },
  frontMeow2: { eyes: 'closed', mouth: 'open', headTilt: -6, headDy: 1, ear: 'rest', tail: 'flickRight', breathe: 1, paw: null },
  // Eating from a bowl in front: head right down, bobbing.
  frontEat1: { eyes: 'closed', mouth: 'closed', headTilt: 6, headDy: 26, ear: 'rest', tail: 'flickLeft', breathe: 0, paw: null },
  frontEat2: { eyes: 'closed', mouth: 'closed', headTilt: 4, headDy: 20, ear: 'rest', tail: 'flickLeft', breathe: 0, paw: null },
  // Pawing at you for attention: paw high, paw lower, and with a meow.
  frontPaw1: { eyes: 'open', mouth: 'closed', headTilt: -3, headDy: 1, ear: 'rest', tail: 'flickRight', breathe: 1, paw: 'up1' },
  frontPaw2: { eyes: 'open', mouth: 'closed', headTilt: -3, headDy: 1, ear: 'rest', tail: 'flickRight', breathe: 1, paw: 'up2' },
  frontPawMeow: { eyes: 'half', mouth: 'open', headTilt: -5, headDy: 1, ear: 'rest', tail: 'flickRight', breathe: 1, paw: 'up1' },
};

function catSitSVG(cat, opts = {}) {
  const c = cat.colors;
  const m = opts.markings === false ? NO_MARKINGS : cat.markings;
  const pose = { ...SIT_POSES.front, ...(opts.pose || {}) };
  const pixel = !!opts.pixel;
  const spriteSize = opts.spriteSize || 64;
  // The whole cat is drawn at SIT_SCALE (anchored at its paws, under its head) so it's the
  // same size as the side-view cat; strokes are thickened to stay a pixel wide after that.
  const minStroke = pixel ? (1.05 * 200) / spriteSize / SIT_SCALE : 0;
  const strokeW = (w) => Math.max(w, minStroke).toFixed(2);
  const SW = Number(strokeW(3));
  const O = c.outline;
  const f = (n) => n.toFixed(2);

  const GROUND = 198;
  const lift = pose.breathe * 1.5; // chest rise

  // ---------- tail: lying round the front of the paws ----------
  const tailTip = { wrap: [146, 190], flickLeft: [140, 176], flickRight: [150, 172] }[pose.tail] || [146, 190];
  const tailD = `M 204 190 C 198 198 182 199 166 197 C 156 196 ${f(tailTip[0] + 4)} ${f(tailTip[1] + 6)} ${f(tailTip[0])} ${f(tailTip[1])}`;

  // ---------- body: neck behind the head, back curving down to the haunch ----------
  const body = `M 150 ${f(60 - lift)} C 184 ${f(68 - lift)} 210 114 213 160 C 215 186 206 ${GROUND} 192 ${GROUND} ` +
    `L 126 ${GROUND} C 110 170 100 ${f(132 - lift)} 101 ${f(102 - lift)} C 102 ${f(80 - lift)} 122 ${f(64 - lift)} 150 ${f(60 - lift)} Z`;
  // The haunch: the thigh's front edge (the hind paw peeks out under it).
  const thighEdge = 'M 168 128 C 155 150 156 180 170 197';

  // ---------- chest and front legs ----------
  // A bib that narrows to a soft point between the legs, like a chest blaze.
  const chest = `M 103 ${f(92 - lift)} C 104 ${f(80 - lift)} 142 ${f(78 - lift)} 147 ${f(94 - lift)} C 150 112 142 128 133 140 ` +
    `Q 126 148 119 140 C 110 128 102 112 103 ${f(92 - lift)} Z`;
  // Far leg (behind, a touch darker), near leg in front. Each: shoulder → paw.
  // Slim and slightly tapered: wider at the elbow, narrower at the wrist, then the paw.
  const leg = (x0, x1, top) => `M ${x0} ${top} C ${x0 - 1} 150 ${x0 + 2} 172 ${x0 + 2} 190 ` +
    `Q ${x0 + 2} ${GROUND} ${(x0 + x1) / 2} ${GROUND} Q ${x1 - 2} ${GROUND} ${x1 - 2} 190 C ${x1 - 2} 172 ${x1 + 1} 150 ${x1} ${top} Z`;
  const farLeg = leg(127, 146, 118);
  const nearLeg = leg(106, 127, 120);
  const paw = (cx) => `<ellipse cx="${cx}" cy="${GROUND - 3}" rx="10.5" ry="5"/>`;

  // Raised paw (pawing at you): the near leg bends up from the shoulder, pads towards you.
  const raised = pose.paw ? (pose.paw === 'up1' ? { x: 96, y: 74 } : { x: 100, y: 88 }) : null;
  const raisedLeg = raised
    ? `M 110 128 C 104 118 ${raised.x - 4} ${raised.y + 22} ${raised.x - 6} ${raised.y + 6} L ${raised.x + 8} ${raised.y + 4} C ${raised.x + 12} ${raised.y + 22} 124 116 128 128 Z`
    : '';

  // ---------- head ----------
  const headT = `translate(0 ${f(pose.headDy - lift)}) rotate(${f(pose.headTilt)} 125 84)`;
  const head = 'M 125 20 C 150 20 168 34 170 55 C 172 70 160 82 144 85 L 106 85 C 90 82 78 70 80 55 C 82 34 100 20 125 20 Z';
  // Big, upright ears: they make the silhouette read as a cat at small sizes.
  const earL = 'M 82 54 L 82 2 Q 84 -4 91 0 L 122 28 Z';
  const earR = pose.ear === 'flick' ? 'M 130 27 L 166 8 Q 173 6 172 13 L 170 56 Z' : 'M 128 28 L 158 0 Q 164 -4 167 3 L 168 54 Z';
  const innerL = 'M 89 44 L 89 11 L 113 31 Z';
  const innerR = pose.ear === 'flick' ? 'M 139 31 L 164 17 L 164 46 Z' : 'M 137 31 L 160 11 L 162 46 Z';

  // Eyes: almond shapes; 'calm' is the relaxed, slightly narrowed look.
  const eyeH = { open: 8.5, calm: 7.2, half: 3.6 }[pose.eyes];
  const eye = (cx, cy) => {
    if (pose.eyes === 'closed') {
      return `<path d="M ${cx - 11} ${cy} Q ${cx} ${cy + 6} ${cx + 11} ${cy}" fill="none" stroke="${O}" stroke-width="${strokeW(3.5)}" stroke-linecap="round"/>`;
    }
    return `
      <path d="M ${cx - 12} ${cy} Q ${cx} ${f(cy - eyeH * 1.5)} ${cx + 12} ${cy} Q ${cx} ${f(cy + eyeH * 1.2)} ${cx - 12} ${cy} Z" fill="url(#gtIris)" stroke="${O}" stroke-width="${f(SW)}" stroke-linejoin="round"/>
      <ellipse cx="${cx + 0.5}" cy="${cy}" rx="2.8" ry="${f(Math.max(1.5, eyeH * 0.9))}" fill="${O}"/>
      <circle cx="${cx - 5}" cy="${f(cy - eyeH * 0.45)}" r="2.8" fill="#ffffff"/>`;
  };
  const mouth = pose.mouth === 'open'
    ? `<path d="M 117 70 Q 125 86 133 70 Z" fill="${O}"/><path d="M 120 76 Q 125 83 130 76 Z" fill="${c.nose}"/>`
    : `<path d="M 125 67 L 125 71 M 118 72 Q 122 75 125 71 Q 128 75 132 72" fill="none" stroke="${O}" stroke-width="${strokeW(2)}" stroke-linecap="round"/>`;

  // ---------- markings ----------
  const stripes = m.stripes ? {
    head: `<g clip-path="url(#ctHead)" fill="${c.stripe}">
        <path d="M 116 22 l 5 0 l -1 15 l -3 0 Z"/><path d="M 123 20 l 5 0 l -1 17 l -3 0 Z"/><path d="M 130 22 l 5 0 l -2 15 l -3 0 Z"/>
        <path d="M 82 58 l 14 2 l -14 4 Z"/><path d="M 168 58 l -14 2 l 14 4 Z"/>
      </g>`,
    body: `<g clip-path="url(#ctBody)" fill="none" stroke="${c.stripe}" stroke-width="7" stroke-linecap="round">
        <path d="M 164 72 q 9 14 5 30"/><path d="M 180 86 q 9 16 5 32"/><path d="M 195 106 q 8 16 4 32"/>
        <path d="M 186 144 q -11 10 -13 28"/><path d="M 202 152 q -9 12 -9 30"/>
      </g>`,
    legs: `<g fill="none" stroke="${c.stripe}" stroke-width="4" stroke-linecap="round">
        <path d="M 111 156 q 7 3 13 0"/><path d="M 112 170 q 6 3 12 0"/>
        <path d="M 131 152 q 6 3 12 0"/><path d="M 132 166 q 5 3 11 0"/></g>`,
  } : { head: '', body: '', legs: '' };
  // Without a white chest it's just fur, blending into the body (no pale apron).
  const chestFill = m.whiteChest ? 'url(#gtWhite)' : c.fur;
  const pawNear = m.whitePaws || m.whiteLegs ? c.white : c.fur;
  const pawFar = m.whitePaws || m.whiteLegs ? c.whiteShadow : c.furShadow;
  const legNear = m.whiteLegs ? c.white : 'url(#gtLeg)';
  const legFar = m.whiteLegs ? c.whiteShadow : c.furShadow;
  const muzzle = m.whiteMuzzle
    ? `<g clip-path="url(#ctHead)" fill="url(#gtWhite)"><ellipse cx="125" cy="72" rx="19" ry="11"/></g>`
    : '';
  const blaze = m.whiteBlaze
    ? `<g clip-path="url(#ctHead)" fill="url(#gtWhite)"><path d="M 121 20 L 129 20 L 136 62 L 114 62 Z"/></g>`
    : '';
  const tailTipStripe = m.whiteTailTip
    ? `<path d="${tailD}" pathLength="100" fill="none" stroke="${c.white}" stroke-width="12" stroke-linecap="round" stroke-dasharray="0 72 28 1"/>`
    : '';

  const outline = (d) => `<path d="${d}" fill="none" stroke="${O}" stroke-width="${f(SW)}" stroke-linejoin="round"/>`;

  return `<svg xmlns="http://www.w3.org/2000/svg" viewBox="${SIT_VIEWBOX.join(' ')}"${pixel ? ' shape-rendering="crispEdges"' : ''}>
  <defs>
    <radialGradient id="gtBody" cx="0.35" cy="0.2" r="0.95">
      <stop offset="0" stop-color="${c.furLight}"/><stop offset="0.45" stop-color="${c.fur}"/>
      <stop offset="0.85" stop-color="${c.furShadow}"/><stop offset="1" stop-color="${c.furDeep}"/>
    </radialGradient>
    <radialGradient id="gtHead" cx="0.4" cy="0.25" r="0.8">
      <stop offset="0" stop-color="${c.furLight}"/><stop offset="0.55" stop-color="${c.fur}"/>
      <stop offset="1" stop-color="${c.furShadow}"/>
    </radialGradient>
    <linearGradient id="gtChest" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0" stop-color="${c.furLight}"/><stop offset="1" stop-color="${c.fur}"/>
    </linearGradient>
    <linearGradient id="gtLeg" x1="0" y1="0" x2="1" y2="0">
      <stop offset="0" stop-color="${c.furLight}"/><stop offset="1" stop-color="${c.fur}"/>
    </linearGradient>
    <radialGradient id="gtWhite" cx="0.4" cy="0.3" r="0.9">
      <stop offset="0" stop-color="${c.white}"/><stop offset="0.65" stop-color="${c.white}"/>
      <stop offset="1" stop-color="${c.whiteShadow}"/>
    </radialGradient>
    <radialGradient id="gtIris" cx="0.5" cy="0.7" r="0.8">
      <stop offset="0" stop-color="${c.irisLight}"/><stop offset="0.5" stop-color="${c.iris}"/>
      <stop offset="1" stop-color="${c.irisDark}"/>
    </radialGradient>
    <clipPath id="ctBody"><path d="${body}"/></clipPath>
    <clipPath id="ctHead"><path d="${head}"/></clipPath>
  </defs>

  <g transform="translate(125 198) scale(${SIT_SCALE}) translate(-125 -198)">
  <!-- tail, curled round the front -->
  <path d="${tailD}" fill="none" stroke="${O}" stroke-width="${f(12 + SW * 2)}" stroke-linecap="round"/>
  <path d="${tailD}" fill="none" stroke="${c.fur}" stroke-width="12" stroke-linecap="round"/>
  ${m.stripes ? `<path d="${tailD}" pathLength="100" fill="none" stroke="${c.stripe}" stroke-width="12" stroke-dasharray="8 12"/>` : ''}
  ${tailTipStripe}

  <!-- body and haunch -->
  <path d="${body}" fill="url(#gtBody)" stroke="${O}" stroke-width="${f(SW)}" stroke-linejoin="round"/>
  ${stripes.body}
  <path d="${thighEdge}" fill="none" stroke="${O}" stroke-width="${f(SW)}" stroke-linecap="round"/>
  <ellipse cx="176" cy="${GROUND - 3}" rx="11" ry="5" fill="${pawFar}" stroke="${O}" stroke-width="${f(SW)}"/>
  ${outline(body)}

  <!-- front legs, then the chest fluff over their tops -->
  <path d="${farLeg}" fill="${legFar}" stroke="${O}" stroke-width="${f(SW)}" stroke-linejoin="round"/>
  <g fill="${pawFar}" stroke="${O}" stroke-width="${f(SW)}">${paw(140)}</g>
  ${raised ? '' : `<path d="${nearLeg}" fill="${legNear}" stroke="${O}" stroke-width="${f(SW)}" stroke-linejoin="round"/>
  <g fill="${pawNear}" stroke="${O}" stroke-width="${f(SW)}">${paw(119)}</g>`}
  ${m.stripes && !m.whiteLegs ? stripes.legs : ''}
  <path d="${chest}" fill="${chestFill}"/>

  <!-- head -->
  <g transform="${headT}">
    <path d="${earL}" fill="${c.fur}" stroke="${O}" stroke-width="${f(SW)}" stroke-linejoin="round"/>
    <path d="${earR}" fill="${c.furShadow}" stroke="${O}" stroke-width="${f(SW)}" stroke-linejoin="round"/>
    <path d="${innerL}" fill="${c.innerEar}"/><path d="${innerR}" fill="${c.innerEar}"/>
    <path d="${head}" fill="url(#gtHead)" stroke="${O}" stroke-width="${f(SW)}" stroke-linejoin="round"/>
    ${stripes.head}
    ${blaze}
    ${muzzle}
    ${outline(head)}
    ${eye(104, 51)}${eye(146, 51)}
    <path d="M 120 62 L 130 62 L 125 67 Z" fill="${c.nose}" stroke="${c.noseShadow}" stroke-width="${strokeW(1)}" stroke-linejoin="round"/>
    ${mouth}
  </g>

  <!-- raised paw, over the chest, pads towards you -->
  ${raised ? `<path d="${raisedLeg}" fill="${legNear}" stroke="${O}" stroke-width="${f(SW)}" stroke-linejoin="round"/>
  <ellipse cx="${raised.x + 1}" cy="${raised.y}" rx="11" ry="10" fill="${pawNear}" stroke="${O}" stroke-width="${f(SW)}"/>
  <ellipse cx="${raised.x + 1}" cy="${raised.y + 2}" rx="5" ry="4" fill="${c.nose}"/>
  <circle cx="${raised.x - 5}" cy="${raised.y - 5}" r="2.4" fill="${c.nose}"/><circle cx="${raised.x + 1}" cy="${raised.y - 7}" r="2.4" fill="${c.nose}"/><circle cx="${raised.x + 7}" cy="${raised.y - 5}" r="2.4" fill="${c.nose}"/>` : ''}
  </g>
</svg>`;
}
