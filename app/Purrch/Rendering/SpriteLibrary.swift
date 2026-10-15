import CoreGraphics
import Foundation

/// Loads sprites.json and turns every frame into a ready-to-draw image once, at launch:
/// each cat × each frame × facing left/right, plus the ball, the bowl, the "meow", the chair
/// cat and the bed. Drawing afterwards only
/// picks cached images; nothing is rebuilt.
final class SpriteLibrary {
    let cats: [CatSpec]
    let play: PlayData
    let chair: ChairData
    let wander: WanderData
    let petting: PettingData
    let hungry: HungryData
    let sleep: SleepData

    private var catImages: [String: CGImage] = [:]
    /// The HD sitting frames (play.hd), same keys as catImages.
    private var hdCatImages: [String: CGImage] = [:]
    private var ballImages: [CGImage] = []
    private var bowlImages: [String: CGImage] = [:]
    /// chairImages[cat][frame]
    private var chairImages: [String: [CGImage]] = [:]
    private var emptyChairImages: [String: CGImage] = [:]
    /// The floating "meow" and the petting heart, one image pixel per screen pixel (already scaled up).
    private(set) var meowImage: CGImage?
    private(set) var heartImage: CGImage?
    /// The bed, behind and in front of the cat, and the floating "z" (one image pixel per z pixel).
    private(set) var bedBackImage: CGImage?
    private(set) var bedFrontImage: CGImage?
    private(set) var zImage: CGImage?

    static func loadFromBundle() -> SpriteLibrary {
        guard let url = Bundle.main.url(forResource: "sprites", withExtension: "json") else {
            fatalError("sprites.json is missing from the app bundle. Run: node tools/export-sprites.mjs")
        }
        do {
            let data = try JSONDecoder().decode(SpriteData.self, from: Data(contentsOf: url))
            return SpriteLibrary(data: data)
        } catch {
            fatalError("Could not read sprites.json: \(error)")
        }
    }

    init(data: SpriteData) {
        cats = data.cats
        play = data.play
        chair = data.chair
        wander = data.wander
        petting = data.petting
        hungry = data.hungry
        sleep = data.sleep

        let width = play.frameWidth, height = play.frameHeight
        for cat in cats {
            let palette = cat.palette.compactMapValues(RGBA.init(hex:))
            for (name, base) in play.frames {
                let layers = [base] + (play.markings[cat.id]?[name].map { [$0] } ?? [])
                for facingLeft in [false, true] {
                    catImages[Self.key(cat.id, name, facingLeft)] =
                        Self.makeImage(layers: layers, width: width, height: height, palette: palette, mirrored: facingLeft)
                }
            }
        }

        for cat in cats {
            let palette = cat.palette.compactMapValues(RGBA.init(hex:))
            for (name, base) in play.hd.frames {
                let layers = [base] + (play.hd.markings[cat.id]?[name].map { [$0] } ?? [])
                for facingLeft in [false, true] {
                    hdCatImages[Self.key(cat.id, name, facingLeft)] = Self.makeImage(
                        layers: layers, width: play.hd.frameWidth, height: play.hd.frameHeight,
                        palette: palette, mirrored: facingLeft)
                }
            }
        }

        let ballPalette = play.ball.palette.compactMapValues(RGBA.init(hex:))
        ballImages = (0..<4).compactMap { i in
            play.ball.frames["roll\(i)"].flatMap {
                Self.makeImage(layers: [$0], width: play.ball.size, height: play.ball.size, palette: ballPalette, mirrored: false)
            }
        }

        for cat in cats {
            let palette = cat.palette.compactMapValues(RGBA.init(hex:))
            let overlays = chair.markings[cat.id] ?? []
            chairImages[cat.id] = chair.frames.enumerated().compactMap { i, base in
                let layers = [base] + (i < overlays.count ? overlays[i].map { [$0] } ?? [] : [])
                return Self.makeImage(layers: layers, width: chair.size, height: chair.size, palette: palette, mirrored: false)
            }
            emptyChairImages[cat.id] = Self.makeImage(layers: [chair.empty], width: chair.size, height: chair.size,
                                                      palette: palette, mirrored: false)
        }

        let bowl = hungry.bowl
        let bowlPalette = bowl.palette.compactMapValues(RGBA.init(hex:))
        bowlImages = bowl.frames.compactMapValues {
            Self.makeImage(layers: [$0], width: bowl.width, height: bowl.height, palette: bowlPalette, mirrored: false)
        }

        // Scaled up here, so they can be drawn 1:1 like everything else.
        meowImage = Self.scaledImage(rows: hungry.meow.rows, scale: hungry.meow.pixelScale, palette: hungry.meow.palette)
        heartImage = Self.scaledImage(rows: petting.heart.rows, scale: petting.heart.pixelScale, palette: petting.palette)

        let bed = sleep.bed
        let bedPalette = bed.palette.compactMapValues(RGBA.init(hex:))
        bedBackImage = Self.makeImage(layers: [bed.back], width: bed.width, height: bed.height, palette: bedPalette, mirrored: false)
        bedFrontImage = Self.makeImage(layers: [bed.front], width: bed.width, height: bed.height, palette: bedPalette, mirrored: false)
        zImage = Self.scaledImage(rows: sleep.z.rows, scale: 1, palette: sleep.z.palette)
    }

