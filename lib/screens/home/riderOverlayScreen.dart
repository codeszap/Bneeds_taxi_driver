import 'dart:isolate';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';

import '../../utils/sharedPrefrencesHelper.dart';

class RiderOverlayScreen extends StatefulWidget {
  final ReceivePort? backgroundPort;
  const RiderOverlayScreen({super.key, this.backgroundPort});

  @override
  State<RiderOverlayScreen> createState() => _RiderOverlayScreenState();
}

class _RiderOverlayScreenState extends State<RiderOverlayScreen> with TickerProviderStateMixin {
  static const String _mainAppPort = 'MainApp';
  SendPort? mainAppPort;
  Map<String, dynamic>? rideData; // To store incoming ride request
  
  // 📍 1. Animation for the reverse timer (Rapido style)
  AnimationController? _timerController;

  @override
  void dispose() {
    _timerController?.dispose();
    super.dispose();
  }

  // 📍 Save bubble position before moving to center
  int? _savedBubbleX;
  int? _savedBubbleY;

  void _initTimerAnimation(int seconds) {
    _timerController?.dispose();
    _timerController = AnimationController(
      vsync: this,
      duration: Duration(seconds: seconds),
    )..reverse(from: 1.0); // Start from Full (1.0) and go to Empty (0.0)

    _timerController?.addStatusListener((status) {
      if (status == AnimationStatus.dismissed) {
        print("🕒 Animation finished! Auto-rejecting...");
        _onReject();
      }
    });

    _timerController?.addListener(() {
      setState(() {}); // Rebuild for each tick
    });
  }

  @override
  void initState() {
    super.initState();
    print("🎬 Overlay Isolate: initState called");

    // 🚀 Attempt immediate load before first build
    final cachedRide = SharedPrefsHelper.getLastRideRequest();
    if (cachedRide != null) {
      rideData = Map<String, dynamic>.from(cachedRide);
      print("🎯 Immediate Recovery: ${rideData!['bookingId']}");
    }

    Future.microtask(() async {
      await SharedPrefsHelper.reload();
      final lastRide = SharedPrefsHelper.getLastRideRequest();
      if (lastRide != null && mounted) {
        print("🎯 Async Recovery: ${lastRide['bookingId']}");
        setState(() {
          rideData = Map<String, dynamic>.from(lastRide);
          final int seconds = int.tryParse(rideData!['duration']?.toString() ?? "30") ?? 30;
          _initTimerAnimation(seconds);
        });
      } else if (rideData == null && mounted) {
        // last fallback: ask main app for the data
        print("❓ Data still missing! Asking main app via GetLastRide...");
        callBackFunction("GetLastRide");
      }
    });

    /// Overlay events listener
    FlutterOverlayWindow.overlayListener.listen((event) async {
      _handleEvent(event);
    });

    /// Background port listener (from IsolateNameServer)
    widget.backgroundPort?.listen((event) async {
      print("📩 Overlay Isolate RECEIVED via Port: $event");
      _handleEvent(event);
    });
  }

  Future<void> _handleEvent(dynamic event) async {
    print("📩 Processing event: $event");
    if (event is Map) {
      final Map<String, dynamic> data = Map<String, dynamic>.from(event);

      if (data.containsKey("x") && data.containsKey("y")) {
        final int nx = (data["x"] as num).toInt();
        final int ny = (data["y"] as num).toInt();
        print("📍 Overlay dragged to: $nx, $ny");
        SharedPrefsHelper.setOverlayPosition(nx, ny);
        callBackFunction("Pos:$nx,$ny");
      } else if (data["action"] == "NEW_RIDE") {
        print("🔥 NEW_RIDE action detected in Overlay Isolate!");
        final int duration = int.tryParse(data["duration"]?.toString() ?? "30") ?? 30;
        final String? bookingId = data["bookingId"]?.toString();

        // 📝 1. Update local state
        if (mounted) {
          setState(() {
            rideData = data;
            final int seconds = int.tryParse(data['duration']?.toString() ?? "30") ?? 30;
            _initTimerAnimation(seconds);
          });
        }

        // 📍 2. Save to SharedPrefs for expansion instance
        await SharedPrefsHelper.setLastRideRequest(data);
        
        // 📍 3. Tell Main Isolate to close and open FULL SCREEN at (0,0)
        print("🎯 Requesting FULL SCREEN expansion from (0,0)...");
        callBackFunction("ExpandFullScreen");

        // Auto Close Timer
        Future.delayed(Duration(seconds: duration), () {
          if (rideData != null && rideData!["bookingId"]?.toString() == bookingId) {
            print("🕒 Duration expired! Auto-closing...");
            _onReject();
          }
        });
      } else if (data["action"] == "RESTORE_BUBBLE") {
        print("🔄 RESTORE_BUBBLE requested! Clearing ride data...");
        if (mounted) {
          setState(() {
            rideData = null;
          });
        }
        _onReject();
      }
    } else if (event is String) {
      if (event == "OpenApp") {
        callBackFunction("StopSound"); // Safety: Stop sound on app open
        _openApp();
      }
    }
  }

