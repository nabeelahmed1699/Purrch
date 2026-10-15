// WANDER — hover the notch for a moment and the chair cat hops down and wanders around the
// hover view. Shared by every cat (side-view and facing-you frames from play-frames.js and
// hungry.js, colours from cats.js).
//
// The wandering cat is drawn with each sprite pixel 2 x 2 screen pixels, so it's the same
// size as the chair cat (64 pt tall). Units: x is points from the notch centre, y points up
// from the hover view's floor (where the chair stands). Times are in milliseconds.
// Nothing may reach up into the notch: at 2x a standing cat's ears are already level with
// its bottom edge, so the cat hops *down* off the chair rather than up.
//
// Each stroll (and each chase) goes either in front of the chair or behind it, at random:
// behind, the chair is drawn over the cat and it shows through the slats. It only changes
// side when it's clear of the chair, so it never pops through it; behind the chair it may
// even stop and sit there, peeking out.
//
// Between strolls it picks a pause at random: looking around, sitting to scratch an ear or groom,
// sitting and staring at you, ... or heading back to the chair for a while before hopping
// off again.
//
// If the cat was already out of the notch when the hover began (hungry, eating, playing),
// it doesn't jump to the chair: it's on the floor at the same spot, doing the same thing.
// A hungry cat sits facing you and meows until fed; an eating cat keeps eating. Both can be
// petted. Throw a hungry cat the ball and it's too weak to play: it drags itself over slowly
// (head hanging), sniffs it, gives it one feeble tap, and goes back to begging.
//
// There's one ball, and it always lies somewhere in the hover view (it never goes away). Grab
// it with the hand, drag and let go to throw it: it flies, falls, bounces and rolls, and the
// cat drops whatever it's doing (hopping off the chair if need be), gallops over, pounces,
// catches it and bats it away — maybe chasing it again — then wanders on. Now and then,
// between strolls, the cat goes and plays with the ball on its own.
//
// Petting works here too, any time (even mid-hop): click the cat and it stops right where it
// is, in the same pose family (standing, sitting side-on, facing you, on the chair), and
// enjoys it (hearts float up); then it carries on.

