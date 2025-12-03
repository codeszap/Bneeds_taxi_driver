class BookingRequest {
  final String action;
  final String bookingId;
  final String riderId;

  BookingRequest({
    required this.action,
    required this.bookingId,
    required this.riderId,
  });

  Map<String, dynamic> toJson() {
    return {
      'action': action,
      'Bookingid': bookingId,
      'Riderid': riderId,
    };
  }
}

class RiderTripUpdateDetail {
  final String riderId;
  final String bookingId;
  final String tripStatus;
  final String? fromLatLong;
  final String? toLatLong;
  final String timestamp;

  RiderTripUpdateDetail({
    required this.riderId,
    required this.bookingId,
    required this.tripStatus,
    this.fromLatLong,
    this.toLatLong,
  }) : timestamp = DateTime.now().toIso8601String();

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> jsonMap = {
      "Riderid": riderId,
      "Bookingid": bookingId,
      "Tripstatus": tripStatus,
    };
    if (fromLatLong != null) {
      jsonMap["FromLatLong"] = fromLatLong;
    }
    if (toLatLong != null) {
      jsonMap["ToLatLong"] = toLatLong;
    }

    return jsonMap;
  }
}

class RiderTripUpdateRequest {
  final List<RiderTripUpdateDetail> updateTripStatus;

  RiderTripUpdateRequest({
    required this.updateTripStatus,
  });

  Map<String, dynamic> toJson() {
    return {
      "updateTripStatus": updateTripStatus.map((e) => e.toJson()).toList(),
    };
  }
}



class FinalBooking {
  final String bookingId;
  final String finalAmt;
  final String driverCurrentLatLong;
  final String riderId;
  final String riderStatus;


  FinalBooking({
    required this.bookingId,
    required this.finalAmt,
    required this.driverCurrentLatLong,
    required this.riderId,
    required this.riderStatus,
  });

  Map<String, dynamic> toJson() {
    return {
      "bookingId": bookingId,
      "finalAmt": finalAmt,
      "driverCurrentLatLong": driverCurrentLatLong,
      "riderId": riderId,
      "riderStatus": riderStatus,
    };
  }
}

// 💡 New Model: final_booking_request.dart (or similar file)
class FinalBookingRequest {
  final List<FinalBooking> finalBookingUpdate;

FinalBookingRequest({required this.finalBookingUpdate});

  Map<String, dynamic> toJson() {
    return {
      "finalBookingUpdate": finalBookingUpdate.map((e) => e.toJson()).toList(),
    };
  }
}