  /// Sends message back to main app
  void callBackFunction(String tag) {
    print("📍 Attempting to send tag: $tag");
    mainAppPort = IsolateNameServer.lookupPortByName(_mainAppPort);
    if (mainAppPort != null) {
      mainAppPort?.send(tag);
      print("✅ Sent overlay tag: $tag");
    } else {
      print("❌ Could not find MainApp port! Is the app running?");
    }
  }

  /// Open main app when logo tapped
  void _openApp() {
    callBackFunction("OpenApp");
    // FlutterOverlayWindow.closeOverlay(); // overlay close
  }

  Future<void> _onAccept() async {
    if (rideData != null) {
      print("✅ Accepting Ride: Clearing data and shrinking...");
      callBackFunction("AcceptRide:${rideData!['bookingId']}");
      callBackFunction("StopSound");

      // 1. Clear UI state and shared prefs
      _timerController?.stop();
      setState(() {
        rideData = null;
      });
      await SharedPrefsHelper.setLastRideRequest(null);

      // Repeat stop signal to ensure it's heard
      Future.delayed(const Duration(milliseconds: 200), () => callBackFunction("StopSound"));
      Future.delayed(const Duration(milliseconds: 500), () => callBackFunction("StopSound"));

      // 2. Shrink window back to regular size
      await FlutterOverlayWindow.resizeOverlay(180, 180, true);
      
      // 📍 3. Restore bubble to original position
      await _restoreBubblePosition();
    }
  }

  Future<void> _onReject() async {
    print("❌ Rejecting Ride: Clearing data and shrinking...");
    callBackFunction("StopSound");

    // 1. Clear UI state and shared prefs
    _timerController?.stop();
    setState(() {
      rideData = null;
    });
    await SharedPrefsHelper.setLastRideRequest(null);

    // Repeat stop signal to ensure it's heard
    Future.delayed(const Duration(milliseconds: 200), () => callBackFunction("StopSound"));
    Future.delayed(const Duration(milliseconds: 500), () => callBackFunction("StopSound"));

    // 2. Shrink window back to regular size
    await FlutterOverlayWindow.resizeOverlay(180, 180, true);

    // 📍 3. Restore bubble to original position (via main isolation)
    await _restoreBubblePosition();
  }

  Future<void> _restoreBubblePosition() async {
    print("🔄 Requesting bubble restoration from main app...");
    // Instead of doing it here (which kills the isolate), we tell the main app.
    // The main app will close this and reopen it at the right spot.
    callBackFunction("RestoreBubble");
  }

