// Compose genuine Pause captures; never draw or reconstruct app controls.
// swiftc -warnings-as-errors tools/AppStoreScreenshots/render.swift -o Build/render-pause-screenshots
import AppKit
import ImageIO
import UniformTypeIdentifiers

let root = URL(fileURLWithPath: CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "docs/app-store/screenshot-redesign-2026-10-17")
let fm = FileManager.default
let approvalRecorded = fm.fileExists(atPath: root.appendingPathComponent("approval.json").path)
func color(_ hex: UInt32) -> NSColor {
    NSColor(srgbRed: CGFloat((hex >> 16) & 255) / 255, green: CGFloat((hex >> 8) & 255) / 255, blue: CGFloat(hex & 255) / 255, alpha: 1)
}
let ink = color(0x173D40), secondary = color(0x496C70), accent = color(0x287C79)
struct Card {
    let key: String
    let title: String
    let detail: String
    let dark: Bool
}
let cards = [
    Card(key: "start", title: "Take a breathing break.", detail: "Choose a ritual. Begin when you're ready.", dark: false),
    Card(key: "breathing", title: "Follow your breath.", detail: "A gentle pulse. Clear cues for each phase.", dark: false),
    Card(key: "night", title: "Let the day wind down.", detail: "A darker session. The option to hide the clock.", dark: true),
    Card(key: "reflection", title: "Finish with a check-in.", detail: "Calm, Okay, or Restless. A moment to reflect.", dark: false),
    Card(key: "insights", title: "See your rhythm.", detail: "Completed sessions, averages, and a calendar.", dark: false)
]

