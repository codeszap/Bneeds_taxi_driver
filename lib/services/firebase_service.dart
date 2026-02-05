import 'dart:convert';
import 'dart:isolate';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart'
    hide NotificationVisibility;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart' as fcm;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:go_router/go_router.dart';

import '../models/rideRequest.dart';
import '../providers/driverStatusProvider.dart';
import '../screens/home/widget/ride_request_card.dart';
import '../utils/constants.dart';
import '../utils/sharedPrefrencesHelper.dart';
import 'package:geolocator/geolocator.dart';
import '../models/Api Modal/AcceptBookingRequest.dart';
import '../providers/booking_provider.dart';
import '../config/routes.dart';
import '../repositories/profile_repository.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

// 🎵 Global AudioPlayer for Ride Requests
final AudioPlayer rideAudioPlayer = AudioPlayer();

// 🚨 Notification channel with custom sound
const AndroidNotificationChannel rideRequestChannel =
    AndroidNotificationChannel(
      'ride_request_channel_v4', // New ID to force no-sound settings
      'Ride Requests Priority',
      description: 'Incoming ride requests',
      importance: Importance.max,
      playSound: false, // 🚫 DISABLE system sound, we handle it via AudioPlayer
    );

// Background handler
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(fcm.RemoteMessage message) async {
  await Firebase.initializeApp();
  final data = message.data;
  final bookingId = int.tryParse(data['bookingId'] ?? '0') ?? 0;

  final androidDetails = AndroidNotificationDetails(
    rideRequestChannel.id,
    rideRequestChannel.name,
    channelDescription: rideRequestChannel.description,
    importance: Importance.max,
    priority: Priority.max,
    fullScreenIntent: true, 
    autoCancel: false,
    ongoing: true,
    category: AndroidNotificationCategory.alarm, // Alarm category is more aggressive for full screen
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

  // 🛠️ Crucial: Re-initialize in background isolate
  const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
  const initSettings = InitializationSettings(android: androidInit);
  await flutterLocalNotificationsPlugin.initialize(
    initSettings,
    onDidReceiveNotificationResponse: (details) {
      // Background isolate doesn't handle UI navigation
    }
  );

  final String status = data['status'] ?? '';
  print("📡 Background Messaging status: $status, data: $data");
  
  if (status == 'new_ride') {
    final overlayData = {
      'action': 'NEW_RIDE',
      'pickup': data['pickup'] ?? 'No Pickup',
      'drop': data['drop'] ?? 'No Drop',
      'fareAmount': data['fareAmount'] ?? data['fare'] ?? '0',
      'bookingId': data['bookingId'] ?? '0',
      'duration': data['duration'] ?? '30',
    };

    // 📝 1. Save to SharedPrefs immediately (Base storage)
    await SharedPrefsHelper.setLastRideRequest(overlayData);
    
    // 📝 2. Pass to Main Isolate for memory sync (Fast and reliable)
    final SendPort? mainPort = IsolateNameServer.lookupPortByName('MainApp');
    if (mainPort != null) {
      mainPort.send(overlayData);
      print("🚀 Sent NEW_RIDE directly to Main Isolate");
    }

    // 📝 3. Share data with existing overlay (Trigger expansion)
    await FlutterOverlayWindow.shareData(overlayData);
    print("✅ Saved and Shared NEW_RIDE with overlay (Notification skipped)");
  } else if (status == 'cancel_ride') {
    // Restore bubble if ride is cancelled
    await FlutterOverlayWindow.shareData({'action': 'RESTORE_BUBBLE'});
    print("✅ Shared RESTORE_BUBBLE with overlay due to cancellation");
    // Cancel the notification
    await flutterLocalNotificationsPlugin.cancel(bookingId);
  }
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
      print("🔔 Notification Response Received: action=${details.actionId}, payload=${details.payload}");
      final data = details.payload != null
          ? jsonDecode(details.payload!)
          : null;
      
      final BuildContext? context = navigatorKey.currentContext;
      if (context == null || !context.mounted) return;

      if (details.actionId == 'accept_action') {
        if (data != null) {
          final rideReq = _parseRideRequest(data);
          await _handleAcceptFromService(context, ref, rideReq);
        }
      } else if (details.actionId == 'reject_action') {
        print("❌ Reject action clicked from notification tray");
        _lastPlayedBookingId = null; 
        await FlutterOverlayWindow.shareData({'action': 'RESTORE_BUBBLE'});
        SharedPrefsHelper.clearBookingId();
        await rideAudioPlayer.stop();
      } else {
        // App opened by clicking the notification body
        if (data != null) {
          final rideReq = _parseRideRequest(data);
          ref.read(rideRequestProvider.notifier).state = rideReq;
          await _playRideSound(bookingId: rideReq.bookingId);
          _showFullScreenRequest(context, ref, rideReq, 30);
        }
      }
    },
  );

  // Android channel creation
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()
      ?.createNotificationChannel(rideRequestChannel);

  // Background handler
  fcm.FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // iOS foreground options
  await fcm.FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );

  // Foreground listener
  fcm.FirebaseMessaging.onMessage.listen((fcm.RemoteMessage message) async {
    final data = message.data;
    final BuildContext? context = navigatorKey.currentContext;

    if (context == null || !context.mounted) {
      print('Firebase onMessage: Navigator Context is not available, skipping.');
      return;
    }

    String driverStatus = await SharedPrefsHelper.getDriverStatus() ?? "OF";
    if (driverStatus == "RB" && (data['status'] ?? '') == 'cancel_ride') {
      if (context.mounted) showRideCancelledDialog(context);
      return;
    }
    if (driverStatus == "OF") return;

    final rideRequest = _parseRideRequest(data);
    final int popupDuration = int.tryParse(data['duration'] ?? '30') ?? 30;

    try {
      ref.read(rideRequestProvider.notifier).state = rideRequest;
    } catch (e) {
      print('Error updating ride request state: $e');
      return;
    }

    // ❌ DON'T share with overlay in foreground - overlay is for background only!
    // The overlay will receive data from background handler when app is actually in background
    // Here we only show the in-app full-screen dialog

    await _playRideSound(bookingId: rideRequest.bookingId);

    if (context.mounted) {
      _showFullScreenRequest(context, ref, rideRequest, popupDuration);
    }
  });

  // Notification tap listener
  fcm.FirebaseMessaging.onMessageOpenedApp.listen((fcm.RemoteMessage message) async {
    final data = message.data;
    final BuildContext? context = navigatorKey.currentContext;
    if (context == null || !context.mounted) return;

    String driverStatus = await SharedPrefsHelper.getDriverStatus() ?? "OF";
    if (driverStatus == "OF") return;

    final rideRequest = _parseRideRequest(data);
    ref.read(rideRequestProvider.notifier).state = rideRequest;

    await _playRideSound(bookingId: rideRequest.bookingId);

    if (context.mounted) {
      _showFullScreenRequest(context, ref, rideRequest, 30);
    }
  });
}

