import AppKit

/// Where the window goes and where the notch sits inside it, worked out from the screens.
///
/// The window is wide enough for the widest wings the game uses and tall enough for the hover
/// view. It's see-through and click-through, so the extra height costs nothing: without hover
/// the black shape stays exactly the notch's height (see CLAUDE.md).
/// On a Mac without a notch, a fake one is drawn at the top centre of the main screen.
struct NotchLayout: Equatable {
    /// Window frame in screen coordinates (AppKit: origin at the bottom left). Whole points.
    let windowFrame: CGRect
    /// The notch inside the window (origin bottom left), flush with the window's top. Can sit
    /// on half points so its sides land exactly on the real notch edges.
    let notch: CGRect
    /// The black shape while hovered, inside the window: the notch grown sideways and down.
    let expanded: CGRect
    /// Points per sprite pixel. Always a whole number of screen pixels.
    let pointsPerSpritePixel: CGFloat
    let backingScale: CGFloat
    /// true when there's no hardware notch and we draw a fake one.
    let isFakeNotch: Bool

    /// nil only if there are no screens at all.
    /// `chairSize`: the chair cat's height in sprite pixels; the hover view fits it below the notch.
    static func current(maxLeftWing: CGFloat, maxRightWing: CGFloat, frameHeight: Int,
                        chairSize: Int) -> NotchLayout? {
        if !forceFakeNotch, let screen = NSScreen.screens.first(where: { $0.notchRect != nil }) {
            return make(screen: screen, notch: screen.notchRect!, fake: false,
                        maxLeftWing: maxLeftWing, maxRightWing: maxRightWing, chairSize: chairSize)
        }
        // NSScreen.screens.first is the screen with the menu bar.
        guard let screen = NSScreen.screens.first else { return nil }
        let catHeight = CGFloat(frameHeight * Tuning.devicePixelsPerSpritePixel) / screen.backingScaleFactor
        let height = max(Tuning.fakeNotchHeight, catHeight)
        let fake = CGRect(x: (screen.frame.midX - Tuning.fakeNotchWidth / 2).rounded(), y: screen.frame.maxY - height,
                          width: Tuning.fakeNotchWidth, height: height)
        return make(screen: screen, notch: fake, fake: true, maxLeftWing: maxLeftWing, maxRightWing: maxRightWing,
                    chairSize: chairSize)
    }

    /// Debug builds only: launch with PURRCH_FORCE_PILL=1 to preview the fake notch.
    private static var forceFakeNotch: Bool {
        #if DEBUG
        ProcessInfo.processInfo.environment["PURRCH_FORCE_PILL"] == "1"
        #else
        false
        #endif
    }

    private static func make(screen: NSScreen, notch: CGRect, fake: Bool,
                             maxLeftWing: CGFloat, maxRightWing: CGFloat, chairSize: Int) -> NotchLayout {
        let scale = screen.backingScaleFactor
        let chairHeight = CGFloat(chairSize * Tuning.devicePixelsPerSpritePixel) / scale
        let hoverHeight = Tuning.hoverGapBelowNotch + chairHeight + Tuning.hoverBottomPadding + Tuning.hoverHeadroom
        // The notch edges can fall on half points (e.g. x = 663.5) but windows can't, so the
        // window is rounded out to whole points and the notch placed exactly inside it.
        let minX = (notch.minX - max(maxLeftWing, Tuning.hoverSideGrow)).rounded(.down)
        let maxX = (notch.maxX + max(maxRightWing, Tuning.hoverSideGrow)).rounded(.up)
        let height = (notch.height + hoverHeight).rounded(.up)
        let frame = CGRect(x: minX, y: screen.frame.maxY - height, width: maxX - minX, height: height)
        let notchInWindow = CGRect(x: notch.minX - minX, y: height - notch.height, width: notch.width, height: notch.height)
        let expanded = CGRect(x: notchInWindow.minX - Tuning.hoverSideGrow, y: 0,
                              width: notch.width + Tuning.hoverSideGrow * 2, height: height)
        return NotchLayout(
            windowFrame: frame,
            notch: notchInWindow,
            expanded: expanded,
            pointsPerSpritePixel: CGFloat(Tuning.devicePixelsPerSpritePixel) / scale,
            backingScale: scale,
            isFakeNotch: fake)
    }
}

extension NSScreen {
    /// The notch's rectangle in screen coordinates, or nil if this screen has no notch.
    /// Built from the safe-area inset (notch height) and the two menu bar areas either
    /// side of the notch, so it is exact on both 14" and 16" MacBook Pros.
    var notchRect: CGRect? {
        guard safeAreaInsets.top > 0,
              let left = auxiliaryTopLeftArea,
              let right = auxiliaryTopRightArea
        else { return nil }
        let minX = frame.minX + left.width
        let maxX = frame.maxX - right.width
        guard maxX > minX else { return nil }
        let height = safeAreaInsets.top
        return CGRect(x: minX, y: frame.maxY - height, width: maxX - minX, height: height)
    }
}
