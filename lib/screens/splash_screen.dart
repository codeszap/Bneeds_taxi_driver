
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:go_router/go_router.dart';
import 'package:bneeds_taxi_driver/utils/storage.dart';
import 'package:permission_handler/permission_handler.dart';
import '../utils/fcmHelper.dart';

class DriverSplashScreen extends ConsumerStatefulWidget {
  const DriverSplashScreen({super.key});

  @override
  ConsumerState<DriverSplashScreen> createState() => _DriverSplashScreenState();
}

class _DriverSplashScreenState extends ConsumerState<DriverSplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeAndNavigate();
  }

  Future<void> _initializeAndNavigate() async {
    await _checkNotificationPermission();
    await FcmHelper.syncTokenWithServer();
    _checkNavigation();

    final driverStatus = ref.read(driverStatusProvider);
    final locationService = ref.read(driverLocationServiceProvider);
    locationService.setupLocationUpdater(driverStatus);
  }

  Future<void> _checkNotificationPermission() async {
    var status = await Permission.notification.status;
    if (status.isDenied) {
      await Permission.notification.request();
    }
  }


  Future<void> _checkNavigation() async {
    // splash delay
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    // 1️⃣ Check if there is any ongoing trip
    final driverStatus = await SharedPrefsHelper.getDriverStatus();
    if (driverStatus == "RB") {
      context.go(AppRoutes.trip);
      return;
    }

    // 2️⃣ Check profile completion + riderId + FCM token
    final isProfileComplete = SharedPrefsHelper.getDriverProfileCompleted();
    final riderId = SharedPrefsHelper.getRiderId();
    String? fcmToken;
    
    try {
      fcmToken = await FirebaseMessaging.instance.getToken();

      // Retry fetching FCM token if null
      int retries = 0;
      while (fcmToken == null && retries < 3) {
        await Future.delayed(const Duration(seconds: 1));
        fcmToken = await FirebaseMessaging.instance.getToken();
        retries++;
      }
    } catch (e) {
      print("🚨 FCM Token Fetch Error: $e");
      fcmToken = null; // Ensure it's null to handle fallback
    }

    if (isProfileComplete && riderId.isNotEmpty) {
      // Even if fcmToken is null, we proceed if profile is complete
      // Notification sounds/alerts might not work, but the app stays functional
      context.go(AppRoutes.driverHome);
    } else {
      // If any essential info missing, go to login/profile
      context.go(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.amberAccent,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(Strings.logo, width: 180, height: 180),
              const SizedBox(height: 24),
              Text(
                "Get there fast, safe and smart.",
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyText.copyWith(
                  color: AppColors.buttonText,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 40),
              const Padding(
                padding: EdgeInsets.all(12.0),
                child: LinearProgressIndicator(
                  minHeight: 6,
                  valueColor: AlwaysStoppedAnimation(AppColors.error),
                  backgroundColor: AppColors.background,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
