#!/usr/bin/env swift

import SwiftUI
import AppKit

struct CaltrainAppIcon: View {
    let darkMode: Bool
    let tinted: Bool

    var body: some View {
        ZStack {
            // Background gradient
            if tinted {
                Color.white
            } else {
                LinearGradient(
                    colors: darkMode ? [
                        Color(red: 0.95, green: 0.2, blue: 0.2),
                        Color(red: 0.85, green: 0.05, blue: 0.05)
                    ] : [
                        Color(red: 0.9, green: 0.1, blue: 0.1),
                        Color(red: 0.8, green: 0.0, blue: 0.0)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }

            VStack(spacing: 0) {
                Spacer()

                // ICE train front - sleek aerodynamic bullet nose
                ZStack {
                    // Main bullet-shaped nose
                    ICETrainNose()
                        .fill(iconColor)
                        .frame(width: 480, height: 600)
                        .shadow(color: shadowColor.opacity(0.3), radius: 10, x: 0, y: 5)

                    VStack(spacing: 0) {
                        // Large wraparound windshield
                        ICEWindshield()
                            .fill(windowColor)
                            .frame(width: 400, height: 240)
                            .overlay(
                                ICEWindshield()
                                    .stroke(iconColor.opacity(0.15), lineWidth: 3)
                            )
                            .offset(y: -80)

                        Spacer()

                        // Red stripe accent (ICE characteristic)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(stripeColor)
                            .frame(width: 420, height: 16)
                            .offset(y: 60)

                        Spacer()

                        // Headlights at bottom
                        HStack(spacing: 320) {
                            Circle()
                                .fill(headlightColor)
                                .frame(width: 50, height: 50)
                                .overlay(
                                    Circle()
                                        .stroke(iconColor.opacity(0.3), lineWidth: 3)
                                )

                            Circle()
                                .fill(headlightColor)
                                .frame(width: 50, height: 50)
                                .overlay(
                                    Circle()
                                        .stroke(iconColor.opacity(0.3), lineWidth: 3)
                                )
                        }
                        .offset(y: 170)

                        // Coupler/buffer area
                        RoundedRectangle(cornerRadius: 6)
                            .fill(shadowColor)
                            .frame(width: 80, height: 24)
                            .offset(y: 210)
                    }
                    .frame(width: 480, height: 600)
                }
                .frame(height: 650)

                // Railway tracks (converging perspective)
                ZStack {
                    // Sleepers (cross ties)
                    ForEach(0..<5, id: \.self) { i in
                        let progress = CGFloat(i) / 4.0
                        let width = 420 - (progress * 220)
                        let yPos = progress * 100

                        RoundedRectangle(cornerRadius: 3)
                            .fill(trackColor.opacity(0.5))
                            .frame(width: width, height: 10)
                            .offset(y: yPos + 10)
                    }

                    // Left rail
                    Path { path in
                        path.move(to: CGPoint(x: 360, y: 10))
                        path.addLine(to: CGPoint(x: 220, y: 110))
                    }
                    .stroke(trackColor, style: StrokeStyle(lineWidth: 18, lineCap: .round))

                    // Right rail
                    Path { path in
                        path.move(to: CGPoint(x: 664, y: 10))
                        path.addLine(to: CGPoint(x: 804, y: 110))
                    }
                    .stroke(trackColor, style: StrokeStyle(lineWidth: 18, lineCap: .round))
                }
                .frame(height: 130)

                Spacer()
            }
            .frame(width: 1024, height: 1024)
        }
        .frame(width: 1024, height: 1024)
    }

    var iconColor: Color {
        tinted ? .black : .white
    }

    var headlightColor: Color {
        if tinted { return Color.black.opacity(0.7) }
        return darkMode ? Color(red: 1.0, green: 0.95, blue: 0.5) : Color(red: 1.0, green: 0.9, blue: 0.3)
    }

    var windowColor: Color {
        if tinted { return Color.black.opacity(0.35) }
        return darkMode ? Color(red: 0.2, green: 0.4, blue: 0.6, opacity: 0.6) : Color(red: 0.15, green: 0.35, blue: 0.55, opacity: 0.5)
    }

    var shadowColor: Color {
        if tinted { return Color.black.opacity(0.5) }
        return darkMode ? Color.black.opacity(0.4) : Color.black.opacity(0.2)
    }

    var stripeColor: Color {
        if tinted { return Color.black.opacity(0.6) }
        return darkMode ? Color.white.opacity(0.25) : Color.white.opacity(0.3)
    }

    var trackColor: Color {
        tinted ? .black : Color.white.opacity(0.85)
    }
}

// ICE train aerodynamic bullet nose shape
struct ICETrainNose: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height

        // Start from bottom left
        path.move(to: CGPoint(x: 0, y: height))

        // Left side curves inward toward top
        path.addCurve(
            to: CGPoint(x: width * 0.15, y: height * 0.3),
            control1: CGPoint(x: 0, y: height * 0.7),
            control2: CGPoint(x: width * 0.05, y: height * 0.45)
        )

        // Top rounded nose - very smooth bullet shape
        path.addCurve(
            to: CGPoint(x: width * 0.5, y: 0),
            control1: CGPoint(x: width * 0.2, y: height * 0.1),
            control2: CGPoint(x: width * 0.35, y: 0)
        )

        path.addCurve(
            to: CGPoint(x: width * 0.85, y: height * 0.3),
            control1: CGPoint(x: width * 0.65, y: 0),
            control2: CGPoint(x: width * 0.8, y: height * 0.1)
        )

        // Right side curves back to bottom
        path.addCurve(
            to: CGPoint(x: width, y: height),
            control1: CGPoint(x: width * 0.95, y: height * 0.45),
            control2: CGPoint(x: width, y: height * 0.7)
        )

        path.closeSubpath()
        return path
    }
}

// ICE train characteristic wraparound windshield
struct ICEWindshield: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height

        // Start from bottom left
        path.move(to: CGPoint(x: width * 0.1, y: height))

        // Left side curves inward
        path.addCurve(
            to: CGPoint(x: width * 0.25, y: height * 0.2),
            control1: CGPoint(x: width * 0.1, y: height * 0.6),
            control2: CGPoint(x: width * 0.15, y: height * 0.3)
        )

        // Top curve
        path.addCurve(
            to: CGPoint(x: width * 0.75, y: height * 0.2),
            control1: CGPoint(x: width * 0.35, y: height * 0.05),
            control2: CGPoint(x: width * 0.65, y: height * 0.05)
        )

        // Right side curves back
        path.addCurve(
            to: CGPoint(x: width * 0.9, y: height),
            control1: CGPoint(x: width * 0.85, y: height * 0.3),
            control2: CGPoint(x: width * 0.9, y: height * 0.6)
        )

        path.closeSubpath()
        return path
    }
}

// Trapezoid shape for train bottom
struct Trapezoid: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        let inset: CGFloat = 50

        path.move(to: CGPoint(x: inset, y: 0))
        path.addLine(to: CGPoint(x: width - inset, y: 0))
        path.addLine(to: CGPoint(x: width, y: height))
        path.addLine(to: CGPoint(x: 0, y: height))
        path.closeSubpath()

        return path
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
