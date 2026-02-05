import 'dart:isolate';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:bneeds_taxi_driver/firebase_options.dart';
import 'package:bneeds_taxi_driver/utils/constants.dart';
import 'package:bneeds_taxi_driver/utils/storage.dart';
import 'package:bneeds_taxi_driver/theme/app_theme.dart';
import 'package:bneeds_taxi_driver/config/routes.dart';
import 'package:bneeds_taxi_driver/screens/home/riderOverlayScreen.dart';
import 'package:bneeds_taxi_driver/utils/sharedPrefrencesHelper.dart';
import 'package:bneeds_taxi_driver/models/Api%20Modal/AcceptBookingRequest.dart';
import 'package:bneeds_taxi_driver/providers/driverStatusProvider.dart';
import 'package:bneeds_taxi_driver/services/firebase_service.dart';
import 'package:bneeds_taxi_driver/screens/onTrip/TripNotifier.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:bneeds_taxi_driver/services/RideOverlayHelper.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

class AppLauncher {
  static const platform = MethodChannel('overlay_channel');

  static Future<void> openApp() async {
    try {
      await platform.invokeMethod('openApp');
    } on PlatformException catch (e) {
      print("Failed to open app: ${e.message}");
    }
  }
}

Future<void> setupNotificationChannel() async {
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    description: 'This channel is used for important notifications.',
    importance: Importance.high,
    sound: RawResourceAndroidNotificationSound('my_ringtone'),
    playSound: true,
  );

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()
      ?.createNotificationChannel(channel);
}

// 🚗 Global storage for last ride data to ensure 100% recovery
Map<String, dynamic>? _lastRideSyncData;

void setupOverlayListener() {
  if (kIsWeb) return;
  print("🛠️ Setting up Overlay Listener...");
  // Check if a SendPort is already registered
  final existingPort = IsolateNameServer.lookupPortByName('MainApp');
  if (existingPort != null) {
    print("⚠️ Port 'MainApp' already exists, removing old one...");
    IsolateNameServer.removePortNameMapping('MainApp');
  }

  ReceivePort receivePort = ReceivePort();
  bool registered = IsolateNameServer.registerPortWithName(
    receivePort.sendPort,
    'MainApp',
  );
  print("📡 Port 'MainApp' registered: $registered");

  receivePort.listen((message) async {
    print("📩 Main Isolate received message: $message");
    if (message is String) {
        if (message == "OpenApp") {
        print("🚀 Overlay clicked! Bringing app to foreground...");
        AppLauncher.openApp();
      } else if (message == "RestoreBubble") {
        print("🔄 Overlay requested bubble restoration...");
        await FlutterOverlayWindow.closeOverlay();
        final pos = SharedPrefsHelper.getOverlayPosition();
        final double? savedX = pos["x"]?.toDouble();
        final double? savedY = pos["y"]?.toDouble();
        RideOverlayHelper.showOverlay(
          null,
          posX: savedX ?? 100,
          posY: savedY ?? 200,
        );
      } else if (message.startsWith("Pos:")) {
        final coords = message.substring(4).split(",");
        if (coords.length == 2) {
          final int x = int.tryParse(coords[0]) ?? 0;
          final int y = int.tryParse(coords[1]) ?? 0;
          print("📊 Main app syncing position: $x, $y");
          SharedPrefsHelper.setOverlayPosition(x, y);
        }
      } else if (message.startsWith("AcceptRide:")) {
        rideAudioPlayer.stop();
        flutterLocalNotificationsPlugin.cancelAll();
        final bookingId = message.substring(11);
        _handleBackgroundAccept(bookingId);
      } else if (message == "PlaySound") {
        print("🔊 Overlay requested ride sound!");
        _playRideSound();
      } else if (message == "ExpandFullScreen") {
        print("📺 Overlay requested full screen expansion...");
        await FlutterOverlayWindow.closeOverlay();
        // ⏳ Small delay to ensure clean state
        await Future.delayed(const Duration(milliseconds: 100));
        await RideOverlayHelper.showFullScreenOverlay();
      } else if (message == "GetLastRide") {
        print("📥 Overlay requested the last ride data! Sending: $_lastRideSyncData");
        if (_lastRideSyncData != null) {
          FlutterOverlayWindow.shareData(_lastRideSyncData!);
        }
      } else if (message == "StopSound" || message == "RejectRide") {
        print("🎵 Stopping ride request sound & notifications...");
        _lastSyncPlayedBookingId = null; // Reset for next ride
        _lastRideSyncData = null; // Clear sync data
        rideAudioPlayer.stop();
        flutterLocalNotificationsPlugin.cancelAll();
      }
    } else if (message is Map) {
      // Background isolate might send data directly
      if (message["action"] == "NEW_RIDE") {
        _lastRideSyncData = Map<String, dynamic>.from(message);
        final bid = int.tryParse(message["bookingId"]?.toString() ?? "0");
        print("💾 Main Isolate: Saved NEW_RIDE data for sync and playing sound");
        _playRideSound(bookingId: bid); // 🔊 Start sound as soon as ride data arrives
      }
    }
  });
}

