import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:go_router/go_router.dart';
import 'package:bneeds_taxi_driver/utils/storage.dart';

import '../models/TripState.dart';
import 'onTrip/TripNotifier.dart';

class DriverSplashScreen extends ConsumerStatefulWidget {
  const DriverSplashScreen({super.key});

  @override
  ConsumerState<DriverSplashScreen> createState() => _DriverSplashScreenState();
}

class _DriverSplashScreenState extends ConsumerState<DriverSplashScreen> {
  @override
  void initState() {
    super.initState();
    _initFCMToken();
    _checkNavigation();
  }

  Future<void> _initFCMToken() async {
    try {
      final fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken != null) {
        await SharedPrefsHelper.setDriverFcmToken(fcmToken);
        debugPrint("✅ FCM Token saved: $fcmToken");
      } else {
        debugPrint("⚠️ Failed to fetch FCM Token");
      }
    } catch (e) {
      debugPrint("❌ Error getting FCM Token: $e");
    }
  }

  LatLng stringToLatLng(String s) {
    final parts = s.split(',');
    return LatLng(double.parse(parts[0]), double.parse(parts[1]));
  }

  Future<void> _checkNavigation() async {
    // splash delay
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    // 1️⃣ Check if there is any ongoing trip
    final tripData = await SharedPrefsHelper.getTripData();
    if (tripData != null) {
      final pickupLatLng = stringToLatLng(tripData['pickupLatLng']);
      final dropLatLng = stringToLatLng(tripData['dropLatLng']);
      final statusIndex = tripData['status'] ?? 0;
      final tripStatus = TripStatus.values[statusIndex];

      ref.read(tripProvider.notifier).acceptRide(
        tripData['pickup'],
        tripData['drop'],
        tripData['fare'],
        pickupLatLng,
        dropLatLng,
        tripData['otp'],
        tripData['bookingId'],
        tripData['fcmToken'],
        tripData['userId'],
        tripData['cusMobile'],
          tripStatus
      );

      context.go(AppRoutes.trip);
      return;
    }

    // 2️⃣ Check profile completion + riderId + FCM token
    final isProfileComplete = SharedPrefsHelper.getDriverProfileCompleted();
    final riderId = SharedPrefsHelper.getRiderId();
    String? fcmToken = await FirebaseMessaging.instance.getToken();

    // Retry fetching FCM token if null
    int retries = 0;
    while (fcmToken == null && retries < 3) {
      await Future.delayed(const Duration(seconds: 1));
      fcmToken = await FirebaseMessaging.instance.getToken();
      retries++;
    }

    if (isProfileComplete && riderId.isNotEmpty && fcmToken != null) {
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
              Image.asset(
                Strings.logo,
                width: 180,
                height: 180,
              ),
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
