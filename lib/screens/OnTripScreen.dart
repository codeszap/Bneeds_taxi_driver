// trip_state_provider.dart
import 'dart:async';
import 'package:bneeds_taxi_driver/config/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'TripCompleteScreen.dart';

enum TripStatus { idle, accepted, onTrip, completed }

class TripState {
  final String pickup;
  final String drop;
  final int fare;
  final TripStatus status;
  final int elapsedTime;
  final bool canCompleteTrip; // New flag

  TripState({
    this.pickup = "",
    this.drop = "",
    this.fare = 0,
    this.status = TripStatus.idle,
    this.elapsedTime = 0,
    this.canCompleteTrip = false,
  });

  TripState copyWith({
    String? pickup,
    String? drop,
    int? fare,
    TripStatus? status,
    int? elapsedTime,
    bool? canCompleteTrip,
  }) {
    return TripState(
      pickup: pickup ?? this.pickup,
      drop: drop ?? this.drop,
      fare: fare ?? this.fare,
      status: status ?? this.status,
      elapsedTime: elapsedTime ?? this.elapsedTime,
      canCompleteTrip: canCompleteTrip ?? this.canCompleteTrip,
    );
  }
}

class TripNotifier extends StateNotifier<TripState> {
  Timer? _timer;

  TripNotifier() : super(TripState());

  void acceptRide(String pickup, String drop, int fare) {
    state = TripState(
      pickup: pickup,
      drop: drop,
      fare: fare,
      status: TripStatus.accepted,
    );
  }

  void startAutoTrip() {
    state = state.copyWith(
      status: TripStatus.onTrip,
      elapsedTime: 0,
      canCompleteTrip: false,
    );
    _timer?.cancel();

    int elapsed = 0;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      elapsed++;
      state = state.copyWith(elapsedTime: elapsed);

      if (elapsed >= 5) {
        timer.cancel();
        state = state.copyWith(canCompleteTrip: true); // Enable complete button
      }
    });
  }

  void completeTrip() {
    state = state.copyWith(status: TripStatus.completed);
  }

  void reset() {
    _timer?.cancel();
    state = TripState();
  }
}

final tripProvider = StateNotifierProvider<TripNotifier, TripState>(
  (ref) => TripNotifier(),
);

/// ------------------ OTP Dialog ------------------
Future<void> showOtpDialog(
  BuildContext context,
  WidgetRef ref,
  Function simulateTaxiMovement,
) async {
  const int otpLength = 4;
  const String correctOTP = "1234";

  final List<TextEditingController> controllers =
      List.generate(otpLength, (_) => TextEditingController());
  final List<FocusNode> focusNodes =
      List.generate(otpLength, (_) => FocusNode());

  bool isError = false;

  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setState) {
          void submitOtp() {
            final otp = controllers.map((c) => c.text).join();
            if (otp == correctOTP) {
              Navigator.of(dialogContext).pop();

              // Start taxi simulation
              simulateTaxiMovement();

              // Start 5-sec auto trip
              ref.read(tripProvider.notifier).startAutoTrip();
            } else {
              setState(() {
                isError = true;
              });
            }
          }

          return AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Center(
              child: Text(
                "Enter OTP",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("Enter the 4-digit OTP sent to the user."),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(otpLength, (index) {
                    return SizedBox(
                      width: 50,
                      child: TextField(
                        controller: controllers[index],
                        focusNode: focusNodes[index],
                        maxLength: 1,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                        decoration: InputDecoration(
                          counterText: '',
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: Colors.grey,
                              width: 2,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: Colors.blue,
                              width: 2,
                            ),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: Colors.red,
                              width: 2,
                            ),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: Colors.red,
                              width: 2,
                            ),
                          ),
                        ),
                        onChanged: (value) {
                          if (value.isNotEmpty && index < otpLength - 1)
                            focusNodes[index + 1].requestFocus();
                          if (value.isEmpty && index > 0)
                            focusNodes[index - 1].requestFocus();
                          if (controllers.every((c) => c.text.isNotEmpty))
                            submitOtp();
                        },
                      ),
                    );
                  }),
                ),
                if (isError)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      "Invalid OTP",
                      style: TextStyle(
                        color: Colors.red[700],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            actionsAlignment: MainAxisAlignment.center,
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text("Cancel"),
              ),
            ],
          );
        },
      );
    },
  );
}

/// ------------------ OnTripScreen ------------------
class OnTripScreen extends ConsumerStatefulWidget {
  const OnTripScreen({super.key});

  @override
  ConsumerState<OnTripScreen> createState() => _OnTripScreenState();
}

class _OnTripScreenState extends ConsumerState<OnTripScreen> {
  GoogleMapController? _mapController;

  final LatLng pickupLatLng = const LatLng(12.9716, 77.5946);
  final LatLng dropLatLng = const LatLng(12.9352, 77.6245);

  Marker taxiMarker = Marker(
    markerId: const MarkerId("taxi"),
    position: const LatLng(12.9716, 77.5946),
    icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
  );

  void simulateTaxiMovement({int durationInSeconds = 5}) {
    int steps = 20;
    int currentStep = 0;

    double latStep = (dropLatLng.latitude - pickupLatLng.latitude) / steps;
    double lngStep = (dropLatLng.longitude - pickupLatLng.longitude) / steps;

    Timer.periodic(
      Duration(milliseconds: (durationInSeconds * 1000 ~/ steps)),
      (timer) {
        if (currentStep >= steps) {
          timer.cancel();
          return;
        }
        currentStep++;

        LatLng newPosition = LatLng(
          pickupLatLng.latitude + latStep * currentStep,
          pickupLatLng.longitude + lngStep * currentStep,
        );

        setState(() {
          taxiMarker = Marker(
            markerId: const MarkerId("taxi"),
            position: newPosition,
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueGreen,
            ),
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final trip = ref.watch(tripProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("On Trip"),
        backgroundColor: Colors.yellow,
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: pickupLatLng,
              zoom: 14,
            ),
            onMapCreated: (controller) => _mapController = controller,
            markers: {
              Marker(markerId: const MarkerId("pickup"), position: pickupLatLng),
              Marker(markerId: const MarkerId("drop"), position: dropLatLng),
              taxiMarker,
            },
            polylines: {
              Polyline(
                polylineId: const PolylineId("route"),
                points: [pickupLatLng, dropLatLng],
                color: Colors.blue,
                width: 5,
              ),
            },
          ),
          Positioned(
            bottom: 20,
            left: 16,
            right: 16,
            child: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(16),
              child: GestureDetector(
                onTap: () {
                         ref.read(tripProvider.notifier).completeTrip();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const TripCompleteScreen()),
                            );
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Pickup: Ashok Nagar",
                        // "Pickup: ${trip.pickup}",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        // "Drop: ${trip.drop}",
                        "Drop: Periyar Nagar",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        // "Fare: ₹${trip.fare}",
                             "Fare: ₹300",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      if (trip.status == TripStatus.onTrip)
                        Text(
                          "Elapsed Time: ${trip.elapsedTime} sec",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      const SizedBox(height: 12),
                      if (trip.status == TripStatus.accepted)
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                          ),
                          onPressed: () {
                            showOtpDialog(
                              context,
                              ref,
                              () => simulateTaxiMovement(),
                            );
                          },
                          child: const Text("Start Trip"),
                        ),
                      if (trip.status == TripStatus.onTrip && trip.canCompleteTrip)
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                          onPressed: () {
                            ref.read(tripProvider.notifier).completeTrip();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const TripCompleteScreen()),
                            );
                          },
                          child: const Text("Complete Trip"),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        
        ],
      ),
    );
  }
}
