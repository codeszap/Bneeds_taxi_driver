import 'package:bneeds_taxi_driver/utils/storage.dart';

    /// 🔥 Local notifications plugin
    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

    /// 🔥 Android channel
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel', // id
      'High Importance Notifications', // title
      description: 'This channel is used for important notifications.',
      importance: Importance.high,
    );

    /// 🔥 Background message handler
    Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
      await Firebase.initializeApp();

      final data = message.data;
      final rideRequest = {
        "pickup": data['pickup'],
        "drop": data['drop'],
        "fare": data['fare'],
        "bookingId": data['bookingId'],
        "pickuplatlong": data['pickuplatlong'],
        "droplatlong": data['droplatlong'],
        "cusMobile": data['userMobNo'],
        "userId": data['userId'],
        "fcmToken": data['token'],
      };

      const channelId = 'ride_request_channel';

      final androidDetails = AndroidNotificationDetails(
        channelId,
        'Ride Requests',
        channelDescription: 'Incoming ride requests',
        importance: Importance.max,
        priority: Priority.high,
        fullScreenIntent: true,  // 🔑 triggers full-screen popup
      );

      final platformDetails = NotificationDetails(android: androidDetails);

      await flutterLocalNotificationsPlugin.show(
        int.parse(rideRequest['bookingId']),
        'New Ride Request',
        '${rideRequest['pickup']} → ${rideRequest['drop']}',
        platformDetails,
        payload: jsonEncode(rideRequest),
      );
    }


    /// Call this in main()
    Future<void> initFirebaseMessaging() async {
      await Firebase.initializeApp();

      // Local notifications init
      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const initSettings = InitializationSettings(android: androidInit);
      await flutterLocalNotificationsPlugin.initialize(initSettings);

      // Android channel create
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);

      // Background handler
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);


      // iOS presentation options
      await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // Foreground listener
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print("📩 Foreground: ${message.notification?.title}");

        final notification = message.notification;
        final android = notification?.android;
        if (notification != null && android != null) {
          flutterLocalNotificationsPlugin.show(
            notification.hashCode,
            notification.title,
            notification.body,
            NotificationDetails(
              android: AndroidNotificationDetails(
                channel.id,
                channel.name,
                channelDescription: channel.description,
                importance: Importance.high,
                priority: Priority.high,
                icon: '@mipmap/ic_launcher',
              ),
            ),
          );
        }
      });

      // When app opened from terminated state
      FirebaseMessaging.instance.getInitialMessage().then((message) {
        // if (message != null) {
        //   print("🚀 App opened from terminated: ${message.data}");
        //
        //   // Optionally restore ride request from data
        //   ref.read(rideRequestProvider.notifier).state = RideRequest(
        //     pickup: message.data['pickup'] ?? '',
        //     drop: message.data['drop'] ?? '',
        //     fare: int.tryParse(message.data['fare'] ?? '0') ?? 0,
        //     bookingId: int.tryParse(message.data['bookingId'] ?? '0') ?? 0,
        //     fcmToken: message.data['token'] ?? '',
        //     pickuplatlong: message.data['pickuplatlong'] ?? '',
        //     droplatlong: message.data['droplatlong'] ?? '',
        //     cusMobile: message.data['userMobNo'] ?? '',
        //     userId: message.data['userId'] ?? '',
        //   );
        // }
      });


      // When tapped on notification (background)
      FirebaseMessaging.onMessageOpenedApp.listen((message) {
        print("👉 Opened from background: ${message.data}");
      });
    }

    /// Ask runtime notification permission (Android 13+ / iOS)
    Future<void> requestNotificationPermissions() async {
      NotificationSettings settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      print("🔑 Permission: ${settings.authorizationStatus}");
    }
