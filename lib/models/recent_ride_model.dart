class RecentRide {
  final String rideId;
  final String pickupLocation;
  final String dropLocation;
  final String rideDate;
  final double fareAmount;

  RecentRide({
    required this.rideId,
    required this.pickupLocation,
    required this.dropLocation,
    required this.rideDate,
    required this.fareAmount,
  });

  factory RecentRide.fromJson(Map<String, dynamic> json) {
    return RecentRide(
      rideId: json['rideId'] ?? '',
      pickupLocation: json['pickupLocation'] ?? '',
      dropLocation: json['dropLocation'] ?? '',
      rideDate: json['rideDate'] ?? '',
      fareAmount: double.tryParse(json['fareAmount'].toString()) ?? 0.0,
    );
  }
}
