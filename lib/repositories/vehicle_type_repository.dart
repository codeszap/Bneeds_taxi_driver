import 'dart:convert';

import 'package:bneeds_taxi_driver/models/vehicle_subtype_model.dart';
import '../core/api_client.dart';
import '../core/api_endpoints.dart';
import '../models/vehicle_type_model.dart';
import '../utils/storage.dart';

class VehicleTypeRepository {
  final _client = ApiClient().dio;

  Future<List<VehicleTypeModel>> fetchVehicleTypes() async {
    final response = await _client.get(ApiEndpoints.getVehicleType);

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

  Future<List<VehicleSubType>> fetchVehicleSubTypes(int vehTypeId) async {
    final response = await _client.get(
      '${ApiEndpoints.getVehicleSubType}&VehTypeid=$vehTypeId',
    );

    dynamic resData = response.data;

    // If API returns a JSON string, decode it
    if (resData is String) {
      resData = jsonDecode(resData);
    }

    // Check if valid map and status is success
    if (resData is Map && resData['status'] == 'success') {
      if (resData['data'] is List) {
        final list = resData['data'] as List;
        return list.map((e) => VehicleSubType.fromJson(e)).toList();
      }
    }

    // If status not success or data not list, return empty list
    return [];
  }


}
