import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:audioplayers/audioplayers.dart';

import 'package:go_router/go_router.dart';

import '../models/rideRequest.dart';
import '../providers/driverStatusProvider.dart';
import '../screens/home/widget/ride_request_card.dart';
import '../screens/onTrip/TripNotifier.dart';
import '../utils/constants.dart';
import '../utils/sharedPrefrencesHelper.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

const AndroidNotificationChannel channel = AndroidNotificationChannel(
  'high_importance_channel',
  'High Importance Notifications',
  description: 'This channel is used for important notifications.',
  importance: Importance.high,
);

Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  final data = message.data;

  final bookingId = int.tryParse(data['bookingId'] ?? '0') ?? 0;

  final androidDetails = AndroidNotificationDetails(
    'ride_request_channel',
    'Ride Requests',
    channelDescription: 'Incoming ride requests',
    importance: Importance.max,
    priority: Priority.high,
    fullScreenIntent: true,
  );

  final platformDetails = NotificationDetails(android: androidDetails);

  await flutterLocalNotificationsPlugin.show(
    bookingId,
    'New Ride Request',
    '${data['pickup']} → ${data['drop']}',
    platformDetails,
    payload: jsonEncode(data),
  );
}

Future<void> initFirebaseMessaging(
  BuildContext context,
  WidgetRef ref,
  AudioPlayer audioPlayer,
) async {
  await Firebase.initializeApp();

  // Local notifications init
  const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
  const initSettings = InitializationSettings(android: androidInit);
  await flutterLocalNotificationsPlugin.initialize(initSettings);

  // Android channel create
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()
      ?.createNotificationChannel(channel);

  // Background handler
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // iOS presentation options
  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );

  // --- Foreground listener ---
  // FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
  //   final data = message.data;
  //
  //   final driverStatus = ref.read(driverStatusProvider);
  //   if (driverStatus != "OL") return;
  //   // Cancel ride
  //   if ((data['status'] ?? '') == 'cancel ride') {
  //     await audioPlayer.stop();
  //     ref.read(rideRequestProvider.notifier).state = null;
  //     ref.read(tripProvider.notifier).reset();
  //
  //     if (context.mounted) {
  //       final rideRequest = ref.read(rideRequestProvider);
  //       showRideCancelledDialog(context, rideRequest, ref, audioPlayer);
  //     }
  //     return;
  //   }
  //
  //   // New ride request
  //   final pickup = data['pickup'] ?? '';
  //   final drop = data['drop'] ?? '';
  //   final fare = (double.tryParse(data['fare'] ?? '0') ?? 0).toInt();
  //   final bookingId = int.tryParse(data['bookingId'] ?? '0') ?? 0;
  //   final pickuplatlong = data['pickuplatlong'] ?? '';
  //   final droplatlong = data['droplatlong'] ?? '';
  //   final cusMobile = data['userMobNo'] ?? '';
  //   final userId = data['userId'] ?? '';
  //
  //   if (driverStatus == "OL") {
  //     ref.read(rideRequestProvider.notifier).state = RideRequest(
  //       pickup: pickup,
  //       drop: drop,
  //       pickuplatlong: pickuplatlong,
  //       droplatlong: droplatlong,
  //       fare: fare,
  //       bookingId: bookingId,
  //       fcmToken: data['token'] ?? '',
  //       cusMobile: cusMobile,
  //       userId: userId,
  //     );
  //
  //     await audioPlayer.setReleaseMode(ReleaseMode.loop);
  //     await audioPlayer.play(AssetSource(Strings.rideRequestSound));
  //   }
  //
  //   // Local notification
  //   flutterLocalNotificationsPlugin.show(
  //     bookingId,
  //     'New Ride Request',
  //     '$pickup → $drop',
  //     NotificationDetails(
  //       android: AndroidNotificationDetails(
  //         channel.id,
  //         channel.name,
  //         channelDescription: channel.description,
  //         importance: Importance.high,
  //         priority: Priority.high,
  //         icon: '@mipmap/ic_launcher',
  //         fullScreenIntent: true,
  //       ),
  //     ),
  //     payload: jsonEncode(data),
  //   );
  // });

  FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
    final data = message.data;
    // final driverStatus = ref.read(driverStatusProvider);
    //
    // if (driverStatus == "OF") return;

    // Cancel ride
    try {
      if ((data['status'] ?? '') == 'cancel_ride') {

        if (context.mounted) {
          showRideCancelledDialog(
            context,
            ref.read(rideRequestProvider),
            ref,
            audioPlayer,
          );
        }
        return;
      }
    }
    catch(e){

    }
    // 🚖 New Ride request
    final rideRequest = RideRequest(
      pickup: data['pickup'] ?? '',
      drop: data['drop'] ?? '',
      pickuplatlong: data['pickuplatlong'] ?? '',
      droplatlong: data['droplatlong'] ?? '',
      fare: (double.tryParse(data['fare'] ?? '0') ?? 0).toInt(),
      bookingId: int.tryParse(data['bookingId'] ?? '0') ?? 0,
      fcmToken: data['token'] ?? '',
      cusMobile: data['userMobNo'] ?? '',
      userId: data['userId'] ?? '',
    );

    final int popupDuration = int.tryParse(data['duration'] ?? '30') ?? 30;
    // Update state
    ref.read(rideRequestProvider.notifier).state = rideRequest;

    // Play ringtone
    await audioPlayer.setReleaseMode(ReleaseMode.loop);
    await audioPlayer.play(AssetSource(Strings.rideRequestSound));

    // 🚨 Global popup (works on any screen)
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        Future.delayed(Duration(seconds: popupDuration), () {
          if (Navigator.canPop(context)) {
            Navigator.of(context).pop();
            ref.read(rideRequestProvider.notifier).state = null;
            audioPlayer.stop();
          }
        });
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          insetPadding: const EdgeInsets.all(24),
          contentPadding: EdgeInsets.zero,
          content: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: double.infinity,
              maxHeight: 300,
            ),
            child: RideRequestCard(
              rideRequest: rideRequest,
              audioPlayer: audioPlayer,
            ),
          ),
        );
      },
    );
  });

  // When tapped on notification (background)
  FirebaseMessaging.onMessageOpenedApp.listen((message) {
    print("Opened from background: ${message.data}");
  });
}

