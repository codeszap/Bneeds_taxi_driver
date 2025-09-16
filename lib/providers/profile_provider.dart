import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_profile_model.dart';
import '../repositories/profile_repository.dart';

final profileRepositoryProvider = Provider((ref) => ProfileRepository());

/// 🔹 Fetch Profile Provider
final fetchProfileProvider =
    FutureProvider.family<List<DriverProfile>, String>((ref, mobileno) {
  final repo = ref.watch(profileRepositoryProvider);
  return repo.getRiderLogin(mobileno: mobileno);
});

/// 🔹 Insert Profile Provider
final insertProfileProvider =
FutureProvider.autoDispose.family<ApiResponse, DriverProfile>((ref, profile) {
  final repo = ref.watch(profileRepositoryProvider);
  return repo.insertUserProfile(profile);
});


/// 🔹 Update Profile Provider
final updateProfileProvider =
FutureProvider.autoDispose.family<ApiResponse, Map<String, String>>((ref, params) {
  final repo = ref.watch(profileRepositoryProvider);
  return repo.updateDriverStatus(
    riderId: params['riderId']!,
    riderStatus: params['riderStatus']!,
    fromLatLong: params['fromLatLong'] ?? "",
  );
});
