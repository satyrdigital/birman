import AppKit
import Foundation

// Generate neutral "RU" icon with macOS built-in frameworks only.
// No keyboard event handling, shortcut reassignment, background service or daemon.
guard CommandLine.arguments.count == 2 else {
    fputs("Usage: swift render-neutral-icon.swift output.icns\n", stderr)
    exit(2)
}
let destination = URL(fileURLWithPath: CommandLine.arguments[1])
let fm = FileManager.default
let working = fm.temporaryDirectory.appendingPathComponent("birman-icon-\(UUID().uuidString)")
let iconset = working.appendingPathComponent("Russian.iconset")
try fm.createDirectory(at: iconset, withIntermediateDirectories: true)
defer { try? fm.removeItem(at: working) }

func render(_ pixels: Int, to url: URL) throws {
    guard let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: pixels, pixelsHigh: pixels,
        bitsPerSample: 8, samplesPerPixel: 4,
        hasAlpha: true, isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0, bitsPerPixel: 0
    ) else { throw NSError(domain: "Icon", code: 1) }

    rep.size = NSSize(width: pixels, height: pixels)
    guard let context = NSGraphicsContext(bitmapImageRep: rep) else {
        throw NSError(domain: "Icon", code: 2)
    }

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = context
    defer { NSGraphicsContext.restoreGraphicsState() }
    let rect = NSRect(x: 0, y: 0, width: pixels, height: pixels)
    NSColor.clear.setFill()
    rect.fill()

    let padding = CGFloat(pixels) * 0.05
    let background = rect.insetBy(dx: padding, dy: padding)
    NSColor(calibratedWhite: 0.22, alpha: 1).setFill()
    NSBezierPath(
        roundedRect: background,
        xRadius: CGFloat(pixels) * 0.20,
        yRadius: CGFloat(pixels) * 0.20
    ).fill()

    let font = NSFont.systemFont(ofSize: CGFloat(pixels) * 0.42, weight: .semibold)
    let attributes: [NSAttributedString.Key: Any] = [
        .font: font,
        .foregroundColor: NSColor.white
    ]
    let string = NSAttributedString(string: "RU", attributes: attributes)
    let size = string.size()
    string.draw(at: NSPoint(
        x: (CGFloat(pixels) - size.width) / 2,
        y: (CGFloat(pixels) - size.height) / 2
    ))
    context.flushGraphics()
    guard let data = rep.representation(using: .png, properties: [:]) else {
        throw NSError(domain: "Icon", code: 3)
    }
    try data.write(to: url)
}

for (name, pixels) in [
    ("icon_16x16.png", 16), ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32), ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128), ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256), ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512), ("icon_512x512@2x.png", 1024)
] {
    try render(pixels, to: iconset.appendingPathComponent(name))
}

let process = Process()
process.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
process.arguments = ["-c", "icns", "-o", destination.path, iconset.path]
try process.run()
process.waitUntilExit()
guard process.terminationStatus == 0 else {
    throw NSError(domain: "Icon", code: Int(process.terminationStatus))
}
print("Created neutral input-source icon: \(destination.path)")
