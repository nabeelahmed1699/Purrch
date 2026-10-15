// PLAY — the ball game. Shared by every cat (frames from play-frames.js, colours from cats.js).
//
// Rule: the black shape never gets taller than the notch (see CLAUDE.md). It only grows
// sideways ("wings"). The notch itself has no pixels, so it works as a tunnel: anything
// inside its width is hidden.
//
// Units: x is in points from the notch centre (negative = left of it). The cat's x is the
// centre of its 40 x 32 pt frame; the ball's x is its centre. Times are in milliseconds.
//
// A segment runs for `ms` and describes, for that stretch of time:
//   cat    null = not drawn, or
//          { x: n | [from, to], facing: 'right' | 'left', ease,
//            frame: 'run' (gallop cycle) | 'stand' | ... | [[frame, ms, facing?], ...] }
//   ball   null = not drawn, or { x: n | [from, to], ease }   (it rolls as it moves)
//   wings  { left: n | [from, to], right: n | [from, to], ease }   extra width either side
//          of the notch, in points
// Eases: 'linear', 'in', 'out', 'inOut'.

const PLAY = {
  name: 'play',
  run: { frames: ['run1', 'run2', 'run3', 'run4', 'run5', 'run6'], frameMs: 70 },
  // How long the cat stays inside the notch before popping out on the other side.
  tunnelMs: [1000, 2000],
  // How often the game starts in the app, in seconds (picked at random each time).
  everySeconds: [120, 360],

  segments: [
    { name: 'ball rolls out', ms: 320,
      cat: null,
      ball: { x: [60, 112] },
      wings: { left: 0, right: [0, 86], ease: 'out' } },

    { name: 'cat dashes out', ms: 480,
      cat: { x: [52, 104], facing: 'right', frame: 'run' },
      ball: { x: [112, 156], ease: 'out' },
      wings: { left: 0, right: 86 } },

    { name: 'crouch', ms: 260,
      cat: { x: 104, facing: 'right', frame: 'crouch' },
      ball: { x: 156 },
      wings: { left: 0, right: 86 } },

    { name: 'pounce', ms: 200,
      cat: { x: [104, 134], facing: 'right', frame: 'pounce', ease: 'out' },
      ball: { x: 156 },
      wings: { left: 0, right: 86 } },

    { name: 'catch', ms: 320,
      cat: { x: 134, facing: 'right', frame: 'catch' },
      ball: { x: [156, 150], ease: 'out' },
      wings: { left: 0, right: 86 } },

    { name: 'paw swipe', ms: 340,
      cat: { x: 134, facing: 'right', frame: [['kick1', 120], ['kick2', 100], ['kick3', 120]] },
      ball: { x: [150, 168], ease: 'out' },
      wings: { left: 0, right: 86 } },

    { name: 'ball bounces back into the notch', ms: 600,
      cat: { x: 134, frame: [['kick3', 120, 'right'], ['stand', 160, 'right'], ['stand', 320, 'left']] },
      ball: { x: [168, -10], ease: 'in' },
      wings: { left: 0, right: 86 } },

    { name: 'cat chases it in', ms: 500,
      cat: { x: [134, 56], facing: 'left', frame: 'run', ease: 'in' },
      ball: null,
      wings: { left: 0, right: [86, 0], ease: 'inOut' } },

    // The duration of this one is picked at random from tunnelMs.
    { name: 'inside the notch', tunnel: true,
      cat: null, ball: null,
      wings: { left: 0, right: 0 } },

    { name: 'pops out on the left', ms: 450,
      cat: { x: [-60, -124], facing: 'left', frame: 'run', ease: 'out' },
      ball: null,
      wings: { left: [0, 74], right: 0, ease: 'out' } },

    { name: 'looks around', ms: 1800,
      cat: { x: -124, frame: [['stand', 200, 'left'], ['lookUp', 450, 'left'], ['stand', 250, 'left'],
                              ['lookDown', 500, 'left'], ['stand', 400, 'right']] },
      ball: null,
      wings: { left: 74, right: 0 } },

    { name: 'heads home', ms: 520,
      cat: { x: [-124, -54], facing: 'right', frame: 'run', ease: 'in' },
      ball: null,
      wings: { left: [74, 0], right: 0, ease: 'inOut' } },
  ],
};
