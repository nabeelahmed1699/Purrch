/// A snapshot of what's on screen at one moment: where the cat, ball and bowl are, any
/// floating "meow"s, how wide the black shape is, and whether the hover view is open.
/// Positions are in points from the notch centre (negative = left).
struct PlayScene: Equatable {
    struct Cat: Equatable {
        var x: Double
        var frame: String
        var facingLeft: Bool
    }

    struct Ball: Equatable {
        var x: Double
        /// Which of the four roll frames to show.
        var roll: Int
    }

    struct Bowl: Equatable {
        var x: Double
        /// "full" or "empty".
        var frame: String
    }

    /// A floating "meow". x is its centre, y its bottom edge in points up from the bottom.
    struct Sound: Equatable {
        var x: Double
        var y: Double
        var opacity: Double
        /// Screen pixels per sprite pixel (only the sleeping cat's "z"s vary).
        var size = 1
    }

    struct Toy: Equatable {
        var x: Double
        var y: Double
        var roll: Int
        var opacity: Double
        /// Pinned under the cat's paws: drawn in front of the cat (otherwise behind it).
        var isHeld: Bool
        /// On the far side of the chair (it goes where the cat plays with it).
        var behindChair = false
    }

    var cat: Cat?
    var ball: Ball?
    var bowl: Bowl?
    var sounds: [Sound] = []
    /// Set while the notch is hovered: the chair cat's idle frame. The view then grows the
    /// shape and shows the chair cat instead of everything else.
    var chairFrame: Int?
    /// The cat once it has hopped off the chair and is wandering the hover view (the chair is
    /// then drawn empty). y is up from the hover view's floor.
    var wanderer: Wanderer.Pose?
    /// The ball the user threw in the hover view. y is up from the floor.
    var toy: Toy?
    /// The hover view's floating "meow"s (hungry cat) and the bowl's x (eating cat).
    var hoverSounds: [Sound] = []
    var hoverBowlX: Double?
    /// Hearts floating up while the chair cat is petted. y is up from the hover view's bottom.
    var hearts: [Sound] = []
    /// The cat is asleep in its bed (the bed's front is drawn over it), and the "z"s floating up.
    var catInBed = false
    var sleepZs: [Sound] = []
    /// Extra black width either side of the notch, in points.
    var leftWing: Double
    var rightWing: Double

    /// Nothing showing: the shape is exactly the notch.
    static let empty = PlayScene(cat: nil, ball: nil, leftWing: 0, rightWing: 0)
}
