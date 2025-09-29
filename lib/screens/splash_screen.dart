import 'package:bneeds_taxi_driver/utils/storage.dart';


class DriverSplashScreen extends StatefulWidget {
  const DriverSplashScreen({super.key});

  @override
  State<DriverSplashScreen> createState() => _DriverSplashScreenState();
}

class _DriverSplashScreenState extends State<DriverSplashScreen> {
  @override
  @override
  void initState() {
    super.initState();
    _checkRoute();
    _initFCMToken();
  }

  Future<void> _initFCMToken() async {
    try {
      final fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken != null) {
        await SharedPrefsHelper.setDriverFcmToken(fcmToken);
        debugPrint("✅ FCM Token saved: $fcmToken");
      } else {
        debugPrint("⚠️ Failed to fetch FCM Token");
      }
    } catch (e) {
      debugPrint("❌ Error getting FCM Token: $e");
    }
  }

  Future<void> _checkRoute() async {
    final isProfileComplete = SharedPrefsHelper.getDriverProfileCompleted();


    // Small delay so splash screen shows
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    if (isProfileComplete) {
    context.go(AppRoutes.driverHome);
     // context.go("/trip");
    } else {
   context.go(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.amberAccent,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                Strings.logo,
                width: 180,
                height: 180,
              ),
              const SizedBox(height: 24),
              Text(
                "Get there fast, safe and smart.",
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyText.copyWith(
                  color: AppColors.buttonText,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 40),
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: const LinearProgressIndicator(
                  minHeight: 6,
                  valueColor: AlwaysStoppedAnimation(AppColors.error),
                  backgroundColor: AppColors.background,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
