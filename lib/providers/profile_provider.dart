import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_profile_model.dart';
import '../repositories/profile_repository.dart';

final profileRepositoryProvider = Provider((ref) => ProfileRepository());

/// 🔹 Fetch Profile Provider
final fetchProfileProvider =
    FutureProvider.family<List<UserProfile>, String>((ref, mobileno) {
  final repo = ref.watch(profileRepositoryProvider);
  return repo.fetchUserProfile(mobileno: mobileno);
});

/// 🔹 Insert Profile Provider
final insertProfileProvider =
    FutureProvider.autoDispose.family<String, UserProfile>((ref, profile) {
  final repo = ref.watch(profileRepositoryProvider);
  return repo.insertUserProfile(profile);
});

/// 🔹 Update Profile Provider
final updateProfileProvider =
    FutureProvider.autoDispose.family<String, UserProfile>((ref, profile) {
  final repo = ref.watch(profileRepositoryProvider);
  return repo.updateUserProfile(profile);
});
