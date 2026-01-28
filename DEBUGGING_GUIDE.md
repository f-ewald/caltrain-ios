# Debugging "No Upcoming Departures" Issue

## What I Added

### 1. Debug Section in UI
The app now shows at the top of the list:
```
Debug Info
- Stations loaded: X
- Location: Available/Waiting...
- Active station: [Name or None]
- Departures: X
```

### 2. Console Logging
Added detailed logs throughout the app startup and data loading process.

## How to Debug

### Step 1: Check Console Output
When you run the app, look for these logs in Xcode console:

**On App Start:**
```
🚀 App started
📍 Requesting location permission...
🗺️ Loading station data...
```

**Station Loading (Should see ONE of these):**

✅ **Success (Stations already loaded):**
```
✅ Stations already loaded: 30
✅ Stations have GTFS IDs: 70012
```

⚠️ **Schema Migration Needed:**
```
⚠️ CRITICAL: Stations missing GTFS IDs - schema migration needed!
💡 Please reset simulator: xcrun simctl erase all
```

✅ **Success (Fresh Load):**
```
📥 Loading stations from JSON...
✅ Found caltrain_stations.json at: [path]
📄 JSON file size: [bytes]
🗺️ Decoded 30 stations from JSON
✅ Successfully loaded 30 stations into SwiftData
```

❌ **Error (JSON not found):**
```
❌ ERROR: caltrain_stations.json not found in bundle
```

**On ContentView Appear:**
```
⚠️ No active station - waiting for location or station selection
📍 Loading mock data for fallback station: San Francisco
```

OR

```
🚂 Loading departures for: [Station Name]
🌐 Fetching from API...
✅ API fetch successful
```

OR

```
❌ API fetch failed: [error]
📝 Loaded mock data as fallback
```

### Step 2: Check Debug Section in App

Look at the top of the list in the app:

**Problem: No Stations**
```
Debug Info
- Stations loaded: 0
- Location: Waiting...
- Active station: None
- Departures: 0
```
**Solution:** The caltrain_stations.json file isn't being loaded. Check if it's added to the Xcode project.

**Problem: Old Schema**
```
Debug Info
- Stations loaded: 30
- Location: Available
- Active station: None
- Departures: 0
```
Check console for: `⚠️ CRITICAL: Stations missing GTFS IDs`
**Solution:** Reset simulator: `xcrun simctl erase all`

**Problem: No Location**
```
Debug Info
- Stations loaded: 30
- Location: Waiting...
- Active station: None
- Departures: X (mock data)
```
**Solution:** Grant location permission or wait for location to be acquired

**Success!**
```
Debug Info
- Stations loaded: 30
- Location: Available
- Active station: Palo Alto
- Departures: 10
```

## Common Issues & Solutions

### Issue 1: "Stations loaded: 0"
**Cause:** `caltrain_stations.json` not found
**Solution:**
1. Check if `caltrain_stations.json` is in `realtime-caltrain/Data/` folder
2. Verify it's added to Xcode project target
3. Rebuild the app

### Issue 2: "Stations missing GTFS IDs"
**Cause:** Schema changed but simulator data not reset
**Solution:**
```bash
xcrun simctl erase all
```
Then rebuild and run.

### Issue 3: "Location: Waiting..." never changes
**Cause:** Location permission not granted or location services disabled
**Solution:**
1. In simulator: Features → Location → Custom Location → Enter coordinates
2. Or Features → Location → Apple (for a fixed location)
3. Check system preferences for location services

### Issue 4: "Active station: None" even with location
**Cause:** No nearby stations or location too far from Caltrain line
**Solution:**
1. Use simulator location near a Caltrain station:
   - Palo Alto: 37.4439, -122.1641
   - San Francisco: 37.7764, -122.3943
   - Mountain View: 37.3945, -122.0760

### Issue 5: API fetch fails
**Check Console For:**
```
❌ API fetch failed: [error message]
```

**Common Errors:**
- "API key not configured" → Check Config.plist has valid key
- "Network error" → Check internet connection
- "Unable to parse" → API structure changed (report this!)

**Fallback:** App should load mock data automatically

## Quick Test Commands

### 1. Reset Simulator
```bash
xcrun simctl erase all
```

### 2. Test API Manually
```bash
curl "http://api.511.org/transit/tripupdates?api_key=YOUR_KEY&agency=CT&format=json" | gunzip | head -100
```

### 3. Set Simulator Location (while running)
In Xcode: Debug → Simulate Location → Custom Location
Enter: 37.4439, -122.1641 (Palo Alto)

## Expected Behavior After Fix

1. **On First Launch (no data):**
   - Loads 30 stations from JSON
   - Requests location permission
   - Shows location permission dialog
   - Loads mock data for first station as fallback

2. **After Location Granted:**
   - Finds nearest station
   - Fetches real-time data from API
   - Shows departures for that station

3. **On Pull-to-Refresh:**
   - Fetches fresh data from API
   - Updates departure list
   - If API fails, keeps old data and shows error

4. **After 20 Seconds:**
   - Pull-to-refresh fetches new data
   - Before 20s, silently skips (throttled)

## Removing Debug Section

Once everything is working, remove the debug section from ContentView.swift:

```swift
// Delete this section:
Section("Debug Info") {
    Text("Stations loaded: \(stations.count)")
    Text("Location: \(locationManager.location != nil ? "Available" : "Waiting...")")
    Text("Active station: \(activeStation?.name ?? "None")")
    Text("Departures: \(departures.count)")
}
```

## Getting Help

If still not working, share:
1. Console output from app launch
2. Debug section values from UI
3. Screenshot of the app
4. Result of manual API test (curl command above)

---

**Most Common Fix:** `xcrun simctl erase all` then rebuild! 🔄
