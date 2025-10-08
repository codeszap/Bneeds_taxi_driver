import 'package:bneeds_taxi_driver/screens/home/widget/ride_request_card.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bneeds_taxi_driver/utils/storage.dart';
import '../../models/rideRequest.dart';
import '../../utils/dialogs.dart';
import '../RideRequestScreen.dart';
import '../onTrip/TripNotifier.dart';

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

    // Call async setup inside Future.microtask
    Future.microtask(() async {
      final savedStatus = await SharedPrefsHelper.getDriverStatus();
      final statusToSet = savedStatus ?? "OF";
      await setDriverStatus(statusToSet);
      initFirebaseMessaging(context, ref, _audioPlayer);
    });

  }


  @override
  void dispose() {
    // _locationService.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  // void _listenForFCMMessages() {
  //   FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
  //     if (message.data.isNotEmpty) {
  //       final pickup = message.data['pickup'] ?? '';
  //       final drop = message.data['drop'] ?? '';
  //       final fareStr = message.data['fare'] ?? '0';
  //       final fare = (double.tryParse(fareStr.toString()) ?? 0).toInt();
  //       final bookingId = int.tryParse(message.data['bookingId'] ?? '0') ?? 0;
  //       final pickuplatlong = message.data['pickuplatlong'] ?? '';
  //       final droplatlong = message.data['droplatlong'] ?? '';
  //       final cusMobile = message.data['userMobNo'] ?? '';
  //       final userId = message.data['userId'] ?? '';
  //
  //       final status = ref.read(driverStatusProvider); // Check if Online
  //       if (status == "OL") {
  //         // Only show if driver is online
  //         // Update the provider to show popup
  //         ref.read(rideRequestProvider.notifier).state = RideRequest(
  //           pickup: pickup,
  //           drop: drop,
  //           pickuplatlong: pickuplatlong.toString(),
  //           droplatlong: droplatlong.toString(),
  //           fare: fare,
  //           bookingId: bookingId,
  //           fcmToken: message.data['token'] ?? '',
  //           cusMobile: cusMobile,
  //           userId: userId,
  //         );
  //
  //         // Play looping ringtone
  //         await _audioPlayer.setReleaseMode(ReleaseMode.loop);
  //         await _audioPlayer.play(AssetSource(Strings.rideRequestSound));
  //       }
  //     }
  //   });
  // }

  // void _listenForFCMMessages() {
  //   FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
  //     if (message.data.isNotEmpty) {
  //       final status = message.data['status'] ?? '';
  //
  //       if (status == 'cancel ride') {
  //         // Stop ringtone
  //         await _audioPlayer.stop();
  //
  //         // Clear ride request provider
  //         ref.read(rideRequestProvider.notifier).state = null;
  //
  //         // Reset trip provider
  //         ref.read(tripProvider.notifier).reset();
  //
  //         // Show cancellation dialog
  //         if (mounted) {
  //           final rideRequest = ref.read(rideRequestProvider); // ✅ get current ride request
  //
  //           showGeneralDialog(
  //             context: context,
  //             barrierDismissible: false,
  //             barrierLabel: "Ride Cancelled",
  //             transitionDuration: const Duration(milliseconds: 300),
  //             pageBuilder: (context, animation, secondaryAnimation) {
  //               return Center(
  //                 child: Container(
  //                   width: MediaQuery.of(context).size.width * 0.85,
  //                   padding: const EdgeInsets.all(24),
  //                   decoration: BoxDecoration(
  //                     color: Colors.white,
  //                     borderRadius: BorderRadius.circular(20),
  //                     boxShadow: [
  //                       BoxShadow(
  //                         color: Colors.black26,
  //                         blurRadius: 20,
  //                         offset: Offset(0, 10),
  //                       ),
  //                     ],
  //                   ),
  //                   child: Material(
  //                     color: Colors.transparent,
  //                     child: Column(
  //                       mainAxisSize: MainAxisSize.min,
  //                       children: [
  //                         // Animated icon
  //                         Container(
  //                           padding: const EdgeInsets.all(20),
  //                           decoration: BoxDecoration(
  //                             color: Colors.redAccent.withOpacity(0.1),
  //                             shape: BoxShape.circle,
  //                           ),
  //                           child: const Icon(
  //                             Icons.cancel_outlined,
  //                             color: Colors.redAccent,
  //                             size: 60,
  //                           ),
  //                         ),
  //                         const SizedBox(height: 16),
  //
  //                         // Title
  //                         const Text(
  //                           "Ride Cancelled",
  //                           style: TextStyle(
  //                             fontSize: 22,
  //                             fontWeight: FontWeight.bold,
  //                             color: Colors.black87,
  //                           ),
  //                         ),
  //                         const SizedBox(height: 12),
  //
  //                         // Message
  //                         const Text(
  //                           "The customer has cancelled this ride.",
  //                           textAlign: TextAlign.center,
  //                           style: TextStyle(
  //                             fontSize: 16,
  //                             color: Colors.black54,
  //                             height: 1.4,
  //                           ),
  //                         ),
  //                         const SizedBox(height: 12),
  //
  //                         // Optional ride details
  //                         if (rideRequest != null) ...[
  //                           Divider(color: Colors.grey.shade300, thickness: 1),
  //                           const SizedBox(height: 8),
  //                           Text(
  //                             "Pickup: ${rideRequest.pickup}\nDrop: ${rideRequest.drop}\nFare: ₹${rideRequest.fare}",
  //                             textAlign: TextAlign.center,
  //                             style: const TextStyle(
  //                               fontSize: 15,
  //                               color: Colors.black87,
  //                               fontWeight: FontWeight.w500,
  //                             ),
  //                           ),
  //                           const SizedBox(height: 12),
  //                         ],
  //
  //                         // OK button
  //                         SizedBox(
  //                           width: double.infinity,
  //                           child: ElevatedButton(
  //                             style: ElevatedButton.styleFrom(
  //                               backgroundColor: Colors.redAccent,
  //                               padding: const EdgeInsets.symmetric(vertical: 16),
  //                               shape: RoundedRectangleBorder(
  //                                 borderRadius: BorderRadius.circular(12),
  //                               ),
  //                               elevation: 3,
  //                             ),
  //                             onPressed: () {
  //                               Navigator.of(context).pop(); // close dialog
  //                               Future.delayed(Duration.zero, () {
  //                                 context.go('/driverHome');
  //                               });
  //                             },
  //                             child: const Text(
  //                               "OK",
  //                               style: TextStyle(fontSize: 18, color: Colors.white),
  //                             ),
  //                           ),
  //                         ),
  //                       ],
  //                     ),
  //                   ),
  //                 ),
  //               );
  //             },
  //             transitionBuilder: (context, animation, secondaryAnimation, child) {
  //               return ScaleTransition(
  //                 scale: CurvedAnimation(
  //                   parent: animation,
  //                   curve: Curves.easeOutBack,
  //                 ),
  //                 child: FadeTransition(
  //                   opacity: animation,
  //                   child: child,
  //                 ),
  //               );
  //             },
  //           );
  //         }
  //
  //
  //
  //         return; // skip further processing
  //       }
  //
  //       // Existing ride request logic
  //       final pickup = message.data['pickup'] ?? '';
  //       final drop = message.data['drop'] ?? '';
  //       final fareStr = message.data['fare'] ?? '0';
  //       final fare = (double.tryParse(fareStr.toString()) ?? 0).toInt();
  //       final bookingId = int.tryParse(message.data['bookingId'] ?? '0') ?? 0;
  //       final pickuplatlong = message.data['pickuplatlong'] ?? '';
  //       final droplatlong = message.data['droplatlong'] ?? '';
  //       final cusMobile = message.data['userMobNo'] ?? '';
  //       final userId = message.data['userId'] ?? '';
  //
  //       final driverStatus = ref.read(driverStatusProvider);
  //       if (driverStatus == "OL") {
  //         ref.read(rideRequestProvider.notifier).state = RideRequest(
  //           pickup: pickup,
  //           drop: drop,
  //           pickuplatlong: pickuplatlong,
  //           droplatlong: droplatlong,
  //           fare: fare,
  //           bookingId: bookingId,
  //           fcmToken: message.data['token'] ?? '',
  //           cusMobile: cusMobile,
  //           userId: userId,
  //         );
  //
  //         // Play looping ringtone
  //         await _audioPlayer.setReleaseMode(ReleaseMode.loop);
  //         await _audioPlayer.play(AssetSource(Strings.rideRequestSound));
  //       }
  //     }
  //   });
  // }

  LatLng stringToLatLng(String s) {
    final parts = s.split(',');
    return LatLng(double.parse(parts[0]), double.parse(parts[1]));
  }
  // Future<void> _checkOngoingTrip() async {
  //   final tripData = await SharedPrefsHelper.getTripData();
  //   if (tripData != null) {
  //     // Update trip provider
  //     final pickupLatLng = stringToLatLng(tripData['pickupLatLng']);
  //     final dropLatLng = stringToLatLng(tripData['dropLatLng']);
  //     ref.read(tripProvider.notifier).acceptRide(
  //       tripData['pickup'],
  //       tripData['drop'],
  //       tripData['fare'],
  //       pickupLatLng,
  //       dropLatLng,
  //       tripData['otp'],
  //       tripData['bookingId'],
  //       tripData['fcmToken'],
  //       tripData['userId'],
  //       tripData['cusMobile'],
  //       tripData['status'],
  //       //true
  //     );
  //
  //     // Navigate to Trip Screen
  //     WidgetsBinding.instance.addPostFrameCallback((_) {
  //       router.go(AppRoutes.trip);
  //     });
  //   }
  // }

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
    int otp = 1000 + random.nextInt(9000);
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

  Future<void> setDriverStatus(String newStatus) async {
    // First, show CK state in UI
    ref.read(driverStatusProvider.notifier).state = "CK";

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      final fromLatLong = "${position.latitude},${position.longitude}";

      final repo = ref.read(driverRepositoryProvider);
      final riderId = SharedPrefsHelper.getRiderId();

      final response = await repo.updateDriverStatus(
        riderId: riderId,
        riderStatus: newStatus,
        fromLatLong: fromLatLong,
      );

      if (response.status == "success") {
        // ✅ update provider & local storage
        ref.read(driverStatusProvider.notifier).state = newStatus;
        await SharedPrefsHelper.setDriverStatus(newStatus);
      } else {
        // ❌ revert if failed
        final oldStatus = await SharedPrefsHelper.getDriverStatus() ?? "OF";
        ref.read(driverStatusProvider.notifier).state = oldStatus;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ ${response.message}")),
        );
      }
    } catch (e) {
      // ❌ revert on exception
      final oldStatus = await SharedPrefsHelper.getDriverStatus() ?? "OF";
      ref.read(driverStatusProvider.notifier).state = oldStatus;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
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
      body: RefreshIndicator(
        onRefresh: () async {},
        child: Stack(
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
                  final newStatus = val ? "OL" : "OF";

                  // ✅ First set CK
                  ref.read(driverStatusProvider.notifier).state = "CK";
                  await _audioPlayer.stop();
                  // ✅ Play toggle sound
                  await _audioPlayer.play(AssetSource(Strings.onOffSound));
                  await setDriverStatus(newStatus);
                  // try {
                  //   final position = await Geolocator.getCurrentPosition(
                  //     desiredAccuracy: LocationAccuracy.high,
                  //   );
                  //   final fromLatLong =
                  //       "${position.latitude},${position.longitude}";
                  //
                  //   final repo = ref.read(driverRepositoryProvider);
                  //   final riderId = SharedPrefsHelper.getRiderId();
                  //
                  //   final response = await repo.updateDriverStatus(
                  //     riderId: riderId,
                  //     riderStatus: newStatus,
                  //     fromLatLong: fromLatLong,
                  //   );
                  //
                  //   if (response.status == "success") {
                  //     ref.read(driverStatusProvider.notifier).state = newStatus;
                  //     await SharedPrefsHelper.setDriverStatus(newStatus);
                  //   } else {
                  //     ref.read(driverStatusProvider.notifier).state = val
                  //         ? "OF"
                  //         : "OL";
                  //     ScaffoldMessenger.of(context).showSnackBar(
                  //       SnackBar(content: Text("❌ ${response.message}")),
                  //     );
                  //   }
                  // } catch (e) {
                  //   ref.read(driverStatusProvider.notifier).state = val
                  //       ? "OF"
                  //       : "OL";
                  //   ScaffoldMessenger.of(
                  //     context,
                  //   ).showSnackBar(SnackBar(content: Text("Error: $e")));
                  // }
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
            // if (rideRequest != null && status == "OL")
            //   RideRequestCard(
            //     rideRequest: rideRequest,
            //     audioPlayer: _audioPlayer,
            //   ),

            // Bottom panel
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
                        : status ==
                              "CK" // ✅ new state
                        ? const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(
                                color: AppColors.buttonText,
                              ),
                              SizedBox(height: 12),
                              Text(
                                "Checking status...",
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.buttonText,
                                ),
                              ),
                            ],
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
      ),
    );
  }
}
