import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/rideRequest.dart';
import '../repositories/profile_repository.dart';
import '../screens/home/customize_home.dart';
import '../screens/home/driver_location_service.dart';


final driverStatusProvider = StateProvider<String>((ref) => "OF");
// Default Offline

final driverRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository();
});


final driverLocationServiceProvider =
Provider<DriverLocationService>((ref) {
  final service = DriverLocationService(ref);

  // Setup initial updater
  final status = ref.read(driverStatusProvider);
  service.setupLocationUpdater(status);

  // Listen to driver status changes
  ref.listen<String>(driverStatusProvider, (previous, next) {
    service.setupLocationUpdater(next);
  });

  ref.onDispose(() => service.dispose());

  return service;
});

final isProfileCompleteProvider = StateProvider<bool>((ref) => true);

// --- Ride Request Provider ---
final rideRequestProvider = StateProvider<RideRequest?>((ref) => null);
