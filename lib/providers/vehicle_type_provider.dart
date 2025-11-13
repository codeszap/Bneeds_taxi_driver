import 'package:bneeds_taxi_driver/providers/params/vehicle_params.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/vehicle_type_model.dart';
import '../models/vehicle_subtype_model.dart';
import 'vehicle_repository_provider.dart';

final vehicleTypesProvider = FutureProvider<List<VehicleTypeModel>>((ref) {
  return ref.read(vehicleRepositoryProvider).fetchVehicleTypes();
});

final fetchVehicleSubTypesProvider =
FutureProvider.family<List<VehicleSubType>, VehicleSubTypeParams>((
    ref,
    params,
    ) async {
  final repository = ref.read(vehicleRepositoryProvider);

  return repository.fetchVehicleSubTypes(params.vehTypeId);
});



