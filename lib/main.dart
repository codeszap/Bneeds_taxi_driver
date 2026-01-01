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

void setupOverlayListener() {
  if (kIsWeb) return;
  // Check if a SendPort is already registered
  if (IsolateNameServer.lookupPortByName('MainApp') == null) {
    ReceivePort receivePort = ReceivePort(); // create a ReceivePort
    // Register the SendPort of this ReceivePort
    IsolateNameServer.registerPortWithName(receivePort.sendPort, 'MainApp');

    receivePort.listen((message) {
      if (message is String && message == "OpenApp") {
        print("Overlay clicked! Bring app to foreground");
        AppLauncher.openApp(); // this will call native Android
      }
    });
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

  runApp(const ProviderScope(child: MyApp()));
}

@pragma("vm:entry-point")
void overlayMain() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MaterialApp(debugShowCheckedModeBanner: false, home: RiderOverlayScreen()),
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
