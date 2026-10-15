import AVFoundation

/// Plays Purrch's sound effects (Resources/Sounds, see SOUNDS.md). Every file is loaded once
/// at launch into a few players so the same sound can overlap itself; nothing is decoded
/// while playing. Missing files are skipped, so a sound can be removed by deleting its file.
@MainActor
final class SoundPlayer {
    /// A sound and how it's played. Several files make one effect when it has variations
    /// (meow1–3): one is picked at random each time.
    enum Effect: CaseIterable {
        case meow, chirp, bounce, swat, throwBall, land, scratch, bowl, crunch, open, close

        var files: [String] {
            switch self {
            case .meow: ["meow1", "meow2", "meow3"]
            case .chirp: ["chirp"]
            case .bounce: ["bounce1", "bounce2", "bounce3"]
            case .swat: ["swat"]
            case .throwBall: ["throw"]
            case .land: ["land"]
            case .scratch: ["scratch1", "scratch2"]
            case .bowl: ["bowl"]
            case .crunch: ["crunch1", "crunch2", "crunch3"]
            case .open: ["open"]
            case .close: ["close"]
            }
        }

        /// Loudness relative to the others (0–1), before the user's volume.
        var level: Float {
            switch self {
            case .meow: 0.8
            case .chirp: 0.7
            case .bounce: 0.6
            case .swat: 0.7
            case .throwBall: 0.5
            case .land: 0.5
            case .scratch: 0.45
            case .bowl: 0.6
            case .crunch: 0.45
            case .open, .close: 0.35
            }
        }

        /// Random pitch change, ± this fraction (pitch and speed change together).
        var pitchJitter: Float {
            switch self {
            case .meow, .chirp: 0.06
            case .bounce, .crunch, .scratch, .land: 0.1
            default: 0.03
            }
        }

        /// Never more often than this, in seconds (stops rapid frame changes from stacking up).
        var minGap: TimeInterval {
            switch self {
            case .meow: 0.35
            case .scratch: 0.45
            case .crunch: 0.3
            case .bounce: 0.08
            case .chirp: 2
            default: 0.15
            }
        }
    }

    /// Off: nothing plays (and the purr stops).
    var isEnabled = true {
        didSet { if !isEnabled { stopPurr(fade: false) } }
    }
    /// The user's volume, 0–1.
    var volume: Float = 0.3 {
        didSet { purrPlayer?.volume = isPurring ? purrLevel * volume : 0 }
    }

    private var players: [String: [AVAudioPlayer]] = [:]
    private var lastPlayed: [Effect: Date] = [:]
    private var purrPlayer: AVAudioPlayer?
    private var isPurring = false
    private let purrLevel: Float = 0.55

    /// How many copies of each sound can play at once.
    private static let voices = 3

    init() {
        for file in Set(Effect.allCases.flatMap(\.files)) {
            guard let url = Bundle.main.url(forResource: file, withExtension: "wav") else { continue }
            players[file] = (0..<Self.voices).compactMap { _ in
                let player = try? AVAudioPlayer(contentsOf: url)
                player?.enableRate = true
                player?.prepareToPlay()
                return player
            }
        }
        if let url = Bundle.main.url(forResource: "purr", withExtension: "wav"),
           let player = try? AVAudioPlayer(contentsOf: url) {
            player.numberOfLoops = -1
            player.volume = 0
            player.prepareToPlay()
            purrPlayer = player
        }
    }

    /// Plays one variation of `effect`, unless sound is off or it played too recently.
    /// `level` scales it further (e.g. quieter in the small notch).
    func play(_ effect: Effect, level: Float = 1) {
        guard isEnabled, volume > 0 else { return }
        let now = Date()
        if let last = lastPlayed[effect], now.timeIntervalSince(last) < effect.minGap { return }
        guard let file = effect.files.filter({ players[$0] != nil }).randomElement(),
              let player = players[file]?.first(where: { !$0.isPlaying }) ?? players[file]?.first else { return }
        lastPlayed[effect] = now
        player.currentTime = 0
        player.rate = 1 + Float.random(in: -effect.pitchJitter...effect.pitchJitter)
        player.volume = effect.level * level * volume
        player.play()
    }

    /// Starts the looping purr (fades in), if it isn't already going.
    func startPurr() {
        guard isEnabled, volume > 0, let purrPlayer, !isPurring else { return }
        isPurring = true
        if !purrPlayer.isPlaying {
            purrPlayer.currentTime = 0
            purrPlayer.play()
        }
        purrPlayer.setVolume(purrLevel * volume, fadeDuration: 0.25)
    }

    /// Fades the purr out (or cuts it).
    func stopPurr(fade: Bool = true) {
        guard let purrPlayer, isPurring else { return }
        isPurring = false
        if fade {
            purrPlayer.setVolume(0, fadeDuration: 0.6)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) { [weak self] in
                MainActor.assumeIsolated {
                    guard let self, !self.isPurring else { return }
                    self.purrPlayer?.pause()
                }
            }
        } else {
            purrPlayer.volume = 0
            purrPlayer.pause()
        }
    }
}
