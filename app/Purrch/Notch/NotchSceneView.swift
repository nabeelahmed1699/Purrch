import AppKit

/// Draws one PlayScene with Core Animation layers:
///   - a black shape: the notch plus its wings, exactly notch height, rounded bottom corners
///   - the ball, the cat, the bowl and any floating "meow"s, masked to the wings only — so
///     anything inside the notch's width is hidden, like the real hardware (the notch has no
///     pixels). That's the "tunnel".
///   - while hovered (scene.chairFrame set): the shape grows sideways and down, and the big
///     chair cat sits in the new space below the notch. This is the only time the shape is
///     taller than the notch (see CLAUDE.md). Clicking the chair cat pets it: hearts float
///     up, and the pointer over it is a pixel-art hand. The cat's bed stands on the floor
///     left of the chair; while the cat naps in it, "z"s float up. The ball always lies
///     somewhere on the floor: the hand picks it up, and drag and let go throws it.
/// The window is taller than the notch to make room for the hover view; the notch sits at its
/// top, so everything else is drawn up from `notch.minY`.
/// Sprites are drawn 1:1 in screen pixels with nearest-neighbour filtering: no blur.
final class NotchSceneView: NSView {
    private let sprites: SpriteLibrary
    private let root = CALayer()
    private let shape = CAShapeLayer()
    private let content = CALayer()
    private let contentMask = CAShapeLayer()
    private let ballLayer = CALayer()
    private let catLayer = CALayer()
    private let bowlLayer = CALayer()
    /// Enough for every "meow" that can float at once (the routines overlap two).
    private let soundLayers = (0..<3).map { _ in CALayer() }
    /// The chair cat, clipped to the black shape so it never shows outside it while growing.
    private let chairContent = CALayer()
    private let chairMask = CAShapeLayer()
    private let chairLayer = CALayer()
    /// The cat once it has hopped off the chair, drawn at chair-cat size.
    private let wandererLayer = CALayer()
    /// The one ball: picked up and thrown with the hand.
    private let toyLayer = CALayer()
    /// The hungry cat's "meow"s and the eating cat's bowl, in the hover view.
    private let hoverSoundLayers = (0..<3).map { _ in CALayer() }
    private let hoverBowlLayer = CALayer()
    /// Enough for a few quick clicks' worth of hearts.
    private let heartLayers = (0..<8).map { _ in CALayer() }
    /// The bed: its back behind the cat, its front over the cat while it sleeps in it.
    private let bedBackLayer = CALayer()
    private let bedFrontLayer = CALayer()
    /// Enough for every "z" floating at once.
    private let zLayers = (0..<3).map { _ in CALayer() }

    /// Called when the cat is clicked (pet it). Set by the notch window.
    var onCatClick: (() -> Void)?
    /// The hand picked the ball up, moved it (x in points from the notch centre, y up from the
    /// floor), and let go of it (velocity in points per second, + = right, up). Set by the
    /// notch window.
    var onBallGrab: (() -> Void)?
    var onBallMove: ((Double, Double) -> Void)?
    var onBallRelease: ((Double, Double) -> Void)?
    private lazy var openHand = makeCursor("open")
    private lazy var strokeHand = makeCursor("stroke")
    private var isPressing = false
    /// Holding the ball: where the pointer is on it (from its middle), and the last few
    /// pointer positions, to fling it with the hand's speed when let go.
    private var ballGrip: CGPoint?
    private var dragTrail: [(time: TimeInterval, point: CGPoint)] = []

    var layout: NotchLayout? {
        didSet { if layout != oldValue { redraw() } }
    }
    private var scene = PlayScene.empty
    private var catID = ""
    /// How far the hover view has grown: 0 = collapsed, 1 = fully open. Animated.
    private var expansion = 0.0
    private var expansionTimer: Timer?
    private var lastExpansionTick = 0.0
    /// The chair cat's last frame, kept on screen while the shape shrinks away.
    private var lastChairFrame = 0
    private var lastWanderer: Wanderer.Pose?
    private var lastCatInBed = false