void showRideCancelledDialog(
  BuildContext context,
  RideRequest? rideRequest,
  WidgetRef ref,
  AudioPlayer audioPlayer,
) {
  showGeneralDialog(
    context: context,
    barrierDismissible: false,
    barrierLabel: "Ride Cancelled",
    transitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (context, animation, secondaryAnimation) {
      return Center(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.85,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 20,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.cancel_outlined,
                    color: Colors.redAccent,
                    size: 60,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  "Ride Cancelled",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  "The customer has cancelled this ride.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black54,
                    height: 1.4,
                  ),
                ),
                if (rideRequest != null) ...[
                  Divider(color: Colors.grey.shade300, thickness: 1),
                  const SizedBox(height: 8),
                  Text(
                    "Pickup: ${rideRequest.pickup}\nDrop: ${rideRequest.drop}\nFare: ₹${rideRequest.fare}",
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 3,
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                      SharedPrefsHelper.clearBookingId();
                      SharedPrefsHelper.clearUserId();
                      SharedPrefsHelper.clearTripData();
                      SharedPrefsHelper.clearOngoingTrip();
                      ref.read(tripProvider.notifier).reset();
                      Future.delayed(Duration.zero, () {
                        context.go('/driverHome');
                      });
                    },
                    child: const Text(
                      "OK",
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      return ScaleTransition(
        scale: CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
        child: FadeTransition(opacity: animation, child: child),
      );
    },
  );
}
