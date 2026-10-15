import Foundation
import Observation
import QuartzCore

/// The pet's single source of truth: which cat, what it's doing, and whether it's paused.
/// The menu reads and changes it; the notch view gets each new scene through `onSceneChange`.
/// (Think: a small store.)
@MainActor
@Observable
final class PetController {
    let cats: [CatSpec]

    /// The chosen cat. Saved, so it survives a restart.
    var catID: String {
        didSet {
            UserDefaults.standard.set(catID, forKey: Self.catDefaultsKey)
            onSceneChange?(scene, catID)
        }
    }

    private(set) var state: PetState = .resting {
        didSet { if state != oldValue { stateChanges &+= 1 } }
    }
    private(set) var isPausedByUser = false

    /// Sound effects on or off, and how loud. Saved.
    var soundEnabled: Bool {
        didSet {
            UserDefaults.standard.set(soundEnabled, forKey: Self.soundEnabledKey)
            sound.isEnabled = soundEnabled
        }
    }
    var soundVolume: SoundVolume {
        didSet {
            UserDefaults.standard.set(soundVolume.rawValue, forKey: Self.soundVolumeKey)
            sound.volume = soundVolume.level
        }
    }

    enum SoundVolume: String, CaseIterable, Identifiable {
        case low, medium, high
        var id: Self { self }
        var level: Float {
            switch self {
            case .low: 0.3
            case .medium: 0.6
            case .high: 1
            }
        }
    }

    /// Called with every new scene (and the cat to draw it with). Set by the notch window.
    @ObservationIgnored var onSceneChange: ((PlayScene, String) -> Void)?
    /// The current scene. Not observed by SwiftUI: it changes 60 times a second while animating.
    @ObservationIgnored private(set) var scene = PlayScene.empty
    @ObservationIgnored private let sound = SoundPlayer()
    /// When the notch last meowed: out there it only meows now and then.
    @ObservationIgnored private var lastNotchMeow = Date.distantPast

    @ObservationIgnored private let play: PlayData
    @ObservationIgnored private let hungry: HungryData
    @ObservationIgnored private let chair: ChairData
    @ObservationIgnored private let petting: PettingData
    @ObservationIgnored private let sleep: SleepData
    /// Petting, in chair-clock ms: when the current petting began and ends, and every click
    /// still floating hearts.
    @ObservationIgnored private var petStart = 0.0
    @ObservationIgnored private var petUntil = 0.0
    /// Each click: when, and where the cat was (hearts float up around it).
    @ObservationIgnored private var petClicks: [(time: Double, x: Double, y: Double)] = []
    /// Once the cat has hopped off the chair (hover held a moment without petting).
    @ObservationIgnored private let wander: WanderData
    @ObservationIgnored private var wanderer: Wanderer?
    @ObservationIgnored private var lastPose: Wanderer.Pose?
    /// The ball thrown in the hover view, and when it was last moved on (chair clock, ms).
    @ObservationIgnored private var ballToy: BallToy?
    /// Which side of the chair the ball is on: wherever the cat last played with it.
    @ObservationIgnored private var ballBehindChair = false
    @ObservationIgnored private var lastBallStep = 0.0
    /// True while the mouse is over the notch: the chair cat shows and everything else waits.
    @ObservationIgnored private var isHovered = false
    @ObservationIgnored private var chairTime = 0.0
    /// Bumped on every state change. The hover view left behind on mouse-out is picked up
    /// again on the next hover only if nothing changed in between (`stateChangesAtHoverEnd`).
    @ObservationIgnored private var stateChanges = 0
    @ObservationIgnored private var stateChangesAtHoverEnd: Int?
    /// The mouse left while the cat was off the chair, wandering: it carries on out in the
    /// notch-height wings (sounds and all) until it's back inside the notch.
    @ObservationIgnored private var roamsOutside = false
    /// The last hover-view scene while roaming, so its sounds still play (`playSounds`).
    @ObservationIgnored private var roamScene = PlayScene.empty
    /// The wings while roaming, eased open on whichever side the cat (or ball) is.
    @ObservationIgnored private var roamWings = (left: 0.0, right: 0.0)
    /// Half the notch's width in points (set by the notch window): where the wings begin.
    @ObservationIgnored var notchHalfWidth = Tuning.fakeNotchWidth / 2
    /// True while the screen is asleep or the Mac is locked.
    @ObservationIgnored private var isSystemPaused = false
    /// What's animating right now (the ball game or a hungry routine), and what comes after it.
    @ObservationIgnored private var routine: Routine?
    @ObservationIgnored private var routineName = ""
    @ObservationIgnored private var routineTime = 0.0
    @ObservationIgnored private var afterRoutine: (() -> Void)?
    @ObservationIgnored private var clock: Timer?
    @ObservationIgnored private var lastTick = 0.0
    @ObservationIgnored private var nextGame: DispatchWorkItem?
    @ObservationIgnored private var nextHunger: DispatchWorkItem?
    /// Coming out just for attention: when next, and whether it got petted this time.
    @ObservationIgnored private var nextAttention: DispatchWorkItem?
    @ObservationIgnored private var attentionAt = Date()
    @ObservationIgnored private var attentionSatisfied = false
    /// Naps: when it next falls asleep, and while asleep, when it wakes up.
    @ObservationIgnored private var nextSleep: DispatchWorkItem?
    @ObservationIgnored private var sleepAt = Date()
    @ObservationIgnored private var napUntil = Date()
    /// Stirred by the ball but not getting up: peeking, then dozing off again (hover clock, ms).
    @ObservationIgnored private var peek: (start: Double, steps: [WanderData.Step])?
    /// When the cat gets hungry next. Saved, so a restart doesn't skip a meal.
    @ObservationIgnored private var hungryAt: Date {
        didSet { UserDefaults.standard.set(hungryAt.timeIntervalSince1970, forKey: Self.hungryDefaultsKey) }
    }

