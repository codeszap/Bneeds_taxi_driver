import 'dart:convert';

import 'package:bneeds_taxi_driver/models/vehicle_subtype_model.dart';
import '../core/api_client.dart';
import '../core/api_endpoints.dart';
import '../models/vehicle_type_model.dart';

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
  final response = await _client.get('${ApiEndpoints.getVehicleSubType}&VehTypeid=$vehTypeId');

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

  Future<double?> fetchFare({required String vehicleId, required double totalKm}) async {
    try {
      final response = await _client.get(
        'https://www.bneedsbill.com/ramauto/Api/frmVehTariffApi.aspx',
        queryParameters: {
          'action': 'D',
          'Totalkm': totalKm.toStringAsFixed(2),
        },
      );

      dynamic resData = response.data;

      // Decode if JSON string
      if (resData is String) {
        resData = jsonDecode(resData);
      }

      if (resData is Map && resData['status'] == 'success' && resData['data'] is List) {
        final list = resData['data'] as List;

        // Find matching vehicle ID
        final vehicleData = list.firstWhere(
              (e) => e['VehSubTypeid'].toString() == vehicleId,
          orElse: () => null,
        );

        if (vehicleData != null && vehicleData['Totalkm'] != null && vehicleData['Totalkm'] != "") {
          return double.parse(vehicleData['Totalkm'].toString());
        }
      }

      return null; // if no match or API issue
    } catch (e) {
      print('Error fetching fare: $e');
      return null;
    }
  }
}
