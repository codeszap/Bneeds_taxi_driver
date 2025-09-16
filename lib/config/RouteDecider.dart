import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RouteDecider extends StatefulWidget {
  const RouteDecider({super.key});

  @override
  State<RouteDecider> createState() => _RouteDeciderState();
}

class _RouteDeciderState extends State<RouteDecider> {
  @override
  void initState() {
    super.initState();
    _checkRoute();
  }

  Future<void> _checkRoute() async {
    final prefs = await SharedPreferences.getInstance();

    final isProfileComplete = prefs.getBool("isDriverProfileCompleted") ?? false;

    if (!mounted) return;

    if (isProfileComplete) {
      context.go("/driverHome");
    } else {
      context.go("/driverProfile");
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
