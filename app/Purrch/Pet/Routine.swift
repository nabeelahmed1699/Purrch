import Foundation

/// One run of a choreography: the ball game from play.js, or one of the hungry routines from
/// hungry.js. Give it the time since it started and it tells you what's on screen
/// (`scene(at:)`).
struct Routine {
    private struct TimedSegment {
        let spec: PlayData.Segment
        let start: Double
        let ms: Double
    }

    private let play: PlayData
    private let segments: [TimedSegment]
    private let sounds: [HungryData.Sound]
    /// Length of this run in ms (random lengths are picked per run, so every run differs a little).
    let duration: Double

    /// The ball game.
    init(play: PlayData) {
        self.init(segments: play.segments, sounds: [], play: play)
    }

    /// A hungry.js routine.
    init(_ spec: HungryData.RoutineSpec, play: PlayData) {
        self.init(segments: spec.segments, sounds: spec.sounds, play: play)
    }

    private init(segments specs: [PlayData.Segment], sounds: [HungryData.Sound], play: PlayData) {
        self.play = play
        self.sounds = sounds
        var t = 0.0
        var timed: [TimedSegment] = []
        for spec in specs {
            let ms: Double
            if spec.tunnel {
                ms = Double.random(in: play.tunnelMs[0]...play.tunnelMs[1])
            } else if let range = spec.msRange {
                ms = Double.random(in: range[0]...range[1])
            } else {
                ms = spec.ms
            }
            timed.append(TimedSegment(spec: spec, start: t, ms: ms))
            t += ms
        }
        segments = timed
        // Let the last sound finish floating away even if the segments end first.
        duration = max(t, sounds.map { $0.at + $0.ms }.max() ?? 0)
    }

    /// What's on screen `t` milliseconds into the run.
    func scene(at t: Double) -> PlayScene {
        guard t < duration else { return .empty }
        // Past the last segment (only while a sound finishes), the last segment holds.
        guard let seg = segments.first(where: { t < $0.start + $0.ms }) ?? segments.last else { return .empty }
        let local = min(t - seg.start, seg.ms)
        let p = seg.ms > 0 ? local / seg.ms : 1
        let spec = seg.spec

        var scene = PlayScene(
            cat: nil, ball: nil,
            leftWing: Self.value(spec.wings.left, p, spec.wings.ease),
            rightWing: Self.value(spec.wings.right, p, spec.wings.ease))

        if let cat = spec.cat {
            var frame = play.run.frames.first ?? ""
            var facing = cat.facing
            if cat.run {
                let index = Int(local / play.run.frameMs) % play.run.frames.count
                frame = play.run.frames[index]
            } else if let step = Self.step(in: cat.steps, at: local) {
                frame = step.frame
                facing = step.facing
            }
            scene.cat = .init(x: Self.value(cat.x, p, cat.ease), frame: frame, facingLeft: facing == .left)
        }

        if let ball = spec.ball {
            let x = Self.value(ball.x, p, ball.ease)
            // One roll frame per ~2.75 pt travelled: a quarter turn of the 7 pt ball.
            scene.ball = .init(x: x, roll: Int(abs(x) / 2.75) % 4)
        }

        if let bowl = spec.bowl {
            scene.bowl = .init(x: Self.value(bowl.x, p, bowl.ease), frame: bowl.frame)
        }

        for sound in sounds where t >= sound.at && t < sound.at + sound.ms {
            let sp = (t - sound.at) / sound.ms
            scene.sounds.append(.init(
                x: Self.value(sound.x, sp, sound.ease),
                y: Self.value(sound.y, sp, sound.ease),
                opacity: Self.soundOpacity(sp)))
        }
        return scene
    }

    /// Pops in quickly, holds, then fades out over the last 40%. (Also used for petting hearts.)
    static func soundOpacity(_ p: Double) -> Double {
        let fadeIn = min(p / 0.08, 1)
        let fadeOut = p < 0.6 ? 1 : 1 - (p - 0.6) / 0.4
        return fadeIn * fadeOut
    }

    static func value(_ span: PlayData.Span, _ p: Double, _ ease: Ease) -> Double {
        span.from + (span.to - span.from) * ease.apply(p)
    }

    /// The step playing `local` ms into a list of frame steps (the last one holds).
    private static func step(in steps: [PlayData.CatTrack.Step], at local: Double) -> PlayData.CatTrack.Step? {
        var elapsed = 0.0
        for step in steps {
            elapsed += step.ms
            if local < elapsed { return step }
        }
        return steps.last
    }
}
