import 'package:bneeds_taxi_driver/utils/storage.dart';
import '../screens/home/riderOverlayScreen.dart';
import '../screens/home/driverHomeScreen.dart';

class AppRoutes {
  // Paths
  static const String decider = '/decider';
  static const String splash = '/splash';
  static const String login = '/login';
  static const String driverHome = '/driverHome';
  static const String tracking = '/tracking';
  static const String wallet = '/wallet';
  static const String customerSupport = '/customer-support';
  static const String driverProfile = '/driverProfile';
  static const String trip = '/trip';
  static const String tripComplete = '/tripComplete';
  static const String demoScreenRoute   = '/Example1';

  // Screens (optional, if you want central reference)
  static Widget deciderScreen() => const RouteDecider();
  static Widget splashScreen() => const DriverSplashScreen();
  static Widget loginScreen() => const DriverLoginScreen();
  static Widget homeScreen() => const DriverHomeScreen();
  static Widget walletScreen() => const WalletScreen();
  static Widget customerSupportScreen() => const CustomerSupportScreen();
  static Widget driverProfileScreen({bool isNewUser = false}) =>
      DriverProfileScreen(isNewUser: isNewUser);
  static Widget tripScreen() => const OnTripScreen();
  static Widget tripCompleteScreen() => const TripCompleteScreen();
  static Widget demoScreenWidget() =>  RiderOverlayScreen();
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();
final GoRouter router = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: AppRoutes.splash,
  routes: [
    GoRoute(
      path: AppRoutes.decider,
      builder: (context, state) => AppRoutes.deciderScreen(),
    ),
    GoRoute(
      path: AppRoutes.splash,
      builder: (context, state) => AppRoutes.splashScreen(),
    ),
    GoRoute(
      path: AppRoutes.login,
      builder: (context, state) => AppRoutes.loginScreen(),
    ),
    GoRoute(
      path: AppRoutes.driverHome,
      builder: (context, state) => AppRoutes.homeScreen(),
    ),
    GoRoute(
      path: AppRoutes.wallet,
      builder: (context, state) => AppRoutes.walletScreen(),
    ),
    GoRoute(
      path: AppRoutes.customerSupport,
      builder: (context, state) => AppRoutes.customerSupportScreen(),
    ),
    GoRoute(
      path: AppRoutes.driverProfile,
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        final isNewUser = extra?['isNewUser'] ?? false;
        return AppRoutes.driverProfileScreen(isNewUser: isNewUser);
      },
    ),
    GoRoute(
      path: AppRoutes.trip,
      builder: (context, state) => AppRoutes.tripScreen(),
    ),
    GoRoute(
      path: AppRoutes.tripComplete,
      builder: (context, state) => AppRoutes.tripCompleteScreen(),
    ),
    GoRoute(
      path: AppRoutes.demoScreenRoute,
      builder: (context, state) => AppRoutes.demoScreenWidget(),
    ),


  ],
);