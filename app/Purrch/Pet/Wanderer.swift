import Foundation

/// The cat after it hops off the chair (wander.js): hop down, then stroll a little way, do a
/// random pause (scratch an ear, look around, sit and stare, ...), stroll again, and so on.
/// Now and then it walks back to the chair, hops up, sits a while and hops off again.
/// Throw it a ball (`noticeBall`) and it gallops over, pounces, catches and bats it away.
/// Petting stops it for a moment. Ask it where it is with `pose(at:ball:)`, passing the hover
/// clock in ms; nil means it's sitting on the chair (draw the chair cat). After each call,
/// `ballCommand` says whether it's pinning or batting the ball.
struct Wanderer {
    struct Pose: Equatable {
        /// Points from the notch centre, and up from the hover view's floor.
        var x: Double
        var y: Double
        var frame: String
        var facingLeft: Bool
        /// Walking behind the chair (the chair is drawn over it) rather than in front.
        var behindChair = false
    }

    private enum Phase {
        /// Hopping off the chair, or back up. `direction`: which side of the chair (+1 right).
        case hop(start: Double, moves: [WanderData.Move], direction: Double)
        case walk(start: Double, from: Double, to: Double, then: AfterWalk)
        case pause(start: Double, steps: [WanderData.Step])
        case onChair(until: Double)
        case petted(start: Double, until: Double, steps: [WanderData.Step])
        /// Galloping towards the ball; `last` is the time of the previous step.
        case chase(last: Double)
        /// Crouch, pounce, catch, bat it away. `direction` +1 = the ball is to its right.
        case pounce(start: Double, from: Double, direction: Double, kicked: Bool)
        /// Sitting facing you, meowing (hungry) or pawing at you (wants attention), or eating
        /// from the bowl: looped.
        case hungry(start: Double)
        case eating(start: Double)
        /// Woken in its bed: lifting its head, getting up (`Start.inBed`).
        case waking(start: Double, steps: [WanderData.Step])
    }

    /// Where the cat is when the hover begins.
    enum Start {
        /// On the chair (it was hidden in the notch).
        case chair
        /// Out on the floor at x: it was playing, so it just carries on wandering from there.
        case floor(x: Double)
        /// Out on the floor at x, hungry, wanting attention or eating: it keeps at it.
        case hungry(x: Double)
        case attention(x: Double)
        case eating(x: Double)
        /// Woken in its bed by the ball: plays `steps` there (lying frames at `lyingX`, the rest
        /// at `x`, all `y` up on the cushion), then goes after the ball with `chase`.
        case inBed(x: Double, lyingX: Double, y: Double, facingLeft: Bool, steps: [WanderData.Step],
                   chase: WanderData.Chase)
    }

    /// What it goes back to after being petted.
    private enum Home { case wander, hungry, attention, eating }

    /// What the cat does to the ball this moment.
    enum BallCommand: Equatable {
        /// Pinned under its paws, here.
        case hold(x: Double)
        /// Batted away at this speed (+ = right).
        case kick(vx: Double)
    }

    private enum AfterWalk { case pause, hopUp(side: Double), beg }

    private let data: WanderData
    private var phase: Phase
    private var x = 0.0
    private var facingLeft = false
    /// The frame last shown (nil on the chair), so petting knows which pose family to use.
    private var lastFrame: String?
    /// Chases left for the ball thrown last; 0 = not interested.
    private var chasesLeft = 0
    private var ball: BallToy?
    /// Set by `pose(at:ball:)`: what it's doing to the ball right now, if anything.
    private(set) var ballCommand: BallCommand?
    /// Set by `pose(at:ball:)`: floating "meow"s (x, y in hover view points) and the bowl's x.
    private(set) var sounds: [PlayScene.Sound] = []
    private(set) var bowlX: Double?
    private var home = Home.wander
    /// Which side of the chair it's on: picked per stroll or chase, only when clear of it.
    private var behindChair = false
    /// Chasing the ball while hungry: slow and feeble (`tiredChase`).
    private var tired = false
    /// Just woken up: ambles after the ball (`sleepyChase`) instead of galloping.
    private var drowsy = false
    private var sleepyChase: WanderData.Chase?
    /// Where it lies, and how high, while getting up in the bed.
    private var lyingX = 0.0
    private var bedY = 0.0
    private var chase: WanderData.Chase {
        tired ? data.tiredChase : drowsy ? (sleepyChase ?? data.chase) : data.chase
    }

