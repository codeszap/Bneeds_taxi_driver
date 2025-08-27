class BookingModel {
  final String userid;
  final String mobileNo;
  final String riderId;
  final String bookDate;
  final String scheduled;
  final String rideDate;
  final String pickupLocation;
  final String dropLocation;
  final String mapLoc;
  final String distance;
  final String fareAmount;
  final String vehSubTypeId;
  final String bookStatus;
  final String paymentMethod;
  final String driverRate;

  BookingModel({
    required this.userid,
    required this.mobileNo,
    required this.riderId,
    required this.bookDate,
    required this.scheduled,
    required this.rideDate,
    required this.pickupLocation,
    required this.dropLocation,
    required this.mapLoc,
    required this.distance,
    required this.fareAmount,
    required this.vehSubTypeId,
    required this.bookStatus,
    required this.paymentMethod,
    required this.driverRate,
  });

  Map<String, dynamic> toMap() {
    return {
      "userid": userid,
      "MobileNo": mobileNo,
      "Riderid": riderId,
      "BookDate": bookDate,
      "Scheduled": scheduled,
      "rideDate": rideDate,
      "pickupLocation": pickupLocation,
      "dropLocation": dropLocation,
      "mapLoc": mapLoc,
      "distance": distance,
      "fareAmount": fareAmount,
      "VehSubTypeid": vehSubTypeId,
      "BookStatus": bookStatus,
      "paymentMethod": paymentMethod,
      "DriverRate": driverRate,
    };
  }
}
