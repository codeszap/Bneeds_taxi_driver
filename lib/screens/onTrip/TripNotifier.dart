import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bneeds_taxi_driver/utils/storage.dart';
import '../../models/TripState.dart';
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

  void acceptRide(
      String pickup,
      String drop,
      int fare,
      LatLng pickupLatLng,
      LatLng dropLatLng,
      String otp,
      String bookingId,
      String fcmToken,
      String userId,
      String cusMobile,
      TripStatus status,
      ) {
    state = state.copyWith(
      pickup: pickup,
      drop: drop,
      fare: fare,
      pickupLatLng: pickupLatLng,
      dropLatLng: dropLatLng,
      otp: otp,
      bookingId: bookingId,
      fcmToken: fcmToken,
      userId: userId,
      cusMobile: cusMobile,
      status: status,
    );

    // Save immediately
    SharedPrefsHelper.setTripData({
      'pickup': pickup,
      'drop': drop,
      'fare': fare,
      'pickupLatLng': "${pickupLatLng.latitude},${pickupLatLng.longitude}",
      'dropLatLng': "${dropLatLng.latitude},${dropLatLng.longitude}",
      'otp': otp,
      'bookingId': bookingId,
      'fcmToken': fcmToken,
      'userId': userId,
      'cusMobile': cusMobile,
      'status': status.index,
    });
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
      _saveTripToPrefs(); // save each second

      if (elapsed >= 5) {
        timer.cancel();
        state = state.copyWith(canCompleteTrip: true);
        _saveTripToPrefs();
      }
    });
  }

  void setDriverCurrentLocation(LatLng loc) {
    state = state.copyWith(driverCurrentLatLng: loc);
    _saveTripToPrefs();
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
    final distanceKm = distanceMeters / 1000.0;

    // Get vehicleId from SharedPrefs
    final vehicleId = await SharedPrefsHelper.getDriverVehicleSubTypeId();
    final InitalfareAmount = trip.fare.toDouble();
    // Fetch fare from API
    final fareRepo = VehicleTypeRepository();
    double fareAmount =
        await fareRepo.fetchFare(vehicleId: vehicleId!, totalKm: distanceKm) ??
            (InitalfareAmount); // fallback

    // Update trip state
    state = state.copyWith(
      status: TripStatus.completed,
      fare: fareAmount.toInt(),
    );

    // Push notification
    if (trip.fcmToken.isNotEmpty) {
      await FirebasePushService.sendPushNotification(
        fcmToken: trip.fcmToken,
        title: "Ride Completed ✅",
        body: "Your trip is completed. Fare: ₹${fareAmount.toInt()}",
        data: {
          "bookingId": trip.bookingId,
          "status": "completed_trip",
          "fareAmount": fareAmount.toStringAsFixed(2),
        },
      );
    }
  }
  // TripNotifier class-kku ullae add pannunga

  void completePickup() {
    state = state.copyWith(
      pickupRouteVisible: false,
      dropRouteVisible: true,
      status: TripStatus.onTrip,
    );
    _saveTripToPrefs();
  }

  // Helper to save trip
  Future<void> _saveTripToPrefs() async {
    final tripMap = {
      'pickup': state.pickup,
      'drop': state.drop,
      'fare': state.fare,
      'pickupLat': state.pickupLatLng.latitude,
      'pickupLng': state.pickupLatLng.longitude,
      'dropLat': state.dropLatLng.latitude,
      'dropLng': state.dropLatLng.longitude,
      'status': state.status.index,
      'otp': state.otp,
      'bookingId': state.bookingId,
      'fcmToken': state.fcmToken,
      'userId': state.userId,
      'cusMobile': state.cusMobile,
      'driverLat': state.driverCurrentLatLng?.latitude,
      'driverLng': state.driverCurrentLatLng?.longitude,
      'pickupRouteVisible': state.pickupRouteVisible,
      'dropRouteVisible': state.dropRouteVisible,
      'canStartTrip': state.canStartTrip,
      'cancompleteTrip': state.canCompleteTrip,
      'elapsedTime': state.elapsedTime,
    };

    await SharedPrefsHelper.setPickupTripData(tripMap);
  }

  Future<void> loadTripFromPrefs() async {
    final tripMap = await SharedPrefsHelper.getPickupTripData();
    if (tripMap == null) return; // No saved trip

    state = TripState(
      pickup: tripMap['pickup'] ?? '',
      drop: tripMap['drop'] ?? '',
      fare: tripMap['fare'] ?? 0,
      pickupLatLng: LatLng(
        tripMap['pickupLat'] ?? 0.0,
        tripMap['pickupLng'] ?? 0.0,
      ),
      dropLatLng: LatLng(tripMap['dropLat'] ?? 0.0, tripMap['dropLng'] ?? 0.0),
      status: TripStatus.values[tripMap['status'] ?? 0],
      otp: tripMap['otp'] ?? '',
      bookingId: tripMap['bookingId'] ?? '',
      fcmToken: tripMap['fcmToken'] ?? '',
      userId: tripMap['userId'] ?? '',
      cusMobile: tripMap['cusMobile'] ?? '',
      driverCurrentLatLng:
      (tripMap['driverLat'] != null && tripMap['driverLng'] != null)
          ? LatLng(tripMap['driverLat'], tripMap['driverLng'])
          : LatLng(tripMap['pickupLat'] ?? 0.0, tripMap['pickupLng'] ?? 0.0),
      pickupRouteVisible: tripMap['pickupRouteVisible'] ?? true,
      dropRouteVisible: tripMap['dropRouteVisible'] ?? false,
      canStartTrip: tripMap['canStartTrip'] ?? false,
      canCompleteTrip: tripMap['canCompleteTrip'] ?? false,
      elapsedTime: tripMap['elapsedTime'] ?? 0,
    );

    // Resume trip timer if onTrip
    if (state.status == TripStatus.onTrip) {
      startAutoTrip(resumeFrom: state.elapsedTime);
    }
  }

  void completeDrop() {
    state = state.copyWith(
      dropRouteVisible: false, // drop route hide
      status: TripStatus.completed, // trip completed
    );
  }

  void reset() {
    _timer?.cancel();
    state = TripState();
  }
}

final tripProvider = StateNotifierProvider<TripNotifier, TripState>(
      (ref) => TripNotifier(),
);