    /// A hand cursor grid ("open" or "stroke"), each pixel `scale` x `scale` image pixels.
    func cursorImage(_ name: String, scale: Int) -> CGImage? {
        let rows = name == "stroke" ? petting.cursor.stroke : petting.cursor.open
        return Self.scaledImage(rows: rows, scale: scale, palette: petting.palette)
    }

    /// A single grid with every pixel blown up to `scale` x `scale`.
    private static func scaledImage(rows: [String], scale k: Int, palette: [String: String]) -> CGImage? {
        let scaledRows = rows.flatMap { row in
            Array(repeating: String(row.flatMap { Array(repeating: $0, count: k) }), count: k)
        }
        return makeImage(layers: [GridLayer(x: 0, y: 0, rows: scaledRows)],
                         width: (rows.first?.count ?? 0) * k, height: scaledRows.count,
                         palette: palette.compactMapValues(RGBA.init(hex:)), mirrored: false)
    }

    /// The full 80 × 64 px frame for a cat, facing left or right.
    func catFrame(cat: String, frame: String, facingLeft: Bool) -> CGImage? {
        catImages[Self.key(cat, frame, facingLeft)]
    }

    /// The same frame at twice the size (160 × 128 px), if it has one (only sitting frames do).
    func hdCatFrame(cat: String, frame: String, facingLeft: Bool) -> CGImage? {
        hdCatImages[Self.key(cat, frame, facingLeft)]
    }

    func ballFrame(_ roll: Int) -> CGImage? {
        ballImages.isEmpty ? nil : ballImages[roll % ballImages.count]
    }

    /// The chair cat's idle frame `index`, size x size px.
    func chairFrame(cat: String, index: Int) -> CGImage? {
        guard let images = chairImages[cat], images.indices.contains(index) else { return nil }
        return images[index]
    }

    /// The chair with nobody on it (wood colours come from the cat's palette).
    func emptyChair(cat: String) -> CGImage? {
        emptyChairImages[cat]
    }

    /// The bowl, "full" or "empty".
    func bowlFrame(_ name: String) -> CGImage? {
        bowlImages[name]
    }

    private static func key(_ cat: String, _ frame: String, _ left: Bool) -> String {
        "\(cat)/\(frame)/\(left ? "L" : "R")"
    }

    // MARK: - Building images

    /// Paints grid layers (the shared frame, then the cat's markings) into one full-size image.
    private static func makeImage(layers: [GridLayer], width: Int, height: Int,
                                  palette: [String: RGBA], mirrored: Bool) -> CGImage? {
        // RGBA bytes, 4 per pixel, all transparent to start with.
        var pixels = [UInt8](repeating: 0, count: width * height * 4)
        for layer in layers {
            for (row, line) in layer.rows.enumerated() {
                for (column, key) in line.enumerated() where key != "." {
                    guard let color = palette[String(key)] else { continue }
                    let x = layer.x + column, y = layer.y + row
                    guard x >= 0, x < width, y >= 0, y < height else { continue }
                    let i = (y * width + (mirrored ? width - 1 - x : x)) * 4
                    pixels[i] = color.r
                    pixels[i + 1] = color.g
                    pixels[i + 2] = color.b
                    pixels[i + 3] = 255
                }
            }
        }

        guard let provider = CGDataProvider(data: Data(pixels) as CFData) else { return nil }
        return CGImage(
            width: width, height: height,
            bitsPerComponent: 8, bitsPerPixel: 32, bytesPerRow: width * 4,
            space: CGColorSpace(name: CGColorSpace.sRGB)!,
            bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue),
            provider: provider, decode: nil, shouldInterpolate: false, intent: .defaultIntent)
    }
}

/// An 8-bit colour parsed from "#rrggbb".
private struct RGBA {
    let r: UInt8, g: UInt8, b: UInt8

    init?(hex: String) {
        let digits = hex.hasPrefix("#") ? String(hex.dropFirst()) : hex
        guard digits.count == 6, let value = UInt32(digits, radix: 16) else { return nil }
        r = UInt8((value >> 16) & 0xFF)
        g = UInt8((value >> 8) & 0xFF)
        b = UInt8(value & 0xFF)
    }
}
