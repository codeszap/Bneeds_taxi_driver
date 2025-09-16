// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import '../models/booking_model.dart';
// import '../repositories/booking_repository.dart';

// /// Repository provider
// final bookingRepositoryProvider = Provider<BookingRepository>((ref) {
//   return BookingRepository();
// });

// /// State provider for bookings
// final bookingListProvider =
//     StateNotifierProvider<BookingNotifier, List<BookingModel>>((ref) {
//   final repo = ref.watch(bookingRepositoryProvider);
//   return BookingNotifier(repo);
// });

// class BookingNotifier extends StateNotifier<List<BookingModel>> {
//   final BookingRepository repository;

//   BookingNotifier(this.repository) : super([]);


//   Future<void> addBooking(BookingModel booking) async {
//     await repository.addBooking(booking);

//     // since no fetch API, just append to state
//     state = [...state, booking];
//   }
// }


// booking_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/accept_booking_repository.dart';
import '../models/ApiResponse.dart';

// Repository provider
final acceptBookingRepositoryProvider = Provider<AcceptBookingRepository>(
  (ref) => AcceptBookingRepository(),
);

// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import '../models/booking_model.dart';
// import '../repositories/booking_repository.dart';

// /// Repository provider
// final bookingRepositoryProvider = Provider<BookingRepository>((ref) {
//   return BookingRepository();
// });

// /// State provider for bookings
// final bookingListProvider =
//     StateNotifierProvider<BookingNotifier, List<BookingModel>>((ref) {
//   final repo = ref.watch(bookingRepositoryProvider);
//   return BookingNotifier(repo);
// });

// class BookingNotifier extends StateNotifier<List<BookingModel>> {
//   final BookingRepository repository;

//   BookingNotifier(this.repository) : super([]);


//   Future<void> addBooking(BookingModel booking) async {
//     await repository.addBooking(booking);

//     // since no fetch API, just append to state
//     state = [...state, booking];
//   }


class BookingParams {
  final int bookingId;
  final int riderId;

  BookingParams(this.bookingId, this.riderId);
}
class CompleteBookingParams {
  final int bookingId;
  final int distanceKms;

  CompleteBookingParams(this.bookingId, this.distanceKms);
}

// Provider for accept booking
final acceptBookingProvider =
    FutureProvider.family<List<ApiResponse>, BookingParams>((ref, params) {
  final repository = ref.read(acceptBookingRepositoryProvider);
  return repository.getAcceptBookingStatus(params.bookingId, params.riderId);
});

// Provider for complete booking
final completeBookingProvider =
    FutureProvider.family<List<ApiResponse>, CompleteBookingParams>((ref, params) {
  final repository = ref.read(acceptBookingRepositoryProvider);
  return repository.getCompleteBookingStatus(params.bookingId, params.distanceKms);
});