// --- Helper Functions ---

RideRequest _parseRideRequest(Map<String, dynamic> data) {
  return RideRequest(
    pickup: data['pickup'] ?? '',
    drop: data['drop'] ?? '',
    pickuplatlong: data['pickuplatlong'] ?? '',
    droplatlong: data['droplatlong'] ?? '',
    fare: (double.tryParse(data['fareAmount'] ?? data['fare'] ?? '0') ?? 0).toInt(),
    bookingId: int.tryParse(data['bookingId'] ?? '0') ?? 0,
    fcmToken: data['token'] ?? '',
    cusMobile: data['userMobNo'] ?? '',
    userId: data['userId'] ?? '',
  );
}

// Track last played booking to prevent double sound
int? _lastPlayedBookingId;

Future<void> _playRideSound({int? bookingId}) async {
  if (bookingId != null && _lastPlayedBookingId == bookingId) {
    print("🎵 Sound already playing for booking $bookingId, skipping restart");
    return;
  }
  _lastPlayedBookingId = bookingId;

  await rideAudioPlayer.stop();
  await rideAudioPlayer.setReleaseMode(ReleaseMode.loop);
  await rideAudioPlayer.play(AssetSource(Strings.rideRequestSound));
}

void _showFullScreenRequest(BuildContext context, WidgetRef ref, RideRequest rideRequest, int durationSeconds) {
  bool isActive = true;
  showGeneralDialog(
    context: context,
    barrierDismissible: false,
    barrierColor: const Color(0xFF1C1C1E),
    pageBuilder: (requestContext, animation, secondaryAnimation) {
      Future.delayed(Duration(seconds: durationSeconds), () {
        if (isActive && Navigator.of(requestContext).canPop()) {
          Navigator.of(requestContext).pop();
          ref.read(rideRequestProvider.notifier).state = null;
          rideAudioPlayer.stop();
          // Restore bubble after timeout
          IsolateNameServer.lookupPortByName('MainApp')?.send("RestoreBubble");
        }
      });

      return Material(
        color: const Color(0xFF1C1C1E),
        child: SafeArea(
          child: Stack(
            children: [
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.amber.withOpacity(0.1), Colors.transparent],
                    ),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(35)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("NEW RIDE REQUEST", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.amber, letterSpacing: 2)),
                      const SizedBox(height: 30),
                      _locRow(Icons.my_location, "PICKUP", rideRequest.pickup, Colors.green),
                      const Padding(
                        padding: EdgeInsets.only(left: 12),
                        child: SizedBox(height: 25, child: VerticalDivider(thickness: 1, color: Colors.grey)),
                      ),
                      _locRow(Icons.location_on, "DROP", rideRequest.drop, Colors.red),
                      const SizedBox(height: 40),
                      const Divider(),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("ESTIMATED FARE", style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                              Text("₹${rideRequest.fare}", style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w900)),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 40),
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: _btn("REJECT", Colors.grey[200]!, Colors.black, () {
                              rideAudioPlayer.stop();
                              Navigator.pop(requestContext);
                              ref.read(rideRequestProvider.notifier).state = null;
                              // Restore bubble on reject
                              IsolateNameServer.lookupPortByName('MainApp')?.send("RestoreBubble");
                            }),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            flex: 3,
                            child: _btn("ACCEPT", Colors.amber, Colors.black, () async {
                              rideAudioPlayer.stop();
                              Navigator.pop(requestContext);
                              await _handleAcceptFromService(context, ref, rideRequest);
                              // Note: Bubble will be handled by trip state
                            }),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  ).then((_) => isActive = false);
}

Widget _locRow(IconData icon, String label, String val, Color c) {
  return Row(
    children: [
      Icon(icon, color: c, size: 28),
      const SizedBox(width: 15),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
            Text(val, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18), maxLines: 2, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    ],
  );
}

Widget _btn(String t, Color bg, Color tc, VoidCallback tap) {
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
      child: Text(t, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
    ),
  );
}

