# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a SwiftUI-based iOS application for real-time Caltrain tracking with a companion home screen widget. The project uses:
- **SwiftUI** for the UI framework
- **SwiftData** for persistence (not Core Data)
- **WidgetKit** for the home screen widget extension
- **Caltrain GTFS Realtime API** for live train data
- **Timetable API** for planned/scheduled departures
- **Core Location** for finding nearest stations
- **Swift Testing** framework (not XCTest) for unit tests
- **Fastlane** for screenshot automation

## Building and Running

### Build the app
```bash
xcodebuild -project caltrain.xcodeproj -scheme caltrain -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -configuration Debug build
```

### Run tests
```bash
# Run all tests
xcodebuild test -project caltrain.xcodeproj -scheme caltrain -destination 'platform=iOS Simulator,name=iPhone 17 Pro'

# Run specific test
xcodebuild test -project caltrain.xcodeproj -scheme caltrain -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:caltrainTests/caltrainTests/example
```

### Generate screenshots
```bash
cd fastlane && bundle exec fastlane screenshots
```

## Architecture

### App Entry Point
- `realtime_caltrainApp.swift` - The main app struct with `@main` attribute
- Initializes SwiftData `ModelContainer` via `SharedModelContainer`
- Sets up `LocationManager` and manages app lifecycle (active/background/inactive)
- Loads station data on first launch via `StationDataLoader`

### Data Layer
- **Models**: SwiftData `@Model` classes for persistence
  - `CaltrainStation.swift` - Station model with coordinates, GTFS stop IDs, amenities, favorites, fare zones
  - `TrainDeparture.swift` - Real-time departure model with status (onTime/delayed/cancelled), delay tracking, train type
  - `PlannedDeparture.swift` - Scheduled timetable departure model, converts to `TrainDeparture`
  - `API/GTFSRealtimeModels.swift` - GTFS Realtime protocol buffer JSON response models
  - `API/Timetable.swift` - Timetable API response models
- **Services**: Business logic and data fetching
  - `CaltrainAPIClient.swift` - API client for trip updates, timetable, and station data
  - `DepartureService.swift` - Merges real-time + planned departures, atomic refresh, widget timeline updates
  - `DepartureRefreshState.swift` - Global refresh throttling (20-second minimum between API calls)
  - `NearestStationService.swift` - Determines nearest station based on location
  - `StationDataLoader.swift` - Loads bundled station JSON into SwiftData on first launch
  - `StationService.swift` - Station queries and management
  - `StationSelectionService.swift` - Manages user station selection state
  - `LocationCacheService.swift` - Caches location to UserDefaults via App Groups for widget access
  - `SharedModelContainer.swift` - SwiftData container configuration with App Groups
  - `SyncRegistry.swift` - Sync state tracking
- **Data**: Static data files
  - `caltrain_stations.json` - Station database with coordinates, amenities, and GTFS stop IDs

### UI Layer
- `ContentView.swift` - Main view with NavigationSplitView, refresh controls, debug info
- `LocationManager.swift` - Core Location wrapper with `@Observable`
- `LocationTestView.swift` - Test view for location features
- **Views**: Modular UI components
  - `ActiveStationSection.swift` - Displays currently selected/nearest station
  - `AllStationsListView.swift` - Browsable/searchable station list with selection
  - `DeparturesByDirectionView.swift` - Groups departures by northbound/southbound
  - `DeparturesSection.swift` - Section with departures, loading state, refresh button
  - `DepartureRow.swift` - Departure item with time, status badge, delay, train type, platform, destination
  - `EmptyDeparturesView.swift` - Empty state when no departures available
  - `StationRow.swift` - Station list item with distance display
  - `PulsingTrainLoadingView.swift` - Animated loading indicator
  - `TrainLogo.swift` - App branding/train icon
  - `Station/StationDetail.swift` - Detailed station information view
  - `Station/Amenities.swift` - Station amenities display (parking, bikes, restrooms, etc.)
  - `Station/Icon.swift` - Station icon component
  - `Station/ZoneTextView.swift` - Fare zone display

### Widget Extension (`CaltrainWidget/`)
- `CaltrainWidgetBundle.swift` - Widget entry point (`@WidgetBundle`)
- `CaltrainWidget.swift` - Widget configuration (systemMedium and systemLarge sizes)
- `CaltrainTimelineProvider.swift` - Timeline provider for widget updates
- `CaltrainConfigurationIntent.swift` - AppIntent for widget station selection
- `WidgetEntry.swift` - Widget entry model with station, departures, errors
- `StationEntity.swift` - AppEntity for station selection in widget config
- `StationEntityQuery.swift` - EntityQuery for station autocomplete
- `WidgetViews/CaltrainWidgetView.swift` - Widget UI rendering

