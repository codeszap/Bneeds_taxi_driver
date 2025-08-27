import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/recent_ride_model.dart';

// final recentRidesRepositoryProvider = Provider<RecentRidesRepository>((ref) {
//   return RecentRidesRepository();
// });

// final recentRidesProvider = FutureProvider.family<List<RecentRide>, String>((ref, userId) async {
//   final repo = ref.read(recentRidesRepositoryProvider);
//   return repo.fetchRecentRides(userId);
// });



final recentRidesProvider = FutureProvider.family<List<RecentRide>, String>((ref, userId) async {
  // Temporary manual data for testing
  await Future.delayed(const Duration(milliseconds: 500)); 
  return [
    RecentRide(
      rideId: "RIDE1234",
      pickupLocation: "Chennai Central",
      dropLocation: "T Nagar",
      rideDate: "2025-08-06 02:40 PM",
      fareAmount: 184.50,
    ),
    RecentRide(
      rideId: "RIDE1235",
      pickupLocation: "Simmakkal",
      dropLocation: "Periyar Bus Stand",
      rideDate: "2025-08-01 04:10 PM",
      fareAmount: 120.0,
    ),
    RecentRide(
      rideId: "RIDE1236",
      pickupLocation: "Madurai Airport",
      dropLocation: "Anna Nagar",
      rideDate: "2025-07-25 06:00 PM",
      fareAmount: 132.0,
    ),
  ];
});