    init(sprites: SpriteLibrary) {
        self.sprites = sprites
        super.init(frame: .zero)

        // A "layer-hosting" view: we own the layer tree and AppKit leaves it alone.
        // Coordinates: origin at the bottom left, in points.
        layer = root
        wantsLayer = true

        shape.fillColor = NSColor.black.cgColor
        content.mask = contentMask
        chairContent.mask = chairMask
        for sprite in [ballLayer, catLayer, bowlLayer] + soundLayers + [chairLayer, wandererLayer, toyLayer, hoverBowlLayer]
            + hoverSoundLayers + heartLayers + [bedBackLayer, bedFrontLayer] + zLayers {
            sprite.magnificationFilter = .nearest
            sprite.minificationFilter = .nearest
            sprite.contentsGravity = .resize
        }
        for sprite in [ballLayer, catLayer, bowlLayer] + soundLayers {
            content.addSublayer(sprite)
        }
        chairContent.addSublayer(chairLayer)
        chairContent.addSublayer(wandererLayer)
        chairContent.addSublayer(toyLayer)
        chairContent.addSublayer(hoverBowlLayer)
        hoverSoundLayers.forEach(chairContent.addSublayer)
        heartLayers.forEach(chairContent.addSublayer)
        chairContent.addSublayer(bedBackLayer)
        chairContent.addSublayer(bedFrontLayer)
        zLayers.forEach(chairContent.addSublayer)
        root.addSublayer(shape)
        root.addSublayer(content)
        root.addSublayer(chairContent)

        // No implicit fades or slides: every change shows up exactly on the next frame.
        let layers = [shape, content, contentMask, ballLayer, catLayer, bowlLayer] + soundLayers
            + [chairContent, chairMask, chairLayer, wandererLayer, toyLayer, hoverBowlLayer] + hoverSoundLayers + heartLayers
            + [bedBackLayer, bedFrontLayer] + zLayers
        for l in layers {
            l.actions = ["contents": NSNull(), "position": NSNull(), "bounds": NSNull(),
                         "path": NSNull(), "hidden": NSNull(), "frame": NSNull(), "opacity": NSNull()]
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not used") }

    func show(_ scene: PlayScene, catID: String) {
        self.scene = scene
        self.catID = catID
        // Kept from the last hovered scene, so the view still has something to show while it shrinks.
        if let frame = scene.chairFrame {
            lastChairFrame = frame
            lastWanderer = scene.wanderer
            lastCatInBed = scene.catInBed
        }
        let target = scene.chairFrame == nil ? 0.0 : 1.0
        // Closed: the hand let go of the ball (the pet drops it).
        if target == 0 { ballGrip = nil }
        if expansion != target { startExpansionAnimation() }
        redraw()
    }

    // MARK: - Hover grow / shrink

    private func startExpansionAnimation() {
        guard expansionTimer == nil else { return }
        lastExpansionTick = CACurrentMediaTime()
        let timer = Timer(timeInterval: 1.0 / Tuning.playFramesPerSecond, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.stepExpansion() }
        }
        RunLoop.main.add(timer, forMode: .common)
        expansionTimer = timer
    }

    private func stepExpansion() {
        let now = CACurrentMediaTime()
        let step = min(now - lastExpansionTick, 0.1) / Tuning.hoverAnimationSeconds
        lastExpansionTick = now
        let target = scene.chairFrame == nil ? 0.0 : 1.0
        expansion = target > expansion ? min(expansion + step, target) : max(expansion - step, target)
        if expansion == target {
            expansionTimer?.invalidate()
            expansionTimer = nil
        }
        redraw()
    }

    // MARK: - Drawing

    private func redraw() {
        guard let layout else { return }
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        defer { CATransaction.commit() }

        let notch = layout.notch
        let base = notch.minY // bottom edge of the notch-height strip
        let scale = layout.backingScale
        let px = layout.pointsPerSpritePixel
        let snap = { (v: CGFloat) in (v * scale).rounded() / scale }

        content.frame = bounds
        chairContent.frame = bounds
        for l in [shape, contentMask, chairMask] as [CALayer] { l.contentsScale = scale }

        // Black shape: notch + wings, same height as the notch — or, while hovered, grown
        // towards `layout.expanded`.
        let left = notch.minX - CGFloat(scene.leftWing)
        let right = notch.maxX + CGFloat(scene.rightWing)
        let hasWings = scene.leftWing > 0 || scene.rightWing > 0
        let e = CGFloat(Self.smooth(expansion))
        let lerp = { (a: CGFloat, b: CGFloat) in a + (b - a) * e }
        let shapeLeft = snap(lerp(left, layout.expanded.minX))
        let shapeRight = snap(lerp(right, layout.expanded.maxX))
        let shapeBottom = snap(lerp(base, layout.expanded.minY))
        let radius = lerp(Tuning.shapeCornerRadius, Tuning.hoverCornerRadius)
        // A real notch needs no drawing at rest (it's black hardware); a fake one always shows.
        shape.isHidden = !hasWings && !layout.isFakeNotch && expansion == 0
        let path = Self.shapePath(left: shapeLeft, right: shapeRight, bottom: shapeBottom, top: notch.maxY, radius: radius)
        shape.path = path

        // The wing scene only shows while collapsed; the hover view replaces it.
        content.isHidden = expansion > 0
        drawWingScene(notch: notch, base: base, px: px, scale: scale, snap: snap, left: left, right: right)

        // Chair cat: centred under the notch, standing on the grown shape's bottom padding.
        // Its top is at or below the notch's bottom, so none of it is lost to the notch.
        chairMask.path = path
        let chairImage = lastWanderer == nil
            ? sprites.chairFrame(cat: catID, index: lastChairFrame)
            : sprites.emptyChair(cat: catID)
        if expansion > 0, let image = chairImage {
            let size = CGFloat(sprites.chair.size) * px
            chairLayer.contents = image
            chairLayer.contentsScale = scale
            chairLayer.frame = CGRect(x: snap(notch.midX - size / 2),
                                      y: snap(layout.expanded.minY + Tuning.hoverBottomPadding),
                                      width: size, height: size)
            // Fades in over the second half of the grow, out over the first half of the shrink.
            chairLayer.opacity = Float(max(0, (expansion - 0.5) / 0.5))
            chairContent.isHidden = false
        } else {
            chairContent.isHidden = true
        }
        drawWanderer(layout: layout, px: px, scale: scale, snap: snap)
        drawToy(layout: layout, px: px, scale: scale, snap: snap)
        drawHoverHunger(layout: layout, px: px, scale: scale, snap: snap)
        drawBed(layout: layout, px: px, scale: scale, snap: snap)

        // Hearts from petting, in the hover view's space (never up in the notch).
        for (i, layer) in heartLayers.enumerated() {
            guard expansion == 1, i < scene.hearts.count, let image = sprites.heartImage else {
                layer.isHidden = true
                continue
            }
            let heart = scene.hearts[i]
            let width = CGFloat(image.width) * px
            let height = CGFloat(image.height) * px
            let y = min(snap(layout.expanded.minY + CGFloat(heart.y)), notch.minY - height)
            layer.contents = image
            layer.contentsScale = scale
            layer.frame = CGRect(x: snap(notch.midX + CGFloat(heart.x) - width / 2), y: y, width: width, height: height)
            layer.opacity = Float(heart.opacity)
            layer.zPosition = 3
            layer.isHidden = false
        }
    }

    /// The wandering cat: side-view (and facing-you) frames blown up to chair-cat size, standing
    /// on the same floor as the chair. Side-view frames have a little space under the paws,
    /// so they're lowered by that much to stand on the floor too.
    private func drawWanderer(layout: NotchLayout, px: CGFloat, scale: CGFloat, snap: (CGFloat) -> CGFloat) {
        // Sitting frames come in HD: same size on screen, one sprite pixel per screen pixel.
        guard expansion > 0, let pose = lastWanderer,
              let image = sprites.hdCatFrame(cat: catID, frame: pose.frame, facingLeft: pose.facingLeft)
                ?? sprites.catFrame(cat: catID, frame: pose.frame, facingLeft: pose.facingLeft) else {
            wandererLayer.isHidden = true
            return
        }
        let k = CGFloat(sprites.wander.pixelScale) * px
        let width = CGFloat(sprites.play.frameWidth) * k
        let height = CGFloat(sprites.play.frameHeight) * k
        let sink = pose.frame.hasPrefix("front") ? 0 : CGFloat(sideViewSink) * k
        let y = layout.expanded.minY + Tuning.hoverBottomPadding + CGFloat(pose.y) - sink
        // Never up into the notch: it has no pixels, and the cat would look cut off.
        let top = min(y + height, layout.notch.minY + (height - visibleHeight(pose.frame) * k))
        wandererLayer.contents = image
        wandererLayer.contentsScale = scale
        wandererLayer.frame = CGRect(x: snap(layout.notch.midX + CGFloat(pose.x) - width / 2), y: snap(top - height),
                                     width: width, height: height)
        wandererLayer.opacity = chairLayer.opacity
        // Depth: the chair is at 0; in front of it +1, behind it -1 (it shows through the slats).
        wandererLayer.zPosition = pose.behindChair ? -1 : 1
        wandererLayer.isHidden = false
    }

    /// The thrown ball, at the wandering cat's scale, sitting on (or bouncing above) the floor.
    private func drawToy(layout: NotchLayout, px: CGFloat, scale: CGFloat, snap: (CGFloat) -> CGFloat) {
        guard expansion == 1, let toy = scene.toy, let image = sprites.ballFrame(toy.roll) else {
            toyLayer.isHidden = true
            return
        }
        let size = CGFloat(sprites.play.ball.size * sprites.wander.ball.pixelScale) * px
        let y = min(floorY(layout) + CGFloat(toy.y), layout.notch.minY - size)
        toyLayer.contents = image
        toyLayer.contentsScale = scale
        toyLayer.frame = CGRect(x: snap(layout.notch.midX + CGFloat(toy.x) - size / 2), y: snap(y), width: size, height: size)
        // In the hand: in front of everything. Otherwise on the same side of the chair as the
        // cat: in front of the cat only while pinned under its paws, otherwise just behind it
        // (so the cat walks in front of it).
        toyLayer.zPosition = toy.isInHand ? 4 : (toy.behindChair ? -1 : 1) + (toy.isHeld ? 0.5 : -0.5)
        toyLayer.isHidden = false
    }

    /// The hungry cat's "meow"s and the eating cat's bowl, at the wandering cat's scale. The
    /// "meow"s stay below the notch.
    private func drawHoverHunger(layout: NotchLayout, px: CGFloat, scale: CGFloat, snap: (CGFloat) -> CGFloat) {
        let floor = floorY(layout)
        if expansion == 1, let x = scene.hoverBowlX, let image = sprites.bowlFrame("full") {
            let k = CGFloat(sprites.wander.pixelScale) * px
            let width = CGFloat(sprites.hungry.bowl.width) * k
            let height = CGFloat(sprites.hungry.bowl.height) * k
            hoverBowlLayer.contents = image
            hoverBowlLayer.contentsScale = scale
            hoverBowlLayer.frame = CGRect(x: snap(layout.notch.midX + CGFloat(x) - width / 2), y: floor,
                                          width: width, height: height)
            hoverBowlLayer.zPosition = 1 // in front of the cat
            hoverBowlLayer.isHidden = false
        } else {
            hoverBowlLayer.isHidden = true
        }
        for (i, layer) in hoverSoundLayers.enumerated() {
            guard expansion == 1, i < scene.hoverSounds.count, let image = sprites.meowImage else {
                layer.isHidden = true
                continue
            }
            let sound = scene.hoverSounds[i]
            let k = CGFloat(sprites.wander.hungry.textScale) * px
            let width = CGFloat(image.width) * k
            let height = CGFloat(image.height) * k
            let y = min(floor + CGFloat(sound.y), layout.notch.minY - height)
            layer.contents = image
            layer.contentsScale = scale
            layer.frame = CGRect(x: snap(layout.notch.midX + CGFloat(sound.x) - width / 2), y: snap(y),
                                 width: width, height: height)
            layer.opacity = Float(sound.opacity)
            layer.zPosition = 2
            layer.isHidden = false
        }
    }

    /// The bed, at the wandering cat's scale, always on the hover view's floor. While the cat
    /// sleeps in it, its front covers the cat's paws and "z"s float up (kept below the notch).
    private func drawBed(layout: NotchLayout, px: CGFloat, scale: CGFloat, snap: (CGFloat) -> CGFloat) {
        let bed = sprites.sleep.bed
        let k = CGFloat(sprites.wander.pixelScale) * px
        let width = CGFloat(bed.width) * k
        let frame = CGRect(x: snap(layout.notch.midX + CGFloat(bed.x) - width / 2), y: floorY(layout),
                           width: width, height: CGFloat(bed.height) * k)
        // Depth: behind a cat in front of the chair (+1), in front of one behind it (-1).
        for (layer, image, isShown, depth) in [(bedBackLayer, sprites.bedBackImage, true, -0.5),
                                               (bedFrontLayer, sprites.bedFrontImage, lastCatInBed, 1.5)] {
            guard expansion > 0, isShown, let image else {
                layer.isHidden = true
                continue
            }
            layer.contents = image
            layer.contentsScale = scale
            layer.frame = frame
            layer.opacity = chairLayer.opacity
            layer.zPosition = CGFloat(depth)
            layer.isHidden = false
        }
        for (i, layer) in zLayers.enumerated() {
            guard expansion == 1, i < scene.sleepZs.count, let image = sprites.zImage else {
                layer.isHidden = true
                continue
            }
            let z = scene.sleepZs[i]
            // `size` screen pixels per "z" pixel.
            let zWidth = CGFloat(image.width * z.size) / scale
            let zHeight = CGFloat(image.height * z.size) / scale
            let y = min(snap(floorY(layout) + CGFloat(z.y)), layout.notch.minY - zHeight)
            layer.contents = image
            layer.contentsScale = scale
            layer.frame = CGRect(x: snap(layout.notch.midX + CGFloat(z.x) - zWidth / 2), y: y, width: zWidth, height: zHeight)
            layer.opacity = Float(z.opacity)
            layer.zPosition = 2
            layer.isHidden = false
        }
    }

    /// The hover view's floor: where the chair stands.
    private func floorY(_ layout: NotchLayout) -> CGFloat {
        layout.expanded.minY + Tuning.hoverBottomPadding
    }

    /// Empty rows under the paws of the side-view standing frame, in sprite pixels.
    private lazy var sideViewSink: Int = {
        guard let stand = sprites.play.frames["stand"] else { return 0 }
        return sprites.play.frameHeight - (stand.y + stand.rows.count)
    }()

    /// How tall a frame's drawing is from the frame's bottom edge, in sprite pixels.
    private func visibleHeight(_ frame: String) -> CGFloat {
        guard let grid = sprites.play.frames[frame] else { return CGFloat(sprites.play.frameHeight) }
        return CGFloat(sprites.play.frameHeight - grid.y)
    }

    // MARK: - Petting: clicks and the hand cursor
    //
    // The panel only takes mouse events while the hover view is open (NotchWindowController).

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        trackingAreas.forEach(removeTrackingArea)
        // activeAlways: Purrch is never the active app, but the cursor should still change.
        addTrackingArea(NSTrackingArea(rect: .zero, options: [.mouseMoved, .mouseEnteredAndExited, .cursorUpdate,
                                                              .activeAlways, .inVisibleRect],
                                       owner: self))
    }

