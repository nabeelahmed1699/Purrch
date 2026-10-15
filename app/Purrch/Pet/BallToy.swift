import Foundation

/// The ball the user throws in the hover view (wander.js `ball`): it pops up, falls, bounces,
/// rolls to a stop, and bounces off the sides of the view. The cat can pin it (`hold`) or bat
/// it away (`kick`). Positions are points from the notch centre and up from the floor.
struct BallToy: Equatable {
    var x: Double
    var y: Double
    private(set) var vx: Double
    private(set) var vy: Double
    /// Pinned under the cat's paws: physics paused.
    private(set) var isHeld = false
    /// How long it has been lying still, in ms.
    private(set) var stillMs = 0.0
    /// Set by `step` when it hit the floor during that step: how hard (downward speed, points
    /// per second). 0 otherwise. Used for the bounce sound.
    private(set) var impact = 0.0

    /// Thrown from (x, y): a small pop upwards, and a random bit sideways.
    init(x: Double, y: Double, spec: WanderData.Ball) {
        self.x = x
        self.y = y
        vx = Double.random(in: -spec.tossSide...spec.tossSide)
        vy = spec.tossUp
    }

    /// How fast it's moving, in points per second.
    var speed: Double { hypot(vx, vy) }

    mutating func hold(at x: Double) {
        isHeld = true
        self.x = x
        y = 0
        vx = 0
        vy = 0
        stillMs = 0
    }

    mutating func kick(vx: Double, spec: WanderData.Ball) {
        isHeld = false
        self.vx = vx
        vy = spec.tossUp * 0.5
        stillMs = 0
    }

    /// Advances `dt` seconds. `wall` is how far either side of the centre it can go.
    mutating func step(_ dt: Double, spec: WanderData.Ball, wall: Double) {
        impact = 0
        guard !isHeld, dt > 0 else { return }
        vy -= spec.gravity * dt
        y += vy * dt
        if y <= 0 {
            y = 0
            if vy < 0 { impact = -vy }
            // Bounce; too small a bounce and it just settles.
            vy = vy < 0 ? -vy * spec.bounce : vy
            if vy < 40 { vy = 0 }
        }
        x += vx * dt
        if abs(x) > wall {
            x = wall * (x > 0 ? 1 : -1)
            vx = -vx * 0.6
        }
        if y == 0, vy == 0 {
            let slow = spec.rollFriction * dt
            vx = abs(vx) <= slow ? 0 : vx - slow * (vx > 0 ? 1 : -1)
        }
        stillMs = speed == 0 ? stillMs + dt * 1000 : 0
    }
}
