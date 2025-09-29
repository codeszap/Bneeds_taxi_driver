
class RideRequest {
  final String pickup;
  final String drop;
  final int fare;
  final int bookingId;
  final String fcmToken;
  final String pickuplatlong;
  final String droplatlong;
  final String cusMobile;
  final String userId;

  RideRequest({
    required this.pickup,
    required this.drop,
    required this.fare,
    required this.bookingId,
    required this.fcmToken,
    required this.pickuplatlong,
    required this.droplatlong,
    required this.cusMobile,
    required this.userId,
  });

  Map<String, dynamic> toJson() => {
    'pickup': pickup,
    'drop': drop,
    'fare': fare,
    'bookingId': bookingId,
    'pickuplatlong': pickuplatlong,
    'droplatlong': droplatlong,
    'cusMobile': cusMobile,
    'userId': userId,
    'fcmToken': fcmToken,
  };

  factory RideRequest.fromJson(Map<String, dynamic> json) => RideRequest(
    pickup: json['pickup'],
    drop: json['drop'],
    fare: json['fare'],
    bookingId: json['bookingId'],
    pickuplatlong: json['pickuplatlong'],
    droplatlong: json['droplatlong'],
    cusMobile: json['cusMobile'],
    userId: json['userId'],
    fcmToken: json['fcmToken'],
  );

}