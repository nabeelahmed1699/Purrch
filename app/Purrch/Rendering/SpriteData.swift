import Foundation

/// The shape of Resources/sprites.json, written by tools/export-sprites.mjs.
/// These are plain decodable structs, like TypeScript types for a JSON file.
struct SpriteData: Decodable {
    let cats: [CatSpec]
    let play: PlayData
    let chair: ChairData
    let wander: WanderData
    let petting: PettingData
    let hungry: HungryData
    let sleep: SleepData
}

/// Naps in the bed (sleep.js).
struct SleepData: Decodable {
    /// Awake for [min, max] minutes between naps; each nap lasts [min, max] minutes.
    let everyMinutes: [Double]
    let napMinutes: [Double]
    /// Sleeping in the bed, looped.
    let steps: [WanderData.Step]
    /// What it does when the ball is thrown while it sleeps, picked at random by weight.
    let ballReactions: [BallReaction]
    /// Going after the ball just after waking up: a walk, not a gallop.
    let sleepyChase: WanderData.Chase
    let bed: Bed
    let z: Z

    struct BallReaction: Decodable {
        let name: String
        let weight: Double
        /// true: gets up at the end of `steps` and goes after the ball. false: dozes off again
        /// (no steps: it doesn't even stir).
        let wakes: Bool
        let steps: [WanderData.Step]
    }

    struct Bed: Decodable {
        /// The bed's centre, in points from the notch centre.
        let x: Double
        /// Where the cat lies: x from the bed's centre (for a cat facing right; mirrored when
        /// facing left), y up from the floor.
        let catX: Double
        let catY: Double
        let facing: PlayData.Facing
        /// Size in sprite pixels (one per point, like the wandering cat).
        let width: Int
        let height: Int
        let palette: [String: String]
        /// Behind the cat (the whole bed), and in front of it while it's in the bed.
        let back: GridLayer
        let front: GridLayer
    }

    /// The floating "z"s.
    struct Z: Decodable {
        let palette: [String: String]
        let rows: [String]
        let loopMs: Double
        let floats: [Drift]

        /// One "z", `at` ms into the loop. dx: from the cat's middle towards its head; y: up
        /// from the floor; size: screen pixels per z pixel.
        struct Drift: Decodable {
            let at: Double
            let ms: Double
            let dx: PlayData.Span
            let y: PlayData.Span
            let size: Int
        }
    }
}

/// The cat hopping off the chair and wandering the hover view (wander.js).
struct WanderData: Decodable {
    /// How long the notch must be hovered (without petting) before the cat hops down, in ms.
    let afterMs: Double
    /// Screen pixels per sprite pixel for the wandering cat (2 = chair-cat size).
    let pixelScale: Int
    /// Chair seat height above the floor, and where on it the cat sits (x from the chair's
    /// middle), in points.
    let seatY: Double
    let chairX: Double
    /// Sitting on the chair, looped.
    let chairSit: [Step]
    /// How far either side of the notch centre it may wander, in points.
    let rangeX: Double
    /// Never stops closer to the chair (at x 0) than this, in points.
    let clearOfChair: Double
    let walk: Walk
    /// Shortest and longest stroll, in points.
    let minWalk: Double
    let maxWalk: Double
    /// Hopping off the chair, heading right (mirrored to head left).
    let hop: [Move]
    /// Hopping back up, from the right of the chair (mirrored from the left).
    let hopUp: [Move]
    /// How long it sits on the chair before hopping off again: [min, max] in ms.
    let chairMs: [Double]
    let pauses: [Pause]
    /// Loop while petted: side-on (it keeps facing the way it was), or facing you when it
    /// was already sitting that way.
    let pettedSide: [Step]
    let pettedSitting: [Step]
    let pettedFront: [Step]
    /// Frames that count as sitting side-on (petting then uses `pettedSitting`).
    let sittingFrames: [String]
    let hungry: Hungry
    /// Wanting attention in the hover view: pawing at you (looped until petted).
    let attention: Hungry
    let eating: Eating
    let ball: Ball
    let chase: Chase
    /// Going after the ball when hungry: slow, droopy, one weak tap.
    let tiredChase: Chase
    /// Chance a stroll or chase goes behind the chair, and how far from it (points) the cat
    /// must be to switch sides.
    let behindChance: Double
    let switchSidesClear: Double

    /// Hungry in the hover view: sits facing you and meows (looped until fed).
    struct Hungry: Decodable {
        let steps: [Step]
        let sounds: [Sound]
        /// How much bigger the "meow" is drawn than in the notch.
        let textScale: Int

