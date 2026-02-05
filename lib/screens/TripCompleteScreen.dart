import 'package:bneeds_taxi_driver/providers/booking_provider.dart';
import 'package:bneeds_taxi_driver/providers/params/booking_params.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';

import '../config/routes.dart';
import '../models/VehBookingFinal.dart';

import '../providers/driverStatusProvider.dart';
import '../repositories/profile_repository.dart';

import '../theme/app_colors.dart';
import '../utils/constants.dart';
import '../utils/sharedPrefrencesHelper.dart';
import 'onTrip/TripNotifier.dart';

class TripCompleteScreen extends ConsumerStatefulWidget {
  const TripCompleteScreen({super.key});

  @override
  ConsumerState<TripCompleteScreen> createState() => _TripCompleteScreenState();
}

class _TripCompleteScreenState extends ConsumerState<TripCompleteScreen> {
  late TextEditingController _fareController;
  String _selectedPayment = "Cash";
  // --- Step 1: Loading state-a 'true' nu maathunga ---
  bool _isLoading = true;
  bool _isFareSubmited = false;

  @override
  void initState() {
    super.initState();
    _fareController = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _calculateAndSetFare();
    });
  }

  Future<void> _handleRefresh() async {
    if (_isLoading) return;

    print("🔄 Screen refreshed. Re-calculating fare...");
    setState(() {
      // Thirumba loading kaatrom
      _isLoading = true;
    });
    // Marubadiyum API call pannunga
    await _calculateAndSetFare();
  }

  // --- Step 3: Fare calculate panra puthu function ---
  Future<void> _calculateAndSetFare() async {
    try {
      final bookingId = await SharedPrefsHelper.getBookingId();
      final riderId = await SharedPrefsHelper.getRiderId();
      final position = await Geolocator.getCurrentPosition();

      if (bookingId.isEmpty || riderId == null) {
        print("❌ BookingId or RiderId is missing in SharedPrefs.");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Could not find booking details.")),
          );
          setState(() => _isLoading = false);
        }
        return;
      }

      final fareParams = FareCalculationParams(
        bookingId: bookingId,
        riderId: riderId,
        CurrentLatlong: "${position.latitude},${position.longitude}",
      );

      // inside _calculateAndSetFare()

      // ...
      final fareMap = await ref.read(calculateFareProvider(fareParams).future);

      // --- 👇 Intha 2 line-a ippadi maathunga START 👇 ---
      final fareFromApi =
          fareMap?['finalFare']; // Ithula '50.00' nu string-a varuthu

      // String-a iruntha, double-a parse panni, aprom integer-a maathunga
      final calculatedFare = fareFromApi is String
          ? (double.tryParse(fareFromApi)?.toInt() ?? 0)
          : (fareFromApi as num?)?.toInt() ?? 0;
      // --- 👆 Intha 2 line-a ippadi maathunga END 👆 ---

      print("✅ Fare Calculated: ₹$calculatedFare");

      if (mounted) {
        setState(() {
          _fareController.text = calculatedFare.toString();
          _isLoading = false;
        });
      }
      // ...
    } catch (e) {
      print("❌ Error calculating fare on TripCompleteScreen: $e");
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to calculate fare.")),
        );
      }
    }
  }

  @override
  void dispose() {
    _fareController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final trip = ref.watch(tripProvider);

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
        child: RefreshIndicator(
          onRefresh: _handleRefresh,
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                )
              : Center(
                  // Matha UI code appadiye irukkum
                  child: Padding(
                    padding: const EdgeInsets.all(AppDimensions.pagePadding),
                    child: Card(
                      elevation: 10,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppDimensions.cardRadius,
                        ),
                      ),
                      color: AppColors.buttonText,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 40,
                          horizontal: AppDimensions.pagePadding,
                        ),
                        child: SingleChildScrollView(
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
                              // Intha text ippo 'trip.fare' la irunthu varum
                              // In build method
                              Text(
                                "Calculated Fare: ₹${_fareController.text}", // trip.fare-ku pathila _fareController.text
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black87,
                                ),
                              ),

                              const SizedBox(height: 8),
                              // Intha TextField ippo API la irunthu varra value-oda irukkum
                              TextField(
                                controller: _fareController,
                                enabled: !_isFareSubmited,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: "Adjust Fare if needed",
                                  filled: true,
                                  fillColor: Colors.white,
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(
                                      color: Colors.grey,
                                      width: 1.5,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(
                                      color: Colors.blue,
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
                              // Dropdown and buttons (no changes needed here)
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
                                onChanged: _isFareSubmited
                                    ? null
                                    : (value) {
                                        setState(() {
                                          _selectedPayment = value!;
                                        });
                                      },
                              ),
                              const SizedBox(height: 24),
                              // Submit Fare Button
                              // In TripCompleteScreen.dart, "Submit Fare" button
                              if (!_isFareSubmited)
                                ElevatedButton.icon(
                                  onPressed: _isLoading
                                      ? null
                                      : () async {
                                          setState(() {
                                            _isLoading = true;
                                          });

                                          try {
                                            final bookingId =
                                                await SharedPrefsHelper.getBookingId();
                                            final riderId =
                                                await SharedPrefsHelper.getRiderId();
                                            final currentPosition =
                                                await Geolocator.getCurrentPosition();

                                            if (bookingId.isEmpty ||
                                                riderId == null) {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    "Booking details not found!",
                                                  ),
                                                ),
                                              );
                                              setState(
                                                () => _isLoading = false,
                                              );
                                              return;
                                            }

                                            final finalBookingParams =
                                                FinalBookingParams(
                                                  bookingId: bookingId,
                                                  finalAmt:
                                                      _fareController.text,
                                                  driverCurrentLatLong:
                                                      "${currentPosition.latitude},${currentPosition.longitude}",
                                                  riderId: riderId,
                                                  riderStatus: "OL",
                                                );

                                            print(
                                              "🚀 Calling finalBookingProvider...",
                                            );
                                            // 3. API-a call pannunga
                                            final response = await ref.read(
                                              finalBookingProvider(
                                                finalBookingParams,
                                              ).future,
                                            );

                                            if (response.status == 'success') {
                                              ref
                                                      .read(
                                                        driverStatusProvider
                                                            .notifier,
                                                      )
                                                      .state =
                                                  "OL";
                                              await SharedPrefsHelper.setDriverStatus(
                                                "OL",
                                              );
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    "✅ Fare Submitted Successfully!",
                                                  ),
                                                  backgroundColor: Colors.green,
                                                ),
                                              );
                                              // UI-a update panni, "Ready For Next Ride" button-a kaatunga
                                              setState(() {
                                                _isFareSubmited = true;
                                              });
                                            } else {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    "❌ Failed: ${response.message}",
                                                  ),
                                                  backgroundColor: Colors.red,
                                                ),
                                              );
                                            }
                                          } catch (e) {
                                            print(
                                              "❌ Error on submitting fare: $e",
                                            );
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  "An error occurred. Please try again.",
                                                ),
                                                backgroundColor: Colors.red,
                                              ),
                                            );
                                          } finally {
                                            // API call mudinja odane loading-a stop pannunga
                                            if (mounted) {
                                              setState(() {
                                                _isLoading = false;
                                              });
                                            }
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
                                      : const Icon(Icons.currency_rupee),
                                  label: Text(
                                    _isLoading
                                        ? "Submitting..."
                                        : Strings.submitFare,
                                  ),
                                ),
                              const SizedBox(height: 12),
                              // Ready For Next Ride
                              if (_isFareSubmited)
                                ElevatedButton.icon(
                                  onPressed: () async {
                                    // On-Press logic for next ride
                                    await ref
                                        .read(tripProvider.notifier)
                                        .reset();
                                    await ref
                                        .read(tripProvider.notifier)
                                        .clearId();
                                    if (mounted)
                                      context.go(AppRoutes.driverHome);
                                  },
                                  icon: const Icon(Icons.refresh),
                                  label: const Text(Strings.readyForNextRide),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}