int? _lastSyncPlayedBookingId;

Future<void> _playRideSound({int? bookingId}) async {
  if (bookingId != null && _lastSyncPlayedBookingId == bookingId) {
    print("🎵 Sound already sync-playing for booking $bookingId, skipping restart");
    return;
  }
  _lastSyncPlayedBookingId = bookingId;

  try {
    await rideAudioPlayer.stop();
    await rideAudioPlayer.setReleaseMode(ReleaseMode.loop);
    await rideAudioPlayer.play(AssetSource('sounds/ride_request.mp3'));
  } catch (e) {
    print("❌ Error playing ride sound: $e");
  }
}

Future<void> _handleBackgroundAccept(String bookingId) async {
  print("🛠️ Background Accepting Ride: $bookingId");
  AppLauncher.openApp(); // Bring app to foreground

  final riderId = SharedPrefsHelper.getRiderId();
  final repo = providerContainer.read(acceptBookingRepositoryProvider);
  final driverRepo = providerContainer.read(driverRepositoryProvider);

  await SharedPrefsHelper.setBookingId(bookingId);

  try {
    final response = await repo.AcceptBookingStatus(
      request: BookingRequest(
        action: 'G',
        bookingId: bookingId,
        riderId: riderId,
      ),
    );

    if (response.status.toLowerCase() == 'success') {
      print("✅ Background Accept Success!");
      // Navigate to trip screen is handled by status listener usually or manual redirect
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );
      final fromLatLong = "${position.latitude},${position.longitude}";
      await driverRepo.updateDriverStatus(
        riderId: riderId,
        riderStatus: "RB",
        fromLatLong: fromLatLong,
      );
      await SharedPrefsHelper.setDriverStatus("RB");

      // Update providers
      providerContainer.read(driverStatusProvider.notifier).state = "RB";
      providerContainer
          .read(tripProvider.notifier)
          .reset(); // ensure fresh trip
      
      rideAudioPlayer.stop();

      // Navigate to trip
      router.go(AppRoutes.trip);
    }
  } catch (e) {
    print("❌ Error in background accept: $e");
  }
}

final container = ProviderContainer();
late ProviderContainer providerContainer;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb) {
    await setupNotificationChannel();
  }
  if (Firebase.apps.isEmpty) {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } catch (e) {
      debugPrint("Firebase initialization failed: $e");
    }
  }
  await SharedPrefsHelper.init();
  await _initPermissions();
  setupOverlayListener();

  providerContainer = ProviderContainer();

  runApp(
    UncontrolledProviderScope(
      container: providerContainer,
      child: const MyApp(),
    ),
  );
}

@pragma("vm:entry-point")
void overlayMain() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SharedPrefsHelper.init();

  // 📡 Register Port for background data sync
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

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: router,
      title: Strings.appTitle,
      theme: AppTheme.lightTheme,
    );
  }
}

Future<void> _initPermissions() async {
  LocationPermission permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
  }
  if (permission == LocationPermission.deniedForever) {
    // Prompt user to open settings
  }
}
