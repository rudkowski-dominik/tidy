#!/usr/bin/env swift
import Cocoa

func renderIconToPNG(pixelSize: Int, path: String) {
    let width = pixelSize
    let height = pixelSize

    guard let colorSpace = CGColorSpace(name: CGColorSpace.sRGB),
          let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
          ) else { return }

    context.setAllowsAntialiasing(true)
    context.setShouldAntialias(true)

    let scale = CGFloat(pixelSize) / 1024.0

    // Standard macOS App Icon Grid (1024x1024 canvas):
    // Squircle size is 824x824, centered at (512, 512), origin at (100, 100)
    let bodySize: CGFloat = 824.0 * scale
    let bodyOrigin: CGFloat = 100.0 * scale
    let cornerRadius: CGFloat = 185.0 * scale
    let squircleRect = CGRect(x: bodyOrigin, y: bodyOrigin, width: bodySize, height: bodySize)

    // 1. Drop shadow beneath the squircle
    context.saveGState()
    context.setShadow(
        offset: CGSize(width: 0, height: -12.0 * scale),
        blur: 24.0 * scale,
        color: NSColor.black.withAlphaComponent(0.24).cgColor
    )

    let squirclePath = CGPath(
        roundedRect: squircleRect,
        cornerWidth: cornerRadius,
        cornerHeight: cornerRadius,
        transform: nil
    )

    context.addPath(squirclePath)
    context.setFillColor(NSColor.black.withAlphaComponent(0.01).cgColor)
    context.fillPath()
    context.restoreGState()

    // 2. Main Squircle Body with Gradient
    context.saveGState()
    context.addPath(squirclePath)
    context.clip()

    // Vibrant Modern Deep Blue to Royal Indigo gradient
    let topColor = NSColor(calibratedRed: 0.12, green: 0.62, blue: 0.99, alpha: 1.0).cgColor
    let midColor = NSColor(calibratedRed: 0.10, green: 0.42, blue: 0.92, alpha: 1.0).cgColor
    let bottomColor = NSColor(calibratedRed: 0.18, green: 0.22, blue: 0.82, alpha: 1.0).cgColor

    let colors = [topColor, midColor, bottomColor] as CFArray
    let locations: [CGFloat] = [0.0, 0.45, 1.0]
    if let gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: locations) {
        context.drawLinearGradient(
            gradient,
            start: CGPoint(x: squircleRect.midX, y: squircleRect.maxY),
            end: CGPoint(x: squircleRect.midX, y: squircleRect.minY),
            options: []
        )
    }

    // Top Specular Highlight (concentric subtle glass sheen)
    let highlightColors = [
        NSColor.white.withAlphaComponent(0.22).cgColor,
        NSColor.white.withAlphaComponent(0.0).cgColor
    ] as CFArray
    if let highlightGradient = CGGradient(colorsSpace: colorSpace, colors: highlightColors, locations: [0.0, 1.0]) {
        context.drawLinearGradient(
            highlightGradient,
            start: CGPoint(x: squircleRect.midX, y: squircleRect.maxY),
            end: CGPoint(x: squircleRect.midX, y: squircleRect.midY),
            options: []
        )
    }

    // Inner Border
    context.setStrokeColor(NSColor.white.withAlphaComponent(0.28).cgColor)
    context.setLineWidth(1.5 * scale)
    context.addPath(squirclePath)
    context.strokePath()

    context.restoreGState()

    // 3. Central Motif: Elegant, Harmonious 4-Point Sparkle + Satellite Stars
    func drawSparkle(center: CGPoint, radius: CGFloat, armWidth: CGFloat, alpha: CGFloat) {
        context.saveGState()
        let path = CGMutablePath()
        let r = radius
        let w = armWidth

        path.move(to: CGPoint(x: center.x, y: center.y + r))
        path.addQuadCurve(to: CGPoint(x: center.x + w, y: center.y), control: CGPoint(x: center.x + w * 0.18, y: center.y + w * 0.18))
        path.addQuadCurve(to: CGPoint(x: center.x + r, y: center.y), control: CGPoint(x: center.x + w * 0.18, y: center.y - w * 0.18))
        path.move(to: CGPoint(x: center.x + r, y: center.y))
        path.addQuadCurve(to: CGPoint(x: center.x, y: center.y - w), control: CGPoint(x: center.x + w * 0.18, y: center.y - w * 0.18))
        path.addQuadCurve(to: CGPoint(x: center.x, y: center.y - r), control: CGPoint(x: center.x - w * 0.18, y: center.y - w * 0.18))
        path.move(to: CGPoint(x: center.x, y: center.y - r))
        path.addQuadCurve(to: CGPoint(x: center.x - w, y: center.y), control: CGPoint(x: center.x - w * 0.18, y: center.y - w * 0.18))
        path.addQuadCurve(to: CGPoint(x: center.x - r, y: center.y), control: CGPoint(x: center.x - w * 0.18, y: center.y + w * 0.18))
        path.move(to: CGPoint(x: center.x - r, y: center.y))
        path.addQuadCurve(to: CGPoint(x: center.x, y: center.y + w), control: CGPoint(x: center.x - w * 0.18, y: center.y + w * 0.18))
        path.addQuadCurve(to: CGPoint(x: center.x, y: center.y + r), control: CGPoint(x: center.x + w * 0.18, y: center.y + w * 0.18))
        path.closeSubpath()

        // Soft drop glow under sparkle
        context.setShadow(
            offset: CGSize(width: 0, height: -2.0 * scale),
            blur: 14.0 * scale,
            color: NSColor(calibratedRed: 0.10, green: 0.30, blue: 0.85, alpha: 0.45).cgColor
        )

        context.setFillColor(NSColor.white.withAlphaComponent(alpha).cgColor)
        context.addPath(path)
        context.fillPath()
        context.restoreGState()
    }

    // Symmetrical, perfectly proportioned main star
    let center = CGPoint(x: squircleRect.midX - 15.0 * scale, y: squircleRect.midY)
    drawSparkle(center: center, radius: 210.0 * scale, armWidth: 44.0 * scale, alpha: 1.0)

    // Top right satellite sparkle
    let topSatellite = CGPoint(x: center.x + 160.0 * scale, y: center.y + 130.0 * scale)
    drawSparkle(center: topSatellite, radius: 95.0 * scale, armWidth: 22.0 * scale, alpha: 0.92)

    // Bottom left small twinkle
    let bottomTwinkle = CGPoint(x: center.x - 120.0 * scale, y: center.y - 120.0 * scale)
    drawSparkle(center: bottomTwinkle, radius: 48.0 * scale, armWidth: 12.0 * scale, alpha: 0.75)

    guard let cgImage = context.makeImage() else { return }
    let rep = NSBitmapImageRep(cgImage: cgImage)
    guard let pngData = rep.representation(using: .png, properties: [:]) else { return }
    try? pngData.write(to: URL(fileURLWithPath: path))
}

let targetDir = "Tidy/Resources/Assets.xcassets/AppIcon.appiconset"
let sizes: [(String, Int)] = [
    ("icon_16x16.png", 16),
    ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32),
    ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128),
    ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256),
    ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512),
    ("icon_512x512@2x.png", 1024)
]

for (filename, px) in sizes {
    renderIconToPNG(pixelSize: px, path: "\(targetDir)/\(filename)")
}
print("Successfully generated pixel-perfect macOS app icons.")