    override func mouseEntered(with event: NSEvent) { updateCursor(event) }
    override func mouseMoved(with event: NSEvent) { updateCursor(event) }
    override func cursorUpdate(with event: NSEvent) { updateCursor(event) }
    override func mouseDragged(with event: NSEvent) {
        if ballGrip != nil { carryBall(event) }
        updateCursor(event)
    }

    override func mouseExited(with event: NSEvent) {
        isPressing = false
        NSCursor.arrow.set()
    }

    override func mouseDown(with event: NSEvent) {
        // The ball is small and lies in front: it gets the click first.
        if isOverBall(event) { return grabBall(event) }
        guard isOverCat(event) else { return }
        isPressing = true
        updateCursor(event)
        onCatClick?()
    }

    override func mouseUp(with event: NSEvent) {
        if ballGrip != nil { releaseBall(event) }
        isPressing = false
        updateCursor(event)
    }

    // MARK: - The ball: pick it up, carry it, throw it

    private var ballSize: CGFloat {
        CGFloat(sprites.play.ball.size * sprites.wander.ball.pixelScale) * (layout?.pointsPerSpritePixel ?? 1)
    }

    private func isOverBall(_ event: NSEvent) -> Bool {
        guard expansion == 1, scene.chairFrame != nil, scene.toy != nil, !toyLayer.isHidden else { return false }
        // A little bigger than the ball: it's tiny.
        return toyLayer.frame.insetBy(dx: -6, dy: -6).contains(convert(event.locationInWindow, from: nil))
    }

