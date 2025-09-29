import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../providers/driverStatusProvider.dart';
import '../../utils/sharedPrefrencesHelper.dart';

class DriverLocationService {
  final Ref ref;
  Timer? _locationUpdateTimer;

  DriverLocationService(this.ref);

  void setupLocationUpdater(String status) {
    _locationUpdateTimer?.cancel();

    Duration interval;
    if (status == "RB") {
      interval = const Duration(minutes: 2);
    } else if (status == "OL") {
      interval = const Duration(minutes: 30);
    } else {
      print("🛑 Driver offline → no location updates");
      return;
    }

    _locationUpdateTimer = Timer.periodic(interval, (_) async {
      await _updateDriverLocation(status);
    });
    print("⏱ Location update interval: ${interval.inSeconds}s");
  }

  Future<void> _updateDriverLocation(String status) async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      String fromLatLong = "${position.latitude},${position.longitude}";
      final repo = ref.read(driverRepositoryProvider);
      final riderId = SharedPrefsHelper.getRiderId();

      final response = await repo.updateDriverStatus(
        riderId: riderId,
        riderStatus: status,
        fromLatLong: fromLatLong,
      );

      if (response.status == "success") {
        print("✅ Driver location updated [$status]");
      } else {
        print("❌ Failed to update location: ${response.message}");
      }
    } catch (e) {
      print("⚠️ Error updating location: $e");
    }
  }

  void dispose() {
    _locationUpdateTimer?.cancel();
  }
}
