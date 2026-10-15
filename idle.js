// IDLE animation — shared by every cat. A frame only picks part variants and offsets;
// colours come from the cat's palette (cats.js) and markings from markings.js.
//
// Frame fields:
//   tail   tail variant      (center, right1, right2, left1, left2)
//   torso  chest variant     (breath0, breath1, breath2 = chest raised 0 / 1 / 2 px)
//   headUp head lift in px   (moves ears, head and eyes together)
//   ears   ear variant       (rest, twitchHalf, twitch)
//   eyes   eye variant       (open, half, closed)
//
// Loop: a slow breath (head bob + chest rise) with a gentle tail sway, one blink,
// and one ear flick, about 10 seconds before it repeats.

const IDLE = {
  name: 'idle',
  frames: [
    /* 0 */ { tail: 'center', torso: 'breath0', headUp: 0, ears: 'rest', eyes: 'open' },
    /* 1 */ { tail: 'right1', torso: 'breath0', headUp: 0, ears: 'rest', eyes: 'open' },
    /* 2 */ { tail: 'right2', torso: 'breath1', headUp: 1, ears: 'rest', eyes: 'open' },
    /* 3 */ { tail: 'right1', torso: 'breath2', headUp: 2, ears: 'rest', eyes: 'open' },
    /* 4 */ { tail: 'center', torso: 'breath2', headUp: 2, ears: 'rest', eyes: 'open' },
    /* 5 */ { tail: 'left1', torso: 'breath2', headUp: 2, ears: 'rest', eyes: 'open' },
    /* 6 */ { tail: 'left2', torso: 'breath1', headUp: 1, ears: 'rest', eyes: 'open' },
    /* 7 */ { tail: 'left1', torso: 'breath0', headUp: 0, ears: 'rest', eyes: 'open' },
    /* 8 */ { tail: 'right1', torso: 'breath2', headUp: 2, ears: 'rest', eyes: 'half' },
    /* 9 */ { tail: 'right1', torso: 'breath2', headUp: 2, ears: 'rest', eyes: 'closed' },
    /* 10 */ { tail: 'left1', torso: 'breath2', headUp: 2, ears: 'twitchHalf', eyes: 'open' },
    /* 11 */ { tail: 'left1', torso: 'breath2', headUp: 2, ears: 'twitch', eyes: 'open' },
  ],
  // Each step shows a frame for `ms` milliseconds; the list loops.
  timeline: [
    // breath 1
    { frame: 0, ms: 320 }, { frame: 1, ms: 320 }, { frame: 2, ms: 320 }, { frame: 3, ms: 320 },
    { frame: 4, ms: 320 }, { frame: 5, ms: 320 }, { frame: 6, ms: 320 }, { frame: 7, ms: 320 },
    // breath 2, with a blink at the top of the breath
    { frame: 0, ms: 320 }, { frame: 1, ms: 320 }, { frame: 2, ms: 320 },
    { frame: 3, ms: 120 }, { frame: 8, ms: 60 }, { frame: 9, ms: 110 }, { frame: 8, ms: 60 },
    { frame: 4, ms: 320 }, { frame: 5, ms: 320 }, { frame: 6, ms: 320 }, { frame: 7, ms: 320 },
    // breath 3, with an ear flick
    { frame: 0, ms: 320 }, { frame: 1, ms: 320 }, { frame: 2, ms: 320 }, { frame: 3, ms: 320 },
    { frame: 4, ms: 320 },
    { frame: 5, ms: 100 }, { frame: 10, ms: 60 }, { frame: 11, ms: 100 }, { frame: 10, ms: 60 },
    { frame: 6, ms: 320 }, { frame: 7, ms: 320 },
    // breath 4
    { frame: 0, ms: 320 }, { frame: 1, ms: 320 }, { frame: 2, ms: 320 }, { frame: 3, ms: 320 },
    { frame: 4, ms: 320 }, { frame: 5, ms: 320 }, { frame: 6, ms: 320 }, { frame: 7, ms: 320 },
  ],
};
