import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bneeds_taxi_driver/utils/storage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initFirebaseMessaging();
  await requestNotificationPermissions();
  await SharedPrefsHelper.init();
  await _initPermissions();

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
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
