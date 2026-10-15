// Vector source for the Purrch cat (viewBox 200 x 200, transparent background).
// The pixel parts in parts.js are generated from this by vector/build-parts.html.
//
// catSVG(cat, opts)
//   opts.parts    which parts to draw (default: all), drawn in PART_ORDER
//   opts.pose     { tail: -1..1, breath: 0..2 (px of chest rise), ear: 0..1, eyes: 'open' | 'half' | 'closed',
//                   headUp: px the ears, head and eyes are lifted }
//   opts.markings false to draw the bare shared shape with no cat-specific markings
//   opts.pixel    true when rasterising to pixels: crisp edges, whiskers left out
//                 (they are drawn as 1px lines afterwards), thin strokes thickened
//   opts.spriteSize  pixel size being rasterised to (default 128). pose.headUp is in these
//                 pixels; pose.breath is always in 128px units. Below 128, every stroke is
//                 widened to at least ~1 pixel so lines don't break up.

const PART_ORDER = ['chair', 'tail', 'torso', 'haunches', 'legs', 'ears', 'head', 'eyes'];
// Parts that move together when the head lifts (pose.headUp, in sprite pixels).
const HEAD_PARTS = ['ears', 'head', 'eyes'];
const NO_MARKINGS = {
  stripes: false, whiteChest: false, whiteMuzzle: false, whiteBlaze: false,
  whitePaws: false, whiteLegs: false, whiteTailTip: false,
};
// One pixel of the 128 x 128 master sprite, in viewBox units.
const PX = 200 / 128;

// Whisker curves (quadratic, left side; the right side is mirrored).
const WHISKERS = [
  [[85, 98], [67, 93.5], [45, 92]],
  [[85, 101], [65, 101], [43, 103]],
  [[86, 104], [69, 107], [51, 111]],
];

function mirrorX(d) {
  // Mirror a path's x coordinates around x = 100. Paths here use absolute commands with
  // plain "x y" pairs (M, L, C, Q), so every even number in the list is an x.
  let i = 0;
  return d.replace(/-?\d+(\.\d+)?/g, (n) => (i++ % 2 === 0 ? String(200 - parseFloat(n)) : n));
}

function rotatePoint([x, y], [px, py], deg) {
  const a = (deg * Math.PI) / 180;
  const dx = x - px, dy = y - py;
  return [px + dx * Math.cos(a) - dy * Math.sin(a), py + dx * Math.sin(a) + dy * Math.cos(a)];
}

