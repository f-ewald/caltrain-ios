# Widget Target Membership Checklist

## ❌ Build Error: Missing Files

The build is failing because these files are **NOT** included in the CaltrainWidgetExtension target:

### To Fix:
Select each file below in Xcode Project Navigator, then in **File Inspector** (⌥⌘1), check ☑ **CaltrainWidgetExtension**:

## Required Files (Must be checked)

### Models - ✅ Already Added
- [x] `Models/CaltrainStation.swift`
- [x] `Models/TrainDeparture.swift`

### Models/API - ❌ MISSING (causing build errors)
- [ ] **`Models/API/GTFSRealtimeModels.swift`** ← **REQUIRED**

### Services - Partially Added
- [x] `Services/DepartureService.swift` (already added)
- [x] `Services/SharedModelContainer.swift` (already added)
- [x] `Services/LocationCacheService.swift` (already added)
- [ ] **`Services/CaltrainAPIClient.swift`** ← **REQUIRED**
- [ ] **`Services/NearestStationService.swift`** ← **REQUIRED**
- [ ] **`Services/StationDataLoader.swift`** ← **REQUIRED**

### Data Files - Need to Check
- [ ] `Supporting Files/Config.plist`
- [ ] `Data/caltrain_stations.json`

---

## Quick Fix Steps

1. **Open Xcode**
2. **Select all 4 missing files** (hold ⌘ and click):
   - `Models/API/GTFSRealtimeModels.swift`
   - `Services/CaltrainAPIClient.swift`
   - `Services/NearestStationService.swift`
   - `Services/StationDataLoader.swift`

3. **Open File Inspector** (⌥⌘1 or View > Inspectors > File)

4. **Check ☑ CaltrainWidgetExtension** under "Target Membership"

5. **Also verify these are checked**:
   - `Supporting Files/Config.plist`
   - `Data/caltrain_stations.json`

6. **Clean and rebuild**:
   - Product > Clean Build Folder (⇧⌘K)
   - Product > Build (⌘B)

---

## Verify All Files

Here's the complete list of files that MUST have CaltrainWidgetExtension target membership:

```
Models/
  ├─ CaltrainStation.swift ✓
  ├─ TrainDeparture.swift ✓
  └─ API/
      └─ GTFSRealtimeModels.swift ⚠️ ADD THIS

Services/
  ├─ CaltrainAPIClient.swift ⚠️ ADD THIS
  ├─ DepartureService.swift ✓
  ├─ LocationCacheService.swift ✓
  ├─ NearestStationService.swift ⚠️ ADD THIS
  ├─ SharedModelContainer.swift ✓
  └─ StationDataLoader.swift ⚠️ ADD THIS

Supporting Files/
  └─ Config.plist ⚠️ VERIFY

Data/
  └─ caltrain_stations.json ⚠️ VERIFY
```

---

## Expected Build Result

After adding these files, the build should succeed with:
```
** BUILD SUCCEEDED **
```

If you still see errors, check that:
1. All checkboxes in Target Membership show ☑ CaltrainWidgetExtension
2. The files are not in red (missing from disk)
3. App Groups are configured for both targets

---

## Quick Command to Verify

After making changes, test the build:
```bash
xcodebuild -project realtime-caltrain.xcodeproj -scheme CaltrainWidget -destination 'platform=iOS Simulator,name=iPhone 17 Pro' clean build
```
