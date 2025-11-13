import 'package:bneeds_taxi_driver/models/Api%20Modal/AcceptBookingRequest.dart';
import 'package:bneeds_taxi_driver/providers/params/booking_params.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/BookingDetail.dart';
import '../repositories/accept_booking_repository.dart';
import '../models/ApiResponse.dart';

/// Repository provider
final acceptBookingRepositoryProvider = Provider<BookingRepository>(
  (ref) => BookingRepository(),
);

/// ✅ Accept booking provider (returns a single ApiResponse)
final acceptBookingProvider =
    FutureProvider.family<ApiResponse, BookingRequest>((ref, params) async {
      final repository = ref.read(acceptBookingRepositoryProvider);
      return repository.AcceptBookingStatus(request: params);
    });

/// ✅ Fetch booking details (still returns list)
final fetchBookingDetailProvider =
    FutureProvider.family<List<BookingDetail>, BookingParams>((
      ref,
      params,
    ) async {
      final repository = ref.read(acceptBookingRepositoryProvider);
      return repository.fetchBookingDetail(params.bookingId, params.riderId);
    });

final updateTripStatusProvider =
    FutureProvider.family<ApiResponse, RiderTripUpdateRequest>((
      ref,
      request,
    ) async {
      final repository = ref.read(acceptBookingRepositoryProvider);
      return repository.updateTripStatus(requestBody: request);
    });

final calculateFareProvider =
    FutureProvider.family<Map<String, dynamic>?, FareCalculationParams>((
      ref,
      params,
    ) async {
      final repository = ref.read(acceptBookingRepositoryProvider);
      return repository.calculateFareForBooking(
        bookingId: params.bookingId,
        riderId: params.riderId,
      );
    });

// booking_providers.dart
// ...
final finalBookingProvider =
FutureProvider.family<ApiResponse, FinalBookingParams>((ref, params) async {
  final repository = ref.read(acceptBookingRepositoryProvider);

  // 1. FinalBooking Detail object create panrom (Inner object)
  final FinalBooking finalBookingDetail = FinalBooking(
    bookingId: params.bookingId,
    finalAmt: params.finalAmt,
    driverCurrentLatLong: params.driverCurrentLatLong,
    riderId: params.riderId,
    riderStatus: params.riderStatus,
  );

  // 2. 💡 FIX 3: FinalBookingRequest wrapper-eh create panrom
  final FinalBookingRequest finalRequestWrapper = FinalBookingRequest(
    finalBookingUpdate: [finalBookingDetail], // List-a wrap panrom
  );

  // 3. Repository-kku wrapper-eh anuprom
  return repository.FinalBookingStatus(request: finalRequestWrapper); // 💡 FIX 4: Wrapper-eh pass panrom
});