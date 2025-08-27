// import 'package:firebase_core/firebase_core.dart';
import 'package:bneeds_taxi_driver/services/firebase_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'config/routes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initFirebaseMessaging();
  await requestNotificationPermissions();
  runApp(ProviderScope(child: MyApp()));
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
Widget build(BuildContext context) {
  return MaterialApp.router(
    routerConfig: router,
    title: 'GoRouter Demo',
    theme: ThemeData(
      scaffoldBackgroundColor: Colors.white,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      primaryColor: Colors.white,
      colorScheme: ColorScheme.fromSwatch().copyWith(
        primary: Colors.black,
        secondary: Colors.blue, 
      ),
    ),
  );
}
}

