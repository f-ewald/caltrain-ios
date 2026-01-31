#!/usr/bin/env swift

import SwiftUI
import AppKit

struct TrainLogo: View {
    var size: CGFloat = 60
    var color: Color = .red

    var body: some View {
        GeometryReader { geometry in
            let s = geometry.size.width

            ZStack {
                // Main train body - front view
                RoundedRectangle(cornerRadius: s * 0.12)
                    .fill(color)
                    .frame(width: s * 0.75, height: s * 0.85)

                // Top rounded roof
                Circle()
                    .fill(color)
                    .frame(width: s * 0.75, height: s * 0.3)
                    .offset(y: -s * 0.35)
                    .clipShape(
                        Rectangle()
                            .offset(y: -s * 0.15)
                    )

                // Large front windshield
                RoundedRectangle(cornerRadius: s * 0.08)
                    .fill(Color.white.opacity(0.9))
                    .frame(width: s * 0.55, height: s * 0.35)
                    .offset(y: -s * 0.15)

                // Side windows
                HStack(spacing: s * 0.35) {
                    RoundedRectangle(cornerRadius: s * 0.04)
                        .fill(Color.white.opacity(0.85))
                        .frame(width: s * 0.15, height: s * 0.2)

                    RoundedRectangle(cornerRadius: s * 0.04)
                        .fill(Color.white.opacity(0.85))
                        .frame(width: s * 0.15, height: s * 0.2)
                }
                .offset(y: s * 0.15)

                // Bottom bumper/cowcatcher
                Path { path in
                    path.move(to: CGPoint(x: s * 0.125, y: s * 0.5))
                    path.addLine(to: CGPoint(x: s * 0.2, y: s * 0.48))
                    path.addLine(to: CGPoint(x: s * 0.8, y: s * 0.48))
                    path.addLine(to: CGPoint(x: s * 0.875, y: s * 0.5))
                }
                .fill(color.opacity(0.8))
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .frame(width: size, height: size)
    }
}

// App icon wrapper with background variants
struct CaltrainAppIcon: View {
    let darkMode: Bool
    let tinted: Bool

    var body: some View {
        ZStack {
            // Background
            if tinted {
                Color.white
            } else {
                LinearGradient(
                    colors: darkMode ? [
                        Color(red: 0.2, green: 0.2, blue: 0.2),
                        Color(red: 0.1, green: 0.1, blue: 0.1)
                    ] : [
                        Color.white,
                        Color(red: 0.85, green: 0.85, blue: 0.85)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }

            // TrainLogo centered
            TrainLogo(size: 800, color: logoColor)
        }
        .frame(width: 1024, height: 1024)
    }

    var logoColor: Color {
        if tinted {
            return .black
        } else {
            return .red
        }
    }
}

// Export function
@MainActor
func generateIcons() async {
    print("Generating app icons...")

    let outputDir = FileManager.default.currentDirectoryPath + "/Scripts/GeneratedIcons"
    try? FileManager.default.createDirectory(atPath: outputDir, withIntermediateDirectories: true)

    let variants = [
        ("AppIcon-1024.png", false, false),
        ("AppIcon-Dark-1024.png", true, false),
        ("AppIcon-Tinted-1024.png", false, true)
    ]

    for (filename, darkMode, tinted) in variants {
        let icon = CaltrainAppIcon(darkMode: darkMode, tinted: tinted)
        let renderer = ImageRenderer(content: icon)
        renderer.scale = 1.0

        if let cgImage = renderer.cgImage {
            let nsImage = NSImage(cgImage: cgImage, size: NSSize(width: 1024, height: 1024))
            if let tiffData = nsImage.tiffRepresentation,
               let bitmapImage = NSBitmapImageRep(data: tiffData),
               let pngData = bitmapImage.representation(using: .png, properties: [:]) {
                let outputPath = outputDir + "/" + filename
                try? pngData.write(to: URL(fileURLWithPath: outputPath))
                print("✓ Generated: \(filename)")
            }
        }
    }

    print("\nIcons saved to: \(outputDir)")
    print("\nNext steps:")
    print("1. Copy generated icons to:")
    print("   - realtime-caltrain/Assets.xcassets/AppIcon.appiconset/")
    print("   - CaltrainWidget/Assets.xcassets/AppIcon.appiconset/")
    print("2. Update Contents.json to reference the images")
}

// Run the generator
await generateIcons()
