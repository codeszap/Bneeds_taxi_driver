// lib/utils/fcmHelper.dart


import 'package:bneeds_taxi_driver/utils/sharedPrefrencesHelper.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../repositories/profile_repository.dart';

class FcmHelper {
  /// A centralized function to sync the FCM token with the server.
  /// Call this on app start (Splash) and after a successful login.
  static Future<void> syncTokenWithServer() async {
    try {
      // 1. பயனர் உள்நுழைந்துள்ளாரா என சரிபார்க்கவும்
      final userId = await SharedPrefsHelper.getRiderId();
      final mobileNo = await SharedPrefsHelper.getDriverMobile();
      if (mobileNo.isEmpty) {
        debugPrint("FCM Sync: User not logged in. Skipping sync.");
        return; // பயனர் உள்நுழையவில்லை என்றால், இங்கேயே நிறுத்திவிடவும்
      }

      // 2. Firebase-இடம் இருந்து புதிய டோக்கனைப் பெறவும்
      // FirebasePushService.dart-ல் உள்ள getFcmToken() மூலம் டோக்கனைப் பெறலாம்
      // அல்லது நேரடியாக FirebaseMessaging.instance.getToken() பயன்படுத்தலாம்.
      // உங்கள் அமைப்பில் இருந்து FirebasePushService-ஐ பயன்படுத்துவது சிறந்தது.
      final String? newFcmToken = await FirebaseMessaging.instance
          .getToken(); // இது வேலை செய்யும்

      if (newFcmToken == null || newFcmToken.isEmpty) {
        debugPrint("FCM Sync: Failed to get a valid token from Firebase.");
        return;
      }

      // 3. ஏற்கனவே மொபைலில் சேமிக்கப்பட்ட பழைய டோக்கனை எடுக்கவும்
      final String? oldFcmToken = await SharedPrefsHelper.getDriverFcmToken();

      // 4. டோக்கன் மாறியிருந்தால் அல்லது இதுவே முதல் முறை என்றால் மட்டும் சர்வரில் புதுப்பிக்கவும்
      if (newFcmToken != oldFcmToken) {
        debugPrint("FCM token has changed. Syncing with server...");

        // உங்கள் Repository-ஐ அழைத்து, சர்வரில் டோக்கனைப் புதுப்பிக்கவும்
        final success = await ProfileRepository().updateFcmToken(
          mobileNo: mobileNo,
          tokenKey: newFcmToken,
        );

        if (success != null) {
          // சர்வரில் வெற்றி பெற்றால் மட்டுமே உள்ளூர் சேமிப்பகத்திலும் (SharedPreferences) புதுப்பிக்கவும்.
          // இது மிக முக்கியம். சர்வர் அப்டேட் தோல்வியுற்றால், பழைய டோக்கனே இருக்க வேண்டும்.
          await SharedPrefsHelper.setDriverFcmToken(newFcmToken);
          debugPrint(
            "✅ FCM token synced successfully to server and local storage.",
          );
        } else {
          debugPrint("❌ FCM Sync: Failed to update token on the server.");
        }
      } else {
        debugPrint("ℹ️ FCM token is already up-to-date. No sync needed.");
      }
    } catch (e) {
      debugPrint("🚨 An error occurred during FCM token sync: $e");
    }
  }
}