  /// Bubble Widget (Draggable)
  Widget bubble() {
    print("🎈 Rendering bubble widget");
    return GestureDetector(
      onTap: () {
        print("🎈 Bubble tapped!");
        _openApp();
      },
      child: Center(
        child: Container(
          width: 85,
          height: 85,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            border: Border.all(color: Colors.amber, width: 3),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 15,
                spreadRadius: 2,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(2),
            child: ClipOval(
              child: Image.asset(
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
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Ride Request Draggable Card Widget
  Widget rideRequestDialog() {
    if (rideData == null) return const SizedBox();

    // Full Screen Overlay UI (Premium Light Theme)
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white, // Premium Light Background
        borderRadius: BorderRadius.zero,
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Top Bar with Timer
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "NEW RIDE",
                        style: TextStyle(
                          color: Colors.amber,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2.0,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "INCOMING REQUEST",
                        style: TextStyle(
                          color: Colors.black.withOpacity(0.5),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                   ),
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 60,
                        height: 60,
                        child: CircularProgressIndicator(
                          value: _timerController?.value ?? 0,
                          strokeWidth: 4,
                          backgroundColor: Colors.blue.withOpacity(0.1),
                          color: _timerController != null && _timerController!.value < 0.3 
                            ? Colors.red 
                            : Colors.blue,
                        ),
                      ),
                      Text(
                        "${((_timerController?.value ?? 0) * (int.tryParse(rideData!['duration']?.toString() ?? "30") ?? 30)).ceil()}",
                        style: TextStyle(
                          color: _timerController != null && _timerController!.value < 0.3 
                            ? Colors.red 
                            : Colors.blue,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const Spacer(),

            // Fare (The Hero)
            Column(
              children: [
                Text(
                  "ESTIMATED FARE",
                  style: TextStyle(
                    color: Colors.black.withOpacity(0.5),
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "₹${rideData!['fareAmount'] ?? '0'}",
                  style: const TextStyle(
                    color: Colors.amber,
                    fontSize: 72,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),

            const Spacer(),

            // Locations Card
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.05),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: Colors.grey.withOpacity(0.2)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  )
                ],
              ),
              child: Column(
                children: [
                  _fullscreenLocRow(Icons.my_location, "PICKUP", rideData!['pickup'] ?? 'Unknown', Colors.green),
                  Padding(
                    padding: const EdgeInsets.only(left: 12),
                    child: SizedBox(
                      height: 30,
                      child: VerticalDivider(color: Colors.grey.withOpacity(0.3), thickness: 2),
                    ),
                  ),
                  _fullscreenLocRow(Icons.location_on, "DROP", rideData!['drop'] ?? 'Unknown', Colors.red),
                ],
              ),
            ),

            const Spacer(),

            // Bottom Actions
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
              child: Row(
                children: [
                  Expanded(
                    flex: 1, // Equal Size
                    child: _fullscreenBtn("REJECT", Colors.red.withOpacity(0.1), Colors.red, _onReject),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    flex: 1, // Equal Size
                    child: _fullscreenBtn("ACCEPT", Colors.green, Colors.white, _onAccept),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fullscreenLocRow(IconData icon, String label, String val, Color c) {
    return Row(
      children: [
        Icon(icon, color: c, size: 28),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: Colors.black.withOpacity(0.4), fontSize: 10, fontWeight: FontWeight.bold)),
              Text(val, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18), maxLines: 2, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ],
    );
  }

  Widget _fullscreenBtn(String t, Color bg, Color tc, VoidCallback tap) {
    return SizedBox(
      height: 70,
      child: ElevatedButton(
        onPressed: tap,
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: tc,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 0,
        ),
        child: Text(t, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _locRow(IconData icon, String label, String value, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(width: 12), // Reduced from 16
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min, // Added
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 10, // Reduced from 11
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 4), // Reduced from 6
              Text(
                value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15, // Reduced from 16
                  color: Colors.black87,
                  height: 1.2, // Reduced from 1.3
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _btn(String label, Color bgColor, Color textColor, VoidCallback onPressed) {
    return SizedBox(
      height: 50,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          foregroundColor: textColor,
          elevation: bgColor == Colors.amber ? 2 : 0,
          shadowColor: bgColor == Colors.amber ? Colors.amber.withOpacity(0.4) : null,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: bgColor != Colors.amber
                ? BorderSide(color: Colors.grey[300]!, width: 1)
                : BorderSide.none,
          ),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // High DPI devices might report smaller logical pixels. 
        // 180 physical / 3.0 density = 60 logical. 
        // 360 physical / 3.0 density = 120 logical.
        // Threshold 100 is safe to distinguish bubble from card.
        final bool isSmall = constraints.maxWidth < 100; 
        print("🏗️ Build - Width: ${constraints.maxWidth.toStringAsFixed(1)}, isSmall: $isSmall, rideData: ${rideData == null ? 'NULL' : 'EXIST'}");

        // 🚨 CRITICAL: If we have ride data, we MUST show the dialog, not the bubble.
        // This prevents the "only bubble in center" issue.
        if (rideData != null) {
          return Material(
            color: Colors.transparent, 
            child: rideRequestDialog()
          );
        }

        return Material(
          color: Colors.transparent,
          child: bubble(),
        );
      },
    );
  }
}
