import 'dart:math';

import 'package:bneeds_taxi_driver/providers/booking_provider.dart';
import 'package:bneeds_taxi_driver/repositories/profile_repository.dart';
import 'package:bneeds_taxi_driver/screens/OnTripScreen.dart';
import 'package:bneeds_taxi_driver/services/FirebasePushService.dart';
import 'package:bneeds_taxi_driver/widgets/common_drawer.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_switch/flutter_switch.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../providers/driverStatusProvider.dart';

// --- Providers ---
final driverNameProvider = StateProvider<String>((ref) => "John Doe");

final isProfileCompleteProvider = StateProvider<bool>((ref) => true);

// --- Ride Request Provider ---
final rideRequestProvider = StateProvider<RideRequest?>((ref) => null);

final driverRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository();
});

class RideRequest {
  final String pickup;
  final String drop;
  final int fare;
  final int bookingId;
  final String fcmToken;
  final String pickuplatlong; // <-- must be String
  final String droplatlong;   // <-- must be String
  final String cusMobile;
  final String userId;

  RideRequest({
    required this.pickup,
    required this.drop,
    required this.fare,
    required this.bookingId,
    required this.fcmToken,
    required this.pickuplatlong,
    required this.droplatlong,
    required this.cusMobile,
    required this.userId,
  });
}


class DriverHomeScreen extends ConsumerStatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  ConsumerState<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends ConsumerState<DriverHomeScreen> {
  GoogleMapController? _mapController;
  LatLng? _currentLocation;
  Set<Marker> _markers = {};
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();

    // restore saved driver status from SharedPreferences
    _restoreDriverStatus();

    // start FCM listener (moved out of inline initState)
    _listenForFCMMessages();
  }

  // restore saved driver status (called from initState)
  Future<void> _restoreDriverStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedStatus = prefs.getString("driverStatus") ?? "";

      if (savedStatus.isNotEmpty) {
        // update riverpod provider
        ref.read(driverStatusProvider.notifier).state = savedStatus;
      }
    } catch (e) {
      // optional: print or ignore
      debugPrint("Failed to restore driver status: $e");
    }
  }

// moved FCM listener into its own function
  void _listenForFCMMessages() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      if (message.data.isNotEmpty) {
        final pickup = message.data['pickup'] ?? '';
        final drop = message.data['drop'] ?? '';
        final fare = int.tryParse(message.data['fare'] ?? '0') ?? 0;
        final bookingId = int.tryParse(message.data['bookingId'] ?? '0') ?? 0;
        final pickuplatlong = message.data['pickuplatlong'] ?? '';
        final droplatlong = message.data['droplatlong'] ?? '';
        final cusMobile = message.data['userMobNo'] ?? '';
        final userId = message.data['userId'] ?? '';

        final status = ref.read(driverStatusProvider); // Check if Online
        if (status == "OL") {     // Only show if driver is online
          // Update the provider to show popup
          ref.read(rideRequestProvider.notifier).state = RideRequest(
            pickup: pickup,
            drop: drop,
            pickuplatlong: pickuplatlong.toString(),
            droplatlong: droplatlong.toString(),
            fare: fare,
            bookingId: bookingId,
            fcmToken: message.data['token'] ?? '',
            cusMobile: cusMobile,
            userId: userId,
          );

          // Play looping ringtone
          await _audioPlayer.setReleaseMode(ReleaseMode.loop);
          await _audioPlayer.play(AssetSource('sounds/ride_request.mp3'));
        }
      }
    });
  }


  // ✅ Get Current Location & Show Marker
  Future<void> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    if (permission == LocationPermission.deniedForever) return;

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    setState(() {
      _currentLocation = LatLng(position.latitude, position.longitude);
      _markers = {
        Marker(
          markerId: const MarkerId("currentLocation"),
          position: _currentLocation!,
          infoWindow: const InfoWindow(title: "You are here"),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ),
      };
    });

    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: _currentLocation!, zoom: 16),
      ),
    );
  }

