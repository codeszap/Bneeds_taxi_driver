import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/booking_model.dart';
import '../repositories/booking_repository.dart';

/// Repository provider
final bookingRepositoryProvider = Provider<BookingRepository>((ref) {
  return BookingRepository();
});

/// State provider for bookings
final bookingListProvider =
    StateNotifierProvider<BookingNotifier, List<BookingModel>>((ref) {
  final repo = ref.watch(bookingRepositoryProvider);
  return BookingNotifier(repo);
});

class BookingNotifier extends StateNotifier<List<BookingModel>> {
  final BookingRepository repository;

  BookingNotifier(this.repository) : super([]);

  /// Add booking and keep it in state
  Future<void> addBooking(BookingModel booking) async {
    await repository.addBooking(booking);

    // since no fetch API, just append to state
    state = [...state, booking];
  }
}
