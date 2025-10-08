import '../models/rideRequest.dart';
import '../theme/app_colors.dart';
import 'home/driverHomeScreen.dart';
import 'package:flutter/material.dart';
class RideRequestScreen extends StatelessWidget {
  final RideRequest rideRequest;

  const RideRequestScreen({super.key, required this.rideRequest});

  factory RideRequestScreen.fromPayload(Map<String, dynamic> payload) {
    return RideRequestScreen(
      rideRequest: RideRequest(
        pickup: payload['pickup'],
        drop: payload['drop'],
        fare: int.parse(payload['fare']),
        bookingId: int.parse(payload['bookingId']),
        pickuplatlong: payload['pickuplatlong'],
        droplatlong: payload['droplatlong'],
        cusMobile: payload['cusMobile'],
        userId: payload['userId'],
        fcmToken: payload['fcmToken'],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Same card UI as your foreground RideRequestCard
    return Scaffold(
      backgroundColor: Colors.black54,
      body: Center(
        child: RideRequestCards(rideRequest: rideRequest),
      ),
    );
  }
}


class RideRequestCards extends StatelessWidget {
  final RideRequest rideRequest;

  const RideRequestCards({super.key, required this.rideRequest});

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.buttonText,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Pickup: ${rideRequest.pickup}",
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              "Drop: ${rideRequest.drop}",
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              "Fare: ₹${rideRequest.fare}",
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green),
                  onPressed: () {
                    // Accept ride logic
                    print("Ride Accepted ✅");
                    // Stop ringtone if playing
                    // Navigate to trip screen
                  },
                  child: const Text("Accept"),
                ),
                ElevatedButton(
                  style:
                  ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: () {
                    // Reject ride logic
                    print("Ride Rejected ❌");
                    // Close card
                    Navigator.pop(context);
                  },
                  child: const Text("Reject"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

