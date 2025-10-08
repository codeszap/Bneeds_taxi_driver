import 'package:bneeds_taxi_driver/utils/storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';

import '../models/VehBookingFinal.dart';
import 'onTrip/TripNotifier.dart';

class TripCompleteScreen extends ConsumerStatefulWidget {
  const TripCompleteScreen({super.key});

  @override
  ConsumerState<TripCompleteScreen> createState() => _TripCompleteScreenState();
}

class _TripCompleteScreenState extends ConsumerState<TripCompleteScreen> {
  late TextEditingController _fareController;
  String _selectedPayment = "Cash";
  bool _isLoading = false;
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
                child: Column(
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
                            style: AppTextStyles.heading(
                              color: Colors.black87,
                              size: 24,
                            ),
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
                              filled: true,
                              fillColor: Colors.white,
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                  color: Colors.grey, // color when not focused
                                  width: 1.5,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                  color: Colors.blue, // color when focused
                                  width: 2,
                                ),
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
                                .map(
                                  (method) => DropdownMenuItem(
                                    value: method,
                                    child: Text(method),
                                  ),
                                )
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
                      onPressed: _isLoading
                          ? null
                          : () async {
                              setState(() => _isLoading = true);
                              try {
                                final trip = ref.read(tripProvider);
                                final bookingIdStr =
                                    SharedPrefsHelper.getBookingId();
                                final updatedFare =
                                    int.tryParse(_fareController.text) ??
                                    trip.fare;

                                final fromLatLong =
                                    "${trip.driverCurrentLatLng.latitude},${trip.driverCurrentLatLng.longitude}";
                                final toLatLong =
                                    "${trip.dropLatLng.latitude},${trip.dropLatLng.longitude}";
                                final riderId = SharedPrefsHelper.getRiderId();
                                final userId = SharedPrefsHelper.getUserId();

                                final distanceInMeters =
                                    Geolocator.distanceBetween(
                                      trip.driverCurrentLatLng.latitude,
                                      trip.driverCurrentLatLng.longitude,
                                      trip.dropLatLng.latitude,
                                      trip.dropLatLng.longitude,
                                    );
                                final distanceInKm = (distanceInMeters / 1000)
                                    .toStringAsFixed(3);

                                final profile = VehBookingFinal(
                                  distance: distanceInKm,
                                  finalamt: updatedFare.toString(),
                                  fromLatLong: fromLatLong,
                                  toLatLong: toLatLong,
                                  userid: userId,
                                  bookingId: bookingIdStr,
                                  riderId: riderId,
                                );

                                await ProfileRepository()
                                    .getCompleteBookingStatus(profile);

                                final repo = ref.read(driverRepositoryProvider);
                                final response = await repo.updateDriverStatus(
                                  riderId: riderId,
                                  riderStatus: "OL",
                                  fromLatLong: fromLatLong,
                                );

                                if (response.status == "success") {
                                  ref
                                          .read(driverStatusProvider.notifier)
                                          .state =
                                      "OL";

                                  // Clear SharedPrefs in background
                                  SharedPrefsHelper.clearBookingId();
                                  SharedPrefsHelper.clearUserId();
                                  SharedPrefsHelper.clearTripData();
                                  SharedPrefsHelper.clearOngoingTrip();
                                  ref.read(tripProvider.notifier).reset();


                                  // Navigate immediately
                                  context.go(AppRoutes.driverHome);


                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        "Failed: ${response.message}",
                                      ),
                                    ),
                                  );
                                }
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text("Error: $e")),
                                );
                              } finally {
                                if (mounted) setState(() => _isLoading = false);
                              }
                            },
                      icon: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.refresh),
                      label: Text(
                        _isLoading ? "Processing..." : Strings.readyForNextRide,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
