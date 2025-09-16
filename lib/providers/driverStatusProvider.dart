import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/profile_repository.dart';


final driverStatusProvider = StateProvider<String>((ref) => "OF");
// Default Offline

final driverRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository();
});
