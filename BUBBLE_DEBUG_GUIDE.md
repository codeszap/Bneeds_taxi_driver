# Bubble Not Showing - Debug Guide

## Problem
Background-க்கு போனா overlay start ஆகுது, ஆனா bubble காட்டல.

## Log Analysis
```
I/flutter: 🔍 Checking if should show overlay. Status: OL
I/flutter: 🚀 Showing Overlay Bubble...
I/flutter: 📊 Loaded coordinates for overlay: X=null, Y=null
I/flutter: 💡 Using default coordinates (center-top)
D/onStartCommand: Service started
```

**Issue:** Overlay service start ஆகுது, ஆனா `overlayMain()` run ஆகல (no "Building overlay" log).

## Changes Made for Debugging

### 1. Added Debug Logs
**File:** `lib/screens/home/riderOverlayScreen.dart`

```dart
@override
Widget build(BuildContext context) {
  print("🏗️ Building overlay - rideData is ${rideData == null ? 'NULL (showing bubble)' : 'NOT NULL (showing bottom sheet)'}");
  return Material(
    color: Colors.transparent,
    child: rideData == null ? bubble() : rideRequestDialog(),
  );
}

Widget bubble() {
  print("🎈 Rendering bubble widget");
  return GestureDetector(
    onTap: () {
      print("🎈 Bubble tapped!");
      _openApp();
    },
    // ... rest of bubble code
  );
}
```

### 2. Added Image Error Handling
```dart
Image.asset(
  "assets/images/logo.png",
  fit: BoxFit.cover,
  errorBuilder: (context, error, stackTrace) {
    print("⚠️ Logo image failed to load: $error");
    // Fallback to icon if image fails
    return Container(
      color: Colors.amber,
      child: const Icon(
        Icons.local_taxi,
        color: Colors.white,
        size: 50,
      ),
    );
  },
)
```

## Expected Logs (When Working)

When overlay starts properly, you should see:
```
I/flutter: 🔍 Checking if should show overlay. Status: OL
I/flutter: 🚀 Showing Overlay Bubble...
I/flutter: 📊 Loaded coordinates for overlay: X=null, Y=null
I/flutter: 💡 Using default coordinates (center-top)
D/onStartCommand: Service started
I/flutter: 🏗️ Building overlay - rideData is NULL (showing bubble)  ← This is missing!
I/flutter: 🎈 Rendering bubble widget  ← This is missing!
```

## Testing Steps

### Step 1: Clean Build
```bash
flutter clean
flutter pub get
flutter build apk --debug
```

### Step 2: Install & Test
```bash
adb install -r build/app/outputs/flutter-apk/app-debug.apk
adb logcat -s flutter:I
```

### Step 3: Test Flow
1. Open app
2. Go ONLINE
3. Press home button (background)
4. Watch logs for:
   - "🏗️ Building overlay"
   - "🎈 Rendering bubble widget"

### Step 4: If Bubble Shows
- Tap bubble
- Should see: "🎈 Bubble tapped!"
- App should open

## Possible Issues & Solutions

### Issue 1: overlayMain() Not Called
**Symptom:** No "Building overlay" log
**Solution:** Check if flutter_overlay_window is properly configured

**Verify in main.dart:**
```dart
@pragma("vm:entry-point")
void overlayMain() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SharedPrefsHelper.init();
  
  final receivePort = ReceivePort();
  IsolateNameServer.removePortNameMapping('OverlayPort');
  IsolateNameServer.registerPortWithName(receivePort.sendPort, 'OverlayPort');
  
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: RiderOverlayScreen(backgroundPort: receivePort),
    ),
  );
}
```

### Issue 2: Assets Not Loading in Overlay
**Symptom:** "Logo image failed to load" log
**Solution:** Fallback icon will show (amber circle with taxi icon)

### Issue 3: Overlay Permission Not Granted
**Symptom:** Overlay doesn't start at all
**Solution:** 
```
Settings → Apps → Bneeds Taxi Driver → Display over other apps → Allow
```

### Issue 4: Overlay Size Too Small
**Symptom:** Bubble too small to see
**Current Size:** 180x180 pixels
**Solution:** Already correct size

## Quick Fix to Try

If bubble still not showing, try this temporary fix to make it VERY visible:

**File:** `lib/services/RideOverlayHelper.dart`

```dart
static Future<void> showOverlay(
  BuildContext? context, {
  double? posX,
  double? posY,
}) async {
  await FlutterOverlayWindow.showOverlay(
    enableDrag: true,
    overlayTitle: "Bneeds Taxi Driver",
    overlayContent: 'Overlay Enabled',
    flag: OverlayFlag.defaultFlag,
    visibility: NotificationVisibility.visibilityPublic,
    positionGravity: PositionGravity.none,
    height: 200,  // ← Increase size
    width: 200,   // ← Increase size
    startPosition: OverlayPosition(posX ?? 100, posY ?? 200),
  );
}
```

## Next Steps

1. **Build & Install** with debug logs
2. **Check logcat** for missing logs
3. **Report back** with:
   - Full logcat output
   - Screenshot of screen when background
   - Any error messages

## Files Modified

1. `lib/screens/home/riderOverlayScreen.dart`
   - Added debug logs to build() and bubble()
   - Added error handler for logo image
   - Added fallback icon

---

**Status:** Debugging in progress
**Next:** Wait for user to test with new debug logs
