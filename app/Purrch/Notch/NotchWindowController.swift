import AppKit

/// Creates the notch window, puts the scene view in it, moves it whenever the displays
/// change (monitor plugged in, resolution changed, lid closed), and tells the pet when the
/// mouse hovers over the notch.
@MainActor
final class NotchWindowController {
    private let panel = NotchPanel()
    private let sceneView: NotchSceneView
    private let sprites: SpriteLibrary
    private let pet: PetController
    private var screenObserver: NSObjectProtocol?
    private var hoverTimer: Timer?
    private var isHovered = false
    /// The widest the game or the hungry routines ever make each wing, so the window can always fit it.
    private let maxLeftWing: CGFloat
    private let maxRightWing: CGFloat

    init(pet: PetController, sprites: SpriteLibrary) {
        self.sprites = sprites
        self.pet = pet
        sceneView = NotchSceneView(sprites: sprites)
        panel.contentView = sceneView

        let segments = sprites.play.segments + sprites.hungry.routines.values.flatMap(\.segments)
        let wings = segments.map(\.wings)
        maxLeftWing = CGFloat(wings.flatMap { [$0.left.from, $0.left.to] }.max() ?? 0)
        maxRightWing = CGFloat(wings.flatMap { [$0.right.from, $0.right.to] }.max() ?? 0)

        sceneView.onCatClick = { [weak pet] in pet?.pet() }
        sceneView.onBallGrab = { [weak pet] in pet?.grabBall() }
        sceneView.onBallMove = { [weak pet] x, y in pet?.moveBall(x: x, y: y) }
        sceneView.onBallDrop = { [weak pet] in pet?.dropBall() }
        pet.onSceneChange = { [weak self] scene, catID in
            self?.sceneView.show(scene, catID: catID)
        }
        sceneView.show(pet.scene, catID: pet.catID)

        screenObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification, object: nil, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.screensChanged() }
        }
    }

    func show() {
        reposition()
        panel.orderFrontRegardless()
        startHoverChecks()
    }

    // MARK: - Hover

    /// The panel lets every click through, so it never gets mouse-entered events. Instead the
    /// mouse position is checked a few times a second: cheap, and needs no permissions.
    private func startHoverChecks() {
        guard hoverTimer == nil else { return }
        let timer = Timer(timeInterval: 1.0 / Tuning.hoverChecksPerSecond, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.checkHover() }
        }
        RunLoop.main.add(timer, forMode: .common)
        hoverTimer = timer
    }

    private func checkHover() {
        guard let layout = sceneView.layout, panel.isVisible else { return }
        let origin = panel.frame.origin
        // Opens over the notch; once open, stays open while the mouse is anywhere on the grown shape.
        let zone = (isHovered ? layout.expanded : layout.notch).offsetBy(dx: origin.x, dy: origin.y)
        // The mouse can sit on the screen's very top row, which `contains` treats as outside.
        let hovered = zone.insetBy(dx: 0, dy: -1).contains(NSEvent.mouseLocation)
        guard hovered != isHovered else { return }
        isHovered = hovered
        // Clicks only land on the panel while the hover view is open (to pet the cat);
        // otherwise they pass straight through to the menu bar.
        panel.ignoresMouseEvents = !hovered
        if !hovered { NSCursor.arrow.set() }
        pet.setHovered(hovered)
    }

    private func screensChanged() {
        reposition()
        // Safe-area values can settle a moment after the change is announced; check again.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            MainActor.assumeIsolated { self?.reposition() }
        }
    }

    private func reposition() {
        guard let layout = NotchLayout.current(maxLeftWing: maxLeftWing, maxRightWing: maxRightWing,
                                               frameHeight: sprites.play.frameHeight,
                                               chairSize: sprites.chair.size) else {
            panel.orderOut(nil)
            return
        }
        if panel.frame != layout.windowFrame {
            panel.setFrame(layout.windowFrame, display: false)
        }
        sceneView.layout = layout
        pet.notchHalfWidth = Double(layout.notch.width / 2)
        if !panel.isVisible { panel.orderFrontRegardless() }
        #if DEBUG
        NSLog("[Purrch] window %@ notch-in-window %@ fake=%d",
              NSStringFromRect(panel.frame), NSStringFromRect(layout.notch), layout.isFakeNotch ? 1 : 0)
        #endif
    }
}
