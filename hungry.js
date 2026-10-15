// HUNGRY — the cat gets hungry, comes out, sits facing you and meows until it's fed. Shared by
// every cat (side-view and sitting frames from play-frames.js — the sitting cat is drawn in
// vector/cat-sit-art.js — colours from cats.js).
//
// Same rules and units as play.js: the black shape never gets taller than the notch, it only
// grows sideways ("wings"); x is in points from the notch centre; times are in milliseconds.
// Segments use the play.js format, plus:
//   ms     n, or [min, max] for a random length picked each time
//   bowl   null = not drawn, or { x: n | [from, to], frame: 'full' | 'empty', ease }
//          x is the bowl's centre; it sits on the bottom edge
//
// A routine is a list of segments, plus optional floating "meow" texts:
//   sounds [{ at, ms, x: [from, to], y: [from, to], ease }]   `at` is ms from the routine's
//          start; x is the text's centre, y its bottom edge (points up from the bottom edge).
//          A sound fades out over the end of its `ms`. Keep y + the text's height <= 32.
//
// Frames: any play-frames.js frame: side view, or the sitting cat facing you (front,
// frontBlink, frontMeow1, frontEat1, frontPaw1, ...; see vector/cat-sit-art.js).
//
// The app runs: comeOut, then meow / wait / meow / wait ... until fed, then eat and goHome.
// Feeding a cat that isn't hungry runs comeOut, eat, goHome.

