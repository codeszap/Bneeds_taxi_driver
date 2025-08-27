import 'package:bneeds_taxi_driver/core/api_client.dart';
import 'package:bneeds_taxi_driver/core/api_endpoints.dart';
import 'package:bneeds_taxi_driver/models/booking_model.dart';
import 'package:dio/dio.dart';

class BookingRepository {
  final Dio _dio = ApiClient().dio;

  Future<void> addBooking(BookingModel booking) async {
    try {
      final payload = {
        "vehbookingDet": [booking.toMap()]
      };

      final response = await _dio.post(
        "${ApiEndpoints.bookingRide}?action=I",
        data: payload,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print("Booking saved successfully");
      } else {
        throw Exception("Failed to save booking");
      }
    } catch (e) {
      print("Error saving booking: $e");
      rethrow;
    }
  }
}
