import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../screens/RideRequestScreen.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

const AndroidNotificationChannel rideRequestChannel = AndroidNotificationChannel(
  'ride_request_channel',
  'Ride Requests',
  description: 'Incoming ride requests',
  importance: Importance.max,
);

Future<void> initNotifications(BuildContext context) async {
  const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
  const initSettings = InitializationSettings(android: androidInit);

  await flutterLocalNotificationsPlugin.initialize(
    initSettings,
    onDidReceiveNotificationResponse: (details) {
      final data = jsonDecode(details.payload ?? '{}');
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => RideRequestScreen.fromPayload(data),
        ),
      );
    },
  );

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(rideRequestChannel);
}
