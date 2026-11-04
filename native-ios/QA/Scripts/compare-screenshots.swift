import AppKit
import Darwin
import Foundation

struct ImageLoadError: Error, CustomStringConvertible {
    let description: String
}

func bitmap(_ path: String) throws -> NSBitmapImageRep {
    guard let image = NSImage(contentsOfFile: path) else { throw ImageLoadError(description: "Cannot read image: \(path)") }
    var rect = CGRect(origin: .zero, size: image.size)
    guard let cgImage = image.cgImage(forProposedRect: &rect, context: nil, hints: nil) else {
        throw ImageLoadError(description: "Cannot decode image: \(path)")
    }
    return NSBitmapImageRep(cgImage: cgImage)
}

func rgb(_ color: NSColor) -> (CGFloat, CGFloat, CGFloat) {
    let converted = color.usingColorSpace(.deviceRGB) ?? color
    return (converted.redComponent, converted.greenComponent, converted.blueComponent)
}

let args = CommandLine.arguments
guard args.count >= 3 else {
    fputs("Usage: compare-screenshots.swift candidate.png approved.png [diff.png] [max-difference-percent]\n", stderr)
    exit(2)
}

do {
    let candidate = try bitmap(args[1])
    let approved = try bitmap(args[2])
    guard candidate.pixelsWide == approved.pixelsWide && candidate.pixelsHigh == approved.pixelsHigh else {
        throw ImageLoadError(description: "Image sizes differ: candidate \(candidate.pixelsWide)x\(candidate.pixelsHigh), approved \(approved.pixelsWide)x\(approved.pixelsHigh). Use the same simulator size.")
    }

    let width = candidate.pixelsWide
    let height = candidate.pixelsHigh
    let pixelLimit: CGFloat = 12 / 255
    let maxPercent = args.count > 4 ? (Double(args[4]) ?? 0.5) : 0.5
    let diff = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: width,
        pixelsHigh: height,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    )!

    var changed = 0
    for y in 0..<height {
        for x in 0..<width {
            guard let a = candidate.colorAt(x: x, y: y), let b = approved.colorAt(x: x, y: y) else { continue }
            let ca = rgb(a), cb = rgb(b)
            let delta = max(abs(ca.0 - cb.0), max(abs(ca.1 - cb.1), abs(ca.2 - cb.2)))
            if delta > pixelLimit {
                changed += 1
                diff.setColor(NSColor(calibratedRed: 1, green: 0.04, blue: 0.04, alpha: 1), atX: x, y: y)
            } else {
                diff.setColor(NSColor(calibratedRed: 0.16, green: 0.16, blue: 0.16, alpha: 1), atX: x, y: y)
            }
        }
    }

    let total = width * height
    let percent = Double(changed) * 100 / Double(total)
    let diffPath = args.count > 3 ? args[3] : "screenshot-diff.png"
    if let data = diff.representation(using: .png, properties: [:]) {
        try data.write(to: URL(fileURLWithPath: diffPath), options: .atomic)
    }
    print(String(format: "Changed pixels: %d / %d (%.3f%%); allowed: %.3f%%", changed, total, percent, maxPercent))
    print("Difference image: \(diffPath)")
    if percent > maxPercent { exit(1) }
} catch {
    fputs("Screenshot comparison failed: \(error)\n", stderr)
    exit(2)
}