    private func grabBall(_ event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        ballGrip = CGPoint(x: point.x - toyLayer.frame.midX, y: point.y - toyLayer.frame.midY)
        dragTrail = [(event.timestamp, point)]
        isPressing = true
        onBallGrab?()
        updateCursor(event)
    }

    /// The ball follows the hand, kept inside the hover view below the notch.
    private func carryBall(_ event: NSEvent) {
        guard let layout, let grip = ballGrip else { return }
        let point = convert(event.locationInWindow, from: nil)
        dragTrail.append((event.timestamp, point))
        dragTrail.removeAll { event.timestamp - $0.time > 0.1 }
        let floor = floorY(layout)
        let y = min(max(point.y - grip.y - ballSize / 2 - floor, 0), ballCeiling(layout))
        onBallMove?(Double(point.x - grip.x - layout.notch.midX), Double(y))
    }

    /// Let go: it flies off as fast as the hand was moving over the last moment, but never so
    /// high that it would go up into the notch.
    private func releaseBall(_ event: NSEvent) {
        guard let layout else { return }
        let point = convert(event.locationInWindow, from: nil)
        var velocity = CGVector.zero
        if let first = dragTrail.first, event.timestamp - first.time > 0.01 {
            let dt = event.timestamp - first.time
            velocity = CGVector(dx: (point.x - first.point.x) / dt, dy: (point.y - first.point.y) / dt)
        }
        let height = max(0, ballCeiling(layout) - (toyLayer.frame.minY - floorY(layout)))
        let maxUp = (2 * sprites.wander.ball.gravity * Double(height)).squareRoot()
        ballGrip = nil
        dragTrail = []
        onBallRelease?(Double(velocity.dx), min(Double(velocity.dy), maxUp))
    }