    private static let catDefaultsKey = "selectedCat"
    private static let hungryDefaultsKey = "hungryAt"
    private static let soundEnabledKey = "soundEnabled"
    private static let soundVolumeKey = "soundVolume"

    init(sprites: SpriteLibrary) {
        cats = sprites.cats
        play = sprites.play
        hungry = sprites.hungry
        chair = sprites.chair
        petting = sprites.petting
        wander = sprites.wander
        sleep = sprites.sleep
        let defaults = UserDefaults.standard
        soundEnabled = defaults.object(forKey: Self.soundEnabledKey) as? Bool ?? true
        soundVolume = defaults.string(forKey: Self.soundVolumeKey).flatMap(SoundVolume.init) ?? .low
        let saved = UserDefaults.standard.string(forKey: Self.catDefaultsKey)
        catID = sprites.cats.contains { $0.id == saved } ? saved! : sprites.cats[0].id

        let savedHungryAt = UserDefaults.standard.double(forKey: Self.hungryDefaultsKey)
        hungryAt = savedHungryAt > 0
            ? Date(timeIntervalSince1970: savedHungryAt)
            : Date().addingTimeInterval(Self.randomMealGap(hungry))
        attentionAt = Date().addingTimeInterval(Self.randomAttentionGap(hungry))
        sleepAt = Date().addingTimeInterval(Self.randomSleepGap(sleep))
        #if DEBUG
        // Launch with PURRCH_SLEEP_AFTER_SECONDS=5 to see it nap in its bed (hover the notch).
        if let seconds = ProcessInfo.processInfo.environment["PURRCH_SLEEP_AFTER_SECONDS"].flatMap(Double.init) {
            sleepAt = Date().addingTimeInterval(seconds)
        }
        // Launch with PURRCH_ATTENTION_AFTER_SECONDS=5 to see it come out for attention.
        if let seconds = ProcessInfo.processInfo.environment["PURRCH_ATTENTION_AFTER_SECONDS"].flatMap(Double.init) {
            attentionAt = Date().addingTimeInterval(seconds)
        }
        // Launch with PURRCH_HUNGRY_AFTER_SECONDS=5 to see the hungry cat without waiting.
        if let seconds = ProcessInfo.processInfo.environment["PURRCH_HUNGRY_AFTER_SECONDS"].flatMap(Double.init) {
            hungryAt = Date().addingTimeInterval(seconds)
        }
        #endif
        sound.isEnabled = soundEnabled
        sound.volume = soundVolume.level
    }

    var isPaused: Bool { isPausedByUser || isSystemPaused }
    /// Paused, or hovered: nothing new starts and the current routine holds still.
    private var isOnHold: Bool { isPaused || isHovered }

