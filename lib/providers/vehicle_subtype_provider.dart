import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/vehicle_subtype_model.dart';
import 'vehicle_repository_provider.dart';

class VehicleSubTypeParams {
  final String vehTypeId;
  final String totalKms;

  VehicleSubTypeParams(this.vehTypeId, this.totalKms);
}


final vehicleSubTypeProvider =
    FutureProvider.family<List<VehicleSubType>, (String, String)>((ref, params) async {
  final (vehTypeId, totalKms) = params;
  return ref.read(vehicleRepositoryProvider)
      .fetchVehicleSubTypes(vehTypeId, totalKms);
});
