import 'package:bneeds_taxi_driver/utils/storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';

class TripCompleteScreen extends ConsumerStatefulWidget {
  const TripCompleteScreen({super.key});

  @override
  ConsumerState<TripCompleteScreen> createState() => _TripCompleteScreenState();
}

class _TripCompleteScreenState extends ConsumerState<TripCompleteScreen> {
  late TextEditingController _fareController;
  String _selectedPayment = "Cash"; // default

  @override
  void initState() {
    super.initState();
    final trip = ref.read(tripProvider);
    _fareController = TextEditingController(text: trip.fare.toString());
  }

  @override
  void dispose() {
    _fareController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.infoCardGradientStart, AppColors.primary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.pagePadding),
            child: Card(
              elevation: 10,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
              ),
              color: AppColors.buttonText,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 40,
                  horizontal: AppDimensions.pagePadding,
                ),
                child:Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.celebration,
                            size: 90,
                            color: Colors.orange,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            Strings.tripCompleted,
                            style: AppTextStyles.heading(color: Colors.black87, size: 24),
                          ),
                          const SizedBox(height: 16),
                          // 1️⃣ Show calculated fare
                          Text(
                            "Calculated Fare: ₹${ref.read(tripProvider).fare}",
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          // 2️⃣ Editable Fare Field
                          TextField(
                            controller: _fareController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: "Adjust Fare if needed",
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Payment Method Dropdown
                          DropdownButtonFormField<String>(
                            value: _selectedPayment,
                            decoration: InputDecoration(
                              labelText: "Payment Method",
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            items: ["Cash", "Online", "Wallet"]
                                .map((method) => DropdownMenuItem(
                              value: method,
                              child: Text(method),
                            ))
                                .toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedPayment = value!;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () async {
                        final bookingIdStr = SharedPrefsHelper.getBookingId();
                        final bookingId = int.tryParse(bookingIdStr) ?? 0;

                        // Get updated fare from TextField
                        final updatedFare = int.tryParse(_fareController.text) ??
                            ref.read(tripProvider).fare;

                        // Get selected payment method
                        final paymentMethod = _selectedPayment;

                        // Get driver current location
                        final trip = ref.read(tripProvider);
                        final fromLatLong =
                            "${trip.driverCurrentLatLng.latitude},${trip.driverCurrentLatLng.longitude}";

                        // Update driver status to ON
                        final repo = ref.read(driverRepositoryProvider);
                        final riderId = SharedPrefsHelper.getRiderId();

                        final response = await repo.updateDriverStatus(
                          riderId: riderId,
                          riderStatus: "ON", // mark driver as available
                          fromLatLong: fromLatLong,
                        );

                        if (response.status == "success") {
                          // 1️⃣ Update Riverpod state
                          ref.read(driverStatusProvider.notifier).state = "OL"; // Online / Ready for rides
                          await SharedPrefsHelper.setDriverStatus("OL"); // persist locally

                          // 2️⃣ Navigate back to HomeScreen
                          context.go(AppRoutes.driverHome);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Failed to update driver status: ${response.message}")),
                          );
                        }

                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: AppDimensions.buttonPadding,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        backgroundColor: AppColors.success,
                        foregroundColor: AppColors.buttonText,
                        elevation: 5,
                        textStyle: AppTextStyles.button(),
                      ),
                      icon: const Icon(Icons.refresh),
                      label: const Text(Strings.readyForNextRide),
                    )


                  ],
                )
              ),
            ),
          ),
        ),
      ),
    );
  }
}
