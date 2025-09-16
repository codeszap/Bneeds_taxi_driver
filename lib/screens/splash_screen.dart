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
    } else {
      context.go("/login");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // <-- set white background
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/images/logo.png', width: 150, height: 150),
              const SizedBox(height: 20),
              const Text(
                "Bneeds Taxi Driver",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.black, // <-- change to black
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "Drive safe, smart & fast",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey, // <-- dark grey for contrast
                ),
              ),
              const SizedBox(height: 40),
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(Colors.green), // better on white
              ),
            ],
          ),
        ),
      ),
    );
  }
}
