#!/usr/bin/env swift
import Cocoa

let srcPath = "/Users/dominik/.gemini/antigravity/brain/5b675117-03ef-4406-98aa-4823df83838b/.user_uploaded/media_1794163999324_476afeba.jpg"
guard let srcImg = NSImage(contentsOfFile: srcPath),
      let tiff = srcImg.tiffRepresentation,
      let srcRep = NSBitmapImageRep(data: tiff),
      let cgSrc = srcRep.cgImage else {
    fatalError("Failed to load source image")
}

// Bounding box of the squircle in the source image
// Light icon: x = 42, y = 264, size = 452 x 452
// Dark icon:  x = 531, y = 265, size = 452 x 452

let lightCropRect = CGRect(x: 42, y: 264, width: 452, height: 452)
let darkCropRect  = CGRect(x: 531, y: 265, width: 452, height: 452)

guard let lightCropped = cgSrc.cropping(to: lightCropRect),
      let darkCropped  = cgSrc.cropping(to: darkCropRect) else {
    fatalError("Failed to crop icons")
}

func generateIcon(croppedCG: CGImage, pixelSize: Int, isDark: Bool) -> Data? {
    let size = CGFloat(pixelSize)
    guard let colorSpace = CGColorSpace(name: CGColorSpace.sRGB),
          let context = CGContext(
            data: nil,
            width: pixelSize,
            height: pixelSize,
            bitsPerComponent: 8,
            bytesPerRow: pixelSize * 4,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
          ) else { return nil }

    context.setAllowsAntialiasing(true)
    context.setShouldAntialias(true)

    let scale = size / 1024.0

    // Standard macOS squircle grid
    let bodySize: CGFloat = 824.0 * scale
    let bodyOrigin: CGFloat = 100.0 * scale
    let cornerRadius: CGFloat = 185.0 * scale
    let destRect = CGRect(x: bodyOrigin, y: bodyOrigin, width: bodySize, height: bodySize)
    let squirclePath = CGPath(roundedRect: destRect, cornerWidth: cornerRadius, cornerHeight: cornerRadius, transform: nil)

    // 1. Subtle drop shadow
    context.saveGState()
    context.setShadow(
        offset: CGSize(width: 0, height: -10.0 * scale),
        blur: 20.0 * scale,
        color: NSColor.black.withAlphaComponent(isDark ? 0.40 : 0.22).cgColor
    )
    context.addPath(squirclePath)
    context.setFillColor(NSColor.black.withAlphaComponent(0.01).cgColor)
    context.fillPath()
    context.restoreGState()

    // 2. Draw cropped artwork clipped to squircle
    context.saveGState()
    context.addPath(squirclePath)
    context.clip()

    // Flip coordinates for drawing CGImage
    context.saveGState()
    context.translateBy(x: destRect.minX, y: destRect.maxY)
    context.scaleBy(x: 1.0, y: -1.0)
    context.draw(croppedCG, in: CGRect(x: 0, y: 0, width: destRect.width, height: destRect.height))
    context.restoreGState()

    // 3. Subtle inner border highlight
    context.setStrokeColor(NSColor.white.withAlphaComponent(isDark ? 0.25 : 0.40).cgColor)
    context.setLineWidth(1.5 * scale)
    context.addPath(squirclePath)
    context.strokePath()

    context.restoreGState()

    guard let cgResult = context.makeImage() else { return nil }
    let rep = NSBitmapImageRep(cgImage: cgResult)
    return rep.representation(using: .png, properties: [:])
}

let targetDir = "Tidy/Resources/Assets.xcassets/AppIcon.appiconset"

let sizes: [(String, String, Int)] = [
    ("icon_16x16.png", "icon_16x16_dark.png", 16),
    ("icon_16x16@2x.png", "icon_16x16@2x_dark.png", 32),
    ("icon_32x32.png", "icon_32x32_dark.png", 32),
    ("icon_32x32@2x.png", "icon_32x32@2x_dark.png", 64),
    ("icon_128x128.png", "icon_128x128_dark.png", 128),
    ("icon_128x128@2x.png", "icon_128x128@2x_dark.png", 256),
    ("icon_256x256.png", "icon_256x256_dark.png", 256),
    ("icon_256x256@2x.png", "icon_256x256@2x_dark.png", 512),
    ("icon_512x512.png", "icon_512x512_dark.png", 512),
    ("icon_512x512@2x.png", "icon_512x512@2x_dark.png", 1024)
]

for (lightName, darkName, px) in sizes {
    if let lightData = generateIcon(croppedCG: lightCropped, pixelSize: px, isDark: false) {
        try? lightData.write(to: URL(fileURLWithPath: "\(targetDir)/\(lightName)"))
    }
    if let darkData = generateIcon(croppedCG: darkCropped, pixelSize: px, isDark: true) {
        try? darkData.write(to: URL(fileURLWithPath: "\(targetDir)/\(darkName)"))
    }
}

// Generate standalone 1024x1024 icons for dynamic runtime switching via AppIconManager
if let light1024 = generateIcon(croppedCG: lightCropped, pixelSize: 1024, isDark: false) {
    try? light1024.write(to: URL(fileURLWithPath: "Tidy/Resources/AppIconLight.png"))
}
if let dark1024 = generateIcon(croppedCG: darkCropped, pixelSize: 1024, isDark: true) {
    try? dark1024.write(to: URL(fileURLWithPath: "Tidy/Resources/AppIconDark.png"))
}

print("Successfully generated user Light and Dark mode app icons.")