// Generate 4-digit OTP
  String generateOtp() {
    final random = Random();
    int otp = 1000 + random.nextInt(9000); // ensures 1000-9999
    return otp.toString();
  }

  LatLng parseLatLng(String latLongStr) {
    // Example input: "Latitude: 9.931449, Longitude: 78.1098963"
    final latMatch = RegExp(r'Latitude:\s*([-\d.]+)').firstMatch(latLongStr);
    final lngMatch = RegExp(r'Longitude:\s*([-\d.]+)').firstMatch(latLongStr);

    if (latMatch == null || lngMatch == null) {
      throw FormatException("Invalid LatLong format: $latLongStr");
    }

    final lat = double.parse(latMatch.group(1)!);
    final lng = double.parse(lngMatch.group(1)!);

    return LatLng(lat, lng);
  }



  @override
  Widget build(BuildContext context) {
    final status = ref.watch(driverStatusProvider); // "OL", "OF", "RB"
    final isProfileComplete = ref.watch(isProfileCompleteProvider);
    final rideRequest = ref.watch(rideRequestProvider);

    // --- Map Status -> Colors ---
    Color bgColor;
    Color textColor;

    if (status == "OL") {
      bgColor = Colors.yellow;
      textColor = Colors.black;
    } else if (status == "RB") {
      bgColor = Colors.green;
      textColor = Colors.white;
    } else {
      // "OF"
      bgColor = Colors.red;
      textColor = Colors.white;
    }

    return Scaffold(
      drawer: isProfileComplete ? CommonDrawer() : null,
      body: Stack(
        children: [
          // Google Map
          GoogleMap(
            onMapCreated: (controller) => _mapController = controller,
            initialCameraPosition: CameraPosition(
              target: _currentLocation ?? const LatLng(12.9716, 77.5946),
              zoom: 14,
            ),
            markers: _markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
          ),

          // Drawer button (hamburger icon)
          Positioned(
            top: 40,
            left: 16,
            child: Builder(
              builder: (context) => InkWell(
                onTap: () => Scaffold.of(context).openDrawer(),
                borderRadius: BorderRadius.circular(30),
                child: CircleAvatar(
                  backgroundColor: bgColor,
                  radius: 24, // adjust size as needed
                  child: Icon(Icons.menu, color: textColor),
                ),
              ),
            ),
          ),


          // Online/Offline toggle
          Positioned(
            top: 40,
            right: 16,
            child: FlutterSwitch(
              width: 100,
              height: 35,
              toggleSize: 28,
              value: status == "OL",
              borderRadius: 30,
              padding: 4,
              activeToggleColor: Colors.white,
              inactiveToggleColor: Colors.white,
              activeColor: Colors.green,
              inactiveColor: Colors.redAccent,
              showOnOff: true,
              activeText: "Online",
              inactiveText: "Offline",
              activeTextColor: Colors.white,
              inactiveTextColor: Colors.white,
                onToggle: (val) async {
                  String newStatus = val ? "OL" : "OF";

                  // ✅ Play toggle sound
                  await _audioPlayer.play(
                    AssetSource(val ? 'sounds/on-off.mp3' : 'sounds/on-off.mp3'),
                  );

                  // ✅ UI update immediately
                  ref.read(driverStatusProvider.notifier).state = newStatus;

                  // ✅ Background API + location update
                  Future.microtask(() async {
                    try {
                      final position = await Geolocator.getCurrentPosition(
                        desiredAccuracy: LocationAccuracy.high,
                      );
                      String fromLatLong = "${position.latitude},${position.longitude}";

                      final repo = ref.read(driverRepositoryProvider);
                      final prefs = await SharedPreferences.getInstance();
                      final riderId = prefs.getString('riderId') ?? "";

                      final response = await repo.updateDriverStatus(
                        riderId: riderId,
                        riderStatus: newStatus,
                        fromLatLong: fromLatLong,
                      );

                      if (response.status == "success") {
                        await prefs.setString("driverStatus", newStatus);
                      } else {
                        // rollback
                        ref.read(driverStatusProvider.notifier).state = val ? "OF" : "OL";
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("❌ ${response.message}")),
                        );
                      }
                    } catch (e) {
                      ref.read(driverStatusProvider.notifier).state = val ? "OF" : "OL";
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Error: $e")),
                      );
                    }
                  });
                }

            ),
          ),

          // Current location button
          Positioned(
            right: 16,
            bottom: 180,
            child: FloatingActionButton(
              mini: true,
              backgroundColor: bgColor,
              onPressed: () {
                if (_currentLocation != null) {
                  _mapController?.animateCamera(
                    CameraUpdate.newCameraPosition(
                      CameraPosition(target: _currentLocation!, zoom: 16),
                    ),
                  );
                }
              },
              child: Icon(Icons.my_location, color: textColor),
            ),
          ),

          // Ride request popup
          if (rideRequest != null && status == "OL")
            _buildRideRequestCard(context, rideRequest),

          // Bottom panel
          if (rideRequest == null)
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10,
                      offset: Offset(0, -3),
                    ),
                  ],
                ),
                height: 160,
                child: Center(
                  child: status == "OF"
                      ? const Text(
                    "Switch to Online to receive rides",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  )
                      : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(
                        Icons.local_taxi,
                        size: 44,
                        color: Colors.black,
                      ),
                      SizedBox(height: 8),
                      Text(
                        "Waiting for ride requests...",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
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

  Widget _buildRideRequestCard(BuildContext context, RideRequest rideRequest) {
    final ref = ProviderScope.containerOf(context); // Riverpod access

    return Positioned(
      top: 20,
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Pickup: ${rideRequest.pickup}",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                "Drop: ${rideRequest.drop}",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                "Fare: ₹${rideRequest.fare}",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    onPressed: () async {
                      _audioPlayer.stop(); // Stop ringtone

                      final repo = ref.read(acceptBookingRepositoryProvider);
                      try {
                        final prefs = await SharedPreferences.getInstance();
                        final riderId = prefs.getString('riderId') ?? "";
                        prefs.setString('bookingId', rideRequest.bookingId.toString());
                        print("Pickup LatLong: ${rideRequest.pickuplatlong}");
                        print("Drop LatLong: ${rideRequest.droplatlong}");
                        final response = await repo.getAcceptBookingStatus(
                          rideRequest.bookingId,
                          int.parse(riderId),
                        );

                        if (response.isEmpty) {
                          await showApiResponseDialog(
                            context,
                            status: 'error',
                            message: 'Something went wrong!',
                          );
                          return;
                        }

                        final apiResp = response.first;
                        await showApiResponseDialog(
                          context,
                          status: apiResp.status ?? 'error',
                          message: apiResp.message ?? 'Unknown error',
                        );




                        // ✅ If success, navigate and send push notification
                        if ((apiResp.status ?? '').toLowerCase() == 'success') {
                          final pickupLatLng = parseLatLng(rideRequest.pickuplatlong);
                          final dropLatLng = parseLatLng(rideRequest.droplatlong);
                          final otp = generateOtp();
                          ref.read(tripProvider.notifier).acceptRide(
                            rideRequest.pickup,
                            rideRequest.drop,
                            rideRequest.fare,
                            pickupLatLng,
                            dropLatLng,
                            otp,
                            rideRequest.bookingId.toString(),
                            rideRequest.fcmToken,
                            rideRequest.userId,
                            rideRequest.cusMobile,
                          );


                          ref.read(rideRequestProvider.notifier).state = null;

                          context.go('/trip');


                          // --- Send push notification to rider ---
                          final customerFcm = rideRequest.fcmToken;
                          if (customerFcm != null && customerFcm.isNotEmpty) {
                            await FirebasePushService.sendPushNotification(
                              fcmToken: customerFcm,
                              title: "Ride Accepted ✅",
                              body:
                                  "Your ride request has been accepted by the driver.",
                              data: {
                                "bookingId": rideRequest.bookingId.toString(),
                                "status": "accepted",
                                "otp": otp,
                                "driverLatLong": _currentLocation != null
                                    ? "${_currentLocation!.latitude},${_currentLocation!.longitude}"
                                    : "",
                              },
                            );
                          }
                        }

                      } catch (e) {
                        await showApiResponseDialog(
                          context,
                          status: 'error',
                          message: 'Failed to accept ride: $e',
                        );
                      }
                    },
                    child: const Text("Accept"),
                  ),

                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    onPressed: () {
                      _audioPlayer.stop(); // Stop the ringtone
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Ride Rejected ❌")),
                      );
                      ref.read(rideRequestProvider.notifier).state = null;
                    },
                    child: const Text("Reject"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> showApiResponseDialog(
  BuildContext context, {
  required String status,
  required String message,
}) async {
  final isSuccess = status.toLowerCase() == 'success';
  await showDialog(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Icon(
        isSuccess ? Icons.check_circle : Icons.error,
        color: isSuccess ? Colors.green : Colors.red,
        size: 48,
      ),
      content: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("OK"),
        ),
      ],
    ),
  );
}
