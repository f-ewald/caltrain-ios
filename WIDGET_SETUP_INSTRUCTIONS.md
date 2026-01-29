# Widget Setup Instructions

Follow these steps to add the widget extension to your Xcode project:

## Step 1: Create Widget Extension Target

1. Open `realtime-caltrain.xcodeproj` in Xcode
2. Go to **File > New > Target...**
3. Select **Widget Extension** (under Application Extension)
4. Configure the extension:
   - **Product Name**: `CaltrainWidget`
   - **Bundle Identifier**: `net.fewald.realtime-caltrain.CaltrainWidget`
   - **Minimum Deployments**: iOS 17.0
   - **Include Configuration Intent**: ❌ **Uncheck this** (we're not using configuration)
5. Click **Finish**
6. When asked to activate the scheme, click **Activate**

This creates:
- `CaltrainWidget/` folder with initial widget files
- `CaltrainWidget.swift` (we'll replace this)
- `Assets.xcassets/`
- `Info.plist`

## Step 2: Create Widget Entitlements File

1. Select the **CaltrainWidget** target in Xcode
2. Go to **Signing & Capabilities** tab
3. Click **+ Capability**
4. Add **App Groups**
5. Click **+** under App Groups
6. Enter: `group.net.fewald.realtime-caltrain`
7. Click **OK**

This creates `CaltrainWidget/CaltrainWidget.entitlements` automatically.

## Step 3: Enable App Groups for Main App

1. Select the **realtime-caltrain** target in Xcode
2. Go to **Signing & Capabilities** tab
3. Click **+ Capability**
4. Add **App Groups**
5. Click **+** under App Groups
6. Enter: `group.net.fewald.realtime-caltrain`
7. Click **OK**

This will use the existing `realtime-caltrain/realtime-caltrain.entitlements` file.

## Step 4: Add Files to Widget Target

In Xcode, select these files and in the **File Inspector** (right panel), check the box for **CaltrainWidget** target membership:

### Models
- ✅ `realtime-caltrain/Models/TrainDeparture.swift`
- ✅ `realtime-caltrain/Models/CaltrainStation.swift`
- ✅ `realtime-caltrain/Models/API/GTFSRealtimeModels.swift`

### Services
- ✅ `realtime-caltrain/Services/DepartureService.swift`
- ✅ `realtime-caltrain/Services/NearestStationService.swift`
- ✅ `realtime-caltrain/Services/CaltrainAPIClient.swift`
- ✅ `realtime-caltrain/Services/StationDataLoader.swift`
- ✅ `realtime-caltrain/Services/SharedModelContainer.swift`
- ✅ `realtime-caltrain/Services/LocationCacheService.swift`

### Supporting Files
- ✅ `realtime-caltrain/Supporting Files/Config.plist`
- ✅ `realtime-caltrain/Data/caltrain_stations.json`

**How to add target membership:**
1. Select the file in Project Navigator
2. Open File Inspector (⌥⌘1 or View > Inspectors > File)
3. Under "Target Membership", check ☑ CaltrainWidget

## Step 5: Replace Widget Implementation Files

Delete the auto-generated `CaltrainWidget.swift` and replace with the files I've created:

1. **Delete** `CaltrainWidget/CaltrainWidget.swift` (the auto-generated one)
2. **Add** the following files I created (they're already in the `CaltrainWidget/` folder):
   - `CaltrainWidget.swift` - Main widget configuration
   - `WidgetEntry.swift` - Timeline entry model
   - `CaltrainTimelineProvider.swift` - Timeline provider
   - `WidgetViews/CaltrainWidgetView.swift` - Widget UI

## Step 6: Build and Test

1. Select the **CaltrainWidget** scheme in Xcode
2. Choose a simulator or device
3. Build and run (⌘R)
4. This will launch the widget preview interface
5. Add the widget to your home screen to test

## Troubleshooting

### Build Error: "Cannot find type in scope"
- Make sure all required files have CaltrainWidget target membership checked
- Clean build folder (Shift+⌘K) and rebuild

### Widget shows "Unable to Load"
- Check that App Groups are configured correctly in both targets
- Verify the App Group identifier matches: `group.net.fewald.realtime-caltrain`

### Widget shows "No Location"
- Run the main app first to request location permissions
- Make sure location services are enabled
- The app caches location for the widget to use

### Widget shows old data
- Widgets update every 5 minutes automatically
- Pull to refresh in the main app to trigger immediate widget update
- Check system Settings > Widget Center for widget refresh settings