    /// Still in its bed, getting up (the bed's front is drawn over it).
    var isInBed: Bool {
        if case .waking = phase { return true }
        return false
    }

    /// Still playing with the ball (so it shouldn't fade away yet).
    var wantsBall: Bool { chasesLeft > 0 }

    init(data: WanderData, start t: Double, from start: Start = .chair) {
        self.data = data
        switch start {
        case .chair:
            phase = .onChair(until: t)
        case .floor(let x):
            self.x = x
            phase = .onChair(until: t) // replaced just below
            startWalk(at: t)
        case .hungry(let x):
            self.x = x
            home = .hungry
            phase = .hungry(start: t)
        case .attention(let x):
            self.x = x
            home = .attention
            phase = .hungry(start: t)
        case .eating(let x):
            self.x = x
            home = .eating
            phase = .eating(start: t)
        case .inBed(let x, let lyingX, let y, let facingLeft, let steps, let chase):
            self.x = x
            self.lyingX = lyingX
            self.facingLeft = facingLeft
            bedY = y
            drowsy = true
            sleepyChase = chase
            phase = .waking(start: t, steps: steps)
        }
    }

    /// Stops right where it is (mid-hop it lands), stays in the same kind of pose, and enjoys
    /// it until `until`; then carries on. On the chair it just stays a little longer.
    mutating func pet(at t: Double, until: Double) {
        switch phase {
        case .petted(let start, _, let steps):
            phase = .petted(start: start, until: until, steps: steps)
        case .onChair(let chairUntil):
            phase = .onChair(until: max(chairUntil, until + 1500))
        case .waking:
            return // still getting up: it enjoys it but carries on
        default:
            let frame = lastFrame ?? "stand"
            let steps = frame.hasPrefix("front") ? data.pettedFront
                : data.sittingFrames.contains(frame) ? data.pettedSitting
                : data.pettedSide
            phase = .petted(start: t, until: until, steps: steps)
        }
    }

    /// A ball was thrown to `ballX`: go after it. Off the chair first if it's up there; a
    /// petted or hopping cat finishes that, then goes.
    mutating func noticeBall(at t: Double, ballX: Double) {
        switch home {
        case .eating:
            return // busy eating
        case .hungry:
            // Too weak to play properly: drags itself over for one feeble tap.
            tired = true
            chasesLeft = data.tiredChase.maxChases
            if case .hungry = phase { phase = .chase(last: t) }
            return
        case .attention:
            home = .wander // attention at last: it's happy to play
            tired = false
        case .wander:
            tired = false
        }
        // Still getting out of bed: it stays sleepy. Properly awake, it gallops.
        drowsy = isInBed
        chasesLeft = chase.maxChases
        switch phase {
        case .onChair:
            startHopDown(at: t, direction: ballX >= 0 ? 1 : -1)
        case .hungry:
            phase = .chase(last: t)
        case .hop, .petted, .pounce, .chase, .eating, .waking:
            break
        case .walk, .pause:
            pickSide()
            phase = .chase(last: t)
        }
    }

    /// Where the cat is `t` ms into the hover, or nil while it sits on the chair. `ball` is the
    /// thrown ball, if there is one.
    mutating func pose(at t: Double, ball: BallToy?) -> Pose? {
        self.ball = ball
        ballCommand = nil
        sounds = []
        bowlX = nil
        var pose = nextPose(at: t)
        pose?.behindChair = behindChair
        lastFrame = pose?.frame
        return pose
    }

