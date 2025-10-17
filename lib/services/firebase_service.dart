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

// 🚨 Notification channel with custom sound
const AndroidNotificationChannel rideRequestChannel = AndroidNotificationChannel(
  'ride_request_channel',
  'Ride Requests',
  description: 'Incoming ride requests',
  importance: Importance.max,
  playSound: true,
  sound: RawResourceAndroidNotificationSound('ride_request'), // no extension
  //fullScreenIntent: true,
);


// Background handler
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  final data = message.data;
  final bookingId = int.tryParse(data['bookingId'] ?? '0') ?? 0;

  final androidDetails = AndroidNotificationDetails(
    rideRequestChannel.id,
    rideRequestChannel.name,
    channelDescription: rideRequestChannel.description,
    importance: Importance.max,
    priority: Priority.high,
    fullScreenIntent: true, // triggers full-screen notification
    autoCancel: false,
    category: AndroidNotificationCategory.call,
    visibility: NotificationVisibility.public,
    sound: RawResourceAndroidNotificationSound('ride_request'),
    actions: <AndroidNotificationAction>[
      AndroidNotificationAction(
        'accept_action',
        'Accept',
        showsUserInterface: true,
      ),
      AndroidNotificationAction(
        'reject_action',
        'Reject',
        showsUserInterface: true,
      ),
    ],
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


// Init FCM
Future<void> initFirebaseMessaging(
    GlobalKey<NavigatorState> navigatorKey,
    WidgetRef ref,
    ) async {
  await Firebase.initializeApp();

  // Local notifications init
  const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
  const initSettings = InitializationSettings(android: androidInit);

  await flutterLocalNotificationsPlugin.initialize(
    initSettings,
    onDidReceiveNotificationResponse: (details) async {
      final data = details.payload != null ? jsonDecode(details.payload!) : null;
      if (data == null) return;

      if (details.actionId == 'accept_action') {
        final BuildContext? context = navigatorKey.currentContext;
        if (context == null || !context.mounted) {
          context?.go('/onTrip', extra: data); // example
        }
      } else if (details.actionId == 'reject_action') {
        // Cancel ride
        SharedPrefsHelper.clearBookingId();
      }
    },
  );


  // Android channel creation
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(rideRequestChannel);

  // Background handler
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // iOS foreground options
  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );

  // Foreground listener
  FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
    final data = message.data;
    final BuildContext? context = navigatorKey.currentContext;

    if (context == null || !context.mounted) {
      print('Firebase onMessage: Navigator Context is not available, skipping message processing.');
      return;
    }

    String driverStatus = await SharedPrefsHelper.getDriverStatus() ?? "OF";
    final AudioPlayer audioPlayer = AudioPlayer();
    if (driverStatus == "RB") {
      if ((data['status'] ?? '') == 'cancel_ride') {
        if (context.mounted) {
          showRideCancelledDialog(context);
        }
        return;
      }
    }
    if (driverStatus == "OF") {
      return;
    }



    // New ride request
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

    try {
      ref.read(rideRequestProvider.notifier).state = rideRequest;
    } catch (e) {
      print('Error updating ride request state with disposed ref: $e');
      return; // Stop processing if state can't be updated.
    }

    // Play ringtone
    await audioPlayer.setReleaseMode(ReleaseMode.loop);
    await audioPlayer.play(AssetSource(Strings.rideRequestSound));

    // Show dialog in foreground
    if (context.mounted) {
      bool isRideRequestDialogActive = true;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (requestContext) {
          Future.delayed(Duration(seconds: popupDuration), () {
            if (isRideRequestDialogActive && Navigator.of(requestContext).canPop()) {
              Navigator.of(requestContext).pop();
              try {
                ref.read(rideRequestProvider.notifier).state = null;
              } catch (e) {
                print('Cleanup ref read failed: $e');
              }
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
                requiredContext: requestContext,
              ),
            ),
          );
        },
      ).then((_) {
        isRideRequestDialogActive = false;
      });
    }
  });

  // Notification tap (background)
  FirebaseMessaging.onMessageOpenedApp.listen((message) async {
    final data = message.data;
    final BuildContext? context = navigatorKey.currentContext;
    final AudioPlayer audioPlayer = AudioPlayer();
    if (context == null || !context.mounted) {
      print('Firebase onMessageOpenedApp: Context is not mounted, skipping.');
      return;
    }
    String driverStatus = await SharedPrefsHelper.getDriverStatus() ?? "OF";

    if (driverStatus == "OF") {
      return;
    }


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

    ref.read(rideRequestProvider.notifier).state = rideRequest;

    // Play sound
    await audioPlayer.setReleaseMode(ReleaseMode.loop);
    await audioPlayer.play(AssetSource(Strings.rideRequestSound));

    // Show the same dialog as foreground
    if (context.mounted) {
      bool isRideRequestDialogActive = true;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (requestContext) {
          Future.delayed(Duration(seconds: int.tryParse(data['duration'] ?? '30') ?? 30), () {
            // 🛑 NEW CHECK: Flag இன்னும் True ஆக இருக்கிறதா என்று சோதிக்கவும்.
            if (isRideRequestDialogActive && Navigator.of(requestContext).canPop()) {
              Navigator.of(requestContext).pop();
              ref.read(rideRequestProvider.notifier).state = null;
              audioPlayer.stop();
            }
          });
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            insetPadding: const EdgeInsets.all(24),
            contentPadding: EdgeInsets.zero,
            content: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: double.infinity, maxHeight: 300),
              child: RideRequestCard(
                rideRequest: rideRequest,
                audioPlayer: audioPlayer,
                requiredContext: requestContext,
              ),
            ),
          );
        },
      ).then((_) {
        isRideRequestDialogActive = false;
      });
    }
  });

}

// Ride cancelled dialog
// Ride cancelled dialog (வரி 293-இல் இருந்து)
void showRideCancelledDialog(
    BuildContext context,
    ) {
  if (!context.mounted) return;

  // First: close any open dialogs
  if (Navigator.of(context, rootNavigator: true).canPop()) {
    Navigator.of(context, rootNavigator: true).pop();
  }

  showGeneralDialog(
    context: context,
    barrierDismissible: false,
    barrierLabel: "Ride Cancelled",
    transitionDuration: const Duration(milliseconds: 350),
    pageBuilder: (dialogContext, animation, secondaryAnimation) {
      return Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 25,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Animated cancel icon
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.7, end: 1.0),
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeOutBack,
                  builder: (context, scale, child) {
                    return Transform.scale(scale: scale, child: child);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.cancel_outlined,
                      size: 64,
                      color: Colors.redAccent,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

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
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                    ),
                    onPressed: () async {
                      // clear stored data
                      await SharedPrefsHelper.clearBookingId();
                      await SharedPrefsHelper.clearUserId();
                      await SharedPrefsHelper.clearTripData();
                      await SharedPrefsHelper.clearOngoingTrip();
                      await SharedPrefsHelper.setDriverStatus("OL");

                      if (context.mounted) {
                        Navigator.of(context, rootNavigator: true).pop();
                        context.go('/driverHome');
                      }
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
      // Fade + Scale transition
      return FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutBack,
          ),
          child: child,
        ),
      );
    },
  );
}



//