    func start() {
        scheduleNextGame()
        scheduleHunger()
        scheduleAttention()
        scheduleSleep()
    }

    /// Starts a game right away (menu: "Play with the ball now"). Wakes it up if it's napping.
    func playNow() {
        if isPausedByUser { isPausedByUser = false }
        endRoaming()
        guard state == .resting || state == .sleeping, !isSystemPaused else { return }
        if state == .sleeping { endNap() }
        startGame()
    }

    /// Sends it to its bed for a nap now, or wakes it up (menu).
    func toggleNap() {
        if isPausedByUser { isPausedByUser = false }
        endRoaming()
        guard !isSystemPaused else { return }
        if state == .sleeping {
            wakeUp()
        } else if state == .resting {
            fallAsleep()
        }
    }

    /// Feeds the cat (menu: "Feed"). A hungry cat eats where it sits; a resting one comes
    /// out for the bowl. Either way it then heads back in, and the next meal is hours away.
    func feed() {
        guard state == .resting || state == .hungry || state == .attention || state == .sleeping,
              !isSystemPaused else { return }
        if isPausedByUser { isPausedByUser = false }
        endRoaming()
        // Food wakes it up; then it comes out for the bowl like a resting cat.
        if state == .sleeping { endNap() }
        hungryAt = Date().addingTimeInterval(Self.randomMealGap(hungry))
        nextHunger?.cancel()
        nextGame?.cancel()

        let wasSeated = (state == .hungry || state == .attention) && routineName != "comeOut"
        state = .eating
        if wasSeated {
            eatAndGoHome()
        } else if routine != nil {
            // Still on its way out: eat as soon as it sits down.
            afterRoutine = { [weak self] in self?.eatAndGoHome() }
        } else {
            run("comeOut") { [weak self] in self?.eatAndGoHome() }
        }
    }

    func togglePause() {
        isPausedByUser.toggle()
        pauseOrResume()
    }

    func setSystemPaused(_ paused: Bool) {
        isSystemPaused = paused
        pauseOrResume()
    }

    /// The cat in the hover view was clicked: pet it. Clicking again while petted keeps it going.
    func pet() {
        guard isHovered, !isPaused else { return }
        if state == .attention { attentionSatisfied = true }
        if chairTime >= petUntil {
            petStart = chairTime
            // Asleep, it just purrs.
            if state != .sleeping { sound.play(.chirp) }
        }
        sound.startPurr()
        petUntil = chairTime + petting.ms
        wanderer?.pet(at: chairTime, until: petUntil)
        // Hearts float around the head: side-on, that's out in front of the body.
        let headOffset: Double = lastPose.map { $0.frame.hasPrefix("front") ? 0 : ($0.facingLeft ? -18 : 18) } ?? 0
        petClicks.append((chairTime, (lastPose?.x ?? 0) + headOffset, lastPose?.y ?? 0))
        show(chairScene())
    }

    /// Empty space in the hover view was clicked: throw the ball there (x from the notch
    /// centre, y up from the floor). The cat goes after it.
    func throwBall(x: Double, y: Double) {
        guard isHovered, !isPaused else { return }
        if state == .sleeping, wanderer == nil { reactInSleep() }
        ballToy = BallToy(x: x, y: y, spec: wander.ball)
        ballBehindChair = false
        lastBallStep = chairTime
        sound.play(.throwBall)
        if state != .sleeping {
            if wanderer == nil { wanderer = Wanderer(data: wander, start: chairTime) }
            wanderer?.noticeBall(at: chairTime, ballX: x)
        }
        show(chairScene())
    }

