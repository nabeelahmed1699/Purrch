import Foundation

/// Every number you might want to tweak, in one place.
/// (Game timings and positions live in play.js, exported into sprites.json.)
enum Tuning {
    /// How many screen (device) pixels each sprite pixel covers. Keep it a whole number so
    /// pixels stay perfectly sharp. 1 on a Retina screen = the 64 px tall cat is 32 pt,
    /// exactly the notch's height.
    static let devicePixelsPerSpritePixel = 1

    /// Radius of the black shape's bottom corners, in points.
    static let shapeCornerRadius: CGFloat = 8

    /// Frames per second while a game is playing. Nothing redraws between games.
    static let playFramesPerSecond = 60.0
    /// After the mouse leaves, a wandering cat carries on in the notch-height wings. Within
    /// this far of the notch centre (points) it's hidden inside the notch; past it, that side's
    /// wing opens to `roamWing` points, at `roamWingSpeed` points per second.
    static let roamHiddenX = 60.0
    static let roamWing = 74.0
    static let roamWingSpeed = 220.0
    /// Half the walking cat's drawn width at notch size, in points: it stops this far short
    /// of a wing's end.
    static let roamCatHalfWidth = 18.0

    /// Shortest wait, in seconds, before a hungry cat comes out: after launch, after a
    /// game, or when it got hungry while paused. (How often it gets hungry is in hungry.js.)
    static let hungerMinimumDelay: TimeInterval = 3

    /// The hover view: while the mouse is over the notch, the black shape grows this much
    /// either side of the notch and down to fit the chair cat below it, in points.
    static let hoverSideGrow: CGFloat = 80
    static let hoverGapBelowNotch: CGFloat = 0
    /// Extra height so the upright cat fits sitting on the chair seat, below the notch.
    static let hoverHeadroom: CGFloat = 0
    static let hoverBottomPadding: CGFloat = 8
    static let hoverCornerRadius: CGFloat = 20
    /// How long the shape takes to grow or shrink, in seconds.
    static let hoverAnimationSeconds = 0.22
    /// How often the mouse position is checked for hover. The panel lets clicks through, so it
    /// can't get mouse-entered events itself; polling needs no permissions.
    static let hoverChecksPerSecond = 15.0

    /// In the small notch, a hungry cat's meow is heard at most this often, in seconds (it
    /// still meows on screen in between). In the hover view every meow is heard.
    static let notchMeowEverySeconds: TimeInterval = 25

    /// Size of the fake notch drawn on Macs (or displays) without one, in points.
    static let fakeNotchWidth: CGFloat = 185
    static let fakeNotchHeight: CGFloat = 32
}
