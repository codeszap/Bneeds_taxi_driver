import 'package:bneeds_taxi_driver/config/RouteDecider.dart';
import 'package:bneeds_taxi_driver/screens/CustomerSupportScreen.dart';
import 'package:bneeds_taxi_driver/screens/DriverSearchingScreen.dart';
import 'package:bneeds_taxi_driver/screens/MyRidesScreen.dart';
import 'package:bneeds_taxi_driver/screens/OnTripScreen.dart';
import 'package:bneeds_taxi_driver/screens/ProfileScreen.dart';
import 'package:bneeds_taxi_driver/screens/RideCompleteScreen.dart';
import 'package:bneeds_taxi_driver/screens/RideOnTripScreen.dart';
import 'package:bneeds_taxi_driver/screens/SelectLocationScreen.dart';
import 'package:bneeds_taxi_driver/screens/SelectOnMapScreen.dart';
import 'package:bneeds_taxi_driver/screens/ServiceOptionsScreen.dart';
import 'package:bneeds_taxi_driver/screens/TrackingScreen.dart';
import 'package:bneeds_taxi_driver/screens/WalletScreen.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import '../screens/home/customize_home.dart';
import '../screens/login/login_screen.dart';
import '../screens/splash_screen.dart';
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

final GoRouter router = GoRouter(
   navigatorKey: navigatorKey,
  initialLocation: '/splash',
  routes: [
    GoRoute(
      path: '/decider',
      builder: (context, state) => const RouteDecider(),
    ),
    GoRoute(path: '/', builder: (context, state) => const DriverSplashScreen()),
    GoRoute(
      path: '/splash',
      builder: (context, state) => const DriverSplashScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const DriverLoginScreen(),
    ),
    //  GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
    GoRoute(
      path: '/driverHome',
      builder: (context, state) => const DriverHomeScreen(),
    ),
    GoRoute(
      path: '/select-location',
      builder: (context, state) {
        final vehTypeId = state.extra as String;
        return SelectLocationScreen(vehTypeId: vehTypeId);
      },
    ),

    // GoRoute(
    //   path: '/service-options',
    //   builder: (context, state) {
    //     final extra = state.extra;
    //     if (extra is! Map<String, dynamic>) {
    //       throw Exception('Expected a Map<String, dynamic> in state.extra');
    //     }

    //     final vehTypeId = extra['vehTypeId'] as String;
    //     final totalKms = extra['totalKms'].toString(); // ensure string
    //     final estTime = extra['estTime'].toString();

    //     return ServiceOptionsScreen(
    //       vehTypeId: vehTypeId,
    //       totalKms: totalKms,
    //       estTime: estTime,
    //     );
    //   },
    // ),

    GoRoute(
      path: '/searching',
      builder: (context, state) => const DriverSearchingScreen(),
    ),
    GoRoute(
      path: '/tracking',
      builder: (context, state) => const TrackingScreen(),
    ),
    GoRoute(path: '/wallet', builder: (context, state) => const WalletScreen()),
    GoRoute(
      path: '/select-on-map',
      builder: (context, state) => const SelectOnMapScreen(),
    ),
    GoRoute(
      path: '/ride-on-trip',
      builder: (context, state) => const RideOnTripScreen(),
    ),
    GoRoute(
      path: '/ride-complete',
      builder: (context, state) => const RideCompleteScreen(),
    ),
    GoRoute(
      path: '/customer-support',
      builder: (context, state) => const CustomerSupportScreen(),
    ),
    GoRoute(
      path: '/my-rides',
      builder: (context, state) => const MyRidesScreen(),
    ),
    GoRoute(
      path: '/driverProfile',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?; // 👈 check extra
        final isNewUser = extra?['isNewUser'] ?? false; // 👈 default false
        return DriverProfileScreen(isNewUser: isNewUser); // 👈 pass flag
      },
    ),
    GoRoute(path: '/trip', builder: (context, state) => const OnTripScreen()),
  ],
);
