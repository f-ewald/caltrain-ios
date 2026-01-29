# Widget Quick Start Guide

Get your Caltrain widget running in 5 minutes!

## Prerequisites
- Xcode 15.0 or later
- iOS 17.0+ simulator or device
- Location permissions granted

## Step 1: Create Widget Target (2 minutes)

1. Open `realtime-caltrain.xcodeproj` in Xcode
2. **File** → **New** → **Target...**
3. Choose **Widget Extension**
4. Configure:
   - Product Name: `CaltrainWidget`
   - Bundle ID: `net.fewald.realtime-caltrain.CaltrainWidget`
   - **UNCHECK** "Include Configuration Intent" ⚠️
5. Click **Finish** → **Activate** scheme

## Step 2: Configure App Groups (1 minute)

### Main App Target
1. Select **realtime-caltrain** target
2. **Signing & Capabilities** tab
3. Click **+ Capability**
4. Add **App Groups**
5. Click **+** under App Groups
6. Enter: `group.net.fewald.realtime-caltrain`

### Widget Target
1. Select **CaltrainWidget** target
2. **Signing & Capabilities** tab
3. Click **+ Capability**
4. Add **App Groups**
5. Click **+** under App Groups
6. Enter: `group.net.fewald.realtime-caltrain`

## Step 3: Add Files to Widget Target (2 minutes)

Select each file below in Project Navigator, then in **File Inspector** (right panel), check ☑ **CaltrainWidget**:

### Quick Selection Method
Hold ⌘ and click to multi-select these files, then check CaltrainWidget in File Inspector:

**Models folder:**
- `TrainDeparture.swift`
- `CaltrainStation.swift`
- `GTFSRealtimeModels.swift` (in API subfolder)

**Services folder:**
- `DepartureService.swift`
- `NearestStationService.swift`
- `CaltrainAPIClient.swift`
- `StationDataLoader.swift`
- `SharedModelContainer.swift` ⭐ NEW
- `LocationCacheService.swift` ⭐ NEW

**Data files:**
- `Supporting Files/Config.plist`
- `Data/caltrain_stations.json`

## Step 4: Build & Test

1. Select **CaltrainWidget** scheme (next to the run button)
2. Choose a simulator (e.g., iPhone 17 Pro)
3. Press **⌘B** to build
4. Press **⌘R** to run

You should see the widget preview interface!

## Step 5: Add to Home Screen

1. **Run the main app first** (important!)
   - Select **realtime-caltrain** scheme
   - Run on simulator/device
   - Grant location permissions
   - Wait for data to load

2. **Add widget to home screen:**
   - Long press on home screen
   - Tap **+** button (top left)
   - Search for "Caltrain"
   - Choose **Medium** or **Large** size
   - Tap **Add Widget**

## ✅ Verify It's Working

You should see:
- Station name in header (e.g., "Palo Alto")
- Northbound departures on left/top
- Southbound departures on right/bottom
- Departure times (e.g., "3:15 PM")
- Color-coded train types (🔵 Local, 🟡 Limited, 🔴 Bullet)

## 🐛 Quick Troubleshooting

### Widget shows "Unable to Load"
→ Check App Groups are configured correctly in both targets

### Widget shows "Location not available"
→ Run main app first and grant location permissions

### Widget shows "No departures"
→ Pull to refresh in main app, then wait a few seconds

### Build error: "Cannot find type in scope"
→ Make sure you added all files to CaltrainWidget target (Step 3)

### Widget not updating
→ Pull to refresh in main app to force update

## 🎯 Testing the Complete Flow

1. **Initial setup:**
   - Run main app → grant location → see departures

2. **Add widget:**
   - Long press home screen → add Caltrain widget

3. **Test refresh:**
   - Pull down in main app to refresh
   - Widget should update within a few seconds

4. **Test auto-update:**
   - Wait 5 minutes
   - Widget should refresh automatically

## 📚 More Information

- **Detailed setup:** See `WIDGET_SETUP_INSTRUCTIONS.md`
- **Architecture:** See `CaltrainWidget/README.md`
- **Summary:** See `WIDGET_IMPLEMENTATION_SUMMARY.md`

---

## 🚀 That's It!

Your widget is now running! The widget will:
- Update every 5 minutes automatically
- Show your nearest station's departures
- Update immediately when you refresh the main app
- Work offline with cached data

Enjoy your real-time Caltrain updates! 🚆
