import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DriverSplashScreen extends StatefulWidget {
  const DriverSplashScreen({super.key});

  @override
  State<DriverSplashScreen> createState() => _DriverSplashScreenState();
}

class _DriverSplashScreenState extends State<DriverSplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkRoute();
  }

  Future<void> _checkRoute() async {
    final prefs = await SharedPreferences.getInstance();
    final isProfileComplete = prefs.getBool("isDriverProfileCompleted") ?? false;

    // Small delay so splash screen shows
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    if (isProfileComplete) {
      context.go("/driverHome");
     // context.go("/trip");
    } else {
      context.go("/login");
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
              Image.asset('assets/images/logo.png', width: 180, height: 180),
              const SizedBox(height: 24),
              // Text(
              //   "Ram Meter Auto",
              //   style: TextStyle(
              //     fontSize: 32,
              //     fontWeight: FontWeight.bold,
              //     color: Colors.deepPurple.shade700,
              //     letterSpacing: 1.2,
              //   ),
              // ),
              // const SizedBox(height: 12),
              const Text(
                "Get there fast, safe and smart.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
              const SizedBox(height: 40),
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: const LinearProgressIndicator(
                  minHeight: 6,
                  valueColor: AlwaysStoppedAnimation(Colors.red),
                  backgroundColor: Colors.black12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
