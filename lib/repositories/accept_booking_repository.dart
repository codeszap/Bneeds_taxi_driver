import 'dart:convert';

import 'package:bneeds_taxi_driver/models/ApiResponse.dart';
import 'package:bneeds_taxi_driver/models/vehicle_subtype_model.dart';
import '../core/api_client.dart';
import '../core/api_endpoints.dart';
import '../models/vehicle_type_model.dart';

// accept_booking_repository.dart
import 'dart:convert';
import '../core/api_client.dart';
import '../core/api_endpoints.dart';
import '../models/ApiResponse.dart';

class AcceptBookingRepository {
  final _client = ApiClient().dio;

Future<List<ApiResponse>> getAcceptBookingStatus(int bookingId, int riderId) async {
  try {
    final response = await _client.get(
      '${ApiEndpoints.acceptBooking}&Bookingid=$bookingId&Riderid=$riderId',
    );

    dynamic resData = response.data;

    if (resData is String) resData = jsonDecode(resData);

    if (resData is Map<String, dynamic>) {
      final status = resData['status'];
      final message = resData['message'];

      print("API Response Status: $status, Message: $message");

      // If success and has data
      if (status == 'success' && resData['data'] is List) {
        final list = resData['data'] as List<dynamic>;
        return list.map((e) => ApiResponse.fromJson(e)).toList();
      }

      // If success but no data, still return a single ApiResponse
      if (status == 'success') {
        return [ApiResponse(status: status, message: message)];
      }

      // If error
      if (status == 'error') {
        return [ApiResponse(status: status, message: message)];
      }
    }

    return [ApiResponse(status: 'error', message: 'Unknown error')];
  } catch (e) {
    return [ApiResponse(status: 'error', message: 'Failed to fetch booking status: $e')];
  }
}
Future<List<ApiResponse>> getCompleteBookingStatus(int bookingId, int totalKms) async {
  try {
    final response = await _client.get(
      '${ApiEndpoints.completeBooking}&Bookingid=$bookingId&distance=$totalKms',
    );

    dynamic resData = response.data;

    if (resData is String) resData = jsonDecode(resData);

    if (resData is Map<String, dynamic>) {
      final status = resData['status'];
      final message = resData['message'];

      print("Complete API Response Status: $status, Message: $message");

      if (status == 'success' && resData['data'] is List) {
        final list = resData['data'] as List<dynamic>;
        return list.map((e) => ApiResponse.fromJson(e)).toList();
      }

      if (status == 'success') {
        return [ApiResponse(status: status, message: message)];
      }

      if (status == 'error') {
        return [ApiResponse(status: status, message: message)];
      }
    }

    return [ApiResponse(status: 'error', message: 'Unknown error')];
  } catch (e) {
    return [ApiResponse(status: 'error', message: 'Failed to fetch complete booking status: $e')];
  }
}

}
