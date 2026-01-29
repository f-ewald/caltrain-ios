# Caltrain Widget

A WidgetKit extension that displays real-time Caltrain departures for your nearest station.

## Features

- **Automatic station detection** - Shows departures for your nearest station
- **Two widget sizes** - Medium and Large
- **Real-time data** - Updates every 5 minutes with live departure information
- **Directional departures** - Shows next 3 northbound and 3 southbound trains
- **Status indicators** - Color-coded train types (Local, Limited, Baby Bullet)
- **Delay information** - Shows delays and countdown timers for imminent departures
- **Error handling** - Clear error states for location issues or data unavailability

## Widget Sizes

### Medium Widget
- Compact two-column layout
- Shows next 3 departures per direction
- Displays: time, train type, destination, status

### Large Widget
- Extended layout with more details
- Shows next 3 departures per direction
- Displays: time, countdown, train type, destination, train number, status, delay info

## Architecture

### Data Flow

1. **Main App** → Caches location and fetches departure data → **Shared SwiftData Container**
2. **Widget** → Reads cached location → Fetches data from shared container → Updates timeline
3. **App Group** (`group.net.fewald.realtime-caltrain`) enables data sharing

### Key Components

#### `WidgetEntry.swift`
- Defines the timeline entry model
- Contains sample data for previews
- Includes error states

#### `CaltrainTimelineProvider.swift`
- Implements WidgetKit's `TimelineProvider` protocol
- Fetches data from shared container
- Attempts API refresh (respects throttling)
- Filters to next 3 departures per direction
- Schedules updates every 5 minutes

#### `CaltrainWidgetView.swift`
- Main widget view with size-specific layouts
- `MediumWidgetView` - Compact two-column design
- `LargeWidgetView` - Extended detailed design
- `DirectionSection` - Reusable direction component
- `CompactDepartureRow` - Minimal departure info
- `ExtendedDepartureRow` - Detailed departure info
- `ErrorView` - Error state display

#### `CaltrainWidget.swift`
- Widget configuration and registration
- Specifies supported families (Medium, Large)
- Sets display name and description

### Shared Services

#### `SharedModelContainer.swift`
- Creates App Group-based SwiftData container
- Shared between main app and widget
- Stores stations and departures

#### `LocationCacheService.swift`
- Caches user location in shared UserDefaults
- Stores nearest station ID
- 30-minute cache freshness window
- Enables widget to use location without CLLocationManager

## Update Strategy

### Widget Updates
- **Scheduled**: Every 5 minutes via timeline policy
- **App-triggered**: When user manually refreshes in main app
- **System-triggered**: Based on iOS widget intelligence

### API Throttling
- Respects existing 20-second throttling from `DepartureService`
- Widget attempts refresh but gracefully falls back to cached data
- Minimizes battery and network usage

## Error States

The widget handles several error scenarios:

| Error | Icon | Description |
|-------|------|-------------|
| `noLocation` | location.slash | Location not yet cached by main app |
| `cacheStale` | location.slash | Location cache older than 30 minutes |
| `noStation` | mappin.slash | Nearest station not found |
| `noData` | tram.slash | No departure data available |
| `apiError` | exclamationmark.triangle | API fetch failed |

## Setup Requirements

### App Groups
Both main app and widget must be configured with:
- **App Group ID**: `group.net.fewald.realtime-caltrain`
- Enabled in **Signing & Capabilities** for both targets

### Shared Files
The following files must have both targets enabled:
- Models: `TrainDeparture.swift`, `CaltrainStation.swift`, `GTFSRealtimeModels.swift`
- Services: All service files
- Data: `Config.plist`, `caltrain_stations.json`

### Location Permissions
- User must grant location permissions in main app
- Main app caches location for widget to use
- Widget cannot request location permissions directly

## Testing

### Xcode Previews
Use the preview providers at the bottom of `CaltrainWidgetView.swift`:
```swift
#Preview("Medium - Sample", as: .systemMedium) {
    CaltrainWidget()
} timeline: {
    CaltrainWidgetEntry.sample
}
```

### Simulator/Device Testing
1. Run the main app first
2. Grant location permissions
3. Wait for data to load
4. Add widget to home screen
5. Verify updates when refreshing main app

### Debug Tips
- Check Xcode console for widget logs (prefix: "Widget:")
- Verify App Group container path
- Confirm SwiftData database exists in App Group
- Check UserDefaults suite for cached location

## Performance Considerations

- **Minimal data fetch**: Only fetches next 2 hours of departures
- **Efficient filtering**: Filters in-memory after fetch
- **Background updates**: Widget updates don't wake the app
- **Smart caching**: 30-minute location cache reduces queries
- **Timeline optimization**: 5-minute refresh balances freshness and battery

## Future Enhancements

Potential improvements:
- [ ] Configurable station selection (instead of nearest only)
- [ ] Adjustable number of departures shown
- [ ] Small widget size (single direction)
- [ ] Live Activities for imminent departures
- [ ] Lock screen widgets
- [ ] Accessibility improvements
- [ ] Siri shortcuts integration
