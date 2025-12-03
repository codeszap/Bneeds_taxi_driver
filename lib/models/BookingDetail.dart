class BookingDetail {
  final String bookingId;
  final String userId;
  final String riderId;
  final String vehSubTypeId;
  final String userMobileNo;
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
  final String ridermobileno;
  final String vehno;

  BookingDetail({
    required this.bookingId,
    required this.userId,
    required this.riderId,
    required this.vehSubTypeId,
    required this.userMobileNo,
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
    required this.ridermobileno,
    required this.vehno,
  });

  factory BookingDetail.fromJson(Map<String, dynamic> json) {
    return BookingDetail(
      bookingId: json['bookingid'] ?? '',
      userId: json['userid'] ?? '',
      otp: json['otp'] ?? '',
      riderId: json['riderid'] ?? '',
      riderName: json['ridername'],
      ridermobileno: json['ridermobileno'],
      vehSubTypeId: json['vehsubtypeid'] ?? '',
      userMobileNo: json['usermobileno'] ?? '',
      bookDate: json['bookdate'] ?? '',
      pickupLocation: json['pickuplocation'] ?? '',
      dropLocation: json['droplocation'] ?? '',
      vehno: json['vehno'] ?? '',
      distance: json['distance'] ?? '',
      fareAmount: json['fareAmount'] ?? '',
      finalAmt: json['finalamt'] ?? '',
      username: json['username'] ?? '',
      vehSubTypeName: json['vehsubtypename'] ?? '',
      fromLatLong: json['fromlatlong'] ?? '',
      toLatLong: json['tolatlong'] ?? '',
      tripStatus: json['tripstatus'] ?? '',
    );
  }
}