    /// The highest the ball's bottom can be above the floor without reaching into the notch.
    private func ballCeiling(_ layout: NotchLayout) -> CGFloat {
        layout.notch.minY - floorY(layout) - ballSize
    }

    /// The hand over the cat or the ball (closed while pressing or holding the ball), the
    /// normal arrow anywhere else.
    private func updateCursor(_ event: NSEvent) {
        if ballGrip != nil {
            strokeHand.set()
        } else if isOverBall(event) || isOverCat(event) {
            (isPressing ? strokeHand : openHand).set()
        } else {
            NSCursor.arrow.set()
        }
    }

    private func isOverCat(_ event: NSEvent) -> Bool {
        guard expansion == 1, scene.chairFrame != nil else { return false }
        let point = convert(event.locationInWindow, from: nil)
        if scene.wanderer != nil {
            // The frame has room around the cat; only count the middle of it.
            let f = wandererLayer.frame
            return f.insetBy(dx: f.width * 0.2, dy: 0).divided(atDistance: f.height * 0.75, from: .minYEdge).slice
                .contains(point)
        }
        return chairLayer.frame.contains(point)
    }

    private func makeCursor(_ name: String) -> NSCursor {
        let spec = sprites.petting.cursor
        // Built at 4 image pixels per cursor pixel, so it stays sharp on Retina screens.
        let detail = 4
        guard let image = sprites.cursorImage(name, scale: detail) else { return .arrow }
        let points = CGFloat(spec.pointsPerPixel)
        let size = NSSize(width: CGFloat(image.width / detail) * points, height: CGFloat(image.height / detail) * points)
        let nsImage = NSImage(size: size)
        nsImage.addRepresentation(NSBitmapImageRep(cgImage: image))
        nsImage.representations.forEach { $0.size = size }
        let hotSpot = NSPoint(x: (CGFloat(spec.hotSpot[0]) + 0.5) * points, y: (CGFloat(spec.hotSpot[1]) + 0.5) * points)
        return NSCursor(image: nsImage, hotSpot: hotSpot)
    }

