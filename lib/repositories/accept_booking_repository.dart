import 'dart:convert';
import '../core/api_client.dart';
import '../core/api_endpoints.dart';
import '../models/Api Modal/AcceptBookingRequest.dart';
import '../models/BookingDetail.dart';
import '../models/ApiResponse.dart';
import '../utils/storage.dart' hide ApiResponse;

class BookingRepository {
  final _client = ApiClient().dio;

  Future<ApiResponse> AcceptBookingStatus({
    required BookingRequest request,
  }) async {
    try {
      final response = await _client.post(
        '${ApiEndpoints.acceptBooking}',
        data: request.toJson(),
      );

      dynamic resData = response.data;
      if (resData is String) resData = jsonDecode(resData);

      print("🔹 Raw API Response: $resData");

      if (resData is Map<String, dynamic>) {
        final status = resData['status']?.toString() ?? 'error';
        final message = resData['message']?.toString() ?? 'Unknown error';

        print("✅ API Response Status: $status | Message: $message");

        return ApiResponse(status: status, message: message);
      }

      return ApiResponse(status: 'error', message: 'Invalid response format');
    } catch (e) {
      print('❌ AcceptBookingStatus Error: $e');
      return ApiResponse(
        status: 'error',
        message: 'Failed to fetch booking status: $e',
      );
    }
  }

  Future<List<BookingDetail>> fetchBookingDetail(
    int bookingId,
    int riderId,
  ) async {
    try {
      final response = await _client.get(
        '${ApiEndpoints.getBookingStatus}&Bookingid=$bookingId&Riderid=$riderId',
      );

      dynamic resData = response.data;
      if (resData is String) resData = jsonDecode(resData);

      if (resData is Map<String, dynamic>) {
        if (resData['status'] == 'success' && resData['data'] is List) {
          final list = resData['data'] as List<dynamic>;
          return list.map((e) => BookingDetail.fromJson(e)).toList();
        }
      }

      return [];
    } catch (e) {
      print('❌ Error fetching booking details: $e');
      return [];
    }
  }

  Future<ApiResponse> updateTripStatus({
    required RiderTripUpdateRequest requestBody,
  }) async {
    final Map<String, dynamic> bodyMap = requestBody.toJson();

    try {
      print("📦 Body: $bodyMap");

      final response = await _client.post(
        ApiEndpoints.updatBookingStatus,
        data: bodyMap,
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
  Future<Map<String, dynamic>?> calculateFareForBooking({
    required String bookingId,
    required String riderId,
  }) async {
    try {
      final requestBody = {
        "RiderId": riderId,
        "Bookingid": bookingId,
      };

      final response = await _client.post(
        ApiEndpoints.getCalculateFare,
        queryParameters: {'action': 'A'},
        data: requestBody,
      );

      dynamic resData = response.data;

      if (resData is String) {
        resData = jsonDecode(resData);
      }
      if (resData is Map && resData['status'] == 'success') {
        final data = resData['data'];

        if (data is Map) {
          return data as Map<String, dynamic>;
        }
      }
      return null;
    } on DioException catch (e) {
      print(
        'Dio Error calculating fare: ${e.response?.statusCode} - ${e.message}',
      );
      return null;
    } catch (e) {
      // General error handling
      print('Error calculating fare for Booking $bookingId: $e');
      return null;
    }
  }

  Future<ApiResponse> FinalBookingStatus({
    required FinalBookingRequest request,
  }) async {
    try {
      final response = await _client.post(
        '${ApiEndpoints.finalBooking}',
        data: request.toJson(),
      );

      dynamic resData = response.data;
      if (resData is String) resData = jsonDecode(resData);

      print("🔹 Raw API Response: $resData");

      if (resData is Map<String, dynamic>) {
        final status = resData['status']?.toString() ?? 'error';
        final message = resData['message']?.toString() ?? 'Unknown error';

        print("✅ API Response Status: $status | Message: $message");

        return ApiResponse(status: status, message: message);
      }

      return ApiResponse(status: 'error', message: 'Invalid response format');
    } catch (e) {
      print('❌ AcceptBookingStatus Error: $e');
      return ApiResponse(
        status: 'error',
        message: 'Failed to fetch booking status: $e',
      );
    }
  }
}
