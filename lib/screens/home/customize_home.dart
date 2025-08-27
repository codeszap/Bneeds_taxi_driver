import 'package:bneeds_taxi_driver/screens/OnTripScreen.dart';
import 'package:bneeds_taxi_driver/widgets/common_drawer.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

// --- Providers ---
final driverNameProvider = StateProvider<String>((ref) => "John Doe");
final driverStatusProvider = StateProvider<bool>((ref) => true); // false = offline
final isProfileCompleteProvider = StateProvider<bool>((ref) => true);

// --- Ride Request Provider ---
final rideRequestProvider = StateProvider<RideRequest?>((ref) => null);

class RideRequest {
  final String pickup;
  final String drop;
  final int fare;

  RideRequest({required this.pickup, required this.drop, required this.fare});
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

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();

    // --- Listen for FCM ride requests ---
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.data.isNotEmpty) {
        final pickup = message.data['pickup'] ?? '';
        final drop = message.data['drop'] ?? '';
        final fare = int.tryParse(message.data['fare'] ?? '0') ?? 0;

        ref.read(rideRequestProvider.notifier).state = RideRequest(
          pickup: pickup,
          drop: drop,
          fare: fare,
        );
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

  @override
  Widget build(BuildContext context) {
    final isOnline = ref.watch(driverStatusProvider);
    final isProfileComplete = ref.watch(isProfileCompleteProvider);
    final rideRequest = ref.watch(rideRequestProvider);

    final bgColor = isOnline ? Colors.yellow : Colors.red;
    final textColor = isOnline ? Colors.black : Colors.white;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: bgColor,
        iconTheme: IconThemeData(color: textColor),
        elevation: 0,
        title: Text(
          isOnline ? "Online" : "Offline",
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        ),
        actions: [
          Switch(
            value: isOnline,
            activeColor: Colors.black,
            trackColor: MaterialStateProperty.all(
              isOnline ? Colors.yellow : Colors.redAccent,
            ),
            onChanged: (val) {
              ref.read(driverStatusProvider.notifier).state = val;
            },
          ),
        ],
      ),
      drawer: isProfileComplete ? CommonDrawer() : null,
      body: Stack(
        children: [
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
          if (rideRequest != null)
            Positioned(
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
                      Text("Pickup: ${rideRequest.pickup}",
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      Text("Drop: ${rideRequest.drop}",
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      Text("Fare: ₹${rideRequest.fare}",
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green),
                            onPressed: () {
                              ref
                                  .read(tripProvider.notifier)
                                  .acceptRide(
                                rideRequest.pickup,
                                rideRequest.drop,
                                rideRequest.fare,
                              );
                              ref.read(rideRequestProvider.notifier).state =
                              null;
                              context.go('/trip');
                            },
                            child: const Text("Accept"),
                          ),
                          ElevatedButton(
                            style:
                            ElevatedButton.styleFrom(backgroundColor: Colors.red),
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text("Ride Rejected ❌")));
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
            ),
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
                child: !isOnline
                    ? const Text(
                  "Switch to Online to receive rides",
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                )
                    : rideRequest == null
                    ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.local_taxi,
                        size: 44, color: Colors.black),
                    SizedBox(height: 8),
                    Text(
                      "Waiting for ride requests...",
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87),
                    ),
                  ],
                )
                    : const SizedBox(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