    private func drawWingScene(notch: CGRect, base: CGFloat, px: CGFloat, scale: CGFloat,
                               snap: (CGFloat) -> CGFloat, left: CGFloat, right: CGFloat) {
        // Only the wings show content; the notch's own width is the tunnel.
        let mask = CGMutablePath()
        mask.addRect(CGRect(x: snap(left), y: base, width: snap(notch.minX - left), height: notch.height))
        mask.addRect(CGRect(x: notch.maxX, y: base, width: snap(right - notch.maxX), height: notch.height))
        contentMask.path = mask

        // Cat: its 80 x 64 px frame stands on the bottom edge, centred on scene.cat.x.
        if let cat = scene.cat,
           let image = sprites.catFrame(cat: catID, frame: cat.frame, facingLeft: cat.facingLeft) {
            let width = CGFloat(sprites.play.frameWidth) * px
            let height = CGFloat(sprites.play.frameHeight) * px
            catLayer.contents = image
            catLayer.contentsScale = scale
            catLayer.frame = CGRect(x: snap(notch.midX + CGFloat(cat.x) - width / 2), y: base, width: width, height: height)
            catLayer.isHidden = false
        } else {
            catLayer.isHidden = true
        }

        // Ball: rolls along 1 pt above the bottom edge.
        if let ball = scene.ball, let image = sprites.ballFrame(ball.roll) {
            let size = CGFloat(sprites.play.ball.size) * px
            ballLayer.contents = image
            ballLayer.contentsScale = scale
            ballLayer.frame = CGRect(x: snap(notch.midX + CGFloat(ball.x) - size / 2), y: base + 1, width: size, height: size)
            ballLayer.isHidden = false
        } else {
            ballLayer.isHidden = true
        }

        // Bowl: sits on the bottom edge, in front of the cat.
        if let bowl = scene.bowl, let image = sprites.bowlFrame(bowl.frame) {
            let width = CGFloat(sprites.hungry.bowl.width) * px
            let height = CGFloat(sprites.hungry.bowl.height) * px
            bowlLayer.contents = image
            bowlLayer.contentsScale = scale
            bowlLayer.frame = CGRect(x: snap(notch.midX + CGFloat(bowl.x) - width / 2), y: base, width: width, height: height)
            bowlLayer.isHidden = false
        } else {
            bowlLayer.isHidden = true
        }

        // Floating "meow"s. Kept inside the notch's height (see CLAUDE.md).
        for (i, layer) in soundLayers.enumerated() {
            guard i < scene.sounds.count, let image = sprites.meowImage else {
                layer.isHidden = true
                continue
            }
            let sound = scene.sounds[i]
            let width = CGFloat(image.width) * px
            let height = CGFloat(image.height) * px
            let y = base + min(snap(CGFloat(sound.y)), notch.height - height)
            layer.contents = image
            layer.contentsScale = scale
            layer.frame = CGRect(x: snap(notch.midX + CGFloat(sound.x) - width / 2), y: y, width: width, height: height)
            layer.opacity = Float(sound.opacity)
            layer.isHidden = false
        }
    }

    /// Smoothstep: eases in and out of the grow.
    private static func smooth(_ t: Double) -> Double {
        t * t * (3 - 2 * t)
    }

    /// Flat top (flush with the screen edge), straight sides, rounded bottom corners.
    private static func shapePath(left: CGFloat, right: CGFloat, bottom: CGFloat, top: CGFloat,
                                  radius: CGFloat) -> CGPath {
        let r = min(radius, (top - bottom) / 2, (right - left) / 2)
        let path = CGMutablePath()
        path.move(to: CGPoint(x: left, y: top))
        path.addLine(to: CGPoint(x: right, y: top))
        path.addLine(to: CGPoint(x: right, y: bottom + r))
        path.addQuadCurve(to: CGPoint(x: right - r, y: bottom), control: CGPoint(x: right, y: bottom))
        path.addLine(to: CGPoint(x: left + r, y: bottom))
        path.addQuadCurve(to: CGPoint(x: left, y: bottom + r), control: CGPoint(x: left, y: bottom))
        path.closeSubpath()
        return path
    }
}
