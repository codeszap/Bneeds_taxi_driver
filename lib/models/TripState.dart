import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import '../../utils/storage.dart';

import '../../repositories/vehicle_type_repository.dart';

enum TripStatus { idle, accepted, onTrip, completed }

enum TripPhase { waitingPickup, onTrip, completed }

class TripState {
  final String pickup;
  final String drop;
  final int fare;
  final LatLng pickupLatLng;
  final LatLng dropLatLng;
  final TripStatus status;
  final TripPhase phase;
  final int elapsedTime;
  final String otp;
  final String fcmToken;
  final String bookingId;
  final String userId;
  final String cusMobile;
  final bool canStartTrip;
  final bool canCompleteTrip;
  final bool pickupRouteVisible;
  final bool dropRouteVisible;
  final LatLng driverCurrentLatLng;
  final bool isLoading;

  TripState({
    this.pickup = '',
    this.drop = '',
    this.fare = 0,
    this.pickupLatLng = const LatLng(0, 0),
    this.dropLatLng = const LatLng(0, 0),
    this.status = TripStatus.idle,
    this.phase = TripPhase.waitingPickup,
    this.elapsedTime = 0,
    this.otp = '',
    this.fcmToken = '',
    this.bookingId = '',
    this.userId = '',
    this.cusMobile = '',
    this.canStartTrip = false,
    this.canCompleteTrip = false,
    this.pickupRouteVisible = true,
    this.dropRouteVisible = false,
    this.driverCurrentLatLng = const LatLng(0, 0),
    this.isLoading = true,
  });

  TripState copyWith({
    String? pickup,
    String? drop,
    int? fare,
    LatLng? pickupLatLng,
    LatLng? dropLatLng,
    TripStatus? status,
    TripPhase? phase,
    int? elapsedTime,
    bool? canStartTrip,
    bool? canCompleteTrip,
    String? otp,
    String? fcmToken,
    String? bookingId,
    String? userId,
    String? cusMobile,
    LatLng? driverCurrentLatLng,
    bool? pickupRouteVisible,  // ← add
    bool? dropRouteVisible,    // ← add
    bool? isLoading,
  }) {
    return TripState(
      pickup: pickup ?? this.pickup,
      drop: drop ?? this.drop,
      fare: fare ?? this.fare,
      pickupLatLng: pickupLatLng ?? this.pickupLatLng,
      dropLatLng: dropLatLng ?? this.dropLatLng,
      status: status ?? this.status,
      phase: phase ?? this.phase,
      elapsedTime: elapsedTime ?? this.elapsedTime,
      canStartTrip: canStartTrip ?? this.canStartTrip,
      canCompleteTrip: canCompleteTrip ?? this.canCompleteTrip,
      otp: otp ?? this.otp,
      fcmToken: fcmToken ?? this.fcmToken,
      bookingId: bookingId ?? this.bookingId,
      userId: userId ?? this.userId,
      cusMobile: cusMobile ?? this.cusMobile,
      driverCurrentLatLng: driverCurrentLatLng ?? this.driverCurrentLatLng,
      pickupRouteVisible: pickupRouteVisible ?? this.pickupRouteVisible, // ← add
      dropRouteVisible: dropRouteVisible ?? this.dropRouteVisible,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "pickup": pickup,
      "drop": drop,
      "fare": fare,
      "pickupLatLng": "${pickupLatLng.latitude},${pickupLatLng.longitude}",
      "dropLatLng": "${dropLatLng.latitude},${dropLatLng.longitude}",
      "driverCurrentLatLng":
      "${driverCurrentLatLng.latitude},${driverCurrentLatLng.longitude}",
      "status": status.toString(),
      "phase": phase.toString(),
      "elapsedTime": elapsedTime,
      "canStartTrip": canStartTrip,
      "canCompleteTrip": canCompleteTrip,
      "otp": otp,
      "fcmToken": fcmToken,
      "bookingId": bookingId,
      "userId": userId,
      "cusMobile": cusMobile,
    };
  }

  factory TripState.fromMap(Map<String, dynamic> map) {
    LatLng parseLatLng(String value) {
      final parts = value.split(',');
      return LatLng(double.parse(parts[0]), double.parse(parts[1]));
    }

    return TripState(
      pickup: map['pickup'] ?? '',
      drop: map['drop'] ?? '',
      fare: map['fare'] ?? 0,
      pickupLatLng: map['pickupLatLng'] != null
          ? parseLatLng(map['pickupLatLng'])
          : const LatLng(0, 0),
      dropLatLng: map['dropLatLng'] != null
          ? parseLatLng(map['dropLatLng'])
          : const LatLng(0, 0),
      driverCurrentLatLng: map['driverCurrentLatLng'] != null
          ? parseLatLng(map['driverCurrentLatLng'])
          : const LatLng(0, 0),
      status: map['status'] != null
          ? TripStatus.values.firstWhere(
            (e) => e.toString() == map['status'],
        orElse: () => TripStatus.idle,
      )
          : TripStatus.idle,
      phase: map['phase'] != null
          ? TripPhase.values.firstWhere(
            (e) => e.toString() == map['phase'],
        orElse: () => TripPhase.waitingPickup,
      )
          : TripPhase.waitingPickup,
      elapsedTime: map['elapsedTime'] ?? 0,
      canStartTrip: map['canStartTrip'] ?? false,
      canCompleteTrip: map['canCompleteTrip'] ?? false,
      otp: map['otp'] ?? '',
      fcmToken: map['fcmToken'] ?? '',
      bookingId: map['bookingId'] ?? '',
      userId: map['userId'] ?? '',
      cusMobile: map['cusMobile'] ?? '',
    );
  }
}