func source(_ file: String) throws -> CGImage {
    guard let s = CGImageSourceCreateWithURL(root.appendingPathComponent(file) as CFURL, nil),
          let image = CGImageSourceCreateImageAtIndex(s, 0, nil) else {
        throw NSError(domain: "PauseScreenshot", code: 1, userInfo: [NSLocalizedDescriptionKey: "Missing capture \(file)"])
    }
    return image
}
func canvas(_ w: Int, _ h: Int, fill: NSColor, draw: (CGContext) throws -> Void) throws -> CGImage {
    let ctx = CGContext(data: nil, width: w, height: h, bitsPerComponent: 8, bytesPerRow: w * 4,
                        space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
    ctx.interpolationQuality = .high
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(cgContext: ctx, flipped: false)
    fill.setFill(); NSRect(x: 0, y: 0, width: w, height: h).fill()
    try draw(ctx)
    NSGraphicsContext.restoreGraphicsState()
    return ctx.makeImage()!
}
func write(_ img: CGImage, _ file: String) throws {
    let dest = root.appendingPathComponent(file)
    try fm.createDirectory(at: dest.deletingLastPathComponent(), withIntermediateDirectories: true)
    let writer = CGImageDestinationCreateWithURL(dest as CFURL, UTType.png.identifier as CFString, 1, nil)!
    CGImageDestinationAddImage(writer, img, nil)
    guard CGImageDestinationFinalize(writer) else { fatalError("Could not export \(file)") }
}
func text(_ value: String, _ rect: CGRect, _ size: CGFloat, weight: NSFont.Weight = .regular,
          color: NSColor = ink, tracking: CGFloat = 0, canvasHeight: CGFloat) {
    let p = NSMutableParagraphStyle(); p.lineBreakMode = .byWordWrapping
    let font = NSFont.systemFont(ofSize: size, weight: weight)
    let rounded = NSFont(descriptor: font.fontDescriptor.withDesign(.rounded) ?? font.fontDescriptor, size: size) ?? font
    let attrs: [NSAttributedString.Key: Any] = [.font: rounded, .foregroundColor: color, .kern: tracking, .paragraphStyle: p]
    let measure = (value as NSString).boundingRect(with: NSSize(width: rect.width, height: .greatestFiniteMagnitude), options: [.usesLineFragmentOrigin, .usesFontLeading], attributes: attrs)
    precondition(measure.height <= rect.height + 2, "Caption clips: \(value) (\(measure.height) > \(rect.height))")
    (value as NSString).draw(in: NSRect(x: rect.minX, y: canvasHeight - rect.maxY, width: rect.width, height: rect.height), withAttributes: attrs)
}

var manifest: [[String: Any]] = []
var rendered: [String: [CGImage]] = [:]
for platform in ["iphone", "ipad"] {
    let isPad = platform == "ipad"
    let w: CGFloat = isPad ? 2064 : 1320, h: CGFloat = isPad ? 2752 : 2868
    rendered[platform] = []
    for (index, card) in cards.enumerated() {
        let rawFile = "raw/\(platform)-\(card.key).png"
        let image = try source(rawFile)
        let bg = card.dark ? color(0x10182B) : color(index == 4 ? 0xEEF2FA : 0xE3F2F3)
        let fg = card.dark ? color(0xF2F5FD) : ink
        let sub = card.dark ? color(0xBBC9DC) : secondary
        let margin: CGFloat = isPad ? 112 : 66
        // Remove only system chrome and unused outer space. Every retained app
        // pixel keeps its original relationship to the other controls.
        let crop: CGRect
        if isPad {
            switch card.key {
            case "start": crop = CGRect(x: 110, y: 80, width: 1844, height: 2040)
            case "breathing", "night": crop = CGRect(x: 110, y: 270, width: 1844, height: 2160)
            case "reflection": crop = CGRect(x: 110, y: 80, width: 1844, height: 2300)
            default: crop = CGRect(x: 460, y: 532, width: 1140, height: 1740)
            }
        } else {
            switch card.key {
            case "breathing", "night": crop = CGRect(x: 0, y: 440, width: 1320, height: 2230)
            default: crop = CGRect(x: 0, y: 145, width: 1320, height: 2590)
            }
        }
        precondition(crop.maxX <= CGFloat(image.width) && crop.maxY <= CGFloat(image.height))
        let cropped = image.cropping(to: crop)!
        let top: CGFloat = isPad ? 470 : 415
        let available = CGRect(x: margin, y: 80, width: w - margin * 2, height: h - top - 80)
        let scale = min(available.width / crop.width, available.height / crop.height)
        let drawRect = CGRect(x: (w - crop.width * scale) / 2, y: h - top - crop.height * scale,
                              width: crop.width * scale, height: crop.height * scale)
        let result = try canvas(Int(w), Int(h), fill: bg) { ctx in
            text("PAUSE", CGRect(x: margin, y: 64, width: 500, height: 65), isPad ? 33 : 28,
                 weight: .medium, color: card.dark ? sub : accent, tracking: 5, canvasHeight: h)
            text(String(format: "%02d / 05", index + 1), CGRect(x: w - margin - 220, y: 68, width: 220, height: 52),
                 isPad ? 28 : 24, color: sub, tracking: 2, canvasHeight: h)
            if isPad {
                // Tablet caption is a horizontal editorial strip. The broad
                // native iPad layout remains large beneath it.
                text(card.title, CGRect(x: margin - 4, y: 164, width: 1120, height: 250), 114,
                     weight: .medium, color: fg, tracking: -3.8, canvasHeight: h)
                text(card.detail, CGRect(x: 1370, y: 196, width: 570, height: 200), 42,
                     color: sub, canvasHeight: h)
            } else {
                text(card.title, CGRect(x: margin - 3, y: 148, width: w - margin * 2 + 6, height: 124), 88,
                     weight: .medium, color: fg, tracking: -3.5, canvasHeight: h)
                text(card.detail, CGRect(x: margin, y: 284, width: w - margin * 2, height: 92), 36,
                     color: sub, canvasHeight: h)
            }
            // A modest crop boundary, no fabricated bezel, reflection, or shadow.
            ctx.saveGState()
            let radius: CGFloat = isPad && card.key == "insights" ? 80 : (isPad ? 24 : 20)
            ctx.addPath(CGPath(roundedRect: drawRect, cornerWidth: radius, cornerHeight: radius, transform: nil))
            ctx.clip(); ctx.draw(cropped, in: drawRect); ctx.restoreGState()
        }
        let file = "\(platform)/\(String(format: "%02d", index + 1))-\(card.key).png"
        try write(result, file)
        rendered[platform]!.append(result)
        manifest.append(["platform": platform, "file": file, "source": rawFile, "title": card.title,
                         "caption": card.detail, "width": Int(w), "height": Int(h), "status": approvalRecorded ? "approved" : "proposed",
                         "sourceCrop": ["x": crop.minX, "y": crop.minY, "width": crop.width, "height": crop.height],
                         "uniformScale": scale, "drawRect": ["x": drawRect.minX, "y": drawRect.minY, "width": drawRect.width, "height": drawRect.height]])
    }
    let thumbW: CGFloat = isPad ? 390 : 285, gap: CGFloat = 18, pad: CGFloat = 28, header: CGFloat = 90
    let thumbH = thumbW * h / w
    let sw = Int(pad * 2 + thumbW * 5 + gap * 4), sh = Int(header + thumbH + pad)
    let sheet = try canvas(sw, sh, fill: color(0xF8FAF9)) { ctx in
        text("PAUSE / \(isPad ? "iPad" : "iPhone") / Proposed sequence", CGRect(x: pad, y: 26, width: 1800, height: 45), 25, weight: .medium, canvasHeight: CGFloat(sh))
        for (index, image) in rendered[platform]!.enumerated() {
            ctx.draw(image, in: CGRect(x: pad + CGFloat(index) * (thumbW + gap), y: pad, width: thumbW, height: thumbH))
        }
    }
    try write(sheet, "\(platform)-sequence.png")
}
try JSONSerialization.data(withJSONObject: manifest, options: [.prettyPrinted, .sortedKeys]).write(to: root.appendingPathComponent("manifest.json"))
print("Rendered 10 proposed screenshots and two contact sheets at \(root.path)")
