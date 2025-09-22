import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import '../services/FirebasePushService.dart';
import 'TripCompleteScreen.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';

enum TripStatus { idle, accepted, onTrip, completed }

class TripState {
  final String pickup;
  final String drop;
  final int fare;
  final LatLng pickupLatLng;
  final LatLng dropLatLng;
  final TripStatus status;
  final int elapsedTime;
  final bool canCompleteTrip;
  final String otp;
  final String fcmToken;      // ← add this
  final String bookingId;     // ← add this

  TripState({
    this.pickup = '',
    this.drop = '',
    this.fare = 0,
    this.pickupLatLng = const LatLng(0, 0),
    this.dropLatLng = const LatLng(0, 0),
    this.status = TripStatus.idle,
    this.elapsedTime = 0,
    this.canCompleteTrip = false,
    this.otp = '',
    this.fcmToken = '',       // ← default
    this.bookingId = '',      // ← default
  });

  TripState copyWith({
    String? pickup,
    String? drop,
    int? fare,
    LatLng? pickupLatLng,
    LatLng? dropLatLng,
    TripStatus? status,
    int? elapsedTime,
    bool? canCompleteTrip,
    String? otp,
    String? fcmToken,
    String? bookingId,
  }) {
    return TripState(
      pickup: pickup ?? this.pickup,
      drop: drop ?? this.drop,
      fare: fare ?? this.fare,
      pickupLatLng: pickupLatLng ?? this.pickupLatLng,
      dropLatLng: dropLatLng ?? this.dropLatLng,
      status: status ?? this.status,
      elapsedTime: elapsedTime ?? this.elapsedTime,
      canCompleteTrip: canCompleteTrip ?? this.canCompleteTrip,
      otp: otp ?? this.otp,
      fcmToken: fcmToken ?? this.fcmToken,
      bookingId: bookingId ?? this.bookingId,
    );
  }
}


class TripNotifier extends StateNotifier<TripState> {
  Timer? _timer;

  TripNotifier() : super(TripState());

  void acceptRide(
      String pickup,
      String drop,
      int fare,
      LatLng pickupLatLng,
      LatLng dropLatLng,
      String otp,
      String bookingId,
      String fcmToken,
      ) {
    state = TripState(
      pickup: pickup,
      drop: drop,
      fare: fare,
      pickupLatLng: pickupLatLng,
      dropLatLng: dropLatLng,
      status: TripStatus.accepted,
      otp: otp,
      bookingId: bookingId,   // ← save bookingId
      fcmToken: fcmToken,     // ← save fcmToken
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
        state = state.copyWith(canCompleteTrip: true);
      }
    });
  }



  void completeTrip() async {
    // Generate random fare between 200 and 500
    final random = Random();
    final fareAmount = 200 + random.nextInt(301); // 200..500

    // Update state with completed status and fare
    state = state.copyWith(
      status: TripStatus.completed,
      fare: fareAmount,  // <-- here
    );

    // Send push notification to customer
    if (state.fcmToken.isNotEmpty) {
      await FirebasePushService.sendPushNotification(
        fcmToken: state.fcmToken,
        title: "Ride Completed ✅",
        body: "Your trip has been completed. Fare: ₹$fareAmount",
        data: {
          "bookingId": state.bookingId,
          "status": "completed_trip",
          "driverLatLong": state.dropLatLng.toString(),
          "otp": state.otp,
          "fareAmount": fareAmount.toString(),
        },
      );
    }
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
    String realOtp,
    String customerFcm,     // add customer FCM token
    String bookingId, LatLng pickupLatLng, String pickup,       // add booking ID
    ) async {

  const int otpLength = 4;

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
          void submitOtp() async {
            final otp = controllers.map((c) => c.text).join();
            if (otp == realOtp) {
              Navigator.of(dialogContext).pop();

              // Start taxi simulation
              simulateTaxiMovement();

              // Start trip in Riverpod state
              ref.read(tripProvider.notifier).startAutoTrip();

              // Send push notification to customer
              await FirebasePushService.sendPushNotification(
                fcmToken: customerFcm,
                title: "Ride Started✅",
                body: "Your ride has started. Sit back and relax!",
                data: {
                  "bookingId": bookingId.toString(),
                  "status": "start trip",
                  "driverLatLong": pickupLatLng.toString(),
                  "otp": otp.toString(),
                },
              );
            } else {
              setState(() => isError = true);
            }
          }


          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
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
                            borderSide: const BorderSide(color: Colors.grey, width: 2),
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
  Marker taxiMarker = Marker(
    markerId: const MarkerId("taxi"),
    position: const LatLng(0, 0),
    icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
  );
  List<LatLng> polylineCoordinates = [];


  Future<void> getRoute(LatLng start, LatLng end) async {
    const String googleApiKey = "AIzaSyAWzUqf3Z8xvkjYV7F4gOGBBJ5d_i9HZhs";

    // Create PolylinePoints instance
    PolylinePoints polylinePoints = PolylinePoints(apiKey: googleApiKey);

    // Create the PolylineRequest
    final request = PolylineRequest(
      origin: PointLatLng(start.latitude, start.longitude),
      destination: PointLatLng(end.latitude, end.longitude),
       mode: TravelMode.driving,
    );

    // Get the route
    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
      request: request,
    );

    // Convert the result to LatLng points
    if (result.status == 'OK' && result.points.isNotEmpty) {
      polylineCoordinates = result.points
          .map((point) => LatLng(point.latitude, point.longitude))
          .toList();
    } else {
      print('Error getting directions: ${result.errorMessage}');
    }
  }


  void simulateTaxiMovementAlongRoute(List<LatLng> routePoints, {int durationInSeconds = 10}) {
    if (routePoints.isEmpty) return;

    int steps = routePoints.length;
    int currentStep = 0;

    Timer.periodic(
      Duration(milliseconds: (durationInSeconds * 1000 ~/ steps)),
          (timer) {
        if (currentStep >= steps) {
          timer.cancel();
          return;
        }

        setState(() {
          taxiMarker = Marker(
            markerId: const MarkerId("taxi"),
            position: routePoints[currentStep],
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          );
        });
        currentStep++;
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
              target: trip.pickupLatLng,
              zoom: 14,
            ),
            onMapCreated: (controller) => _mapController = controller,
            markers: {
              Marker(markerId: const MarkerId("pickup"), position: trip.pickupLatLng),
              Marker(markerId: const MarkerId("drop"), position: trip.dropLatLng),
              taxiMarker,
            },
            polylines: {
              Polyline(
                polylineId: const PolylineId("route"),
                points: polylineCoordinates, // ✅ real route
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
                    Text("Pickup: ${trip.pickup}", style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text("Drop: ${trip.drop}", style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text("Fare: ₹${trip.fare}", style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    if (trip.status == TripStatus.onTrip)
                      Text("Elapsed Time: ${trip.elapsedTime} sec", style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    if (trip.status == TripStatus.accepted)
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                        onPressed: () async {
                          await getRoute(trip.pickupLatLng, trip.dropLatLng); // fetch route

                          await showOtpDialog(
                            context,
                            ref,
                                () => simulateTaxiMovementAlongRoute(polylineCoordinates),
                            trip.otp,
                            trip.fcmToken,      
                            trip.bookingId,  
                            trip.pickupLatLng,
                            trip.pickup
                          );
                        },
                        child: const Text("Start Trip"),
                      ),


                    if (trip.status == TripStatus.onTrip && trip.canCompleteTrip)
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                        onPressed: () {
                          ref.read(tripProvider.notifier).completeTrip();
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const TripCompleteScreen()));
                        },
                        child: const Text("Complete Trip"),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