const WANDER = {
  // How long the notch must be hovered (without petting) before the cat hops down.
  afterMs: 1500,
  // Screen pixels per sprite pixel for the wandering cat.
  pixelScale: 2,
  // Height of the chair seat above the floor, in points, and where on it the cat sits (x
  // from the chair's middle: the sitting cat's body reaches right, so it sits a bit left).
  seatY: 15,
  chairX: -6,
  // Sitting on the chair (the upright sitting cat), looped: breathing, blinks, ear and tail.
  chairSit: [['front', 1600], ['frontBreathe', 700], ['front', 900], ['frontBlink', 150], ['front', 1200],
             ['frontTailRight', 500], ['front', 800], ['frontBreathe', 700], ['front', 700], ['frontEarFlick', 200],
             ['front', 1000], ['frontTailLeft', 500]],
  // How far either side of the notch centre the cat may wander, in points.
  rangeX: 120,
  // In front of the chair it never stops closer than this (it would look half on it), in
  // points. (Behind the chair it can stop anywhere.)
  clearOfChair: 56,
  // Chance a stroll or chase goes behind the chair, and how far from the chair (points) the
  // cat must be to switch sides.
  behindChance: 0.4,
  switchSidesClear: 44,
  // Walking: a casual stroll using the walk cycle, at this speed (points per second).
  walk: { frames: ['walk1', 'walk2', 'walk3', 'walk4', 'walk5', 'walk6'], frameMs: 140, speed: 26 },
  // Each stroll covers between these distances, in points: a little here and there.
  minWalk: 25,
  maxWalk: 110,

  // Hopping off the chair, heading right (mirrored at random to head left). Each step:
  // [frame, ms, x: [from, to], y: [from, to], ease]. x is from where it sits (`chairX`).
  hop: [
    ['crouch', 220, [0, 0], [15, 15], 'linear'],
    ['pounce', 260, [0, 48], [8, 0], 'in'],
    ['crouch', 160, [48, 48], [0, 0], 'linear'],
    ['stand', 160, [48, 48], [0, 0], 'linear'],
  ],
  // Hopping back up, from the right of the chair (mirrored from the left). It walks to x 48
  // first. Same format as `hop`.
  hopUp: [
    ['stand', 150, [48, 48], [0, 0], 'linear'],
    ['crouch', 220, [48, 48], [0, 0], 'linear'],
    ['pounce', 260, [48, 4], [0, 10], 'out'],
    ['crouch', 180, [0, 0], [15, 15], 'linear'],
  ],
  // How long it stays on the chair before hopping off again, [min, max] in ms.
  chairMs: [3000, 8000],

  // After each walk the cat does one of these at random (weight = how likely), then walks
  // somewhere else. Each step: [frame, ms] (side-view frames keep the direction it walked
  // in). `chair: true` instead walks back to the chair, hops up and sits a while.
  pauses: [
    { name: 'sits and scratches an ear', weight: 2, steps: [
      ['sitSide', 500], ['scratchReach', 160],
      ['scratch1', 110], ['scratch2', 110], ['scratch1', 110], ['scratch2', 110], ['scratch1', 110], ['scratch2', 110],
      ['scratch1', 110], ['scratch2', 110], ['scratch1', 110], ['scratch2', 110], ['scratch1', 110], ['scratch2', 110],
      ['scratchReach', 140], ['sitSide', 450], ['scratchReach', 140],
      ['scratch1', 110], ['scratch2', 110], ['scratch1', 110], ['scratch2', 110], ['scratch1', 110], ['scratch2', 110],
      ['scratchReach', 160], ['sitSide', 900],
    ] },
    // Grooming: licks a front paw and washes its face with it (paw wiping from over the ear
    // down to the nose), licks its chest, then turns round and licks its flank.
    { name: 'grooms', weight: 2, steps: [
      ['sitSide', 500],
      ['groomLick1', 180], ['groomLick2', 160], ['groomLick1', 180], ['groomLick2', 160], ['groomLick1', 180], ['groomLick2', 220],
      ['groomWash1', 180], ['groomWash2', 140], ['groomWash3', 140], ['groomWash4', 200],
      ['groomLick1', 180], ['groomLick2', 160], ['groomLick1', 180], ['groomLick2', 200],
      ['groomWash1', 180], ['groomWash2', 140], ['groomWash3', 140], ['groomWash4', 200],
      ['groomLick1', 180], ['groomLick2', 300], ['sitSide', 500],
      ['groomChest2', 250], ['groomChest1', 200], ['groomChest2', 180], ['groomChest1', 200], ['groomChest2', 180], ['groomChest1', 200],
      ['groomChest2', 250], ['sitSide', 400],
      ['groomFlank2', 300], ['groomFlank1', 220], ['groomFlank2', 200], ['groomFlank1', 220], ['groomFlank2', 200], ['groomFlank1', 220],
      ['groomFlank2', 300], ['sitSide', 900],
    ] },
    { name: 'sits for a bit', steps: [['sitSide', 1800], ['sitSidePet', 300], ['sitSide', 1200]] },
    { name: 'back to the chair', chair: true, weight: 2 },
    { name: 'looks around', steps: [['stand', 400], ['lookUp', 600], ['stand', 300], ['lookDown', 600], ['stand', 300]] },
    { name: 'sits and stares', steps: [['front', 1200], ['frontBlink', 150], ['front', 900], ['frontEarFlick', 200],
                                       ['front', 900], ['frontTailRight', 400], ['front', 600]] },
    { name: 'little meow', steps: [['front', 500], ['frontMeow1', 120], ['frontMeow2', 400], ['front', 900]] },
    // Comes to the front and paws at you for attention (only in front of the chair).
    { name: 'asks for attention', inFront: true, steps: [['front', 400], ['frontPaw1', 160], ['frontPaw2', 160], ['frontPaw1', 160], ['frontPaw2', 160], ['frontPaw1', 160], ['frontPaw2', 160], ['frontPawMeow', 450],
                                                         ['front', 300], ['frontPaw1', 160], ['frontPaw2', 160], ['frontPaw1', 160], ['frontPaw2', 160], ['front', 800]] },
    { name: 'stretches', steps: [['crouch', 700], ['stand', 500]] },
    { name: 'pauses', steps: [['stand', 900]] },
  ],

  // Hungry, in the hover view: sits facing you and meows, looped until it's fed. `sounds` are
  // floating "meow"s: `at` ms into the loop; dx is from the cat's middle towards the centre of
  // the view (so the text stays inside it); y up from the floor. textScale: how much bigger
  // than the notch's "meow" (to match the bigger cat).
  hungry: {
    steps: [['front', 1400], ['frontMeow1', 120], ['frontMeow2', 320], ['front', 220], ['frontMeow1', 120],
            ['frontMeow2', 320], ['front', 1600], ['frontBlink', 150], ['front', 900], ['frontTailRight', 400],
            ['front', 600]],
    sounds: [
      { at: 1420, ms: 1500, dx: [30, 38], y: [42, 56] },
      { at: 1880, ms: 1500, dx: [36, 44], y: [38, 52] },
    ],
    textScale: 2,
  },
  // Wanting attention, in the hover view: sits facing you pawing at the screen, looped until
  // it's petted (then it's happy and wanders off). Same format as `hungry`.
  attention: {
    steps: [['front', 900], ['frontPaw1', 160], ['frontPaw2', 160], ['frontPaw1', 160], ['frontPaw2', 160], ['frontPaw1', 160], ['frontPaw2', 160], ['frontPawMeow', 450], ['front', 250], ['frontPaw1', 160], ['frontPaw2', 160], ['frontPaw1', 160], ['frontPaw2', 160],
            ['front', 1600], ['frontBlink', 150], ['front', 900]],
    sounds: [
      { at: 1880, ms: 1500, dx: [30, 38], y: [42, 56] },
    ],
    textScale: 2,
  },
  // Eating, in the hover view: head bobbing into the bowl in front of it.
  eating: { steps: [['frontEat1', 200], ['frontEat2', 200]] },

  // The ball (play-frames.js ball, drawn at `pixelScale`). Speeds in points per second.
  ball: {
    pixelScale: 2,
    startX: 70,         // where it lies when the app starts
    gravity: 900,       // pulls it down, points/s²
    bounce: 0.45,       // how much upward speed survives a bounce
    rollFriction: 120,  // slows it while rolling, points/s²
    tossUp: 140,        // it pops up a little when the cat bats it
    maxThrowSpeed: 700, // the hand can't fling it faster than this
    playChance: 0.25,   // between strolls, chance the cat goes and plays with it on its own
  },

  // Going after the ball.
  chase: {
    frames: ['run1', 'run2', 'run3', 'run4', 'run5', 'run6'], // gallop
    frameMs: 70,
    speed: 150,
    // It stops this far short of the ball (its front paws are ahead of its middle).
    reach: 30,
    // Then: [frame, ms, dx] — dx is how far forward it has moved by the end of the step.
    pounce: [['crouch', 180, 0], ['crouch', 90, -2], ['crouch', 90, 0], ['pounce', 200, 16], ['catch', 320, 18],
             ['kick1', 110, 18], ['kick2', 100, 18], ['kick3', 140, 18], ['stand', 260, 18]],
    // While these frames show the ball is pinned under its paws, this far ahead of its middle.
    holdFrames: ['catch', 'kick1'],
    holdOffset: 22,
    // On this frame it bats the ball away, this fast.
    kickFrame: 'kick2',
    kickSpeed: 160,
    // Chance it chases the ball again after batting it, and the most chases per throw.
    again: 0.6,
    maxChases: 3,
  },

  // Hungry and thrown the ball: a slow, droopy walk over, a sniff and one weak tap.
  // Same format as `chase`.
  tiredChase: {
    frames: ['tiredWalk1', 'tiredWalk2', 'tiredWalk3', 'tiredWalk4', 'tiredWalk5', 'tiredWalk6'],
    frameMs: 200,
    speed: 14,
    reach: 30,
    pounce: [['lookDown', 900, 0], ['kick1', 300, 2], ['kick2', 220, 2], ['kick3', 300, 2], ['lookDown', 600, 2],
             ['stand', 400, 2]],
    holdFrames: [],
    holdOffset: 22,
    kickFrame: 'kick2',
    kickSpeed: 45,
    again: 0,
    maxChases: 1,
  },

  // Being petted, looped while it lasts. Standing side-on (walking, hopping): stays standing,
  // eyes shut, head pushing up into the hand. Sitting side-on (scratching): stays sitting.
  // Already sitting facing you: stays that way. (On the chair it's the chair cat's petting.)
  pettedSide: [['petSide1', 350], ['petSide2', 500], ['petSide1', 300], ['petSide2', 450]],
  pettedSitting: [['sitSidePet', 1000]],
  pettedFront: [['frontBlink', 700], ['frontMeow2', 300], ['frontBlink', 500]],
  // Frames that count as "sitting side-on" for petting.
  sittingFrames: ['sitSide', 'sitSidePet', 'scratchReach', 'scratch1', 'scratch2',
                  'groomLick1', 'groomLick2', 'groomWash1', 'groomWash2', 'groomWash3', 'groomWash4',
                  'groomChest1', 'groomChest2', 'groomFlank1', 'groomFlank2'],
};