function catSVG(cat, opts = {}) {
  const c = cat.colors;
  const m = opts.markings === false ? NO_MARKINGS : cat.markings;
  const W = cat.wood || WOOD;
  const O = c.outline;
  const pixel = !!opts.pixel;
  const spriteSize = opts.spriteSize || 128;
  // Stroke width, widened to at least ~1 sprite pixel when rasterising below 128 px.
  const minStroke = pixel && spriteSize < 128 ? (1.05 * 200) / spriteSize : 0;
  const strokeW = (w) => Math.max(w, minStroke).toFixed(2);
  const SW = strokeW(3); // outline width
  const parts = new Set(opts.parts || PART_ORDER);
  const pose = { tail: 0, breath: 0, ear: 0, eyes: 'open', ...(opts.pose || {}) };

  const white = (on, fallback) => (on ? 'url(#gWhite)' : fallback);
  const R = (d) => `${d} ${mirrorX(d)}`; // path plus its mirror image, as one "d"
  const f = (n) => n.toFixed(2);

  // ---------- shapes ----------
  const head =
    'M 100 32 C 128 32 148 44 152 66 C 154 76 153 83 150 88 L 161 92 L 149 96 L 157 102 L 143 104 ' +
    'C 132 112 116 115 100 115 C 84 115 68 112 57 104 L 43 102 L 51 96 L 39 92 L 50 88 ' +
    'C 47 83 46 76 48 66 C 52 44 72 32 100 32 Z';
  const earL = 'M 52 62 L 55 17 Q 57 9 64 13 L 96 40 Z';
  const innerEarL = 'M 60 52 L 61.5 25 Q 62.5 20 67 23.5 L 86 41 Z';
  const earStrandsL = 'M 63 46 Q 64 38 66 31 M 69 45 Q 71 39 73 34 M 75 44 Q 76 41 78 38';

  // Breathing lifts the top of the chest; the base stays planted on the seat.
  const lift = pose.breath * PX;
  const torso = `M 62 157 C 57 ${f(122 - lift * 0.5)} 70 ${f(98 - lift)} 100 ${f(98 - lift)} ` +
    `C 130 ${f(98 - lift)} 143 ${f(122 - lift * 0.5)} 138 157 Z`;
  const haunchL = 'M 38 157 C 32 132 48 117 69 121 C 85 125 88 146 83 157 Z';
  const bib =
    'M 100 103 C 86 103 79 115 83 128 C 85 135 88 140 91 141 L 94 137 L 97 143 L 100 138 L 103 143 ' +
    'L 106 137 L 109 141 C 112 140 115 135 117 128 C 121 115 114 103 100 103 Z';
  const legL = 'M 83 126 C 80.5 136 79.5 146 80 155 L 98.5 155 C 98.5 146 98.6 136 99.5 128 Z';
  const legSideL = 'M 82.6 128 C 80.5 137 79.5 146 80 154 M 98.6 136 C 98.5 142 98.5 148 98.5 154';

  // Tail: the curl past the seat edge swings around the corner of the seat.
  const pivot = [188, 166];
  const sw = pose.tail * 9;
  const [a1, a2, a3, b1, b2, b3] = [[190, 182], [177, 193], [165, 187], [158, 183], [159, 175], [166, 174.5]]
    .map((p) => rotatePoint(p, pivot, sw).map(f).join(' '));
  const tail = `M 136 150 C 162 153 186 149 188 166 C ${a1} ${a2} ${a3} C ${b1} ${b2} ${b3}`;

  // ---------- markings (cat-specific) ----------
  const stripesHead = m.stripes
    ? `<g clip-path="url(#cHead)" fill="${c.stripe}">
        <path d="M 95.5 32 L 104.5 32 L 100 55 Z"/>
        <path d="${R('M 80 36 L 88 33 L 87.5 51 Z')}"/>
        <path d="${R('M 67 43 L 74 39.5 L 74 52 Z')}"/>
        <path d="${R('M 40 80 L 66 82.5 L 40 86 Z')}"/>
        <path d="${R('M 42 91 L 62 92 L 44 96.5 Z')}"/>
      </g>`
    : '';
  const blaze = m.whiteBlaze
    ? `<path clip-path="url(#cHead)" d="M 100 46 C 96 60 91 78 88 96 L 112 96 C 109 78 104 60 100 46 Z" fill="url(#gWhite)"/>`
    : '';
  const haunchStripe = 'M 44 134 Q 58 123 74 130 M 42 145 Q 56 135 72 141';
  const stripesTorso = m.stripes
    ? `<path clip-path="url(#cTorso)" d="${R('M 60 114 L 76 117 M 60 122 L 74 124')}" fill="none" stroke="${c.stripe}" stroke-width="${strokeW(3.5)}" stroke-linecap="round"/>`
    : '';
  const stripesHaunch = m.stripes
    ? `<g fill="none" stroke="${c.stripe}" stroke-width="${strokeW(4)}" stroke-linecap="round">
        <path clip-path="url(#cHaunchL)" d="${haunchStripe}"/>
        <path clip-path="url(#cHaunchR)" d="${mirrorX(haunchStripe)}"/>
      </g>`
    : '';
  const stripesLegs = m.stripes
    ? `<g clip-path="url(#cLegs)" stroke="${c.stripe}" stroke-width="${strokeW(3)}" stroke-linecap="round">
        <path d="${R('M 78 134 L 90 135 M 78 143 L 88 144')}"/>
      </g>`
    : '';

  // ---------- eyes ----------
  // Lids reuse the head shape and gradient, clipped to the eye, so they match the fur exactly.
  // Head markings are redrawn on the lid so stripes or patches never get cut by a blink.
  const eye = (cx, side) => {
    const open = `
      <ellipse cx="${cx}" cy="72" rx="13" ry="14" fill="url(#gIris)" stroke="${O}" stroke-width="${SW}"/>
      <ellipse cx="${cx}" cy="73" rx="4.6" ry="10.5" fill="${O}"/>
      <path d="M ${cx - 12.4} 67 A 13 14 0 0 1 ${cx + 12.4} 67" fill="none" stroke="${O}" stroke-width="${strokeW(5)}" stroke-linecap="round"/>
      <circle cx="${cx - 5.5}" cy="65.5" r="4.3" fill="#ffffff"/>
      <circle cx="${cx + 6}" cy="79.5" r="1.9" fill="#ffffff"/>`;
    const lid = (clip) => `
      <g clip-path="url(#${clip})">
        <path d="${head}" fill="url(#gHead)"/>
        ${stripesHead}${blaze}
      </g>`;
    if (pose.eyes === 'half') {
      return `${open}${lid(`cLidHalf${side}`)}
        <path d="M ${cx - 13.6} 72 Q ${cx} 75.5 ${cx + 13.6} 72" fill="none" stroke="${O}" stroke-width="${strokeW(3.6)}" stroke-linecap="round"/>`;
    }
    if (pose.eyes === 'closed') {
      return `${lid(`cLidFull${side}`)}
        <path d="M ${cx - 12} 71 Q ${cx} 79.5 ${cx + 12} 71" fill="none" stroke="${O}" stroke-width="${strokeW(3.6)}" stroke-linecap="round"/>`;
    }
    return open;
  };
  const lidClips = [['L', 78], ['R', 122]].map(([s, cx]) => `
    <clipPath id="cLidHalf${s}"><path d="M ${cx - 16.5} 72 A 16.5 17.5 0 0 1 ${cx + 16.5} 72 Z"/></clipPath>
    <clipPath id="cLidFull${s}"><ellipse cx="${cx}" cy="72" rx="16.5" ry="17.5"/></clipPath>`).join('');

  // ---------- parts ----------
  // Markings are clipped to a part's shape, but the outline straddles that edge, so each part
  // redraws its outline after its markings: markings can never change the shared outline.
  const outlineAgain = (d) => `<path d="${d}" fill="none" stroke="${O}" stroke-width="${SW}" stroke-linejoin="round"/>`;
  const P = {};

  P.chair = `
  <g stroke="${O}" stroke-width="${SW}" stroke-linejoin="round">
    <rect x="38" y="66" width="124" height="12" rx="2" fill="url(#gSeatFront)"/>
    <rect x="38" y="99" width="124" height="8" rx="2" fill="url(#gSeatFront)"/>
    <rect x="26" y="56" width="14" height="98" rx="2" fill="url(#gPost)"/>
    <rect x="160" y="56" width="14" height="98" rx="2" fill="url(#gPost)"/>
    <circle cx="33" cy="52" r="9" fill="url(#gKnob)"/>
    <circle cx="167" cy="52" r="9" fill="url(#gKnob)"/>
    <rect x="42" y="172" width="10" height="18" fill="${W.deep}"/>
    <rect x="148" y="172" width="10" height="18" fill="${W.deep}"/>
    <rect x="32" y="182" width="136" height="7" fill="${W.deep}"/>
    <path d="M 18 172 L 34 172 L 33 196 L 19 196 Z" fill="url(#gPost)"/>
    <path d="M 166 172 L 182 172 L 181 196 L 167 196 Z" fill="url(#gPost)"/>
    <path d="M 12 162 L 188 162 L 188 173 Q 188 177 184 177 L 16 177 Q 12 177 12 173 Z" fill="url(#gSeatFront)"/>
    <path d="M 19 149 L 181 149 L 188 162 L 12 162 Z" fill="url(#gSeatTop)"/>
  </g>
  <g stroke="${W.shadow}" stroke-width="${strokeW(1.2)}" stroke-linecap="round" fill="none" opacity="0.8">
    <path d="M 30 167 L 70 167 M 88 171 L 120 171 M 132 167 L 170 167 M 18 171 L 34 171 M 150 171 L 178 171"/>
    <path d="M 33 64 L 33 92 M 33 112 L 33 146 M 167 64 L 167 92 M 167 112 L 167 146"/>
  </g>
  <ellipse cx="102" cy="158" rx="72" ry="4.5" fill="#000" opacity="0.22"/>`;

  P.tail = `
  <path d="${tail}" fill="none" stroke="${O}" stroke-width="${13 + SW * 2}" stroke-linecap="round"/>
  <path d="${tail}" fill="none" stroke="url(#gTail)" stroke-width="${strokeW(13)}" stroke-linecap="round"/>
  ${m.stripes ? `<path d="${tail}" pathLength="100" fill="none" stroke="${c.stripe}" stroke-width="${strokeW(13)}" stroke-dasharray="5 8" stroke-dashoffset="-6"/>` : ''}
  ${m.whiteTailTip ? `<path d="${tail}" pathLength="100" fill="none" stroke="${c.white}" stroke-width="${strokeW(13)}" stroke-linecap="round" stroke-dasharray="0 80 20 1"/>` : ''}
  <path d="${tail}" fill="none" stroke="${c.furLight}" stroke-width="${strokeW(2.5)}" stroke-linecap="round" opacity="0.55" transform="translate(-2.5 -3)" stroke-dasharray="40 200"/>`;

  P.torso = `
  <path d="${torso}" fill="url(#gBody)" stroke="${O}" stroke-width="${SW}" stroke-linejoin="round"/>
  <g transform="translate(0 ${f(-lift * 0.6)})">
    ${m.whiteChest ? `<path d="${bib}" fill="url(#gWhite)"/>` : `<path d="${bib}" fill="${c.furLight}" opacity="0.25"/>`}
  </g>
  ${stripesTorso}
  <ellipse cx="100" cy="${f(114 - lift)}" rx="30" ry="5" fill="#000" opacity="0.1" clip-path="url(#cTorso)"/>
  ${outlineAgain(torso)}`;

  P.haunches = `
  <g stroke="${O}" stroke-width="${SW}" stroke-linejoin="round">
    <path d="${haunchL}" fill="url(#gHaunch)"/>
    <path d="${mirrorX(haunchL)}" fill="url(#gHaunch)"/>
  </g>
  ${stripesHaunch}
  ${outlineAgain(R(haunchL))}
  <g stroke="${O}" stroke-width="${SW}" stroke-linejoin="round">
    <ellipse cx="50" cy="156" rx="15" ry="7" fill="${white(m.whitePaws, 'url(#gHaunch)')}"/>
    <ellipse cx="150" cy="156" rx="15" ry="7" fill="${white(m.whitePaws, 'url(#gHaunch)')}"/>
  </g>
  <path d="${R('M 43 158 L 43 162 M 50 159 L 50 163')}" stroke="${m.whitePaws ? c.whiteShadow : c.furDeep}" stroke-width="${strokeW(1.6)}" stroke-linecap="round"/>`;

  P.legs = `
  <path d="${R(legL)}" fill="${white(m.whiteLegs, 'url(#gLeg)')}"/>
  ${stripesLegs}
  <path d="${R(legSideL)}" fill="none" stroke="${O}" stroke-width="${SW}" stroke-linecap="round"/>
  <g stroke="${O}" stroke-width="${SW}">
    <ellipse cx="89.5" cy="155" rx="12" ry="7" fill="${white(m.whitePaws, 'url(#gLeg)')}"/>
    <ellipse cx="110.5" cy="155" rx="12" ry="7" fill="${white(m.whitePaws, 'url(#gLeg)')}"/>
  </g>
  <path d="${R('M 85.5 157 L 85.5 161.5 M 92.5 157 L 92.5 161.5')}" stroke="${m.whitePaws ? c.whiteShadow : c.furDeep}" stroke-width="${strokeW(1.6)}" stroke-linecap="round"/>`;

  const strandW = strokeW(pixel ? 1.65 : 1.3);
  const ear = (d, inner, strands, fill) => `
    <path d="${d}" fill="${fill}" stroke="${O}" stroke-width="${SW}" stroke-linejoin="round"/>
    <path d="${inner}" fill="url(#gInnerEar)"/>
    <path d="${strands}" fill="none" stroke="${c.furLight}" stroke-width="${strandW}" stroke-linecap="round" opacity="0.9"/>`;
  P.ears = `
  ${ear(earL, innerEarL, earStrandsL, 'url(#gEarL)')}
  <g transform="rotate(${f(pose.ear * 14)} 126 44)">
    ${ear(mirrorX(earL), mirrorX(innerEarL), mirrorX(earStrandsL), 'url(#gEarR)')}
  </g>`;

  const whiskerPath = WHISKERS.map(([a, b, e]) => `M ${a.join(' ')} Q ${b.join(' ')} ${e.join(' ')}`).join(' ');
  P.head = `
  <path d="${head}" fill="url(#gHead)" stroke="${O}" stroke-width="${SW}" stroke-linejoin="round"/>
  ${stripesHead}
  ${blaze}
  ${outlineAgain(head)}
  <ellipse cx="68" cy="91" rx="8" ry="4" fill="${c.blush}" opacity="0.35"/>
  <ellipse cx="132" cy="91" rx="8" ry="4" fill="${c.blush}" opacity="0.35"/>
  ${m.whiteMuzzle ? `<ellipse cx="93" cy="100" rx="8.5" ry="6.5" fill="url(#gWhite)"/><ellipse cx="107" cy="100" rx="8.5" ry="6.5" fill="url(#gWhite)"/>` : ''}
  <g fill="${m.whiteMuzzle ? c.whiteShadow : c.furDeep}">
    <circle cx="89" cy="98" r="0.9"/><circle cx="87.5" cy="101.5" r="0.9"/><circle cx="90.5" cy="102.5" r="0.9"/>
    <circle cx="111" cy="98" r="0.9"/><circle cx="112.5" cy="101.5" r="0.9"/><circle cx="109.5" cy="102.5" r="0.9"/>
  </g>
  ${pixel ? '' : `<path d="${R(whiskerPath)}" fill="none" stroke="${c.whisker}" stroke-width="${strokeW(1.2)}" stroke-linecap="round" opacity="0.9"/>`}
  <path d="M 93 89 Q 100 86 107 89 Q 107.5 92.5 100 97 Q 92.5 92.5 93 89 Z" fill="${c.nose}" stroke="${c.noseShadow}" stroke-width="${strokeW(1.4)}" stroke-linejoin="round"/>
  <ellipse cx="97.3" cy="89.6" rx="2.2" ry="1.1" fill="#ffffff" opacity="0.8"/>
  <path d="M 100 97 L 100 101 M 100 101 Q 96 106 91.5 102.5 M 100 101 Q 104 106 108.5 102.5"
        fill="none" stroke="${O}" stroke-width="${strokeW(2.2)}" stroke-linecap="round" stroke-linejoin="round"/>`;

  P.eyes = `${eye(78, 'L')}${eye(122, 'R')}`;

  return `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 200 200"${pixel ? ' shape-rendering="crispEdges"' : ''}>
  <defs>
    <radialGradient id="gHead" cx="0.36" cy="0.16" r="0.85">
      <stop offset="0" stop-color="${c.furLight}"/><stop offset="0.42" stop-color="${c.fur}"/>
      <stop offset="0.82" stop-color="${c.furShadow}"/><stop offset="1" stop-color="${c.furDeep}"/>
    </radialGradient>
    <radialGradient id="gBody" cx="0.38" cy="0.25" r="0.85">
      <stop offset="0" stop-color="${c.furLight}"/><stop offset="0.4" stop-color="${c.fur}"/>
      <stop offset="0.85" stop-color="${c.furShadow}"/><stop offset="1" stop-color="${c.furDeep}"/>
    </radialGradient>
    <radialGradient id="gHaunch" cx="0.35" cy="0.28" r="0.85">
      <stop offset="0" stop-color="${c.furLight}"/><stop offset="0.45" stop-color="${c.fur}"/>
      <stop offset="1" stop-color="${c.furShadow}"/>
    </radialGradient>
    <linearGradient id="gEarL" x1="0" y1="0" x2="1" y2="0">
      <stop offset="0" stop-color="${c.furLight}"/><stop offset="1" stop-color="${c.fur}"/>
    </linearGradient>
    <linearGradient id="gEarR" x1="0" y1="0" x2="1" y2="0">
      <stop offset="0" stop-color="${c.fur}"/><stop offset="1" stop-color="${c.furShadow}"/>
    </linearGradient>
    <linearGradient id="gLeg" x1="0" y1="0" x2="1" y2="0">
      <stop offset="0" stop-color="${c.furLight}"/><stop offset="0.5" stop-color="${c.fur}"/>
      <stop offset="1" stop-color="${c.furShadow}"/>
    </linearGradient>
    <radialGradient id="gWhite" cx="0.38" cy="0.3" r="0.85">
      <stop offset="0" stop-color="${c.white}"/><stop offset="0.6" stop-color="${c.white}"/>
      <stop offset="1" stop-color="${c.whiteShadow}"/>
    </radialGradient>
    <radialGradient id="gIris" cx="0.5" cy="0.78" r="0.75">
      <stop offset="0" stop-color="${c.irisLight}"/><stop offset="0.5" stop-color="${c.iris}"/>
      <stop offset="1" stop-color="${c.irisDark}"/>
    </radialGradient>
    <radialGradient id="gInnerEar" cx="0.35" cy="0.75" r="0.8">
      <stop offset="0" stop-color="${c.innerEar}"/><stop offset="1" stop-color="${c.noseShadow}"/>
    </radialGradient>
    <linearGradient id="gTail" gradientUnits="userSpaceOnUse" x1="150" y1="140" x2="190" y2="190">
      <stop offset="0" stop-color="${c.fur}"/><stop offset="1" stop-color="${c.furShadow}"/>
    </linearGradient>
    <linearGradient id="gPost" x1="0" y1="0" x2="1" y2="0">
      <stop offset="0" stop-color="${W.light}"/><stop offset="0.45" stop-color="${W.base}"/>
      <stop offset="1" stop-color="${W.shadow}"/>
    </linearGradient>
    <radialGradient id="gKnob" cx="0.35" cy="0.3" r="0.75">
      <stop offset="0" stop-color="${W.light}"/><stop offset="0.6" stop-color="${W.base}"/>
      <stop offset="1" stop-color="${W.shadow}"/>
    </radialGradient>
    <linearGradient id="gSeatTop" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="${W.light}"/><stop offset="1" stop-color="${W.base}"/>
    </linearGradient>
    <linearGradient id="gSeatFront" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="${W.base}"/><stop offset="1" stop-color="${W.shadow}"/>
    </linearGradient>
    <clipPath id="cHead"><path d="${head}"/></clipPath>
    <clipPath id="cTorso"><path d="${torso}"/></clipPath>
    <clipPath id="cHaunchL"><path d="${haunchL}"/></clipPath>
    <clipPath id="cHaunchR"><path d="${mirrorX(haunchL)}"/></clipPath>
    <clipPath id="cLegs"><path d="${R(legL)}"/></clipPath>
    ${lidClips}
  </defs>
  ${PART_ORDER.filter((p) => parts.has(p))
    .map((p) => (HEAD_PARTS.includes(p) && pose.headUp ? `<g transform="translate(0 ${f((-pose.headUp * 200) / spriteSize)})">${P[p]}</g>` : P[p]))
    .join('\n')}
</svg>`;
}

// Turn a cat into an <img>-ready data URL.
function catDataURL(cat, opts) {
  return 'data:image/svg+xml;charset=utf-8,' + encodeURIComponent(catSVG(cat, opts));
}
