  import 'package:flutter_riverpod/flutter_riverpod.dart';
  import 'package:bneeds_taxi_driver/utils/storage.dart';

  import '../../../models/rideRequest.dart';
  import '../../../utils/dialogs.dart';

  import 'package:flutter/material.dart';


  class RideRequestCard extends ConsumerWidget {
    final RideRequest rideRequest;
    final AudioPlayer audioPlayer;

    const RideRequestCard({
      super.key,
      required this.rideRequest,
      required this.audioPlayer,
    });

    String generateOtp() {
      final random = Random();
      int otp = 1000 + random.nextInt(9000);
      return otp.toString();
    }

    LatLng parseLatLng(String latLongStr) {
      // Customer is sending "lat,lng" format
      final parts = latLongStr.split(',');
      if (parts.length != 2) {
        throw FormatException("Invalid LatLong format: $latLongStr");
      }
      final lat = double.parse(parts[0]);
      final lng = double.parse(parts[1]);
      return LatLng(lat, lng);
    }


    @override
    Widget build(BuildContext context, WidgetRef ref) {
      return Positioned(
        top: 120,
        left: 16,
        right: 16,
        child: Material(
          elevation: 10,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.buttonText,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Pickup & Drop info
                Row(
                  children: [
                    const Icon(Icons.my_location, color: Colors.green),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        rideRequest.pickup,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.location_on, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        rideRequest.drop,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.currency_rupee, color: Colors.orange),
                    const SizedBox(width: 6),
                    Text(
                      '${rideRequest.fare}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24, thickness: 1.2),

                // Accept / Reject buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: Builder(
                        builder: (buttonContext) => ElevatedButton.icon(
                          icon: const Icon(Icons.check),
                          label: const Text("Accept"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () async {
                            audioPlayer.stop();
                            await _handleAccept(buttonContext, ref);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.close),
                        label: const Text("Reject"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          audioPlayer.stop();
                          ref.read(rideRequestProvider.notifier).state = null;
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }

    Future<void> _handleAccept(BuildContext context, WidgetRef ref) async {
      // Read all providers & data at the start
      final repo = ref.read(acceptBookingRepositoryProvider);
      final driverRepo = ref.read(driverRepositoryProvider);
      final tripNotifier = ref.read(tripProvider.notifier);
      final rideRequestNotifier = ref.read(rideRequestProvider.notifier);
      final driverStatusNotifier = ref.read(driverStatusProvider.notifier);




      final riderId = SharedPrefsHelper.getRiderId();
      await SharedPrefsHelper.setBookingId(rideRequest.bookingId.toString());
      final mobileNo = SharedPrefsHelper.getDriverMobile();

      try {
        final response = await repo.getAcceptBookingStatus(
          rideRequest.bookingId,
          int.parse(riderId),
        );

        if (response.isEmpty) {
          if (context.mounted) {
            await ApiResponseDialog.show(
              context: context,
              ref: ref,
              status: 'error',
              message: 'Something went wrong!',
            );
          }
          return;
        }

        final apiResp = response.first;

        if (context.mounted) {
          await ApiResponseDialog.show(
            context: context,
            ref: ref,
            status: apiResp.status ?? 'error',
            message: apiResp.message ?? 'Unknown error',
          );
        }

        if ((apiResp.status ?? '').toLowerCase() == 'success') {
          final pickupLatLng = parseLatLng(rideRequest.pickuplatlong);
          final dropLatLng = parseLatLng(rideRequest.droplatlong);
          final otp = generateOtp();

          // Store trip data locally
          final tripData = {
            'pickup': rideRequest.pickup,
            'drop': rideRequest.drop,
            'fare': rideRequest.fare,
            'pickupLatLng': pickupLatLng,
            'dropLatLng': dropLatLng,
            'otp': otp,
            'bookingId': rideRequest.bookingId.toString(),
            'fcmToken': rideRequest.fcmToken,
            'userId': rideRequest.userId,
            'cusMobile': rideRequest.cusMobile,
          };

          await SharedPrefsHelper.setTripData({
            'pickup': tripData['pickup'],
            'drop': tripData['drop'],
            'fare': tripData['fare'],
            'pickupLatLng': pickupLatLng != null
                ? "${pickupLatLng.latitude},${pickupLatLng.longitude}"
                : "0,0",
            'dropLatLng': dropLatLng != null
                ? "${dropLatLng.latitude},${dropLatLng.longitude}"
                : "0,0",
            'otp': tripData['otp'] ?? '',
            'bookingId': tripData['bookingId'],
            'fcmToken': tripData['fcmToken'],
            'userId': tripData['userId'],
            'cusMobile': tripData['cusMobile'],
          });


          // Update driver status
          final position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
          );
          final fromLatLong = "${position.latitude},${position.longitude}";

          final statusResp = await driverRepo.updateDriverStatus(
            riderId: riderId,
            riderStatus: "RB",
            fromLatLong: fromLatLong,
          );

          // Use local notifier variables instead of ref after awaits
          tripNotifier.acceptRide(
            tripData['pickup'] as String,
            tripData['drop'] as String,
            (tripData['fare'] as num).toInt(),
            tripData['pickupLatLng'] as LatLng,
            tripData['dropLatLng'] as LatLng,
            tripData['otp'] as String,
            tripData['bookingId'] as String,
            tripData['fcmToken'] as String,
            tripData['userId'] as String,
            tripData['cusMobile'] as String,
          );

          if (statusResp.status == "success") {
            driverStatusNotifier.state = "RB";
            await SharedPrefsHelper.setDriverStatus("RB");
          } else if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("Failed to set status RB: ${statusResp.message}"),
              ),
            );
          }

          if (context.mounted) Navigator.of(context).pop(); // close dialog

          WidgetsBinding.instance.addPostFrameCallback((_) {
            router.go(AppRoutes.trip);
          });


          // Clear ride request
          rideRequestNotifier.state = null;

          if (rideRequest.fcmToken.isNotEmpty) {
            await FirebasePushService.sendPushNotification(
              fcmToken: rideRequest.fcmToken,
              title: "Ride Accepted ✅",
              body: "Your ride request has been accepted by the driver.",
              data: {
                "bookingId": rideRequest.bookingId.toString(),
                "status": "accepted",
                "otp": otp,
                "driverLatLong": fromLatLong,
                "driverMobno": mobileNo,
                "dropLatLong": rideRequest.droplatlong,
              },
            );
          }
        }
      } catch (e) {
        if (context.mounted) {
          await ApiResponseDialog.show(
            context: context,
            ref: ref,
            status: 'error',
            message: 'Failed to accept ride: $e',
          );
        }
      }
    }

  }
