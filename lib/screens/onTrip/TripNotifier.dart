import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bneeds_taxi_driver/utils/storage.dart';
import '../../models/TripState.dart';
import '../../repositories/accept_booking_repository.dart';
import '../../repositories/vehicle_type_repository.dart';

class TripNotifier extends StateNotifier<TripState> {
  Timer? _timer;

  TripNotifier() : super(TripState()) {
    _init();
  }

  Future<void> _init() async {
    final tripMap = await SharedPrefsHelper.getPickupTripData();
    if (tripMap != null) {
      state = TripState.fromMap(tripMap).copyWith(isLoading: false);
    } else {
      state = state.copyWith(isLoading: false);
    }
  }

  void updateCanStartTrip(bool value) {
    state = state.copyWith(canStartTrip: value);
  }

  void startAutoTrip({int resumeFrom = 0}) {
    state = state.copyWith(
      status: TripStatus.onTrip,
      canCompleteTrip: false,
      elapsedTime: resumeFrom, // use saved value
    );

    _timer?.cancel();
    int elapsed = resumeFrom;

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      elapsed++;
      state = state.copyWith(elapsedTime: elapsed);

      if (elapsed >= 5) {
        timer.cancel();
        state = state.copyWith(canCompleteTrip: true);
      }
    });
  }

  void setDriverCurrentLocation(LatLng loc) {
    state = state.copyWith(driverCurrentLatLng: loc);
    //  _saveTripToPrefs();
  }

  Future<void> completeTrip() async {
    final trip = state;

    // Calculate distance in km
    final distanceMeters = Geolocator.distanceBetween(
      trip.driverCurrentLatLng.latitude,
      trip.driverCurrentLatLng.longitude,
      trip.dropLatLng.latitude,
      trip.dropLatLng.longitude,
    );

    final fareRepo = BookingRepository();
    await fareRepo.calculateFareForBooking(
      riderId: "",
      bookingId: "",
    );
  }

  void completePickup() {
    state = state.copyWith(
      pickupRouteVisible: false,
      dropRouteVisible: true,
      status: TripStatus.onTrip,
    );
  }

  void completeDrop() {
    state = state.copyWith(
      dropRouteVisible: false, // drop route hide
      status: TripStatus.completed, // trip completed
    );
  }

  void setPickupAndDrop(LatLng pickup, LatLng drop) {
    state = state.copyWith(pickupLatLng: pickup, dropLatLng: drop);
  }

  void updateRouteVisibility({bool? pickupVisible, bool? dropVisible}) {
    state = state.copyWith(
      pickupRouteVisible: pickupVisible ?? state.pickupRouteVisible,
      dropRouteVisible: dropVisible ?? state.dropRouteVisible,
    );
  }

  // TripNotifier.dart-ல் உள்ள குறியீடு
  Future<void> reset() async {
    _timer?.cancel();
    state = TripState();
  }

  Future<void> clearId() async {
    await SharedPrefsHelper.clearBookingId();
  }
}

final tripProvider = StateNotifierProvider<TripNotifier, TripState>(
  (ref) => TripNotifier(),
);
