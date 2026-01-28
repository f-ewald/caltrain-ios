# Quick Fix Guide - API Parsing Error

## What Was Wrong?

The 511.org API uses **different field names** than expected:
- ❌ Expected: `trip_update`, `stop_id`, `direction_id` (snake_case)
- ✅ Actual: `TripUpdate`, `StopId`, `DirectionId` (PascalCase)

Also, the app was using friendly station IDs ("palo_alto") but the API needs GTFS IDs ("70172").

## What Was Fixed?

1. ✅ Updated JSON parsing to match API's PascalCase format
2. ✅ Added GTFS stop ID mapping for all 30 stations
3. ✅ Updated station model to store both friendly and GTFS IDs
4. ✅ Modified refresh logic to fetch both northbound and southbound

## To Test the Fix

### Step 1: Reset Simulator (REQUIRED)
The CaltrainStation model changed, so you must clear old data:

```bash
xcrun simctl erase all
```

Or manually delete the app from the simulator.

### Step 2: Build and Run
Open in Xcode and press ⌘R

### Step 3: Pull to Refresh
Pull down on the departure list - you should now see real trains!

## What You'll See

- **Train Numbers**: 114, 115, 116, 412, 511 (real train IDs)
- **Destinations**: "San Francisco", "San Jose", "Gilroy"
- **Train Types**: Local, Limited, Baby Bullet/Express
- **Times**: Real-time arrival/departure estimates

## If It Still Doesn't Work

Check these:
1. ✅ API key is configured in Config.plist
2. ✅ Simulator has internet connection
3. ✅ Simulator data was reset (schema migration)
4. ✅ All 3 new files are added to Xcode project

## Technical Details

See `API_FIX_SUMMARY.md` for complete technical documentation.

---

**TL;DR**: Reset simulator, rebuild, pull-to-refresh should now work! 🚂