const HUNGRY = {
  // How long after a meal the cat gets hungry again, in minutes (picked at random each meal).
  hungryAfterMinutes: [120, 180],
  // Now and then it comes out just for attention: every [min, max] minutes it comes out, sits
  // facing you and paws at the screen (`attention` routine, `attentionLoops` times), then goes
  // back in. Hover and pet it and it's happy.
  attentionEveryMinutes: [20, 45],
  attentionLoops: 4,

  routines: {
    comeOut: { segments: [
      { name: 'wing opens', ms: 250,
        cat: null, bowl: null,
        wings: { left: 0, right: [0, 84], ease: 'out' } },

      { name: 'trots out', ms: 450,
        cat: { x: [52, 116], facing: 'right', frame: 'run', ease: 'out' },
        bowl: null,
        wings: { left: 0, right: 84 } },

      { name: 'turns to face you', ms: 250,
        cat: { x: 116, facing: 'right', frame: [['stand', 120], ['front', 130]] },
        bowl: null,
        wings: { left: 0, right: 84 } },
    ] },

    meow: {
      segments: [
        { name: 'sits', ms: 300,
          cat: { x: 116, facing: 'right', frame: 'front' },
          bowl: null,
          wings: { left: 0, right: 84 } },

        { name: 'meow meow', ms: 1300,
          cat: { x: 116, facing: 'right',
                 frame: [['frontMeow1', 120], ['frontMeow2', 300], ['front', 230],
                         ['frontMeow1', 120], ['frontMeow2', 300], ['front', 230]] },
          bowl: null,
          wings: { left: 0, right: 84 } },

        { name: 'waits for the sounds to float away', ms: 1000,
          cat: { x: 116, facing: 'right', frame: 'front' },
          bowl: null,
          wings: { left: 0, right: 84 } },
      ],
      sounds: [
        { at: 320, ms: 1500, x: [146, 154], y: [12, 24], ease: 'out' },
        { at: 970, ms: 1500, x: [150, 158], y: [12, 24], ease: 'out' },
      ],
    },

    wait: { segments: [
      { name: 'stares at you', ms: [5000, 9000],
        cat: { x: 116, facing: 'right',
               frame: [['front', 900], ['frontBreathe', 700], ['front', 500], ['frontTailRight', 400],
                       ['front', 900], ['frontBlink', 150], ['front', 700], ['frontEarFlick', 200],
                       ['front', 600], ['frontTailLeft', 400], ['front', 800], ['frontBreathe', 700], ['front', 0]] },
        bowl: null,
        wings: { left: 0, right: 84 } },
    ] },

    eat: { segments: [
      { name: 'bowl slides in', ms: 350,
        cat: { x: 116, facing: 'right', frame: 'front' },
        bowl: { x: [176, 116], frame: 'full', ease: 'out' },
        wings: { left: 0, right: 84 } },

      { name: 'eats', ms: 2400,
        cat: { x: 116, facing: 'right',
               frame: [['frontEat1', 200], ['frontEat2', 200], ['frontEat1', 200], ['frontEat2', 200],
                       ['frontEat1', 200], ['frontEat2', 200], ['frontEat1', 200], ['frontEat2', 200],
                       ['frontEat1', 200], ['frontEat2', 200], ['frontEat1', 200], ['frontEat2', 200]] },
        bowl: { x: 116, frame: 'full' },
        wings: { left: 0, right: 84 } },

      { name: 'happy', ms: 700,
        cat: { x: 116, facing: 'right', frame: [['front', 300], ['frontBlink', 250], ['front', 150]] },
        bowl: { x: 116, frame: 'empty' },
        wings: { left: 0, right: 84 } },

      { name: 'bowl slides away', ms: 300,
        cat: { x: 116, facing: 'right', frame: 'front' },
        bowl: { x: [116, 176], frame: 'empty', ease: 'in' },
        wings: { left: 0, right: 84 } },
    ] },

    // Wants attention: sits facing you, paws at the screen, a little meow, then waits.
    attention: {
      segments: [
        { name: 'paws at you', ms: 2570,
          cat: { x: 116, facing: 'right',
                 frame: [['front', 300], ['frontPaw1', 160], ['frontPaw2', 160], ['frontPaw1', 160], ['frontPaw2', 160], ['frontPaw1', 160], ['frontPaw2', 160], ['frontPawMeow', 450], ['front', 250],
                         ['frontPaw1', 160], ['frontPaw2', 160], ['frontPaw1', 160], ['frontPaw2', 160]] },
          bowl: null,
          wings: { left: 0, right: 84 } },

        { name: 'waits to see if you noticed', ms: [2500, 4500],
          cat: { x: 116, facing: 'right', frame: [['front', 1400], ['frontBlink', 150], ['front', 900], ['frontEarFlick', 200], ['front', 0]] },
          bowl: null,
          wings: { left: 0, right: 84 } },
      ],
      sounds: [
        { at: 1270, ms: 1500, x: [146, 154], y: [12, 24], ease: 'out' },
      ],
    },

    goHome: { segments: [
      { name: 'turns around', ms: 200,
        cat: { x: 116, facing: 'left', frame: 'stand' },
        bowl: null,
        wings: { left: 0, right: 84 } },

      { name: 'runs back in', ms: 500,
        cat: { x: [116, 52], facing: 'left', frame: 'run', ease: 'in' },
        bowl: null,
        wings: { left: 0, right: [84, 0], ease: 'inOut' } },
    ] },
  },

  // The food bowl, 16 x 8 px, facing right. Its own palette (same bowl for every cat).
  bowl: {
    width: 16,
    height: 8,
    palette: { o: '#24161a', B: '#4a90d9', D: '#2c5f9e', y: '#cfe6ff', F: '#c98a4b', K: '#7a4520' },
    frames: {
      full: { x: 0, y: 0, rows: [
        '...oooooooooo...',
        '..oFKFFKFFKFFo..',
        '.oFFFKFFFFKFFFo.',
        'oooooooooooooooo',
        'oyBBBBBBBBBBBBBo',
        '.oyBBBBBBBBBBBo.',
        '.oDDDDDDDDDDDDo.',
        '..oooooooooooo..',
      ] },
      empty: { x: 0, y: 3, rows: [
        'oooooooooooooooo',
        'oyBBBBBBBBBBBBBo',
        '.oyBBBBBBBBBBBo.',
        '.oDDDDDDDDDDDDo.',
        '..oooooooooooo..',
      ] },
    },
  },

  // The floating "meow". Drawn with each pixel 2 x 2 screen pixels so it stays readable.
  meow: {
    pixelScale: 2,
    palette: { w: '#fff3e0' },
    rows: [
      'ww.w...ww...ww..w...w',
      'w.w.w.w..w.w..w.w...w',
      'w.w.w.wwww.w..w.w.w.w',
      'w.w.w.w....w..w.w.w.w',
      'w.w.w..www..ww...w.w.',
    ],
  },
};
