import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/profile_repository.dart';
import '../models/user_profile_model.dart';

final userProfileProvider =
    FutureProvider.family<List<UserProfile>, Map<String, String>>((ref, creds) {
  final repo = ProfileRepository();
  return repo.fetchUserProfile(
    mobileno: creds['mobileno']!,
  );
});
