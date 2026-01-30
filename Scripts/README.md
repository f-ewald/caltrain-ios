# Scripts

This directory contains utility scripts for the Caltrain Real-Time Tracking app.

## App Icon Generator

### AppIconGenerator.swift

Swift script that generates app icons programmatically using SwiftUI.

**What it generates:**
- `AppIcon-1024.png` - Standard light mode icon
- `AppIcon-Dark-1024.png` - Dark mode variant
- `AppIcon-Tinted-1024.png` - Tinted monochrome variant for iOS 18

**Design:**
- Modern train front view with Caltrain red gradient background
- White train silhouette with yellow headlights
- Converging railway tracks for depth
- All icons are 1024x1024 PNG format

**To regenerate icons:**

```bash
# Run from project root
swift Scripts/AppIconGenerator.swift
```

**Output location:**
`Scripts/GeneratedIcons/`

**To update app icons:**

1. Run the generator script
2. Icons are automatically copied to:
   - `realtime-caltrain/Assets.xcassets/AppIcon.appiconset/`
   - `CaltrainWidget/Assets.xcassets/AppIcon.appiconset/`
3. Contents.json files reference the images

**Design specifications:**
- **Background**: Red gradient (#E61919 → #CC0000)
- **Foreground**: White train with yellow headlights
- **Dark Mode**: Lighter red gradient, brighter headlights
- **Tinted**: Monochrome black on white for system tinting
