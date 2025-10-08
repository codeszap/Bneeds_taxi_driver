class VehBookingFinal {
  String bookingId;
  String distance;
  String finalamt;
  String fromLatLong;
  String toLatLong;
  String userid;
  String riderId;

  VehBookingFinal({
    required this.bookingId,
    required this.distance,
    required this.finalamt,
    required this.fromLatLong,
    required this.toLatLong,
    required this.userid,
    required this.riderId,
  });

  Map<String, dynamic> toJson() {
    return {
      "Bookingid": bookingId,
      "distance": distance,
      "finalamt": finalamt,
      "FromLatLong": fromLatLong,
      "ToLatLong": toLatLong,
      "userid": userid,
      "Riderid": riderId,
    };
  }
}
