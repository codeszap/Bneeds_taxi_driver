import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/vehicle_type_repository.dart';

final vehicleRepositoryProvider = Provider<VehicleTypeRepository>((ref) {
  return VehicleTypeRepository();
});
