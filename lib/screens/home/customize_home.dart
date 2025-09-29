
import 'package:bneeds_taxi_driver/screens/home/widget/ride_request_card.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bneeds_taxi_driver/utils/storage.dart';
import '../../models/rideRequest.dart';
import '../../utils/dialogs.dart';
import '../RideRequestScreen.dart';


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
    Future.microtask(() async {
      ref.read(driverLocationServiceProvider);
    });
    _listenForFCMMessages();

    // ✅ Check ongoing trip after app opens
    _checkOngoingTrip();
  }




  @override
  void dispose() {
    // _locationService.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _listenForFCMMessages() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      if (message.data.isNotEmpty) {
        final pickup = message.data['pickup'] ?? '';
        final drop = message.data['drop'] ?? '';
        final fareStr = message.data['fare'] ?? '0';
        final fare = (double.tryParse(fareStr.toString()) ?? 0).toInt();
        final bookingId = int.tryParse(message.data['bookingId'] ?? '0') ?? 0;
        final pickuplatlong = message.data['pickuplatlong'] ?? '';
        final droplatlong = message.data['droplatlong'] ?? '';
        final cusMobile = message.data['userMobNo'] ?? '';
        final userId = message.data['userId'] ?? '';

        final status = ref.read(driverStatusProvider); // Check if Online
        if (status == "OL") {
          // Only show if driver is online
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
          await _audioPlayer.play(AssetSource(Strings.rideRequestSound));
        }
      }
    });
  }

  LatLng stringToLatLng(String s) {
    final parts = s.split(',');
    return LatLng(double.parse(parts[0]), double.parse(parts[1]));
  }
  Future<void> _checkOngoingTrip() async {
    final tripData = await SharedPrefsHelper.getTripData();
    if (tripData != null) {
      // Update trip provider
      final pickupLatLng = stringToLatLng(tripData['pickupLatLng']);
      final dropLatLng = stringToLatLng(tripData['dropLatLng']);
      ref.read(tripProvider.notifier).acceptRide(
        tripData['pickup'],
        tripData['drop'],
        tripData['fare'],
        pickupLatLng,
        dropLatLng,
        tripData['otp'],
        tripData['bookingId'],
        tripData['fcmToken'],
        tripData['userId'],
        tripData['cusMobile'],
      );

      // Navigate to Trip Screen
      WidgetsBinding.instance.addPostFrameCallback((_) {
        router.go(AppRoutes.trip);
      });
    }
  }


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

  String generateOtp() {
    final random = Random();
    int otp = 1000 + random.nextInt(9000); // ensures 1000-9999
    return otp.toString();
  }

  LatLng parseLatLng(String latLongStr) {
    // Customer is sending "lat,lng" format
    final parts = latLongStr.split(',');
    if (parts.length != 2) {
      throw FormatException("Invalid LatLong format: $latLongStr");
    }
    final lat = double.parse(parts[0]);
    final lng = double.parse(parts[1]);
    return LatLng(lat, lng);
  }


  @override
  Widget build(BuildContext context) {
    final status = ref.watch(driverStatusProvider);
    final isProfileComplete = ref.watch(isProfileCompleteProvider);
    final rideRequest = ref.watch(rideRequestProvider);


    // --- Map Status -> Colors ---
    Color bgColor;
    Color textColor;

    if (status == "OL") {
      bgColor = AppColors.online;
      textColor = AppColors.buttonText;
    } else if (status == "RB") {
      bgColor = AppColors.rideBusy;
      textColor = AppColors.buttonText;
    } else {
      bgColor = AppColors.offline;
      textColor = AppColors.buttonText;
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
              activeToggleColor: AppColors.buttonText,
              inactiveToggleColor: AppColors.buttonText,
              activeColor: AppColors.online,
              inactiveColor: AppColors.offline,
              showOnOff: true,
              activeText: "Online",
              inactiveText: "Offline",
              activeTextColor: AppColors.buttonText,
              inactiveTextColor: AppColors.buttonText,
              onToggle: (val) async {
                String newStatus = val ? "OL" : "OF";

                // ✅ Play toggle sound
                await _audioPlayer.play(AssetSource(Strings.onOffSound));

                // ✅ UI update immediately
                ref.read(driverStatusProvider.notifier).state = newStatus;

                // ✅ Background API + location update
                Future.microtask(() async {
                  try {
                    final position = await Geolocator.getCurrentPosition(
                      desiredAccuracy: LocationAccuracy.high,
                    );
                    String fromLatLong =
                        "${position.latitude},${position.longitude}";

                    final repo = ref.read(driverRepositoryProvider);
                    final riderId = SharedPrefsHelper.getRiderId();

                    final response = await repo.updateDriverStatus(
                      riderId: riderId,
                      riderStatus: newStatus,
                      fromLatLong: fromLatLong,
                    );

                    if (response.status == "success") {
                      await SharedPrefsHelper.setDriverStatus(newStatus);
                    } else {
                      // rollback
                      ref.read(driverStatusProvider.notifier).state = val
                          ? "OF"
                          : "OL";
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("❌ ${response.message}")),
                      );
                    }
                  } catch (e) {
                    ref.read(driverStatusProvider.notifier).state = val
                        ? "OF"
                        : "OL";
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text("Error: $e")));
                  }
                });
              },
            ),
          ),

          // Current location button
          Positioned(
            right: 16,
            bottom: 160,
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
            RideRequestCard(
              rideRequest: rideRequest,
              audioPlayer: _audioPlayer,
            ),

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
                      color: AppColors.buttonText,
                    ),
                  )
                      : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(
                        Icons.local_taxi,
                        size: 44,
                        color: AppColors.buttonText,
                      ),
                      SizedBox(height: 8),
                      Text(
                        "Waiting for ride requests...",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.buttonText,
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

}
