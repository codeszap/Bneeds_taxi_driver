import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/vehicle_type_model.dart';
import 'vehicle_repository_provider.dart';

final vehicleTypesProvider = FutureProvider<List<VehicleTypeModel>>((ref) {
  return ref.read(vehicleRepositoryProvider).fetchVehicleTypes();
});
