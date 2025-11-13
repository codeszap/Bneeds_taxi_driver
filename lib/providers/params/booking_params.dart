// 💡 IMPORTANT: Unga 'booking_params.dart' file-la idhu maadhiri irukkanum

class BookingParams {
  // Named Parameters use panna, idhukku curly braces {} thevai
  const BookingParams({
    required this.bookingId, // 'required' keyword must be used
    required this.riderId,
  });

  final int bookingId;
  final int riderId;
}

class FareCalculationParams {
  final String bookingId;
  final String riderId;
  final String CurrentLatlong;

  FareCalculationParams({
    required this.bookingId,
    required this.riderId,
    required this.CurrentLatlong,
  });
}

class FinalBookingParams {
  final String bookingId;
  final String finalAmt;
  final String driverCurrentLatLong;
  final String riderId;
  final String riderStatus;


  FinalBookingParams({
    required this.bookingId,
    required this.finalAmt,
    required this.driverCurrentLatLong,
    required this.riderId,
    required this.riderStatus,
  });
}