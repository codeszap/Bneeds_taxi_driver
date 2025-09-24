import 'package:bneeds_taxi_driver/providers/profile_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/profile_repository.dart';
import '../models/user_profile_model.dart';


final userProfileProvider =
FutureProvider.family<List<DriverProfile>, String>((ref, mobileno) {
  final repo = ref.watch(profileRepositoryProvider);
  return repo.getRiderLogin(mobileno: mobileno);
});