    /// Mouse entered or left the notch. While hovered the chair cat sits in the grown shape;
    /// whatever was going on freezes and carries on afterwards. The hover view freezes too:
    /// hovering again picks it up where it left off, unless the cat has moved on since.
    func setHovered(_ hovered: Bool) {
        guard hovered != isHovered else { return }
        isHovered = hovered
        sound.play(hovered ? .open : .close)
        if !hovered { sound.stopPurr() }
        if hovered, stateChangesAtHoverEnd == stateChanges {
            // Same cat, same moment: roaming or not, the hover view picks up right here.
            roamsOutside = false
            if chairTime < petUntil { sound.startPurr() }
            show(chairScene())
        } else if hovered {
            chairTime = 0
            petUntil = 0
            petClicks = []
            peek = nil
            wanderer = hoverStart().map { Wanderer(data: wander, start: 0, from: $0) }
            lastPose = nil
            ballToy = nil
            lastBallStep = 0
            show(chairScene())
        } else {
            stateChangesAtHoverEnd = stateChanges
            // Off the chair and just wandering: it keeps going, out in the wings.
            if state == .resting, wanderer != nil, wanderer?.isInBed == false, lastPose != nil {
                roamsOutside = true
                roamScene = scene
                roamWings = (0, 0)
            }
            if state == .attention, attentionSatisfied {
                // It got the attention it came out for: back into the notch, content.
                run("goHome") { [weak self] in self?.goToRest() }
            }
            if let routine {
                show(routine.scene(at: routineTime))
            } else if roamsOutside {
                roam()
            } else {
                show(.empty)
            }
        }
        pauseOrResume()
    }

    // MARK: - Roaming outside the hover view

    /// One frame of the hover view carrying on after the mouse left: the cat drawn at notch
    /// size in the wings, at the same x (inside the notch's width it's hidden: the tunnel).
    /// Back up on the chair, it's home: roaming ends.
    private func roam() {
        let hoverScene = chairScene()
        playSounds(from: roamScene, to: hoverScene)
        roamScene = hoverScene
        guard let pose = lastPose else {
            endRoaming()
            return
        }
        var wingScene = PlayScene.empty
        wingScene.cat = .init(x: roamX(pose.x), frame: pose.frame, facingLeft: pose.facingLeft)
        if let toy = hoverScene.toy {
            wingScene.ball = .init(x: roamX(toy.x), roll: toy.roll)
        }
        // Each wing opens while something is near or past that side of the notch.
        let xs = [pose.x] + (hoverScene.toy.map { [$0.x] } ?? [])
        let open = Tuning.roamWing, step = Tuning.roamWingSpeed / Tuning.playFramesPerSecond
        let ease = { (wing: Double, target: Double) in
            target > wing ? min(wing + step, target) : max(wing - step, target)
        }
        roamWings.left = ease(roamWings.left, xs.contains { $0 < -Tuning.roamHiddenX } ? open : 0)
        roamWings.right = ease(roamWings.right, xs.contains { $0 > Tuning.roamHiddenX } ? open : 0)
        wingScene.leftWing = roamWings.left
        wingScene.rightWing = roamWings.right
        show(wingScene, playingSounds: false)
    }

    /// Where a hover-view x lands in the wings. The hover view is narrower than the notch plus
    /// its wings, so it's stretched: within `roamHiddenX` of the centre it stays inside the
    /// notch (hidden); from there to the edge of the hover view it crosses the whole wing,
    /// from just peeking out to standing at the wing's far end.
    private func roamX(_ x: Double) -> Double {
        let hidden = Tuning.roamHiddenX, edge = wander.rangeX + 5
        let peek = notchHalfWidth - Tuning.roamCatHalfWidth
        let far = notchHalfWidth + Tuning.roamWing - Tuning.roamCatHalfWidth
        let d = abs(x)
        let out = d <= hidden ? d / hidden * peek : peek + min(1, (d - hidden) / (edge - hidden)) * (far - peek)
        return x < 0 ? -out : out
    }

    /// The cat is out of sight in the notch again (or something else needs it): the hover
    /// view is dropped, and the next hover starts fresh.
    private func endRoaming() {
        guard roamsOutside else { return }
        roamsOutside = false
        stateChangesAtHoverEnd = nil
        wanderer = nil
        lastPose = nil
        ballToy = nil
        if routine == nil { show(.empty) }
        pauseOrResume()
    }

    /// Something wants to start (a game, a meal, a nap, attention). Fine once the roaming cat
    /// is out of sight inside the notch; while it's out in the wings, it has to wait.
    private var canStartRoutine: Bool {
        guard roamsOutside else { return true }
        guard let pose = lastPose, abs(pose.x) < Tuning.roamHiddenX else { return false }
        endRoaming()
        return true
    }

    // MARK: - Ball game