    private mutating func nextPose(at t: Double) -> Pose? {
        while true {
            switch phase {
            case .hop(let start, let moves, let direction):
                let local = t - start
                var elapsed = 0.0
                for move in moves {
                    if local < elapsed + move.ms {
                        let p = move.ms > 0 ? (local - elapsed) / move.ms : 1
                        x = data.chairX + direction * Routine.value(move.x, p, move.ease)
                        return Pose(x: x, y: Routine.value(move.y, p, move.ease), frame: move.frame, facingLeft: facingLeft)
                    }
                    elapsed += move.ms
                }
                let endsOnChair = (moves.last?.x.to ?? 0) == 0
                x = data.chairX + direction * (moves.last?.x.to ?? 0)
                if endsOnChair, chasesLeft > 0, let ball {
                    // Hopped up just as a ball was thrown: straight back down after it.
                    startHopDown(at: start + elapsed, direction: ball.x >= 0 ? 1 : -1)
                } else if endsOnChair {
                    // Hopped back up: sits on the chair for a while.
                    let stay = Double.random(in: data.chairMs[0]...max(data.chairMs[0], data.chairMs[1]))
                    phase = .onChair(until: start + elapsed + stay)
                } else if chasesLeft > 0 {
                    phase = .chase(last: start + elapsed)
                } else {
                    startWalk(at: start + elapsed)
                }

            case .walk(let start, let from, let to, let then):
                // Hungry and tired: the droopy walk, slowly.
                let (speed, frames, frameMs) = tired
                    ? (data.tiredChase.speed, data.tiredChase.frames, data.tiredChase.frameMs)
                    : (data.walk.speed, data.walk.frames, data.walk.frameMs)
                let duration = abs(to - from) / speed * 1000
                let local = t - start
                if local < duration {
                    x = from + (to - from) * local / duration
                    let frame = frames.isEmpty ? "stand" : frames[Int(local / frameMs) % frames.count]
                    return Pose(x: x, y: 0, frame: frame, facingLeft: facingLeft)
                }
                x = to
                switch then {
                case .pause:
                    startPause(at: start + duration)
                case .hopUp(let side):
                    facingLeft = side > 0 // face the chair
                    phase = .hop(start: start + duration, moves: data.hopUp, direction: side)
                case .beg:
                    tired = false
                    phase = .hungry(start: start + duration)
                }

            case .pause(let start, let steps):
                if let frame = Self.frame(in: steps, at: t - start, loop: false) {
                    return Pose(x: x, y: 0, frame: frame, facingLeft: facingLeft)
                }
                startWalk(at: start + steps.reduce(0) { $0 + $1.ms })

            case .onChair(let until):
                if t < until { return nil }
                startHopDown(at: until)

            case .petted(let start, let until, let steps):
                if home == .eating { bowlX = x } // the bowl stays put while it's petted
                if t < until, let frame = Self.frame(in: steps, at: t - start, loop: true) {
                    return Pose(x: x, y: 0, frame: frame, facingLeft: facingLeft)
                }
                switch home {
                case .hungry: phase = chasesLeft > 0 ? .chase(last: until) : .hungry(start: until)
                case .attention:
                    // Got the attention it wanted: off it goes, happy.
                    home = .wander
                    startWalk(at: until)
                case .eating: phase = .eating(start: until)
                case .wander: if chasesLeft > 0 { phase = .chase(last: until) } else { startWalk(at: until) }
                }

            case .hungry(let start):
                let hungry = home == .attention ? data.attention : data.hungry
                let loop = hungry.steps.reduce(0) { $0 + $1.ms }
                let local = loop > 0 ? (t - start).truncatingRemainder(dividingBy: loop) : 0
                // "meow"s float towards the middle of the view, so they never fall off its side.
                let inward: Double = x > 0 ? -1 : 1
                for sound in hungry.sounds {
                    let st = local - sound.at
                    guard st >= 0, st < sound.ms else { continue }
                    let p = st / sound.ms
                    sounds.append(.init(x: x + inward * Routine.value(sound.dx, p, .out),
                                        y: Routine.value(sound.y, p, .out), opacity: Routine.soundOpacity(p)))
                }
                let frame = Self.frame(in: hungry.steps, at: local, loop: true) ?? "front"
                return Pose(x: x, y: 0, frame: frame, facingLeft: false)

            case .waking(let start, let steps):
                if let frame = Self.frame(in: steps, at: t - start, loop: false) {
                    let lying = frame.hasPrefix("sleep")
                    // Once up on its feet it turns towards the ball.
                    if !lying, let ball, abs(ball.x - x) > 1 { facingLeft = ball.x < x }
                    return Pose(x: lying ? lyingX : x, y: bedY, frame: frame, facingLeft: facingLeft)
                }
                let end = start + steps.reduce(0) { $0 + $1.ms }
                if chasesLeft > 0, ball != nil { phase = .chase(last: end) } else { startPause(at: end) }

            case .eating(let start):
                bowlX = x
                let frame = Self.frame(in: data.eating.steps, at: t - start, loop: true) ?? "frontEat1"
                return Pose(x: x, y: 0, frame: frame, facingLeft: false)

            case .chase(let last):
                let chase = self.chase
                guard let ball, chasesLeft > 0 else {
                    chasesLeft = 0
                    if home == .hungry { tired = false; phase = .hungry(start: t) } else { startPause(at: t) }
                    continue
                }
                let side: Double = ball.x >= x ? 1 : -1
                // Never runs so far out that the side of the view cuts it off.
                let limit = data.rangeX + 8
                let target = min(max(ball.x - side * chase.reach, -limit), limit)
                let step = chase.speed * max(0, t - last) / 1000
                if abs(target - x) <= max(step, 2), ball.speed < 60, ball.y < 4 {
                    x = target
                    facingLeft = side < 0
                    phase = .pounce(start: t, from: x, direction: side, kicked: false)
                    continue
                }
                x += min(step, abs(target - x)) * (target > x ? 1 : -1)
                if abs(target - x) > 1 { facingLeft = target < x }
                phase = .chase(last: t)
                let frame = chase.frames.isEmpty ? "stand" : chase.frames[Int(t / chase.frameMs) % chase.frames.count]
                return Pose(x: x, y: 0, frame: frame, facingLeft: facingLeft)

            case .pounce(let start, let from, let direction, let kicked):
                let chase = self.chase
                let local = t - start
                var elapsed = 0.0, reached = 0.0
                for step in chase.pounce {
                    if local < elapsed + step.ms {
                        let p = step.ms > 0 ? (local - elapsed) / step.ms : 1
                        x = from + direction * (reached + (step.dx - reached) * p)
                        facingLeft = direction < 0
                        if chase.holdFrames.contains(step.frame) {
                            ballCommand = .hold(x: x + direction * chase.holdOffset)
                        }
                        if step.frame == chase.kickFrame, !kicked {
                            ballCommand = .kick(vx: kickDirection(direction) * chase.kickSpeed)
                            phase = .pounce(start: start, from: from, direction: direction, kicked: true)
                        }
                        return Pose(x: x, y: 0, frame: step.frame, facingLeft: facingLeft)
                    }
                    elapsed += step.ms
                    reached = step.dx
                }
                x = from + direction * reached
                // Never leave the ball pinned (if the kick frame was skipped over).
                if !kicked { ballCommand = .kick(vx: kickDirection(direction) * chase.kickSpeed) }
                chasesLeft -= 1
                if home == .hungry {
                    // Back to begging — but not sat in front of the chair: trudge clear of it first.
                    chasesLeft = 0
                    if !behindChair, abs(x) < data.clearOfChair {
                        let spot = (x < 0 ? -1.0 : 1.0) * data.clearOfChair
                        facingLeft = spot < x
                        phase = .walk(start: start + elapsed, from: x, to: spot, then: .beg)
                    } else {
                        tired = false
                        phase = .hungry(start: start + elapsed)
                    }
                } else if chasesLeft > 0, Double.random(in: 0..<1) < chase.again {
                    phase = .chase(last: start + elapsed)
                } else {
                    chasesLeft = 0
                    startPause(at: start + elapsed)
                }
            }
        }
    }

