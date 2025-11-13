class BookingDetail {
  final String bookingId;
  final String userId;
  final String riderId;
  final String vehSubTypeId;
  final String mobileNo;
  final String bookDate;
  final String pickupLocation;
  final String dropLocation;
  final String distance;
  final String fareAmount;
  final String finalAmt;
  final String username;
  final String? riderName;
  final String vehSubTypeName;
  final String fromLatLong;
  final String toLatLong;
  final String tripStatus;
  final String otp;

  BookingDetail({
    required this.bookingId,
    required this.userId,
    required this.riderId,
    required this.vehSubTypeId,
    required this.mobileNo,
    required this.bookDate,
    required this.pickupLocation,
    required this.dropLocation,
    required this.distance,
    required this.fareAmount,
    required this.finalAmt,
    required this.username,
    this.riderName,
    required this.vehSubTypeName,
    required this.fromLatLong,
    required this.toLatLong,
    required this.tripStatus,
    required this.otp,
  });

  factory BookingDetail.fromJson(Map<String, dynamic> json) {
    return BookingDetail(
      bookingId: json['Bookingid'] ?? '',
      userId: json['userid'] ?? '',
      riderId: json['Riderid'] ?? '',
      vehSubTypeId: json['VehSubTypeid'] ?? '',
      mobileNo: json['MobileNo'] ?? '',
      bookDate: json['BookDate'] ?? '',
      pickupLocation: json['pickupLocation'] ?? '',
      dropLocation: json['dropLocation'] ?? '',
      distance: json['distance'] ?? '',
      fareAmount: json['fareAmount'] ?? '',
      finalAmt: json['finalamt'] ?? '',
      username: json['username'] ?? '',
      riderName: json['ridername'],
      vehSubTypeName: json['vehsubtypename'] ?? '',
      fromLatLong: json['FromLatLong'] ?? '',
      toLatLong: json['ToLatLong'] ?? '',
      tripStatus: json['TripStatus'] ?? '',
      otp: json['otp'] ?? '',
    );
  }
}