    /// Waits a random 2–6 minutes (play.js `everySeconds`), then starts a game.
    private func scheduleNextGame() {
        nextGame?.cancel()
        guard !isOnHold else { return }
        let delay = Double.random(in: play.everySeconds[0]...play.everySeconds[1])
        let work = DispatchWorkItem { [weak self] in
            MainActor.assumeIsolated {
                guard let self, self.state == .resting, !self.isOnHold else { return }
                guard self.canStartRoutine else { return self.scheduleNextGame() }
                self.startGame()
            }
        }
        nextGame = work
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: work)
    }

    private func startGame() {
        nextGame?.cancel()
        state = .playing
        start(Routine(play: play), named: "ball") { [weak self] in self?.goToRest() }
    }

    // MARK: - Hunger

    /// Waits until `hungryAt`, then brings the cat out to beg.
    private func scheduleHunger() {
        nextHunger?.cancel()
        guard !isOnHold else { return }
        // A short gap at least, so it never pops straight back out after going in.
        let delay = max(hungryAt.timeIntervalSinceNow, Tuning.hungerMinimumDelay)
        let work = DispatchWorkItem { [weak self] in
            MainActor.assumeIsolated {
                guard let self, !self.isOnHold else { return }
                guard self.canStartRoutine else { return self.scheduleHunger() }
                self.getHungry()
            }
        }
        nextHunger = work
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: work)
    }

    /// Comes out, sits, and meows every few seconds until it's fed. If it's busy playing, it
    /// gets hungry when the game ends instead.
    private func getHungry() {
        guard state == .resting else { return }
        nextGame?.cancel()
        state = .hungry
        run("comeOut") { [weak self] in self?.beg() }
    }

    /// meow, wait, meow, wait, ... — until `feed()` replaces what comes next.
    private func beg() {
        run("meow") { [weak self] in
            self?.run("wait") { [weak self] in self?.beg() }
        }
    }

    private func eatAndGoHome() {
        run("eat") { [weak self] in
            self?.run("goHome") { [weak self] in self?.goToRest() }
        }
    }

    // MARK: - Attention

    /// Waits until `attentionAt`, then comes out to ask for attention.
    private func scheduleAttention() {
        nextAttention?.cancel()
        guard !isOnHold else { return }
        let delay = max(attentionAt.timeIntervalSinceNow, Tuning.hungerMinimumDelay)
        let work = DispatchWorkItem { [weak self] in
            MainActor.assumeIsolated {
                guard let self, !self.isOnHold else { return }
                guard self.canStartRoutine else { return self.scheduleAttention() }
                self.seekAttention()
            }
        }
        nextAttention = work
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: work)
    }

    /// Comes out, sits facing you and paws at the screen a few times, then goes back in (or
    /// goes in happy once it's been petted). Busy? It tries again a little later.
    private func seekAttention() {
        guard state == .resting else {
            attentionAt = Date().addingTimeInterval(180)
            return
        }
        nextGame?.cancel()
        attentionAt = Date().addingTimeInterval(Self.randomAttentionGap(hungry))
        attentionSatisfied = false
        state = .attention
        run("comeOut") { [weak self] in self?.pawAtYou(times: self?.hungry.attentionLoops ?? 1) }
    }

    private func pawAtYou(times: Int) {
        guard times > 0 else {
            run("goHome") { [weak self] in self?.goToRest() }
            return
        }
        run("attention") { [weak self] in self?.pawAtYou(times: times - 1) }
    }

    private static func randomAttentionGap(_ hungry: HungryData) -> TimeInterval {
        Double.random(in: hungry.attentionEveryMinutes[0]...hungry.attentionEveryMinutes[1]) * 60
    }

    private static func randomMealGap(_ hungry: HungryData) -> TimeInterval {
        Double.random(in: hungry.hungryAfterMinutes[0]...hungry.hungryAfterMinutes[1]) * 60
    }

    // MARK: - Naps

    /// Awake: waits until `sleepAt`, then naps. Asleep: waits until `napUntil`, then wakes up.
    private func scheduleSleep() {
        nextSleep?.cancel()
        guard !isOnHold else { return }
        let delay = max((state == .sleeping ? napUntil : sleepAt).timeIntervalSinceNow, Tuning.hungerMinimumDelay)
        let work = DispatchWorkItem { [weak self] in
            MainActor.assumeIsolated {
                guard let self, !self.isOnHold else { return }
                guard self.canStartRoutine else { return self.scheduleSleep() }
                if self.state == .sleeping { self.wakeUp() } else { self.fallAsleep() }
            }
        }
        nextSleep = work
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: work)
    }

    /// Curls up in its bed, out of sight in the notch. Nothing else starts while it sleeps: a
    /// game, a meal or attention that comes due waits until it wakes. Busy? It naps a little later.
    private func fallAsleep() {
        guard state == .resting else {
            sleepAt = Date().addingTimeInterval(180)
            return
        }
        nextGame?.cancel()
        state = .sleeping
        napUntil = Date().addingTimeInterval(Double.random(in: sleep.napMinutes[0]...sleep.napMinutes[1]) * 60)
        scheduleSleep()
    }

    private func wakeUp() {
        endNap()
        goToRest()
    }

    /// Awake again; the next nap is a while away.
    private func endNap() {
        nextSleep?.cancel()
        sleepAt = Date().addingTimeInterval(Self.randomSleepGap(sleep))
        state = .resting
    }

    /// The ball landed while it sleeps: like a real cat it might not stir at all, peek and doze
    /// off again, or slowly get up and amble over (sleep.js `ballReactions`).
    private func reactInSleep() {
        let reactions = sleep.ballReactions
        var pick = Double.random(in: 0..<max(reactions.reduce(0) { $0 + $1.weight }, 0.001))
        guard let reaction = reactions.first(where: { pick -= $0.weight; return pick < 0 }) ?? reactions.last else { return }
        if reaction.wakes {
            peek = nil
            // Awake; everything else is back on the clock once the hover ends.
            endNap()
            let bed = sleep.bed
            let pose = sleepPose()
            wanderer = Wanderer(data: wander, start: chairTime,
                                from: .inBed(x: bed.x, lyingX: pose.x, y: bed.catY, facingLeft: pose.facingLeft,
                                             steps: reaction.steps, chase: sleep.sleepyChase))
        } else if !reaction.steps.isEmpty {
            peek = (chairTime, reaction.steps)
        }
    }

    private static func randomSleepGap(_ sleep: SleepData) -> TimeInterval {
        Double.random(in: sleep.everyMinutes[0]...sleep.everyMinutes[1]) * 60
    }

    // MARK: - Routines

    private func run(_ name: String, then next: @escaping () -> Void) {
        guard let spec = hungry.routines[name] else {
            assertionFailure("hungry.js has no '\(name)' routine")
            goToRest()
            return
        }
        start(Routine(spec, play: play), named: name, then: next)
    }

    private func start(_ newRoutine: Routine, named name: String, then next: @escaping () -> Void) {
        routine = newRoutine
        routineName = name
        routineTime = 0
        afterRoutine = next
        if !isOnHold { startClock() }
    }

    /// Back inside the notch: nothing drawn, and the next game and meal are on the clock.
    private func goToRest() {
        stopClock()
        routine = nil
        routineName = ""
        afterRoutine = nil
        state = .resting
        show(isHovered ? chairScene() : .empty)
        scheduleNextGame()
        scheduleHunger()
        scheduleAttention()
        scheduleSleep()
    }

    /// Freezes whatever is animating in place while paused or hovered; carries on from the same
    /// moment afterwards. The chair cat keeps breathing while hovered unless paused.
    private func pauseOrResume() {
        if isOnHold {
            nextGame?.cancel()
            nextHunger?.cancel()
            nextAttention?.cancel()
            nextSleep?.cancel()
        }
        if isPaused {
            stopClock()
            sound.stopPurr(fade: false)
        } else if isHovered || routine != nil {
            startClock()
        } else {
            if roamsOutside { startClock() } else { stopClock() }
            scheduleNextGame()
            scheduleHunger()
            scheduleAttention()
            scheduleSleep()
        }
    }

    /// Where the cat is when the hover begins: if it's out of the notch (hungry, eating,
    /// playing) it stays on the floor at the same spot, doing the same thing. nil = on the chair.
    private func hoverStart() -> Wanderer.Start? {
        guard let cat = routine?.scene(at: routineTime).cat else { return nil }
        // Same spot, kept inside the view and clear of the chair.
        var x = min(max(cat.x, -wander.rangeX), wander.rangeX)
        if abs(x) < wander.clearOfChair { x = (x < 0 ? -1 : 1) * wander.clearOfChair }
        switch state {
        case .hungry: return .hungry(x: x)
        case .attention: return .attention(x: x)
        case .eating: return .eating(x: x)
        case .playing: return .floor(x: x)
        case .resting, .sleeping: return nil
        }
    }

    /// The upright cat sitting on the chair: breathing and blinking, or eyes shut when petted.
    private func chairSitPose(isPetted: Bool) -> Wanderer.Pose {
        let (steps, local) = isPetted ? (wander.pettedFront, chairTime - petStart) : (wander.chairSit, chairTime)
        return .init(x: wander.chairX, y: wander.seatY, frame: Self.frame(in: steps, at: local) ?? "front", facingLeft: false)
    }

    /// Curled up asleep in the bed, breathing (petted or not: it sleeps through it), or
    /// peeking at the ball before dozing off again.
    private func sleepPose() -> Wanderer.Pose {
        let bed = sleep.bed
        let facingLeft = bed.facing == .left
        var frame = Self.frame(in: sleep.steps, at: chairTime) ?? "sleep1"
        if let peek, chairTime - peek.start < peek.steps.reduce(0, { $0 + $1.ms }) {
            frame = Self.frame(in: peek.steps, at: chairTime - peek.start) ?? frame
        } else {
            peek = nil
        }
        return .init(x: bed.x + (facingLeft ? -bed.catX : bed.catX), y: bed.catY, frame: frame, facingLeft: facingLeft)
    }

    /// The "z"s floating up from the sleeping cat's head, looped.
    private func sleepZs() -> [PlayScene.Sound] {
        let bed = sleep.bed, z = sleep.z
        let towardsHead: Double = bed.facing == .left ? -1 : 1
        let t = chairTime.truncatingRemainder(dividingBy: z.loopMs)
        return z.floats.compactMap { drift in
            // Measured round the loop, so a "z" that started near the end carries on into the next.
            let local = (t - drift.at + z.loopMs).truncatingRemainder(dividingBy: z.loopMs)
            guard local < drift.ms else { return nil }
            let p = local / drift.ms
            return .init(x: bed.x + towardsHead * Routine.value(drift.dx, p, .out), y: Routine.value(drift.y, p, .out),
                         opacity: Routine.soundOpacity(p), size: drift.size)
        }
    }

    /// The frame `t` ms into a looping list of steps.
    private static func frame(in steps: [WanderData.Step], at t: Double) -> String? {
        let total = steps.reduce(0) { $0 + $1.ms }
        var local = total > 0 ? t.truncatingRemainder(dividingBy: total) : 0
        for step in steps {
            if local < step.ms { return step.frame }
            local -= step.ms
        }
        return steps.last?.frame
    }

    private func chairScene() -> PlayScene {
        var scene = PlayScene.empty
        let isPetted = chairTime < petUntil
        // Asleep in its bed (until the ball wakes it): it stays put.
        let isAsleep = state == .sleeping && wanderer == nil
        scene.chairFrame = isPetted
            ? ChairData.frame(in: petting.timeline, at: chairTime - petStart)
            : chair.frame(at: chairTime)
        // Hovered a moment without being petted: hop off the chair and wander.
        if wanderer == nil, !isAsleep, !isPetted, chairTime - max(petUntil, 0) >= wander.afterMs {
            wanderer = Wanderer(data: wander, start: chairTime)
        }
        // The ball moves on, then the cat reacts to where it is (and may pin or bat it).
        if var ball = ballToy {
            // Walls a little past where the cat roams, so it can always reach the ball whole.
            ball.step((chairTime - lastBallStep) / 1000, spec: wander.ball, wall: wander.rangeX + 5)
            ballToy = ball
            // Louder the harder it lands; the tiny settling hits are silent.
            if ball.impact > 80 { sound.play(.bounce, level: Float(min(1, ball.impact / 400))) }
        }
        lastBallStep = chairTime
        lastPose = wanderer?.pose(at: chairTime, ball: ballToy) ?? (isAsleep ? sleepPose() : chairSitPose(isPetted: isPetted))
        switch wanderer?.ballCommand {
        case .hold(let x)?: ballToy?.hold(at: x)
        case .kick(let vx)?:
            ballToy?.kick(vx: vx, spec: wander.ball)
            sound.play(.swat)
        case nil: break
        }
        scene.wanderer = lastPose
        if let lastPose, wanderer?.wantsBall == true { ballBehindChair = lastPose.behindChair }
        scene.hoverSounds = wanderer?.sounds ?? []
        scene.hoverBowlX = wanderer?.bowlX
        scene.catInBed = isAsleep || wanderer?.isInBed == true
        // No "z"s while it's peeking.
        if isAsleep, peek == nil { scene.sleepZs = sleepZs() }
        if let ball = ballToy {
            // Left alone and still for a while: it fades away.
            let fade = (wanderer?.wantsBall ?? false) ? 0 : (ball.stillMs - wander.ball.fadeAfterMs) / 500
            if fade >= 1 {
                ballToy = nil
            } else {
                // One roll frame per quarter turn of the ball (its diameter in points on Retina).
                let diameter = Double(play.ball.size * wander.ball.pixelScale) / 2
                let quarterTurn = .pi * diameter / 4
                scene.toy = .init(x: ball.x, y: ball.y, roll: Int(abs(ball.x) / quarterTurn) % 4, opacity: 1 - max(0, fade), isHeld: ball.isHeld, behindChair: ballBehindChair)
            }
        }
        let heartsLast = petting.hearts.map { $0.at + $0.ms }.max() ?? 0
        petClicks.removeAll { chairTime - $0.time >= heartsLast }
        for click in petClicks {
            for heart in petting.hearts {
                let t = chairTime - click.time - heart.at
                guard t >= 0, t < heart.ms else { continue }
                let p = t / heart.ms
                scene.hearts.append(.init(x: click.x + Routine.value(heart.x, p, heart.ease),
                                          y: click.y + Routine.value(heart.y, p, heart.ease),
                                          opacity: Routine.soundOpacity(p)))
            }
        }
        return scene
    }

    // MARK: - Clock (only runs while something is animating)

    private func startClock() {
        guard clock == nil else { return }
        lastTick = CACurrentMediaTime()
        let timer = Timer(timeInterval: 1.0 / Tuning.playFramesPerSecond, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.tick() }
        }
        RunLoop.main.add(timer, forMode: .common)
        clock = timer
    }

    private func stopClock() {
        clock?.invalidate()
        clock = nil
    }

    private func tick() {
        let now = CACurrentMediaTime()
        // Cap the step so a stall (e.g. a busy system) doesn't make the cat teleport.
        let step = min(now - lastTick, 0.1) * 1000
        lastTick = now
        if isHovered {
            chairTime += step
            if chairTime >= petUntil { sound.stopPurr() }
            show(chairScene())
            return
        }
        if roamsOutside {
            chairTime += step
            roam()
            return
        }
        guard let routine else { stopClock(); return }
        routineTime += step
        if routineTime >= routine.duration {
            let next = afterRoutine
            self.routine = nil
            afterRoutine = nil
            if let next { next() } else { goToRest() }
        } else {
            show(routine.scene(at: routineTime))
        }
    }

    private func show(_ newScene: PlayScene, playingSounds: Bool = true) {
        guard newScene != scene else { return }
        if playingSounds { playSounds(from: scene, to: newScene) }
        scene = newScene
        onSceneChange?(newScene, catID)
    }

    // MARK: - Sound effects

    /// Sounds that go with what just started on screen. In the notch only the hungry meow
    /// (now and then) and feeding make a sound; everything else only while hovered.
    private func playSounds(from old: PlayScene, to new: PlayScene) {
        if let frame = new.cat?.frame, frame != old.cat?.frame {
            if frame == "frontMeow1" || frame == "frontPawMeow",
               Date().timeIntervalSince(lastNotchMeow) >= Tuning.notchMeowEverySeconds {
                lastNotchMeow = Date()
                sound.play(.meow, level: 0.7)
            }
            if frame == "frontEat1" { sound.play(.crunch, level: 0.7) }
        }
        if old.bowl == nil, new.bowl != nil { sound.play(.bowl, level: 0.7) }

        if let frame = new.wanderer?.frame, frame != old.wanderer?.frame {
            switch frame {
            case "frontMeow1", "frontPawMeow": sound.play(.meow)
            case "frontEat1": sound.play(.crunch)
            case "scratch1": sound.play(.scratch)
            case "crouch" where old.wanderer?.frame == "pounce": sound.play(.land) // landed a hop
            default: break
            }
        }
    }
}
