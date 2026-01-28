# API Integration Fix Summary

## Issues Found

1. **Wrong JSON Structure**: API uses PascalCase (e.g., `TripUpdate`, `StopId`), not snake_case
2. **Gzip Compression**: API returns gzip-compressed data (handled automatically by URLSession)
3. **Missing Stop ID Mapping**: App uses friendly IDs ("sf", "palo_alto") but API needs GTFS IDs ("70012", "70172")
4. **No Delay Data**: 511.org API doesn't provide delay field, only real-time estimates
5. **No Trip Headsign**: API doesn't include destination names in trip data

## Fixes Applied

### 1. Updated GTFSRealtimeModels.swift
**Changed**: All property names to match API's PascalCase format
```swift
// Before
struct GTFSRealtimeResponse: Codable {
    let entity: [FeedEntity]
}
struct FeedEntity: Codable {
    let id: String
    let tripUpdate: TripUpdate?
    enum CodingKeys: String, CodingKey {
        case tripUpdate = "trip_update"
    }
}

// After
struct GTFSRealtimeResponse: Codable {
    let entities: [FeedEntity]
    enum CodingKeys: String, CodingKey {
        case entities = "Entities"
    }
}
struct FeedEntity: Codable {
    let id: String
    let tripUpdate: TripUpdate?
    enum CodingKeys: String, CodingKey {
        case id = "Id"
        case tripUpdate = "TripUpdate"
    }
}
```

**Removed**: `delay` and `tripHeadsign` fields (not in API)
**Updated**: All CodingKeys to map to PascalCase

### 2. Added GTFS Stop IDs to Station Data

**Updated caltrain_stations.json**: Added `gtfsStopIdSouth` and `gtfsStopIdNorth` to each station
```json
{
  "id": "palo_alto",
  "name": "Palo Alto",
  "gtfsStopIdSouth": "70171",  // NEW
  "gtfsStopIdNorth": "70172",  // NEW
  ...
}
```

**Mapping Table**:
| Station | South ID | North ID |
|---------|----------|----------|
| San Francisco | 70011 | 70012 |
| Palo Alto | 70171 | 70172 |
| Mountain View | 70211 | 70212 |
| San Jose | 70261 | 70262 |
| (all 30 stations) | ... | ... |

### 3. Updated CaltrainStation Model

**Added Properties**:
```swift
@Model
final class CaltrainStation {
    var gtfsStopIdSouth: String  // NEW - for API calls
    var gtfsStopIdNorth: String  // NEW - for API calls
    ...
}
```

**Impact**: ⚠️ **Schema Migration Required** - Must reset simulator data

### 4. Updated StationDataLoader.swift

**Changed**: Load GTFS stop IDs from JSON
```swift
let newStation = CaltrainStation(
    stationId: station.id,
    name: station.name,
    gtfsStopIdSouth: station.gtfsStopIdSouth,  // NEW
    gtfsStopIdNorth: station.gtfsStopIdNorth,  // NEW
    ...
)
```

**Updated StationJSON** struct to include new fields

### 5. Updated DepartureService.swift

**Changed Refresh Logic**: Fetch for both directions
```swift
// Before
let response = try await CaltrainAPIClient.fetchTripUpdates(for: station.stationId)
let newDepartures = transformToTrainDepartures(response, for: station.stationId)

// After
let response = try await CaltrainAPIClient.fetchTripUpdates()
var newDepartures: [TrainDeparture] = []
newDepartures.append(contentsOf: transformToTrainDepartures(response, for: station.gtfsStopIdNorth))
newDepartures.append(contentsOf: transformToTrainDepartures(response, for: station.gtfsStopIdSouth))
```

**Updated Transform Logic**:
- Removed `delay` handling (not in API)
- Removed `tripHeadsign` usage (not in API)
- Set `scheduledTime = estimatedTime` (no schedule data)
- Always set `status = .onTime` (no delay data)
- Use `routeId` to infer train type ("Local Weekday", "Limited", "Express")
- Use `directionId` to infer destination names

### 6. Fixed Helper Methods

**inferDestinationName**: Uses direction and route info
```swift
private static func inferDestinationName(from trip: Trip) -> String {
    if trip.directionId == 1 {
        return "San Francisco"
    } else {
        return "San Jose"  // or "Gilroy" if route indicates
    }
}
```