### Key Patterns
1. **Service-based Architecture**: Business logic is separated into focused service classes
2. **SwiftData Persistence**: `@Model` entities with atomic operations and App Groups for widget sharing
3. **Observable Objects**: Services use `@Observable` for reactive state management
4. **Environment Injection**: Shared services are passed via SwiftUI environment
5. **Protocol-based API Client**: `CaltrainAPIClientProtocol` enables testing with mocks
6. **Dual Data Source Merging**: Real-time GTFS data merged with planned timetable data in `DepartureService`
7. **Throttled Refresh**: `DepartureRefreshState` prevents excessive API calls (20-second minimum)

## API Integration

- **Trip Updates**: `https://caltrain-gateway.fewald.net/transit/tripupdates?agency=CT&format=json`
- **Timetable**: `https://caltrain-gateway.fewald.net/caltrain/timetable`
- Data format: GTFS Realtime protocol buffers (JSON encoded)

## Testing

- Uses the **Swift Testing** framework (not XCTest)
- Tests use `@Test` attribute instead of XCTest's `func test*()` pattern
- Use `#expect(...)` for assertions, not XCTAssert
- Import the module under test with `@testable import realtime_caltrain`
- Unit tests: `realtime_caltrainTests.swift`, `NearestStationServiceTests.swift`, `StationServiceTests.swift`, `LocationCacheServiceTests.swift`
- UI tests with screenshot capture: `Screenshot.swift` (uses Fastlane `SnapshotHelper`)

## Project Structure

```
realtime-caltrain/              # Main app target
├── realtime_caltrainApp.swift  # App entry point
├── ContentView.swift           # Main UI view
├── LocationManager.swift       # Core Location wrapper
├── LocationTestView.swift      # Location testing view
├── Models/                     # SwiftData models
│   ├── CaltrainStation.swift
│   ├── TrainDeparture.swift
│   ├── PlannedDeparture.swift
│   └── API/
│       ├── GTFSRealtimeModels.swift
│       └── Timetable.swift
├── Services/                   # Business logic layer
│   ├── CaltrainAPIClient.swift
│   ├── DepartureService.swift
│   ├── DepartureRefreshState.swift
│   ├── NearestStationService.swift
│   ├── StationDataLoader.swift
│   ├── StationService.swift
│   ├── StationSelectionService.swift
│   ├── LocationCacheService.swift
│   ├── SharedModelContainer.swift
│   └── SyncRegistry.swift
├── Views/                      # UI components
│   ├── ActiveStationSection.swift
│   ├── AllStationsListView.swift
│   ├── DeparturesByDirectionView.swift
│   ├── DeparturesSection.swift
│   ├── DepartureRow.swift
│   ├── EmptyDeparturesView.swift
│   ├── PulsingTrainLoadingView.swift
│   ├── StationRow.swift
│   ├── TrainLogo.swift
│   └── Station/
│       ├── StationDetail.swift
│       ├── Amenities.swift
│       ├── Icon.swift
│       └── ZoneTextView.swift
├── Data/                       # Static data files
│   └── caltrain_stations.json
├── Supporting Files/           # Configuration files
│   ├── Config.plist
│   └── Config.plist.template
└── Assets.xcassets/           # App assets

CaltrainWidget/                 # Widget extension target
├── CaltrainWidgetBundle.swift
├── CaltrainWidget.swift
├── CaltrainTimelineProvider.swift
├── CaltrainConfigurationIntent.swift
├── WidgetEntry.swift
├── StationEntity.swift
├── StationEntityQuery.swift
├── WidgetViews/
│   └── CaltrainWidgetView.swift
├── Assets.xcassets/
└── Info.plist

realtime-caltrainTests/         # Unit tests (Swift Testing)
├── realtime_caltrainTests.swift
├── NearestStationServiceTests.swift
├── StationServiceTests.swift
└── LocationCacheServiceTests.swift

realtime-caltrainUITests/       # UI tests & screenshots
├── realtime_caltrainUITests.swift
├── realtime_caltrainUITestsLaunchTests.swift
├── Screenshot.swift
└── SnapshotHelper.swift

Scripts/                        # Build utilities
├── AppIconGenerator.swift
└── GeneratedIcons/

fastlane/                       # CI/CD automation
├── Fastfile                    # Screenshot generation lane
├── Snapfile                    # Screenshot device/scheme config
└── screenshots/                # Generated screenshots
```

## Important Notes

- The Xcode project is `caltrain.xcodeproj` with scheme `caltrain`
- The app uses `Config.plist` for API configuration (based on `Config.plist.template`)
- Station data is loaded from the bundled `caltrain_stations.json` file into SwiftData on first launch
- Services use the `@Observable` macro for reactive state management
- The app name uses underscores in code (`realtime_caltrain`) but hyphens in the folder/project name
- Location permissions are required for nearest station functionality
- Widget shares data with the main app via App Groups and `SharedModelContainer`