        /// A floating "meow", `at` ms into the loop. dx: from the cat's middle towards the view's
        /// centre; y: up from the floor.
        struct Sound: Decodable {
            let at: Double
            let ms: Double
            let dx: PlayData.Span
            let y: PlayData.Span
        }
    }

    /// Eating in the hover view, with the bowl in front.
    struct Eating: Decodable {
        let steps: [Step]
    }

    /// The one ball. Speeds in points per second, gravity and friction in points/s².
    struct Ball: Decodable {
        let pixelScale: Int
        /// Where it lies when the app starts, in points from the notch centre.
        let startX: Double
        let gravity: Double
        let bounce: Double
        let rollFriction: Double
        /// How fast it pops up when the cat bats it.
        let tossUp: Double
        /// Between strolls, chance the cat goes and plays with it on its own.
        let playChance: Double
    }

    /// Going after the ball: gallop over, then pounce, catch and bat it away.
    struct Chase: Decodable {
        let frames: [String]
        let frameMs: Double
        let speed: Double
        /// Stops this far short of the ball, in points.
        let reach: Double
        let pounce: [PounceStep]
        /// The ball is pinned under its paws on these frames, `holdOffset` ahead of its middle.
        let holdFrames: [String]
        let holdOffset: Double
        let kickFrame: String
        let kickSpeed: Double
        /// Chance of chasing again after batting it, and the most chases per throw.
        let again: Double
        let maxChases: Int

        struct PounceStep: Decodable {
            let frame: String
            let ms: Double
            /// How far forward it has moved by the end of this step, in points.
            let dx: Double
        }
    }

    struct Walk: Decodable {
        /// The walk cycle (side-view frames).
        let frames: [String]
        let frameMs: Double
        /// Points per second.
        let speed: Double
    }

    struct Move: Decodable {
        let frame: String
        let ms: Double
        let x: PlayData.Span
        let y: PlayData.Span
        let ease: Ease
    }

    struct Pause: Decodable {
        let name: String
        /// How likely this pause is, relative to the others.
        let weight: Double
        /// true: walk back to the chair and sit there a while (no steps).
        let chair: Bool
        /// Only when in front of the chair (it faces you).
        let inFront: Bool
        let steps: [Step]
    }

    struct Step: Decodable {
        let frame: String
        let ms: Double
    }
}

/// Petting the chair cat (petting.js): its frames, the hearts and the hand cursor.
struct PettingData: Decodable {
    /// How long one click pets the cat, in ms.
    let ms: Double
    /// Loops while petted. Frame numbers index ChairData.frames.
    let timeline: [ChairData.Step]
    /// Floated up on each click; `at` is ms after the click. y is up from the hover view's bottom.
    let hearts: [HungryData.Sound]
    let palette: [String: String]
    let heart: Heart
    let cursor: Cursor

    struct Heart: Decodable {
        let pixelScale: Int
        let rows: [String]
    }

    struct Cursor: Decodable {
        /// Size of one cursor pixel, in points.
        let pointsPerPixel: Double
        /// [x, y] of the pixel the click lands on, from the top left.
        let hotSpot: [Int]
        let open: [String]
        let stroke: [String]
    }
}

/// The big chair cat (parts.js + idle.js), shown below the notch while it's hovered.
struct ChairData: Decodable {
    /// Every frame is size x size sprite pixels (128 x 128).
    let size: Int
    /// idle.js frames, shared by every cat.
    let frames: [GridLayer]
    /// markings[cat][i] — that cat's overlay for frame i (nil when it has none).
    let markings: [String: [GridLayer?]]
    /// Each step shows a frame for `ms`; the list loops.
    let timeline: [Step]
    /// The chair on its own, for when the cat has hopped down.
    let empty: GridLayer

    struct Step: Decodable {
        let frame: Int
        let ms: Double
    }

    /// The idle frame showing `t` ms into the loop.
    func frame(at t: Double) -> Int {
        Self.frame(in: timeline, at: t)
    }

    /// The frame showing `t` ms into a looping list of steps.
    static func frame(in timeline: [Step], at t: Double) -> Int {
        let total = timeline.reduce(0) { $0 + $1.ms }
        guard total > 0 else { return 0 }
        var local = t.truncatingRemainder(dividingBy: total)
        for step in timeline {
            if local < step.ms { return step.frame }
            local -= step.ms
        }
        return timeline.last?.frame ?? 0
    }
}

struct CatSpec: Decodable, Identifiable {
    let id: String
    let name: String
    /// Palette key → "#rrggbb".
    let palette: [String: String]
}