Future<void> _handleAcceptFromService(BuildContext context, WidgetRef ref, RideRequest rideRequest) async {
  final repo = ref.read(acceptBookingRepositoryProvider);
  final driverRepo = ref.read(driverRepositoryProvider);
  final riderId = SharedPrefsHelper.getRiderId();
  await SharedPrefsHelper.setBookingId(rideRequest.bookingId.toString());

  try {
    final apiResp = await repo.AcceptBookingStatus(
      request: BookingRequest(
        action: 'G',
        bookingId: rideRequest.bookingId.toString(),
        riderId: riderId.toString(),
      ),
    );

    if (apiResp.status?.toLowerCase() == 'success') {
      ref.read(rideRequestProvider.notifier).state = null;
      router.go(AppRoutes.trip);

      final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      final fromLatLong = "${position.latitude},${position.longitude}";

      final statusResp = await driverRepo.updateDriverStatus(
        riderId: riderId,
        riderStatus: "RB",
        fromLatLong: fromLatLong,
      );

      if (statusResp.status == "success") {
        ref.read(driverStatusProvider.notifier).state = "RB";
        await SharedPrefsHelper.setDriverStatus("RB");
      }
    } else {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(apiResp.message ?? "Accept Failed")));
    }
  } catch (e) {
    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
  }
}
// Ride cancelled dialog (வரி 293-இல் இருந்து)
void showRideCancelledDialog(BuildContext context) {
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
          scale: CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
          child: child,
        ),
      );
    },
  );
}



//