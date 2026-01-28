# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a SwiftUI-based iOS application for real-time Caltrain tracking. The project uses:
- **SwiftUI** for the UI framework
- **SwiftData** for data persistence and model management
- **Swift Testing** framework (not XCTest) for unit tests

## Building and Running

### Build the app
```bash
xcodebuild -project realtime-caltrain.xcodeproj -scheme realtime-caltrain -configuration Debug build
```

### Build and run on simulator
```bash
xcodebuild -project realtime-caltrain.xcodeproj -scheme realtime-caltrain -destination 'platform=iOS Simulator,name=iPhone 15' build
```

### Run tests
```bash
# Run all tests
xcodebuild test -project realtime-caltrain.xcodeproj -scheme realtime-caltrain -destination 'platform=iOS Simulator,name=iPhone 15'

# Run specific test
xcodebuild test -project realtime-caltrain.xcodeproj -scheme realtime-caltrain -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:realtime-caltrainTests/realtime_caltrainTests/example
```

## Architecture

### App Entry Point
- `realtime_caltrainApp.swift` - The main app struct with `@main` attribute
- Sets up SwiftData `ModelContainer` with a shared schema at app launch
- Model container is injected into the environment via `.modelContainer()` modifier

### Data Layer
- Uses **SwiftData** (not Core Data) for persistence
- Models are defined with the `@Model` macro (see `Item.swift`)
- The `ModelContainer` is configured with a `Schema` and `ModelConfiguration`
- By default, data is persisted to disk (`isStoredInMemoryOnly: false`)

### UI Layer
- `ContentView.swift` - Root view with navigation split view pattern
- Uses `@Query` property wrapper to fetch SwiftData models reactively
- Accesses `modelContext` from environment to insert/delete items

### Key Patterns
1. **SwiftData Integration**: Models use `@Model` macro, views use `@Query` for fetching and `@Environment(\.modelContext)` for mutations
2. **Navigation**: Uses `NavigationSplitView` for adaptive master-detail interface
3. **Previews**: SwiftUI previews are configured with in-memory model containers for testing

## Testing

- Uses the **Swift Testing** framework (not XCTest)
- Tests use `@Test` attribute instead of XCTest's `func test*()` pattern
- Use `#expect(...)` for assertions, not XCTAssert
- Import the module under test with `@testable import realtime_caltrain`
- UI tests are in separate target: `realtime-caltrainUITests`

## Project Structure

```
realtime-caltrain/          # Main app target
├── realtime_caltrainApp.swift  # App entry point, SwiftData setup
├── ContentView.swift           # Main UI view
├── Item.swift                  # SwiftData model example
└── Assets.xcassets/           # App assets

realtime-caltrainTests/     # Unit tests (Swift Testing)
realtime-caltrainUITests/   # UI tests
```

## Important Notes

- When adding new SwiftData models, register them in the `Schema` array in `realtime_caltrainApp.swift`
- For previews that need SwiftData, use `.modelContainer(for: ModelType.self, inMemory: true)`
- The app name uses underscores in code (`realtime_caltrain`) but hyphens in the folder/project name