/// A cropped grid of palette keys placed at (x, y) on a frame. "." is transparent.
struct GridLayer: Decodable {
    let x: Int
    let y: Int
    let rows: [String]
}

/// Everything for the ball game: the side-view frames, the ball, and the choreography
/// from play.js.
struct PlayData: Decodable {
    /// Size of every cat frame, in sprite pixels (80 x 64).
    let frameWidth: Int
    let frameHeight: Int
    /// frames[name] — shared grids, the same for every cat. All face right.
    let frames: [String: GridLayer]
    /// markings[cat][frame] — a cat's overlay, drawn on top of the shared frame.
    let markings: [String: [String: GridLayer]]
    let ball: BallSpec
    /// Sitting frames again at twice the size, for the hover view (sharper than doubling).
    let hd: HiRes
    let run: RunCycle
    /// How long the cat stays inside the notch, picked at random: [min, max] in ms.
    let tunnelMs: [Double]
    /// How often a game starts: [min, max] in seconds.
    let everySeconds: [Double]
    let segments: [Segment]

    /// Same layout as the frames above, `frameWidth` x `frameHeight` (160 x 128).
    struct HiRes: Decodable {
        let frameWidth: Int
        let frameHeight: Int
        let frames: [String: GridLayer]
        let markings: [String: [String: GridLayer]]
    }

    struct BallSpec: Decodable {
        let size: Int
        let palette: [String: String]
        let frames: [String: GridLayer]
    }

    struct RunCycle: Decodable {
        let frames: [String]
        let frameMs: Double
    }

    /// A value that moves from `from` to `to` over a segment (they're equal when it holds still).
    struct Span: Decodable {
        let from: Double
        let to: Double
    }

    /// One stretch of the game. Positions are in points from the notch centre.
    struct Segment: Decodable {
        let name: String
        let ms: Double
        /// Set when the length is random: [min, max] in ms, picked each run.
        let msRange: [Double]?
        /// The cat is inside the notch; this segment's length is random (tunnelMs).
        let tunnel: Bool
        let cat: CatTrack?
        let ball: BallTrack?
        let bowl: BowlTrack?
        let wings: Wings
    }

    struct CatTrack: Decodable {
        let x: Span
        let ease: Ease
        let facing: Facing
        /// true = play the gallop cycle; false = play `steps` in order.
        let run: Bool
        let steps: [Step]

        struct Step: Decodable {
            let frame: String
            let ms: Double
            let facing: Facing
        }
    }

    struct BallTrack: Decodable {
        let x: Span
        let ease: Ease
    }

    struct BowlTrack: Decodable {
        let x: Span
        /// "full" or "empty".
        let frame: String
        let ease: Ease
    }

    /// Extra width either side of the notch, in points.
    struct Wings: Decodable {
        let left: Span
        let right: Span
        let ease: Ease
    }

    enum Facing: String, Decodable { case left, right }
}

/// Everything for hunger and feeding (hungry.js): the routines, the bowl and the "meow" text.
struct HungryData: Decodable {
    /// How long after a meal the cat gets hungry again: [min, max] in minutes.
    let hungryAfterMinutes: [Double]
    /// How often it comes out just for attention: [min, max] in minutes; and how many times it
    /// runs the `attention` routine before giving up and going back in.
    let attentionEveryMinutes: [Double]
    let attentionLoops: Int
    /// comeOut, meow, wait, eat, goHome.
    let routines: [String: RoutineSpec]
    let bowl: BowlSpec
    let meow: TextSpec

    struct RoutineSpec: Decodable {
        let segments: [PlayData.Segment]
        let sounds: [Sound]
    }

    /// A floating "meow": starts `at` ms into the routine and lasts `ms`.
    struct Sound: Decodable {
        let at: Double
        let ms: Double
        let x: PlayData.Span
        let y: PlayData.Span
        let ease: Ease
    }

    struct BowlSpec: Decodable {
        let width: Int
        let height: Int
        let palette: [String: String]
        let frames: [String: GridLayer]
    }

    /// A small pixel-art word, drawn with each pixel `pixelScale` x `pixelScale` screen pixels.
    struct TextSpec: Decodable {
        let pixelScale: Int
        let palette: [String: String]
        let rows: [String]
    }
}

/// How a value speeds up or slows down between `from` and `to`.
enum Ease: String, Decodable {
    case linear, `in`, out, inOut

    func apply(_ p: Double) -> Double {
        switch self {
        case .linear: p
        case .in: p * p
        case .out: 1 - (1 - p) * (1 - p)
        case .inOut: p < 0.5 ? 2 * p * p : 1 - 2 * (1 - p) * (1 - p)
        }
    }
}
