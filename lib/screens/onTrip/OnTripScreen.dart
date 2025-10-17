import 'package:bneeds_taxi_driver/screens/onTrip/widget/TripCustomerInfoDialog.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:bneeds_taxi_driver/utils/storage.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../../models/TripState.dart';
import '../../repositories/vehicle_type_repository.dart';
import '../../utils/otp_dialog.dart';
import 'TripNotifier.dart';


/// ------------------ OTP Dialog ------------------

/// ------------------ OnTripScreen ------------------
class OnTripScreen extends ConsumerStatefulWidget {
  const OnTripScreen({super.key});

  @override
  ConsumerState<OnTripScreen> createState() => _OnTripScreenState();
}

class _OnTripScreenState extends ConsumerState<OnTripScreen> {
  // Inside your ConsumerState<_OnTripScreenState>
  UserProfile? userProfile;
  bool showCustomerInfo = false;
  final PageController _pageController = PageController(viewportFraction: 0.95);
  int currentPage = 0;
  StreamSubscription<Position>? _positionStream;
  Position? _currentPosition;
  double _lastRouteLat = 0;
  double _lastRouteLng = 0;
  double routeUpdateThreshold = 20; // meters
  List<LatLng> pickupPolyline = [];
  List<LatLng> dropPolyline = [];
  bool showInfoPanel = false;
  bool _otpShown = false; // to avoid showing OTP dialog repeatedly
  List<LatLng> polylineCoordinates = [];
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    fetchUserProfile();
    WakelockPlus.enable();
    Future.microtask(() async {
      await _initForTrip();
    });
  }

  Future<void> _initForTrip() async {
    final hasPermission = await _checkLocationPermission();
    if (!hasPermission) return;

    await ref.read(tripProvider.notifier).loadTripFromPrefs();
    final trip = ref.read(tripProvider);

    LatLng startLatLng;
    LatLng endLatLng;

    if (trip.status == TripStatus.accepted) {
      startLatLng = LatLng(
        _currentPosition?.latitude ?? trip.pickupLatLng.latitude,
        _currentPosition?.longitude ?? trip.pickupLatLng.longitude,
      );
      endLatLng = trip.pickupLatLng;
    } else if (trip.status == TripStatus.onTrip) {
      startLatLng = LatLng(
        _currentPosition?.latitude ??
            trip.driverCurrentLatLng?.latitude ??
            trip.pickupLatLng.latitude,
        _currentPosition?.longitude ??
            trip.driverCurrentLatLng?.longitude ??
            trip.pickupLatLng.longitude,
      );
      endLatLng = trip.dropLatLng;
    } else {
      return;
    }

    await getRoute(startLatLng, endLatLng);

    // Move camera
    // _moveCameraToFitBounds();

   // _focusDriverAndPickup();

    // Resume trip timer if needed
    if (trip.status == TripStatus.onTrip) {
      ref
          .read(tripProvider.notifier)
          .startAutoTrip(resumeFrom: trip.elapsedTime);
    }

    // Restore taxi marker
    setState(() {
      taxiMarker = taxiMarker.copyWith(
        positionParam: trip.driverCurrentLatLng ?? trip.pickupLatLng,
      );
    });

    // Start live tracking
    _startLiveTracking();
  }

  void _startLiveTracking() async {
    final hasPermission = await _checkLocationPermission();
    if (!hasPermission) return;

    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5,
    );

    _positionStream?.cancel();
    _positionStream =
        Geolocator.getPositionStream(
          locationSettings: locationSettings,
        ).listen((Position pos) {
          _currentPosition = pos;
          final newLatLng = LatLng(pos.latitude, pos.longitude);

          setState(() {
            taxiMarker = taxiMarker.copyWith(positionParam: newLatLng);
          });

          _mapController?.animateCamera(CameraUpdate.newLatLng(newLatLng));

          final trip = ref.watch(tripProvider);

          // -----------------------------
          // Pickup Geofence
          // -----------------------------
          if (trip.status == TripStatus.accepted && !_otpShown) {
            double radius = 50; // meters
            double distanceToPickup = Geolocator.distanceBetween(
              pos.latitude,
              pos.longitude,
              trip.pickupLatLng.latitude,
              trip.pickupLatLng.longitude,
            );

            if (distanceToPickup <= radius) {
              _otpShown = true; // prevent duplicate
              ref.read(tripProvider.notifier).updateCanStartTrip(true);

              if (trip.fcmToken.isNotEmpty) {
                FirebasePushService.sendPushNotification(
                  fcmToken: trip.fcmToken,
                  title: "Driver Arrived at Pickup ✅",
                  body: "Your driver has arrived at the pickup location.",
                  data: {
                    "bookingId": trip.bookingId,
                    "status": "arrived_pickup",
                  },
                );
              }
            }
          }
          // -----------------------------
          // Auto Drop Geofence
          // -----------------------------
          else if (trip.status == TripStatus.onTrip) {
            double dropRadius = 30; // meters
            double distanceToDrop = Geolocator.distanceBetween(
              pos.latitude,
              pos.longitude,
              trip.dropLatLng.latitude,
              trip.dropLatLng.longitude,
            );

            // if (distanceToDrop <= dropRadius) {
            //   _stopLiveTracking();
            //   // ref
            //   //     .read(tripProvider.notifier)
            //   //     .completeTrip(); // sends notification
            // }
          }

          // -----------------------------
          // Auto Recalculate Route
          // -----------------------------
          double distFromLastRoute = Geolocator.distanceBetween(
            pos.latitude,
            pos.longitude,
            _lastRouteLat,
            _lastRouteLng,
          );

          if (distFromLastRoute > routeUpdateThreshold) {
            _lastRouteLat = pos.latitude;
            _lastRouteLng = pos.longitude;

            if (trip.status == TripStatus.accepted) {
              getRoute(newLatLng, trip.pickupLatLng); // recalc route to pickup
            } else if (trip.status == TripStatus.onTrip) {
              getRoute(newLatLng, trip.dropLatLng); // recalc route to drop
            }
          }
        });
  }

  Future<void> getRoute(LatLng start, LatLng end) async {
    const String googleApiKey = Strings.googleApiKey;

    print("getRoute called");
    print("Start: ${start.latitude}, ${start.longitude}");
    print("End: ${end.latitude}, ${end.longitude}");

    // Use the legacy PolylinePoints instance
    PolylinePoints polylinePoints = PolylinePoints.legacy(googleApiKey);

    // Create a PolylineRequest
    final request = PolylineRequest(
      origin: PointLatLng(start.latitude, start.longitude),
      destination: PointLatLng(end.latitude, end.longitude),
      mode: TravelMode.driving,
    );

    // Call the legacy API
    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
      request: request,
    );

    print("Polyline result status: ${result.status}");
    print("Polyline error message: ${result.errorMessage}");
    print("Number of points received: ${result.points.length}");

    if (result.status == 'OK' && result.points.isNotEmpty) {
      setState(() {
        polylineCoordinates = result.points
            .map((point) => LatLng(point.latitude, point.longitude))
            .toList();
      });
      // Move camera here to ensure polyline is drawn
      // if (_mapController != null) {
      //   _moveCameraToFitBounds();
      // }
      if (_mapController != null) {
        final trip = ref.read(tripProvider);

        if (trip.status == TripStatus.accepted) {
          // Before starting trip: focus on driver + pickup
          _focusDriverAndPickup();
        } else if (trip.status == TripStatus.onTrip) {
          // After trip started: focus on pickup + drop
          _focusPickupAndDrop();
        }
      }
    } else {
      print('Error getting directions: ${result.errorMessage}');
    }
  }

  void _stopLiveTracking() {
    _positionStream?.cancel();
    _positionStream = null;
    _otpShown = false;

    _lastRouteLat = 0;
    _lastRouteLng = 0;
  }

  void _testmoveTaxiToPickup() async {
    final trip = ref.read(tripProvider);

    // Update state to accepted
    ref.read(tripProvider.notifier).updateCanStartTrip(false);

    // Move taxi instantly (or animate if you want)
    setState(() {
      taxiMarker = taxiMarker.copyWith(positionParam: trip.pickupLatLng);
    });

    // // Send push notification
    // if (trip.fcmToken.isNotEmpty) {
    //   await FirebasePushService.sendPushNotification(
    //     fcmToken: trip.fcmToken,
    //     title: "Driver Arrived at Pickup ✅",
    //     body: "Your driver has arrived at the pickup location.",
    //     data: {"bookingId": trip.bookingId, "status": "arrived_pickup"},
    //   );
    // }

    // Enable Drop button
    ref.read(tripProvider.notifier).updateCanStartTrip(true);
  }

  void _testmoveTaxiToDrop() async {
    final trip = ref.read(tripProvider);

    // Move taxi instantly to drop location
    setState(() {
      taxiMarker = taxiMarker.copyWith(positionParam: trip.dropLatLng);
    });

    await SharedPrefsHelper.clearTripData();
    await ref.read(tripProvider.notifier).completeTrip();
    _stopLiveTracking();

    // Navigate to TripCompleteScreen
    if (mounted) {
      context.go(AppRoutes.tripComplete); // <-- use your GoRouter route
    }
  }

  void _moveTaxiToPickup() async {
    final trip = ref.read(tripProvider);

    if (_currentPosition == null) return;

    double distanceToPickup = Geolocator.distanceBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      trip.pickupLatLng.latitude,
      trip.pickupLatLng.longitude,
    );

    const pickupRadius = 50; // meters

    if (distanceToPickup <= pickupRadius) {
      // Move taxi marker
      setState(() {
        taxiMarker = taxiMarker.copyWith(positionParam: trip.pickupLatLng);
      });

      ref.read(tripProvider.notifier).updateCanStartTrip(true);

      // Push notification
      if (trip.fcmToken.isNotEmpty) {
        FirebasePushService.sendPushNotification(
          fcmToken: trip.fcmToken,
          title: "Driver Arrived at Pickup ✅",
          body: "Your driver has arrived at the pickup location.",
          data: {"bookingId": trip.bookingId, "status": "arrived_pickup"},
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "You are too far from pickup location to start the trip.",
          ),
        ),
      );
    }
  }

  void _moveTaxiToDrop() async {
    final trip = ref.read(tripProvider);

    if (_currentPosition == null) return;

    double distanceToDrop = Geolocator.distanceBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      trip.dropLatLng.latitude,
      trip.dropLatLng.longitude,
    );

    const dropRadius = 30; // meters

  //  if (distanceToDrop <= dropRadius) {
      // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false, // Force the driver to choose
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle_outline,
                    size: 60, color: Colors.green),
                const SizedBox(height: 16),
                const Text(
                  "Complete Trip?",
                  style: TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                const Text(
                  "Are you sure you want to complete this trip?",
                  style: TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text("Cancel"),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        backgroundColor: Colors.green,
                      ),
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text(
                        "Confirm",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        );
      },
    );


    // If driver confirms
      if (confirm == true) {
        setState(() {
          taxiMarker = taxiMarker.copyWith(positionParam: trip.dropLatLng);
        });

        await SharedPrefsHelper.clearTripData();
        await ref.read(tripProvider.notifier).completeTrip();

        if (mounted) {
          context.go(AppRoutes.tripComplete);
        }
      }
    // } else {
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     const SnackBar(
    //       content: Text(
    //         "You are too far from drop location to complete the trip.",
    //       ),
    //     ),
    //   );
    // }
  }


  @override
  void dispose() {
    _positionStream?.cancel();
    _mapController?.dispose();
    _pageController.dispose();
    WakelockPlus.disable();
    super.dispose();
  }

  void _onOtpVerified() async {
    final tripNotifier = ref.read(tripProvider.notifier);

    LatLng driverLatLng = _currentPosition != null
        ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
        : ref.read(tripProvider).pickupLatLng;

    // Save driver location
    tripNotifier.setDriverCurrentLocation(driverLatLng);

    // Complete pickup first
    tripNotifier.completePickup();

    // Clear old pickup polyline
    setState(() {
      polylineCoordinates.clear();
    });

    // Draw route to drop
    await getRoute(driverLatLng, ref.read(tripProvider).dropLatLng);

    // Move camera AFTER polyline ready
    //_moveCameraToFitBounds();

   // _focusPickupAndDrop();

    // Start trip timer
    tripNotifier.startAutoTrip();
    final trip = ref.read(tripProvider);

    if (trip.fcmToken.isNotEmpty) {
      await FirebasePushService.sendPushNotification(
        fcmToken: trip.fcmToken,
        title: "Trip Started 🚖",
        body: "Your trip has started towards the drop location.",
        data: {
          "bookingId": trip.bookingId,
          "status": "start trip",
          "driverLatLong": "${driverLatLng.latitude},${driverLatLng.longitude}",
          "dropLatLong":
              "${trip.dropLatLng.latitude},${trip.dropLatLng.longitude}", // ✅ include this
          "otp": trip.otp,
        },
      );
    }
  }

  void _focusDriverAndPickup() {
    if (_mapController == null) return;

    final trip = ref.read(tripProvider);

    // Ensure driver location exists
    if (_currentPosition == null) return;

    final LatLng driverLatLng = LatLng(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
    );
    final LatLng pickupLatLng = trip.pickupLatLng;

    final south = [driverLatLng.latitude, pickupLatLng.latitude].reduce(min);
    final north = [driverLatLng.latitude, pickupLatLng.latitude].reduce(max);
    final west = [driverLatLng.longitude, pickupLatLng.longitude].reduce(min);
    final east = [driverLatLng.longitude, pickupLatLng.longitude].reduce(max);

    final bounds = LatLngBounds(
      southwest: LatLng(south, west),
      northeast: LatLng(north, east),
    );

    _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 100));
  }

  void _focusPickupAndDrop() {
    if (_mapController == null) return;

    final trip = ref.read(tripProvider);

    final LatLng pickupLatLng = trip.pickupLatLng;
    final LatLng dropLatLng = trip.dropLatLng;

    final south = [pickupLatLng.latitude, dropLatLng.latitude].reduce(min);
    final north = [pickupLatLng.latitude, dropLatLng.latitude].reduce(max);
    final west = [pickupLatLng.longitude, dropLatLng.longitude].reduce(min);
    final east = [pickupLatLng.longitude, dropLatLng.longitude].reduce(max);

    final bounds = LatLngBounds(
      southwest: LatLng(south, west),
      northeast: LatLng(north, east),
    );

    _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 100));
  }

  Future<void> fetchUserProfile() async {
    final trip = ref.read(tripProvider); // read current trip state
    if (trip.cusMobile.isNotEmpty) {
      final profileList = await ProfileRepository().getUserDetail(
        mobileno: trip.cusMobile,
        //mobileno: "8870602962",
      );

      if (profileList.isNotEmpty) {
        setState(() {
          userProfile =
              profileList[0];
        });
      }
    }
  }

  void showTripCustomerInfoDialog(
      BuildContext context,
      TripState trip,
      UserProfile? userProfile,
      ) {
    showDialog(
      context: context,
      builder: (context) {
        return TripCustomerInfoDialog(
          trip: trip,
          userProfile: userProfile,
          customerToken: trip.fcmToken,
        );
      },
    );
  }
  Future<bool> _checkLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      // optional: show dialog guiding user to settings
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Location permission permanently denied. Please enable it in settings.',
          ),
        ),
      );
      return false;
    }
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  Marker taxiMarker = Marker(
    markerId: const MarkerId("taxi"),
    position: const LatLng(0, 0),
    icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
  );

  @override
  Widget build(BuildContext context) {
    final trip = ref.watch(tripProvider);
    return Scaffold(
      body: Stack(
        children: [
          // 1️⃣ Google Map
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: trip.pickupLatLng,
              zoom: 14,
            ),
            polylines: {
              Polyline(
                polylineId: const PolylineId("route"),
                points: polylineCoordinates,
                color: Colors.blue,
                width: 5,
              ),
            },
            markers: {
              if (trip.pickupRouteVisible)
                Marker(
                  markerId: const MarkerId("pickup"),
                  position: trip.pickupLatLng,
                ),
              if (trip.dropRouteVisible)
                Marker(
                  markerId: const MarkerId("drop"),
                  position: trip.dropLatLng,
                ),
              taxiMarker,
            },
            // onMapCreated: (controller) {
            //   _mapController = controller;
            //   _moveCameraToFitBounds();
            // },
            onMapCreated: (controller) {
              _mapController = controller;
              // Focus camera depending on trip phase
              if (trip.status == TripStatus.accepted) {
                // Before trip: focus on driver + pickup
                _focusDriverAndPickup();
              } else if (trip.status == TripStatus.onTrip) {
                // Trip already started: focus on pickup + drop
                _focusPickupAndDrop();
              }
            },
          ),

          // 2️⃣ Info Floating Button
          Positioned(
            top: 40,
            right: 20,
            child: FloatingActionButton(
              mini: true,
              backgroundColor: Colors.blueAccent,
              child: const Icon(Icons.info_outline),
              onPressed: () {
                showTripCustomerInfoDialog(context, trip, userProfile);
              },
            ),
          ),

          // 3️⃣ Floating Action Buttons Panel (bottom)
          Positioned(
            bottom: 20,
            left: 16,
            right: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Start Trip / Complete Ride

             //   if (trip.status == TripStatus.accepted && trip.canStartTrip)
              //  if(trip.status == TripStatus.accepted)
             //   if(trip.status != TripStatus.accepted)
                ElevatedButton(
                  onPressed: () {
                    // Show OTP in SnackBar for testing
                    // ScaffoldMessenger.of(context).showSnackBar(
                    //   SnackBar(
                    //     content: Text("Test OTP: ${trip.otp}"),
                    //     duration: const Duration(seconds: 5),
                    //     backgroundColor: Colors.redAccent,
                    //   ),
                    // );

                    // Open OTP dialog
                    showOtpDialog(
                      context,
                      ref,
                      _onOtpVerified,
                      trip.otp,
                      trip.fcmToken,
                      trip.bookingId,
                      trip.pickupLatLng,
                      trip.pickup,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 6,
                  ),
                  child: const Text(
                    "Start Trip",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                //     if (trip.status == TripStatus.onTrip && trip.canCompleteTrip)
                  const SizedBox(height: 12),

              //  if (trip.status == TripStatus.onTrip && trip.canCompleteTrip)
            //    if(trip.status == TripStatus.onTrip)
                  ElevatedButton(
                    onPressed: _moveTaxiToDrop,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange.shade700,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 6,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.flag, size: 20),
                        SizedBox(width: 8),
                        Text("Complete Trip"),
                      ],
                    ),
                  ),

                const SizedBox(height: 12),

                // Pickup / Drop Side-by-Side Buttons
           //     if (SharedPrefsHelper.getDriverMobile() == "8870602962")
           //        Row(
           //          children: [
           //            Expanded(
           //              child: ElevatedButton(
           //                onPressed: _testmoveTaxiToPickup,
           //                style: ElevatedButton.styleFrom(
           //                  backgroundColor: Colors.green.shade600,
           //                  padding: const EdgeInsets.symmetric(vertical: 14),
           //                  shape: RoundedRectangleBorder(
           //                    borderRadius: BorderRadius.circular(12),
           //                  ),
           //                  elevation: 6,
           //                ),
           //                child: Row(
           //                  mainAxisAlignment: MainAxisAlignment.center,
           //                  children: const [
           //                    Icon(Icons.navigation, size: 20),
           //                    SizedBox(width: 8),
           //                    Text("Pickup"),
           //                  ],
           //                ),
           //              ),
           //            ),
           //            const SizedBox(width: 12),
           //            Expanded(
           //              child: ElevatedButton(
           //                onPressed: trip.canStartTrip
           //                    ? _testmoveTaxiToDrop
           //                    : null,
           //                style: ElevatedButton.styleFrom(
           //                  backgroundColor: trip.canStartTrip
           //                      ? Colors.blue.shade600
           //                      : Colors.grey.shade400,
           //                  padding: const EdgeInsets.symmetric(vertical: 14),
           //                  shape: RoundedRectangleBorder(
           //                    borderRadius: BorderRadius.circular(12),
           //                  ),
           //                  elevation: trip.canStartTrip ? 6 : 2,
           //                ),
           //                child: Row(
           //                  mainAxisAlignment: MainAxisAlignment.center,
           //                  children: const [
           //                    Icon(Icons.flag, size: 20),
           //                    SizedBox(width: 8),
           //                    Text("Drop"),
           //                  ],
           //                ),
           //              ),
           //            ),
           //          ],
           //        ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