    /// Bats the ball the way it faces, unless that's straight into the side of the view:
    /// then it swats it back behind itself, into open space.
    private func kickDirection(_ facing: Double) -> Double {
        abs(x + facing * (chase.holdOffset + 40)) > data.rangeX ? -facing : facing
    }

    /// Picks in front of or behind the chair for the next stroll or chase. Only when clear of
    /// the chair, so it never pops through it.
    private mutating func pickSide() {
        guard abs(x) >= data.switchSidesClear else { return }
        behindChair = Double.random(in: 0..<1) < data.behindChance
    }

    private mutating func startHopDown(at start: Double, direction: Double = Bool.random() ? 1 : -1) {
        x = data.chairX
        behindChair = false
        facingLeft = direction < 0
        phase = .hop(start: start, moves: data.hop, direction: direction)
    }

    /// A random pause, picked by weight. "Back to the chair" walks to the near side of the
    /// chair, then hops up.
    private mutating func startPause(at start: Double) {
        let total = data.pauses.reduce(0) { $0 + $1.weight }
        var pick = Double.random(in: 0..<max(total, 0.001))
        guard var pause = data.pauses.first(where: { pick -= $0.weight; return pick < 0 }) ?? data.pauses.last else {
            return startWalk(at: start)
        }
        #if DEBUG
        // Launch with PURRCH_PAUSE=grooms (a wander.js pause name) to always pick that pause.
        if let name = ProcessInfo.processInfo.environment["PURRCH_PAUSE"],
           let forced = data.pauses.first(where: { $0.name == name }) {
            pause = forced
        }
        #endif
        if pause.inFront, behindChair {
            // Facing-you pauses (pawing for attention) only happen in front of the chair.
            startWalk(at: start)
        } else if pause.chair, behindChair, abs(x) < data.switchSidesClear {
            // Right behind the chair: it can't come round to the front from here; stroll first.
            startWalk(at: start)
        } else if pause.chair {
            behindChair = false
            let side: Double = x >= 0 ? 1 : -1
            let spot = data.chairX + side * (data.hopUp.first?.x.from ?? 48)
            facingLeft = spot < x
            phase = .walk(start: start, from: x, to: spot, then: .hopUp(side: side))
        } else {
            phase = .pause(start: start, steps: pause.steps)
        }
    }

