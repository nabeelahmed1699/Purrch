// SLEEP — now and then the cat naps in its bed. Shared by every cat.
//
// While it naps it stays hidden in the notch (nothing extra is drawn there). Hover the notch
// and the bed sits on the floor of the hover view, left of the chair, with the cat curled up
// in it: breathing slowly, little "z"s floating up from its head. It doesn't hop off to
// wander. Pet it and it purrs in its sleep (hearts float up). Throw the ball and it reacts
// like a sleepy cat (see `ballReactions`): sleeps on, peeks and dozes off again, or slowly
// gets up and ambles over to it. Feeding it or starting a game from the menu wakes it up too.
// Awake, the bed is still there in the hover view, empty.
//
// Units: x is points from the notch centre, y points up from the hover view's floor (as in
// wander.js). Bed grids use one sprite pixel per point, like the wandering cat. Times in ms.

const SLEEP = {
  // Awake for [min, max] minutes between naps, and each nap lasts [min, max] minutes.
  everyMinutes: [20, 45],
  napMinutes: [8, 20],

  // Sleeping, looped (side-view frames from play-frames.js, see vector/cat-side-art.js):
  // breathing out, then in.
  steps: [['sleep1', 1700], ['sleep2', 1500]],

  // The ball lands while it sleeps: it picks one of these at random (weight = how likely).
  // Each step: [frame, ms]. Lying frames: sleep1, sleep2, sleepDrowsy (head lifting, eyes
  // half open), sleepLookUp (head up, looking). `wakes: true` gets up at the end of its steps
  // and goes after the ball with `sleepyChase`; otherwise it dozes off again.
  // Another throw while it's still asleep (or dozing off) picks again.
  ballReactions: [
    { name: 'sleeps right through it', weight: 3, steps: [] },
    { name: 'peeks, then dozes off', weight: 3, steps: [
      ['sleep1', 700], ['sleepDrowsy', 600], ['sleepLookUp', 1400], ['sleepDrowsy', 160], ['sleepLookUp', 900],
      ['sleepDrowsy', 900], ['sleep2', 400],
    ] },
    { name: 'wakes up slowly and goes over', weight: 4, wakes: true, steps: [
      ['sleep2', 600], ['sleepDrowsy', 900], ['sleepLookUp', 800], ['sleepDrowsy', 160], ['sleepLookUp', 900],
      ['crouch', 700], ['stand', 400], ['crouch', 600], ['stand', 500],
    ] },
  ],

  // Just woken: walks over (no galloping), then a lazy pounce. Same format as wander.js
  // `chase`. Once it's properly awake, the next throw gets the usual gallop.
  sleepyChase: {
    frames: ['walk1', 'walk2', 'walk3', 'walk4', 'walk5', 'walk6'],
    frameMs: 150,
    speed: 24,
    reach: 30,
    pounce: [['crouch', 500, 0], ['crouch', 120, -1], ['pounce', 220, 10], ['catch', 420, 12],
             ['kick1', 140, 12], ['kick2', 120, 12], ['kick3', 160, 12], ['stand', 500, 12]],
    holdFrames: ['catch', 'kick1'],
    holdOffset: 22,
    kickFrame: 'kick2',
    kickSpeed: 90,
    again: 0.3,
    maxChases: 2,
  },

  bed: {
    // The bed's centre, and where in it the cat lies: catX from the bed's centre (the frame
    // is wider than the curled-up cat), catY up from the floor (on the cushion).
    x: -118,
    catX: -9,
    catY: 2,
    facing: 'right',
    palette: { o: '#24161a', l: '#f29bb0', b: '#d9667f', s: '#a8445f', d: '#7a2c45', c: '#fbe6cf', C: '#e5c2a2' },
    // Drawn behind the cat: the back bolster, the round ends and the cushion.
    back: {
      x: 0, y: 0, rows: [
        '.........oooooooooooooooooooooooooooooooooooooooooooooooo.........',
        '.....oooolllllllllllllllllllllllllllllllllllllllllllllllloooo.....',
        '...oollllllllbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbllllllllloo...',
        '..ollllllllbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbblllllllllbbbo..',
        '.olllllllbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbllllllllbbbbbbo.',
        '.olllllbbbbbbbbbssssssssssssssssssssssssssssssssssllllllbbbbbbbbo.',
        'ollllbbbbbbbbbbbssssssssssssssssssssssssssssssssslllllbbbbbbbbbbbo',
        'ollbbbbbbbbbbbsssddddddddddddddddddddddddddddddddlllbbbbbbbbbbbsso',
        'obbbbbbbbbbbsssssCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCClbbbbbbbbbbbsssso',
        'obbbbbbbbbsssssssCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCbbbbbbbbbbsssssso',
        'obbbbbbbsssssssssccccccccccccccccccccccccccccccccbbbbbbbbsssssssso',
        'obbbbbsssssssssddccccccccccccccccccccccccccccccccbbbbbbsssssssssdo',
        'obbbsssssssssddddccccccccccccccccccccccccccccccccbbbbsssssssssdddo',
        '.osssssssssdddddccccccccccccccccccccccccccccccccccbsssssssssddddo.',
        '.osssssssdddddddccccccccccccccccccccccccccccccccccssssssssddddddo.',
        '..ossssddddddddccccccccccccccccccccccccccccccccccccsssssdddddddo..',
        '...osdddddddddccccccccccccccccccccccccccccccccccccccssddddddddo...',
        '....odddddddccccccccccccccccccccccccccccccccccccccccccdddddddo....',
        '....ooccccccccccccccccccccccccccccccccccccccccccccccccccccccoo....',
        '......oooooooooooooooooooooooooooooooooooooooooooooooooooooo......',
      ],
    },
    // Drawn in front of the cat while it's in the bed: the low front bolster.
    front: {
      x: 0, y: 12, rows: [
        '...oooooooooooooooooooooooooooooooooooooooooooooooooooooooooooo...',
        '.oolllllllllllllllllllllllllllllllllllllllllllllllllllllllllllloo.',
        '.obbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbo.',
        'obbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbo',
        '.obbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbo.',
        '.osssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssso.',
        '..oossssssssssssssssssssssssssssssssssssssssssssssssssssssssssoo..',
        '....oooooooooooooooooooooooooooooooooooooooooooooooooooooooooo....',
      ],
    },
  },

  // The floating "z"s: `size` is screen pixels per z pixel. Each one starts `at` ms into a
  // `loopMs` loop; dx is from the cat's middle towards its head, y up from the floor.
  z: {
    palette: { w: '#fff3e0' },
    rows: [
      'wwwww',
      '...ww',
      '..ww.',
      '.ww..',
      'wwwww',
    ],
    loopMs: 3600,
    floats: [
      { at: 0, ms: 2400, dx: [27, 34], y: [27, 40], size: 2 },
      { at: 1200, ms: 2400, dx: [32, 42], y: [32, 50], size: 3 },
    ],
  },
};
