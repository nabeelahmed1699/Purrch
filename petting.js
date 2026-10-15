// PETTING — click the chair cat in the hover view to pet it. Shared by every cat.
//
// While hovered, the pointer over the cat becomes a pixel-art hand (`cursor.open`), and a
// press switches it to `cursor.stroke`. Each click pets the cat for `ms`: it loops `timeline`
// (chair-cat frames from parts.js, same fields as idle.js) and floats up a pair of `hearts`.
// Clicking again while it's being petted keeps it going.
//
// Hearts use the chair cat's space: x is points from the notch centre, y points up from the
// bottom of the hover view (the chair cat stands on it). They never reach the notch itself.

const PETTING = {
  // How long one click pets the cat, in ms.
  ms: 1600,

  // Chair-cat frames for petting: eyes shut, head pushing up into the hand, ears flicking.
  frames: {
    pet1: { tail: 'right1', torso: 'breath2', headUp: 2, ears: 'twitchHalf', eyes: 'closed' },
    pet2: { tail: 'right2', torso: 'breath1', headUp: 3, ears: 'twitch', eyes: 'closed' },
    pet3: { tail: 'center', torso: 'breath2', headUp: 1, ears: 'rest', eyes: 'closed' },
  },
  // Loops while petted. Each step: [frame, ms].
  timeline: [['pet1', 180], ['pet2', 200], ['pet1', 160], ['pet3', 220]],

  // Two hearts per click, one either side of the head. at = ms after the click.
  hearts: [
    { at: 0, ms: 1100, x: [-26, -32], y: [40, 60], ease: 'out' },
    { at: 250, ms: 1100, x: [26, 34], y: [36, 58], ease: 'out' },
  ],

  palette: { o: '#24161a', w: '#ffdcb8', s: '#e0a477', h: '#fff4e6', R: '#ff5d7a', D: '#c93a5a', y: '#ffffff' },

  // Drawn with each pixel 2 x 2 screen pixels, like the "meow".
  heart: {
    pixelScale: 2,
    rows: [
      '.oo.oo.',
      'oyRoRRo',
      'oRRRRRo',
      'oRRRRDo',
      '.oRRDo.',
      '..oDo..',
      '...o...',
    ],
  },

  // The pointer over the cat. 16 x 16 px, each pixel 1.5 x 1.5 pt (a 24 pt cursor).
  // hotSpot is the pixel the click lands on.
  cursor: {
    pointsPerPixel: 1.5,
    hotSpot: [7, 2],
    open: [
      '...oo.oo.oo.....',
      '..ohwohwohwo....',
      '..owwowwowwooo..',
      '..owwowwowwohwo.',
      '..owwowwowwowwo.',
      '..owwowwowwowwo.',
      '..owwowwowwowwo.',
      'oo.owwwwwwwwwwo.',
      'ohwowwwwwwwwwwo.',
      'owwowwwwwwwwwso.',
      '.owwwwwwwwwwwso.',
      '..owwwwwwwwwsso.',
      '...owwwwwwwsso..',
      '....owwwwwsso...',
      '.....owwwsso....',
      '......ooooo.....',
    ],
    stroke: [
      '................',
      '................',
      '...oo.oo.oo.....',
      '..ohwohwohwooo..',
      '..owwowwowwohwo.',
      '..owwowwowwowwo.',
      '..osswsswsswsso.',
      '.ooowwwwwwwwwwo.',
      'ohwwowwwwwwwwwo.',
      'owwwowwwwwwwwso.',
      '.owwwwwwwwwwwso.',
      '..owwwwwwwwwsso.',
      '...owwwwwwwsso..',
      '....owwwwwsso...',
      '.....owwwsso....',
      '......ooooo.....',
    ],
  },
};