**inferTrainType**: Uses routeId field
```swift
private static func inferTrainType(from trip: Trip) -> TrainType {
    guard let routeId = trip.routeId else { return .local }
    let routeIdUpper = routeId.uppercased()
    if routeIdUpper.contains("EXPRESS") || routeIdUpper.contains("BULLET") {
        return .babyBullet
    } else if routeIdUpper.contains("LIMITED") {
        return .limited
    }
    return .local
}
```

**extractTrainNumber**: Uses trip ID directly
```swift
private static func extractTrainNumber(from tripId: String) -> String {
    return tripId  // API uses simple numbers like "114", "412"
}
```

## Testing the Fix

### 1. Reset Simulator (REQUIRED)
```bash
xcrun simctl erase all
```
Or delete app from simulator manually

### 2. Build and Run
- Open project in Xcode
- Build and run (⌘R)

### 3. Test Pull-to-Refresh
- Pull down on departure list
- Should see real-time departures populate
- Check that trains show correct:
  - Direction (Northbound/Southbound)
  - Destination ("San Francisco", "San Jose", "Gilroy")
  - Train Type (Local, Limited, Baby Bullet/Express)
  - Train Number (114, 115, 412, etc.)
  - Times (in local timezone)

### 4. Test Throttling
- Pull to refresh
- Immediately pull again → Should silently skip (no API call)
- Wait 21 seconds, pull → Should fetch new data

## API Response Example

**Actual Response Structure**:
```json
{
  "Header": {"GtfsRealtimeVersion": "1.0", ...},
  "Entities": [
    {
      "Id": "114",
      "TripUpdate": {
        "Trip": {
          "TripId": "114",
          "RouteId": "Local Weekday",
          "DirectionId": 1
        },
        "StopTimeUpdates": [
          {
            "StopId": "70172",
            "Arrival": {"Time": 1769620605},
            "Departure": {"Time": 1769620665}
          }
        ]
      }
    }
  ]
}
```

## Known Limitations

1. **No Scheduled Time**: API only provides real-time estimates
   - `scheduledTime = estimatedTime` (same value)
   - Can't show original schedule vs. current estimate

2. **No Delay Information**: API doesn't indicate how late trains are
   - All trains show `status = .onTime`
   - Can't highlight delayed trains

3. **Generic Destinations**: API doesn't include specific destination names
   - Shows "San Francisco" for all northbound
   - Shows "San Jose" for most southbound (some "Gilroy")
   - Could improve with GTFS static data

4. **Train Type Inference**: Based on route name, may not be 100% accurate
   - "Local Weekday" → `.local`
   - "Limited" → `.limited`
   - "Express" → `.babyBullet`

## Files Changed

**Modified**:
- `realtime-caltrain/Models/API/GTFSRealtimeModels.swift` - Fixed JSON structure
- `realtime-caltrain/Models/CaltrainStation.swift` - Added GTFS stop IDs
- `realtime-caltrain/Services/StationDataLoader.swift` - Load GTFS IDs
- `realtime-caltrain/Services/DepartureService.swift` - Fetch both directions, fixed transform
- `realtime-caltrain/Data/caltrain_stations.json` - Added GTFS stop IDs

**No Changes Needed**:
- `realtime-caltrain/Services/CaltrainAPIClient.swift` - Already correct
- `realtime-caltrain/ContentView.swift` - Already correct

## Success Criteria

✅ Pull-to-refresh works without parsing errors
✅ Real-time departures appear in both directions
✅ Train numbers match API data (114, 115, 412, etc.)
✅ Destinations show appropriate names
✅ Train types inferred correctly (Local, Limited, Express)
✅ Times display in local timezone
✅ Throttling prevents excessive API calls

## Next Steps

After confirming the fix works:

1. **Improve Destination Names**: Load GTFS static data for accurate destinations
2. **Add Scheduled Time**: Parse GTFS schedule to show on-time vs. delayed
3. **Platform Numbers**: Research if 511 API provides platform info
4. **Caching**: Store API responses for offline mode
5. **Background Refresh**: Auto-update every 30-60 seconds when app active

---

**Status**: ✅ Ready to Test
**Action Required**: Reset simulator, build, and test pull-to-refresh
