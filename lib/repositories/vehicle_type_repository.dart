import 'dart:convert';

import 'package:bneeds_taxi_driver/models/vehicle_subtype_model.dart';
import '../core/api_client.dart';
import '../core/api_endpoints.dart';
import '../models/vehicle_type_model.dart';

class VehicleTypeRepository {
  final _client = ApiClient().dio;

Future<List<VehicleTypeModel>> fetchVehicleTypes() async {
  final response = await _client.get(ApiEndpoints.vehicleType);

  dynamic resData = response.data;

  // If API returns a JSON string, decode it
  if (resData is String) {
    resData = jsonDecode(resData);
  }

  // Check if valid map and status is success
  if (resData is Map && resData['status'] == 'success') {
    if (resData['data'] is List) {
      final list = resData['data'] as List;
      return list.map((e) => VehicleTypeModel.fromJson(e)).toList();
    }
  }

  // If status not success or data not list, return empty list
  return [];
}


Future<List<VehicleSubType>> fetchVehicleSubTypes(String vehTypeId, String totalKms) async {
  final res = await _client.get(
    ApiEndpoints.vehicleSubType,
    queryParameters: {'action': 'D', 'VehTypeid': vehTypeId, 'TotalKms': totalKms},
  );

  dynamic data = res.data;
  if (data is String) {
    data = jsonDecode(data);
  }

  // Check for status first
  if (data is Map && data['status'] == 'success') {
    final list = data['data'];
    if (list is List) {
      return list.map((e) => VehicleSubType.fromJson(e)).toList();
    }
  }

  // If status != success or format invalid, return empty list
  return [];
}

}
