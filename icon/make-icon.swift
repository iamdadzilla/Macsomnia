import AppKit

// Renders the KeepAwake app icon (red rounded square with a white,
// crossed-out "Zzz") to a PNG at the path given as the first argument.
// Usage: swift make-icon.swift <output.png> [sizePx]

let outPath = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "icon_master.png"
let size = CommandLine.arguments.count > 2 ? CGFloat(Int(CommandLine.arguments[2]) ?? 1024) : 1024

guard let rep = NSBitmapImageRep(
    bitmapDataPlanes: nil,
    pixelsWide: Int(size), pixelsHigh: Int(size),
    bitsPerSample: 8, samplesPerPixel: 4,
    hasAlpha: true, isPlanar: false,
    colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
) else { fatalError("could not create bitmap rep") }

NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
let ctx = NSGraphicsContext.current!.cgContext

// Transparent canvas; the rounded square is the icon silhouette.
ctx.clear(CGRect(x: 0, y: 0, width: size, height: size))

let inset = size * 0.086          // macOS icon art safe-area padding
let rect = CGRect(x: inset, y: inset, width: size - 2 * inset, height: size - 2 * inset)
let radius = rect.width * 0.2237  // ~ continuous-corner ratio
let shape = NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)

// Red vertical gradient fill.
ctx.saveGState()
shape.addClip()
let grad = CGGradient(
    colorsSpace: CGColorSpaceCreateDeviceRGB(),
    colors: [
        NSColor(srgbRed: 0.90, green: 0.19, blue: 0.19, alpha: 1).cgColor,
        NSColor(srgbRed: 0.60, green: 0.05, blue: 0.08, alpha: 1).cgColor,
    ] as CFArray,
    locations: [0, 1]
)!
ctx.drawLinearGradient(grad, start: CGPoint(x: 0, y: size), end: CGPoint(x: 0, y: 0), options: [])
ctx.restoreGState()

// White "Zzz".
let text = "Zzz" as NSString
let font = NSFont.systemFont(ofSize: size * 0.40, weight: .heavy)
let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: NSColor.white]
let tsize = text.size(withAttributes: attrs)
text.draw(at: CGPoint(x: (size - tsize.width) / 2, y: (size - tsize.height) / 2 - size * 0.01),
          withAttributes: attrs)

// Prohibition-style slash: draw a wider background-red pass first (a "gap"),
// then a white line on top, so the slash reads as crossing the letters.
func drawSlash(color: NSColor, width: CGFloat) {
    let p = NSBezierPath()
    p.move(to: CGPoint(x: inset + rect.width * 0.16, y: size - inset - rect.width * 0.16))
    p.line(to: CGPoint(x: size - inset - rect.width * 0.16, y: inset + rect.width * 0.16))
    p.lineWidth = width
    p.lineCapStyle = .round
    color.setStroke()
    p.stroke()
}
drawSlash(color: NSColor(srgbRed: 0.74, green: 0.10, blue: 0.12, alpha: 1), width: size * 0.15)
drawSlash(color: .white, width: size * 0.082)

NSGraphicsContext.restoreGraphicsState()

guard let png = rep.representation(using: .png, properties: [:]) else {
    fatalError("could not encode PNG")
}
try! png.write(to: URL(fileURLWithPath: outPath))
FileHandle.standardError.write(Data("wrote \(outPath) (\(Int(size))px)\n".utf8))