    /// Strolls `minWalk`–`maxWalk` one way or the other, turning back at the edges, in front of
    /// or behind the chair. It may walk past the chair but never stops right in front of it.
    private mutating func startWalk(at start: Double) {
        pickSide()
        let range = data.rangeX
        let distance = Double.random(in: data.minWalk...max(data.minWalk, data.maxWalk))
        var direction: Double = Bool.random() ? 1 : -1
        if abs(x + direction * distance) > range { direction = -direction }
        var target = min(max(x + direction * distance, -range), range)
        if !behindChair, abs(target) < data.clearOfChair {
            // Carry on past the chair if heading across it, otherwise stop short of it.
            let crossing = (target - x) * (0 - x) > 0 && abs(target - x) > abs(x)
            target = (crossing ? -1 : 1) * (x >= 0 ? 1 : -1) * data.clearOfChair
        }
        facingLeft = target < x
        phase = .walk(start: start, from: x, to: target, then: .pause)
    }

    /// The frame `local` ms into a list of steps; nil once a non-looping list is over.
    private static func frame(in steps: [WanderData.Step], at local: Double, loop: Bool) -> String? {
        let total = steps.reduce(0) { $0 + $1.ms }
        guard total > 0 else { return nil }
        if !loop, local >= total { return nil }
        var t = loop ? local.truncatingRemainder(dividingBy: total) : local
        for step in steps {
            if t < step.ms { return step.frame }
            t -= step.ms
        }
        return steps.last?.frame
    }
}
