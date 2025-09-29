
import 'package:bneeds_taxi_driver/utils/storage.dart';


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
    final isProfileComplete = SharedPrefsHelper.getDriverProfileCompleted();

    if (!mounted) return;

    if (isProfileComplete) {
      context.go(AppRoutes.driverHome);
    } else {
      context.go(AppRoutes.driverProfile);
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
