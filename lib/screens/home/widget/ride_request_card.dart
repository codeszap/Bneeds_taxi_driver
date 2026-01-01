import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bneeds_taxi_driver/utils/storage.dart';

import '../../../firebase/TripFirebaseService.dart';
import '../../../models/Api Modal/AcceptBookingRequest.dart';
import '../../../models/TripState.dart';
import '../../../models/rideRequest.dart';
import '../../../utils/dialogs.dart';

import 'package:flutter/material.dart';

import '../../onTrip/TripNotifier.dart';

class RideRequestCard extends ConsumerWidget {
  final RideRequest rideRequest;
  final AudioPlayer audioPlayer;
  final BuildContext requiredContext;

  const RideRequestCard({
    super.key,
    required this.rideRequest,
    required this.audioPlayer,
    required this.requiredContext,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Material(
      elevation: 10,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.buttonText,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Pickup & Drop info
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
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
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
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
                    const SizedBox(height: 12),
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
                  ],
                ),
              ),
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
                        await _handleAccept(requiredContext, ref);
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
                      Navigator.pop(context);
                      audioPlayer.stop();
                      ref.read(rideRequestProvider.notifier).state = null;
                      ref.read(tripProvider.notifier).reset();
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleAccept(BuildContext rootContext, WidgetRef ref) async {
    final repo = ref.read(acceptBookingRepositoryProvider);
    final driverRepo = ref.read(driverRepositoryProvider);
    final rideRequestNotifier = ref.read(rideRequestProvider.notifier);
    final driverStatusNotifier = ref.read(driverStatusProvider.notifier);
    final riderId = SharedPrefsHelper.getRiderId();
    await SharedPrefsHelper.setBookingId(rideRequest.bookingId.toString());

    try {
      final apiResp = await repo.AcceptBookingStatus(
        request: BookingRequest(
          action: 'G',
          bookingId: rideRequest.bookingId.toString(),
          riderId: riderId.toString(),
        ),
      );

      if (rootContext.mounted) {
        await ApiResponseDialog.show(
          context: rootContext,
          context2: requiredContext,
          ref: ref,
          status: apiResp.status ?? 'error',
          message: apiResp.message ?? 'Unknown error',
        );
      }

      if ((apiResp.status ?? '').toLowerCase() == 'success') {
        // ✅ Success — move to Trip Screen
        rideRequestNotifier.state = null;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          router.go(AppRoutes.trip);
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

        if (statusResp.status == "success") {
          driverStatusNotifier.state = "RB";
          await SharedPrefsHelper.setDriverStatus("RB");
        }
      }
    } catch (e) {
      if (rootContext.mounted) {
        await ApiResponseDialog.show(
          context: rootContext,
          context2: requiredContext,
          ref: ref,
          status: 'error',
          message: 'Failed to accept ride: $e',
        );
      }
    }
  }
}
