#!/usr/bin/env swift
// Generates Hum app icon: waveform on a purple gradient background
import AppKit
import Foundation

let sizes: [(name: String, size: CGFloat)] = [
    ("icon_16x16", 16),
    ("icon_16x16@2x", 32),
    ("icon_32x32", 32),
    ("icon_32x32@2x", 64),
    ("icon_128x128", 128),
    ("icon_128x128@2x", 256),
    ("icon_256x256", 256),
    ("icon_256x256@2x", 512),
    ("icon_512x512", 512),
    ("icon_512x512@2x", 1024),
]

let iconsetDir = "Hum.iconset"
try? FileManager.default.removeItem(atPath: iconsetDir)
try FileManager.default.createDirectory(atPath: iconsetDir, withIntermediateDirectories: true)

for (name, size) in sizes {
    let image = NSImage(size: NSSize(width: size, height: size))
    image.lockFocus()

    let rect = NSRect(x: 0, y: 0, width: size, height: size)
    let cornerRadius = size * 0.22

    // Rounded rect clip
    let path = NSBezierPath(roundedRect: rect, xRadius: cornerRadius, yRadius: cornerRadius)
    path.addClip()

    // Purple gradient background
    let gradient = NSGradient(colors: [
        NSColor(red: 0.55, green: 0.23, blue: 0.87, alpha: 1.0),
        NSColor(red: 0.35, green: 0.15, blue: 0.75, alpha: 1.0),
    ])!
    gradient.draw(in: rect, angle: -45)

    // Draw waveform symbol
    if let symbol = NSImage(systemSymbolName: "waveform", accessibilityDescription: nil) {
        let config = NSImage.SymbolConfiguration(pointSize: size * 0.45, weight: .medium)
        let configured = symbol.withSymbolConfiguration(config)!
        let symbolSize = configured.size
        let x = (size - symbolSize.width) / 2
        let y = (size - symbolSize.height) / 2
        configured.draw(
            in: NSRect(x: x, y: y, width: symbolSize.width, height: symbolSize.height),
            from: .zero,
            operation: .sourceOver,
            fraction: 1.0
        )
        // Draw it white by compositing
        NSColor.white.setFill()
        NSRect(x: x, y: y, width: symbolSize.width, height: symbolSize.height).fill(using: .sourceAtop)
    }

    image.unlockFocus()

    // Save as PNG
    guard let tiff = image.tiffRepresentation,
          let bitmap = NSBitmapImageRep(data: tiff),
          let png = bitmap.representation(using: .png, properties: [:])
    else {
        print("Failed to render \(name)")
        continue
    }
    try png.write(to: URL(fileURLWithPath: "\(iconsetDir)/\(name).png"))
    print("Generated \(name).png (\(Int(size))x\(Int(size)))")
}

print("Converting to .icns...")
let process = Process()
process.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
process.arguments = ["-c", "icns", iconsetDir, "-o", "Resources/AppIcon.icns"]
try process.run()
process.waitUntilExit()

if process.terminationStatus == 0 {
    print("Created Resources/AppIcon.icns")
    try? FileManager.default.removeItem(atPath: iconsetDir)
} else {
    print("iconutil failed with status \(process.terminationStatus)")
}
