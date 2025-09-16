import 'dart:convert';
import 'package:bneeds_taxi_driver/core/api_client.dart';
import 'package:bneeds_taxi_driver/core/api_endpoints.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile_model.dart';
class ApiResponse {
  final String status;
  final String message;
  final dynamic data;

  ApiResponse({required this.status, required this.message, this.data});

  factory ApiResponse.fromJson(Map<String, dynamic> json) {
    return ApiResponse(
      status: json['status'] ?? 'error',
      message: json['message'] ?? '',
      data: json['data'],
    );
  }

  void operator [](String other) {}
}

class ProfileRepository {
  final Dio _dio = ApiClient().dio;

  Future<List<DriverProfile>> getRiderLogin({required String mobileno}) async {
    final url = "frmRiderProfileApi.aspx?action=L&mobileno=$mobileno";

    try {
      final response = await _dio.get(url);

      // முழு response data print பண்ண
      print("Raw response: ${response.data}");

      final data = response.data is String ? jsonDecode(response.data) : response.data;

      // decode ஆனது print பண்ண
      print("Decoded data: $data");

      if (data['status'] == 'success' && data['data'] != null) {
        final riders = List<Map<String, dynamic>>.from(data['data']);
        return riders.map((r) => DriverProfile.fromJson(r)).toList();
      } else {
        return [];
      }
    } on DioException catch (e) {
      print("Error fetching rider login: ${e.response?.data ?? e.message}");
      return [];
    }

  }

  /// Insert driver profile → return success message
  // Future<ApiResponse> insertUserProfile(DriverProfile profile) async {
  //   final url = "frmRiderProfileApi.aspx?action=I";
  //   final body = {"RiderprofileDet": [profile.toJson()]};

  //   try {
  //     final response = await _dio.post(
  //       url,
  //       data: body,
  //       options: Options(headers: {"Content-Type": "application/json"}),
  //     );

  //     final data = response.data is String ? jsonDecode(response.data) : response.data;
  //     return ApiResponse.fromJson(data);
  //   } on DioException catch (e) {
  //     return ApiResponse(
  //       status: "error",
  //       message: e.response?.data.toString() ?? e.message ?? "Unknown error",
  //     );
  //   }
  // }

  Future<ApiResponse> insertUserProfile(DriverProfile profile) async {
  final url = "frmRiderProfileApi.aspx?action=I";
  final body = {"RiderprofileDet": [profile.toJson()]};

  try {
    final response = await _dio.post(
      url,
      data: body,
      options: Options(headers: {"Content-Type": "application/json"}),
    );

    final data = response.data is String ? jsonDecode(response.data) : response.data;

    if (data["status"] == "success" && data["Riderid"] != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString("riderId", data["Riderid"].toString());
      print("✅ RiderId saved: ${data["Riderid"]}");
    }

    return ApiResponse.fromJson(data);
  } on DioException catch (e) {
    return ApiResponse(
      status: "error",
      message: e.response?.data.toString() ?? e.message ?? "Unknown error",
    );
  }
}


Future<ApiResponse> updateDriverStatus({
  required String riderId,
  required String riderStatus,
  required String fromLatLong,
}) async {
  final url = "frmRiderProfileApi.aspx?action=U";

final body = jsonEncode({
  "updateriderpro": [
    {
      "Riderid": riderId,
      "FromLatLong": fromLatLong,
      "riderstatus": riderStatus,
      "timestamp": DateTime.now().toIso8601String(),
    }
  ]
});

  try {
    print("🚀 Calling API: $url");
    print("📦 Body: $body");

    final response = await _dio.post(
      url,
      data: body,
      options: Options(headers: {"Content-Type": "application/json"}),
    );

    print("✅ Raw Response: ${response.data}");

    final data = response.data is String
        ? jsonDecode(response.data)
        : response.data;

    return ApiResponse(
      status: data['status'] ?? 'error',
      message: data['message'] ?? 'Unknown',
    );
  } on DioException catch (e) {
    print("❌ Dio Error: ${e.response?.data ?? e.message}");
    return ApiResponse(
      status: "error",
      message: e.response?.data.toString() ?? e.message ?? "Unknown error",
    );
  }
}

}
