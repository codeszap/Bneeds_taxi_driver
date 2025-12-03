import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../models/BookingDetail.dart';
import '../../../models/CancelModel.dart';
import '../../../models/TripState.dart';
import '../../../models/user_profile_model.dart';
import '../../../utils/storage.dart';
import '../TripNotifier.dart';

// Dialog Widget
class TripCustomerInfoDialog extends ConsumerWidget {
  final BookingDetail? bookingDetail;

  const TripCustomerInfoDialog({super.key, this.bookingDetail});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (bookingDetail == null) {
    return const Dialog(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Text("Booking details not available."),
        ),
      );
    }

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
                _modernInfoRow(
                  Icons.location_pin,
                  "Pickup",
                  bookingDetail!.pickupLocation,
                ),
                _modernInfoRow(Icons.flag, "Drop", bookingDetail!.dropLocation),
                _modernInfoRow(
                  Icons.attach_money,
                  "Fare",
                  "₹${bookingDetail?.fareAmount}",
                ),
                const Divider(height: 24, thickness: 1),

                // Customer Info Section

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
                    bookingDetail!.username,
                  ),
                  GestureDetector(
                    onTap: () async {
                      final phone = bookingDetail!.userMobileNo;
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
                      bookingDetail!.userMobileNo,
                    ),
                  ),

                  // _modernInfoRow(
                  //   Icons.home,
                  //   "Address",
                  //   "${bookingDetail!.address1}, ${bookingDetail!.address2}, ${bookingDetail!.city}",
                  // ),
                  //
                const SizedBox(height: 20),

                // Close Button
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: () async {
                          // 🔹 Step 1: `await` seivatharku munbu, `context`, `ref`, matrum `container`-ai save seiyavum.
                          // Indha`context`-ai thaan `await` ku piragu payanpadutha vendum.
                          final currentContext = context;
                          final container = ProviderScope.containerOf(currentContext, listen: false);
                          // `ref` aiyum munkoottiye read seithu, antha `repo`-vai save seithukollalam.
                          final repo = ref.read(driverRepositoryProvider);

                          // 🔹 Step 2: Cancel reason-ஐ dialog moolam vaangavum.
                          final String? cancelReason = await showDialog<String>(
                            context: currentContext, // Inga save seitha `currentContext`-ஐ payanpaduthavum.
                            barrierDismissible: false,
                            builder: (ctx) {
                              // Indha dialog code-il entha maattrangalum thevai illai.
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
                                          (!isOtherSelected ||
                                              otherController.text.trim().isNotEmpty);

                                  return AlertDialog(
                                    title: const Text("Cancel Ride"),
                                    content: SingleChildScrollView(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Text("Select a reason for cancellation:"),
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
                                        onPressed: () => Navigator.of(context).pop(null),
                                        child: const Text("Close"),
                                      ),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red,
                                        ),
                                        onPressed: canConfirm
                                            ? () {
                                          final reason = isOtherSelected
                                              ? otherController.text.trim()
                                              : reasons[selectedIndex];
                                          Navigator.of(context).pop(reason);
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

                          // 🔹 Step 3: `await` ku piragu, `context` in nilaiyai `mounted` property moolam check seiyavum.
                          // `currentContext.mounted` enbathu, antha widget ippozhuthum UI-il irukkiratha enbathai uruthi seiyum.
                          if (cancelReason != null && currentContext.mounted) {
                            // 🔹 Cancel API call
                            final lastBookingId = SharedPrefsHelper.getBookingId();
                            final cancelModel = CancelModel(
                              decline_reason: cancelReason,
                              Bookingid: lastBookingId,
                            );

                            final success = await ProfileRepository().cancelBooking(cancelModel);

                            // `mounted` property-ai marubadiyum check seivathu nallathu, network call neram eduthirukkalam.
                            if (!currentContext.mounted) return;

                            if (success) {
                              await SharedPrefsHelper.clearBookingId();
                              container.read(tripProvider.notifier).reset();

                              final position = await Geolocator.getCurrentPosition(
                                desiredAccuracy: LocationAccuracy.high,
                              );
                              final fromLatLong = "${position.latitude},${position.longitude}";

                              // Riverpod state-ai update seiyavum
                              container.read(driverStatusProvider.notifier).state = "OL";
                              await SharedPrefsHelper.setDriverStatus("OL");
                              final riderId = SharedPrefsHelper.getRiderId();

                              // Munadiyae edutha `repo`-vai inga payanpaduthavum.
                              await repo.updateDriverStatus(
                                riderId: riderId,
                                riderStatus: "OL",
                                fromLatLong: fromLatLong,
                              );

                              // UI-il feedback kaatta `ScaffoldMessenger`-ai payanpaduthavum.
                              ScaffoldMessenger.of(currentContext).showSnackBar(
                                const SnackBar(
                                  content: Text("Ride cancelled successfully ✅"),
                                  backgroundColor: Colors.green,
                                ),
                              );

                              // Anaithu dialog-kalaiyum moodi, home screen-ku sellavum.
                              Navigator.of(currentContext).pop(); // TripCustomerInfoDialog-ai close seiyum

                              // GoRouter-ai payanpaduthi Home screen-ku navigate seiyavum.
                              router.go(
                                AppRoutes.driverHome,
                                extra: {
                                  'initialLat': position.latitude,
                                  'initialLng': position.longitude,
                                },
                              );

                            } else {
                              // API call fail aanaal, error message kaattavum.
                              ScaffoldMessenger.of(currentContext).showSnackBar(
                                const SnackBar(
                                  content: Text("Failed to cancel ride. Please try again."),
                                  backgroundColor: Colors.redAccent,
                                ),
                              );
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
