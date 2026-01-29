# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a SwiftUI-based iOS application for real-time Caltrain tracking. The project uses:
- **SwiftUI** for the UI framework
- **Caltrain GTFS Realtime API** for live train data
- **Core Location** for finding nearest stations
- **Swift Testing** framework (not XCTest) for unit tests

## Building and Running

### Build the app
```bash
xcodebuild -project realtime-caltrain.xcodeproj -scheme realtime-caltrain -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -configuration Debug build
```

### Build and run on simulator
```bash
xcodebuild -project realtime-caltrain.xcodeproj -scheme realtime-caltrain -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```

### Run tests
```bash
# Run all tests
xcodebuild test -project realtime-caltrain.xcodeproj -scheme realtime-caltrain -destination 'platform=iOS Simulator,name=iPhone 17 Pro'

# Run specific test
xcodebuild test -project realtime-caltrain.xcodeproj -scheme realtime-caltrain -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:realtime-caltrainTests/realtime_caltrainTests/example
```

## Architecture

### App Entry Point
- `realtime_caltrainApp.swift` - The main app struct with `@main` attribute
- Initializes core services and sets up the app environment

### Data Layer
- **Models**: Define the data structures for stations and departures
  - `CaltrainStation.swift` - Station model with coordinates and metadata
  - `TrainDeparture.swift` - Departure information model
  - `GTFSRealtimeModels.swift` - API response models for GTFS Realtime feed
- **Services**: Business logic and data fetching
  - `CaltrainAPIClient.swift` - API client for Caltrain GTFS Realtime data
  - `DepartureService.swift` - Manages departure data fetching and processing
  - `NearestStationService.swift` - Determines nearest station based on location
  - `StationDataLoader.swift` - Loads station data from JSON file
  - `StationSelectionService.swift` - Manages user station selection state
- **Data**: Static data files
  - `caltrain_stations.json` - Station database with coordinates and names

### UI Layer
- `ContentView.swift` - Main view orchestrating the app UI
- **Views**: Modular UI components
  - `ActiveStationSection.swift` - Displays currently selected station
  - `AllStationsListView.swift` - List of all available stations
  - `DeparturesByDirectionView.swift` - Shows departures organized by direction
  - `DeparturesSection.swift` - Section displaying upcoming departures
  - `DepartureRow.swift` - Individual departure item view
  - `EmptyDeparturesView.swift` - Empty state when no departures available
  - `StationRow.swift` - Individual station list item
  - `PulsingTrainLoadingView.swift` - Loading indicator
- **Location**: Location services integration
  - `LocationManager.swift` - Manages Core Location functionality
  - `LocationTestView.swift` - Test view for location features

### Key Patterns
1. **Service-based Architecture**: Business logic is separated into focused service classes
2. **Observable Objects**: Services use `@Observable` for reactive state management
3. **Environment Objects**: Shared services are passed via SwiftUI environment

## Testing

- Uses the **Swift Testing** framework (not XCTest)
- Tests use `@Test` attribute instead of XCTest's `func test*()` pattern
- Use `#expect(...)` for assertions, not XCTAssert
- Import the module under test with `@testable import realtime_caltrain`
- UI tests are in separate target: `realtime-caltrainUITests`

## Project Structure

```
realtime-caltrain/              # Main app target
├── realtime_caltrainApp.swift  # App entry point
├── ContentView.swift           # Main UI view
├── LocationManager.swift       # Core Location wrapper
├── LocationTestView.swift      # Location testing view
├── Models/                     # Data models
│   ├── CaltrainStation.swift
│   ├── TrainDeparture.swift
│   └── API/
│       └── GTFSRealtimeModels.swift
├── Services/                   # Business logic layer
│   ├── CaltrainAPIClient.swift
│   ├── DepartureService.swift
│   ├── NearestStationService.swift
│   ├── StationDataLoader.swift
│   └── StationSelectionService.swift
├── Views/                      # UI components
│   ├── ActiveStationSection.swift
│   ├── AllStationsListView.swift
│   ├── DeparturesByDirectionView.swift
│   ├── DeparturesSection.swift
│   ├── DepartureRow.swift
│   ├── EmptyDeparturesView.swift
│   ├── PulsingTrainLoadingView.swift
│   └── StationRow.swift
├── Data/                       # Static data files
│   └── caltrain_stations.json
├── Supporting Files/           # Configuration files
│   ├── Config.plist
│   └── Config.plist.template
└── Assets.xcassets/           # App assets
    ├── AppIcon.appiconset
    └── AccentColor.colorset

realtime-caltrainTests/         # Unit tests (Swift Testing)
├── realtime_caltrainTests.swift
└── NearestStationServiceTests.swift

realtime-caltrainUITests/       # UI tests
├── realtime_caltrainUITests.swift
└── realtime_caltrainUITestsLaunchTests.swift
```

## Important Notes

- The app uses `Config.plist` for API configuration (based on `Config.plist.template`)
- Station data is loaded from the bundled `caltrain_stations.json` file
- Services use the `@Observable` macro for reactive state management
- The app name uses underscores in code (`realtime_caltrain`) but hyphens in the folder/project name
- Location permissions are required for nearest station functionality
