import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../models/CancelModel.dart';
import '../../../models/TripState.dart';
import '../../../models/user_profile_model.dart';
import '../../../utils/storage.dart';
import '../TripNotifier.dart';

// Dialog Widget
class TripCustomerInfoDialog extends ConsumerWidget {
  final TripState trip;
  final UserProfile? userProfile;
  final String? customerToken;

  const TripCustomerInfoDialog({
    Key? key,
    required this.trip,
    this.userProfile,
    required this.customerToken,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 8,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 400),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Row(
                  children: const [
                    Icon(Icons.info_outline, color: Colors.blueAccent),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Trip & Customer Info",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Trip Info Section
                Row(
                  children: const [
                    Icon(Icons.directions_car, color: Colors.green),
                    SizedBox(width: 8),
                    Text(
                      "Trip Info",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _modernInfoRow(Icons.location_pin, "Pickup", trip.pickup),
                _modernInfoRow(Icons.flag, "Drop", trip.drop),
                _modernInfoRow(Icons.attach_money, "Fare", "₹${trip.fare}"),
                const Divider(height: 24, thickness: 1),

                // Customer Info Section
                if (userProfile != null) ...[
                  Row(
                    children: const [
                      Icon(Icons.person, color: Colors.blue),
                      SizedBox(width: 8),
                      Text(
                        "Customer Info",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _modernInfoRow(
                    Icons.person_outline,
                    "Name",
                    userProfile!.userName,
                  ),
                  GestureDetector(
                    onTap: () async {
                      final phone = userProfile!.mobileNo;
                      final uri = Uri.parse("tel:$phone");
                      try {
                        await launchUrl(uri, mode: LaunchMode.platformDefault);
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Error opening dialer: $e")),
                        );
                      }
                    },
                    child: _modernInfoRow(
                      Icons.phone,
                      "Mobile",
                      userProfile!.mobileNo,
                    ),
                  ),

                  _modernInfoRow(
                    Icons.home,
                    "Address",
                    "${userProfile!.address1}, ${userProfile!.address2}, ${userProfile!.city}",
                  ),
                ],

                const SizedBox(height: 20),

                // Close Button
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: () async {
                          final String? cancelReason = await showDialog<String>(
                            context: context,
                            barrierDismissible: false,
                            builder: (ctx) {
                              final reasons = <String>[
                                "Customer not available",
                                "Wrong pickup location",
                                "Passenger refused to board",
                                "Emergency",
                                "Other",
                              ];
                              int selectedIndex = -1;
                              final otherController = TextEditingController();

                              return StatefulBuilder(
                                builder: (context, setState) {
                                  final bool isOtherSelected =
                                      selectedIndex == reasons.length - 1;
                                  final bool canConfirm =
                                      selectedIndex != -1 &&
                                      (!(isOtherSelected) ||
                                          otherController.text
                                              .trim()
                                              .isNotEmpty);

                                  return AlertDialog(
                                    title: const Text("Cancel Ride"),
                                    content: SingleChildScrollView(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Text(
                                            "Select a reason for cancellation:",
                                          ),
                                          const SizedBox(height: 12),
                                          ...List.generate(reasons.length, (i) {
                                            return RadioListTile<int>(
                                              value: i,
                                              groupValue: selectedIndex,
                                              title: Text(reasons[i]),
                                              onChanged: (val) => setState(() {
                                                selectedIndex = val!;
                                              }),
                                            );
                                          }),
                                          if (isOtherSelected) ...[
                                            const SizedBox(height: 8),
                                            TextField(
                                              controller: otherController,
                                              onChanged: (_) => setState(() {}),
                                              decoration: const InputDecoration(
                                                labelText: "Specify reason",
                                                hintText: "Type reason",
                                                border: OutlineInputBorder(),
                                                isDense: true,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(context).pop(null),
                                        child: const Text("Close"),
                                      ),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red,
                                        ),
                                        onPressed: canConfirm
                                            ? () {
                                                final reason = isOtherSelected
                                                    ? otherController.text
                                                          .trim()
                                                    : reasons[selectedIndex];
                                                Navigator.of(
                                                  context,
                                                ).pop(reason);
                                              }
                                            : null,
                                        child: const Text("Confirm Cancel"),
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                          );

                          if (cancelReason != null) {
                            // 🔹 Cancel API call
                            final lastBookingId =
                                SharedPrefsHelper.getBookingId();

                            final cancelModel = CancelModel(
                              decline_reason: cancelReason,
                              Bookingid: lastBookingId,
                            );

                            final success = await ProfileRepository()
                                .cancelBooking(cancelModel);

                            if (success) {
                              await SharedPrefsHelper.clearBookingId();
                              final container = ProviderScope.containerOf(
                                context,
                                listen: false,
                              );
                              container.read(tripProvider.notifier).reset();
                              if (context.mounted) {
                                final position = await Geolocator.getCurrentPosition(
                                  desiredAccuracy: LocationAccuracy.high,
                                );
                                final fromLatLong = "${position.latitude},${position.longitude}";

                                container
                                        .read(driverStatusProvider.notifier)
                                        .state =
                                    "OL";
                                await SharedPrefsHelper.setDriverStatus("OL");
                                final repo = ref.read(driverRepositoryProvider);
                                final riderId = SharedPrefsHelper.getRiderId();
                                final response = await repo.updateDriverStatus(
                                  riderId: riderId,
                                  riderStatus: "OL",
                                  fromLatLong: fromLatLong,
                                );
                                if(response != null){
                                  FirebasePushService.sendPushNotification(
                                    fcmToken: customerToken!,
                                    title: "Rider Cancel Ride",
                                    body: "Ride Cancelled By Rider",
                                    data: {
                                      "status": "cancel ride",
                                      "reason": "Unable to pickup",
                                    },
                                  );
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        "Ride cancelled successfully ✅",
                                      ),
                                      backgroundColor: Colors.green,
                                    ),
                                  );

                                  Navigator.of(
                                    context,
                                  ).pop(); // close TripCustomerInfoDialog
                                  // Navigate home

                                  Future.delayed(
                                    Duration.zero,
                                        () => router.go(AppRoutes.driverHome),
                                  );
                                }


                              }
                            } else {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      "Failed to cancel ride. Please try again.",
                                    ),
                                    backgroundColor: Colors.redAccent,
                                  ),
                                );
                              }
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          elevation: 4,
                        ),
                        child: const Text(
                          "Cancel Ride",
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                      ),

                      const SizedBox(width: 12),

                      // Close Button
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          elevation: 4,
                        ),
                        child: const Text(
                          "Close",
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Helper Widget Row
/// Modern info row with icon
Widget _modernInfoRow(IconData icon, String label, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey[700]),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: "$label: ",
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                    fontSize: 14,
                  ),
                ),
                TextSpan(
                  text: value,
                  style: const TextStyle(color: Colors.black, fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

// Function to show dialog
