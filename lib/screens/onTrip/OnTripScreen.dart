import 'package:bneeds_taxi_driver/screens/onTrip/widget/InfoCard.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:bneeds_taxi_driver/utils/storage.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../models/TripState.dart';
import '../../repositories/vehicle_type_repository.dart';
import '../../utils/otp_dialog.dart';

class TripNotifier extends StateNotifier<TripState> {
  Timer? _timer;

  TripNotifier() : super(TripState()) {
    _init();
  }

  Future<void> _init() async {
    final tripMap = await SharedPrefsHelper.getPickupTripData();
    if (tripMap != null) {
      state = TripState.fromMap(tripMap).copyWith(isLoading: false);
    } else {
      state = state.copyWith(isLoading: false);
    }
  }

  void acceptRide(
    String pickup,
    String drop,
    int fare,
    LatLng pickupLatLng,
    LatLng dropLatLng,
    String otp,
    String bookingId,
    String fcmToken,
    String userId,
    String cusMobile,
  ) {
    state = TripState(
      pickup: pickup,
      drop: drop,
      fare: fare,
      pickupLatLng: pickupLatLng,
      dropLatLng: dropLatLng,
      status: TripStatus.accepted,
      otp: otp,
      bookingId: bookingId, // ← save bookingId
      fcmToken: fcmToken, // ← save fcmToken
      userId: userId,
      cusMobile: cusMobile,
      pickupRouteVisible: true, // show pickup route first
      dropRouteVisible: false,
    );
  }

  void updateCanStartTrip(bool value) {
    state = state.copyWith(canStartTrip: value);
  }

  void startAutoTrip({int resumeFrom = 0}) {
    state = state.copyWith(
      status: TripStatus.onTrip,
      canCompleteTrip: false,
      elapsedTime: resumeFrom, // use saved value
    );

    _timer?.cancel();
    int elapsed = resumeFrom;

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      elapsed++;
      state = state.copyWith(elapsedTime: elapsed);
      _saveTripToPrefs(); // save each second

      if (elapsed >= 5) {
        timer.cancel();
        state = state.copyWith(canCompleteTrip: true);
        _saveTripToPrefs();
      }
    });
  }


  void setDriverCurrentLocation(LatLng loc) {
    state = state.copyWith(driverCurrentLatLng: loc);
    _saveTripToPrefs();
  }

  Future<void> completeTrip() async {
    final trip = state;

    // Calculate distance in km
    final distanceMeters = Geolocator.distanceBetween(
      trip.driverCurrentLatLng.latitude,
      trip.driverCurrentLatLng.longitude,
      trip.dropLatLng.latitude,
      trip.dropLatLng.longitude,
    );
    final distanceKm = distanceMeters / 1000.0;

    // Get vehicleId from SharedPrefs
    final vehicleId = await SharedPrefsHelper.getDriverVehicleSubTypeId();
    final InitalfareAmount = trip.fare.toDouble();
    // Fetch fare from API
    final fareRepo = VehicleTypeRepository();
    double fareAmount =
        await fareRepo.fetchFare(vehicleId: vehicleId!, totalKm: distanceKm) ??
        (InitalfareAmount); // fallback

    // Update trip state
    state = state.copyWith(
      status: TripStatus.completed,
      fare: fareAmount.toInt(),
    );

    // Push notification
    if (trip.fcmToken.isNotEmpty) {
      await FirebasePushService.sendPushNotification(
        fcmToken: trip.fcmToken,
        title: "Ride Completed ✅",
        body: "Your trip is completed. Fare: ₹${fareAmount.toInt()}",
        data: {
          "bookingId": trip.bookingId,
          "status": "completed_trip",
          "fareAmount": fareAmount.toStringAsFixed(2),
        },
      );
    }
  }
  // TripNotifier class-kku ullae add pannunga

  void completePickup() {
    state = state.copyWith(
      pickupRouteVisible: false,
      dropRouteVisible: true,
      phase: TripPhase.onTrip,
    );
    _saveTripToPrefs();
  }



// Helper to save trip
  Future<void> _saveTripToPrefs() async {
    final tripMap = {
      'pickup': state.pickup,
      'drop': state.drop,
      'fare': state.fare,
      'pickupLat': state.pickupLatLng.latitude,
      'pickupLng': state.pickupLatLng.longitude,
      'dropLat': state.dropLatLng.latitude,
      'dropLng': state.dropLatLng.longitude,
      'status': state.status.index,
      'phase': state.phase.index,
      'otp': state.otp,
      'bookingId': state.bookingId,
      'fcmToken': state.fcmToken,
      'userId': state.userId,
      'cusMobile': state.cusMobile,
      'driverLat': state.driverCurrentLatLng?.latitude,
      'driverLng': state.driverCurrentLatLng?.longitude,
      'pickupRouteVisible': state.pickupRouteVisible,
      'dropRouteVisible': state.dropRouteVisible,
      'canStartTrip': state.canStartTrip,
      'canCompleteTrip': state.canCompleteTrip,
      'elapsedTime': state.elapsedTime,
    };

    await SharedPrefsHelper.setPickupTripData(tripMap);
  }

  Future<void> loadTripFromPrefs() async {
    final tripMap = await SharedPrefsHelper.getPickupTripData();
    if (tripMap == null) return; // No saved trip

    state = TripState(
      pickup: tripMap['pickup'] ?? '',
      drop: tripMap['drop'] ?? '',
      fare: tripMap['fare'] ?? 0,
      pickupLatLng: LatLng(
        tripMap['pickupLat'] ?? 0.0,
        tripMap['pickupLng'] ?? 0.0,
      ),
      dropLatLng: LatLng(
        tripMap['dropLat'] ?? 0.0,
        tripMap['dropLng'] ?? 0.0,
      ),
      status: TripStatus.values[tripMap['status'] ?? 0],
      phase: TripPhase.values[tripMap['phase'] ?? 0],
      otp: tripMap['otp'] ?? '',
      bookingId: tripMap['bookingId'] ?? '',
      fcmToken: tripMap['fcmToken'] ?? '',
      userId: tripMap['userId'] ?? '',
      cusMobile: tripMap['cusMobile'] ?? '',
      driverCurrentLatLng: (tripMap['driverLat'] != null && tripMap['driverLng'] != null)
          ? LatLng(tripMap['driverLat'], tripMap['driverLng'])
          : LatLng(tripMap['pickupLat'] ?? 0.0, tripMap['pickupLng'] ?? 0.0),
      pickupRouteVisible: tripMap['pickupRouteVisible'] ?? true,
      dropRouteVisible: tripMap['dropRouteVisible'] ?? false,
      canStartTrip: tripMap['canStartTrip'] ?? false,
      canCompleteTrip: tripMap['canCompleteTrip'] ?? false,
      elapsedTime: tripMap['elapsedTime'] ?? 0,
    );

    // Resume trip timer if onTrip
    if (state.status == TripStatus.onTrip) {
      startAutoTrip(resumeFrom: state.elapsedTime);
    }
  }

  void completeDrop() {
    state = state.copyWith(
      dropRouteVisible: false, // drop route hide
      phase: TripPhase.completed, // trip completed
    );
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

  @override
  void initState() {
    super.initState();
    fetchUserProfile();
    WakelockPlus.enable();
    Future.microtask(() async {
      await _initForTrip();
    });

    Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_pageController.hasClients) {
        currentPage = (currentPage + 1) % 2;
        _pageController.animateToPage(
          currentPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _testmoveTaxiToPickup() async {
    final trip = ref.read(tripProvider);

    // Update state to accepted
    ref.read(tripProvider.notifier).updateCanStartTrip(false);

    // Move taxi instantly (or animate if you want)
    setState(() {
      taxiMarker = taxiMarker.copyWith(positionParam: trip.pickupLatLng);
    });

    // Send push notification
    if (trip.fcmToken.isNotEmpty) {
      await FirebasePushService.sendPushNotification(
        fcmToken: trip.fcmToken,
        title: "Driver Arrived at Pickup ✅",
        body: "Your driver has arrived at the pickup location.",
        data: {"bookingId": trip.bookingId, "status": "arrived_pickup"},
      );
    }

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
          content: Text("You are too far from pickup location to start the trip."),
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

    if (distanceToDrop <= dropRadius) {
      // Move taxi marker
      setState(() {
        taxiMarker = taxiMarker.copyWith(positionParam: trip.dropLatLng);
      });

      await SharedPrefsHelper.clearTripData();
      await ref.read(tripProvider.notifier).completeTrip();

      // Navigate to TripCompleteScreen
      if (mounted) {
        context.go(AppRoutes.tripComplete);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("You are too far from drop location to complete the trip."),
        ),
      );
    }
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _mapController?.dispose();
    _pageController.dispose();
    WakelockPlus.disable();
    super.dispose();
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
        _currentPosition?.latitude ?? trip.driverCurrentLatLng?.latitude ?? trip.pickupLatLng.latitude,
        _currentPosition?.longitude ?? trip.driverCurrentLatLng?.longitude ?? trip.pickupLatLng.longitude,
      );
      endLatLng = trip.dropLatLng;
    } else {
      return; // no active trip
    }

    await getRoute(startLatLng, endLatLng);

    // Move camera
    _moveCameraToFitBounds();

    // Resume trip timer if needed
    if (trip.status == TripStatus.onTrip) {
      ref.read(tripProvider.notifier).startAutoTrip(resumeFrom: trip.elapsedTime);
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


  void _moveCameraToFitBounds() {
    if (_mapController == null) return;
    final trip = ref.read(tripProvider);

    final List<LatLng> points = [];
    if (_currentPosition != null) {
      points.add(
        LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
      );
    }
    points.add(trip.pickupLatLng);
    points.add(trip.dropLatLng);
    if (polylineCoordinates.isNotEmpty) {
      points.addAll(polylineCoordinates);
    }

    if (points.isEmpty) return;

    final latitudes = points.map((p) => p.latitude).toList();
    final longitudes = points.map((p) => p.longitude).toList();

    final southwestLat = latitudes.reduce(min);
    final southwestLng = longitudes.reduce(min);
    final northeastLat = latitudes.reduce(max);
    final northeastLng = longitudes.reduce(max);

    final bounds = LatLngBounds(
      southwest: LatLng(southwestLat, southwestLng),
      northeast: LatLng(northeastLat, northeastLng),
    );

    _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 70));
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
    _moveCameraToFitBounds();

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
          "dropLatLong": "${trip.dropLatLng.latitude},${trip.dropLatLng.longitude}", // ✅ include this
          "otp": trip.otp,
        },
      );
    }

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

          final trip = ref.read(tripProvider);

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

            if (distanceToDrop <= dropRadius) {
              _stopLiveTracking();
              ref
                  .read(tripProvider.notifier)
                  .completeTrip(); // sends notification
            }
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

  void _stopLiveTracking() {
    _positionStream?.cancel();
    _positionStream = null;
    _otpShown = false;

    _lastRouteLat = 0;
    _lastRouteLng = 0;
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
              profileList[0]; // Already UserProfile, no fromJson needed
        });
      }
    }
  }
  void showTripCustomerInfoDialog(
      BuildContext context, TripState trip, UserProfile? userProfile) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 8,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 400),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Dialog Title
                    Row(
                      children: const [
                        Icon(Icons.info_outline, color: Colors.blueAccent),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "Trip & Customer Info",
                            style: TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Trip Info Section
                    Row(
                      children: const [
                        Icon(Icons.directions_car, color: Colors.green),
                        SizedBox(width: 8),
                        Text(
                          "Trip Info",
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _modernInfoRow(Icons.location_pin, "Pickup", trip.pickup),
                    _modernInfoRow(Icons.flag, "Drop", trip.drop),
                    _modernInfoRow(Icons.attach_money, "Fare", "₹${trip.fare}"),
                    const Divider(height: 24, thickness: 1),

                    // Customer Info Section (if available)
                    if (userProfile != null) ...[
                      Row(
                        children: const [
                          Icon(Icons.person, color: Colors.blue),
                          SizedBox(width: 8),
                          Text(
                            "Customer Info",
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _modernInfoRow(Icons.person_outline, "Name", userProfile.userName),
                      _modernInfoRow(Icons.phone, "Mobile", userProfile.mobileNo),
                      _modernInfoRow(Icons.home, "Address",
                          "${userProfile.address1}, ${userProfile.address2}, ${userProfile.city}"),
                    ],

                    const SizedBox(height: 20),

                    // Close Button
                    Center(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 32, vertical: 12),
                          elevation: 4,
                        ),
                        child: const Text(
                          "Close",
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Modern info row with icon
  Widget _modernInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey[700]),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: "$label: ",
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                        fontSize: 14),
                  ),
                  TextSpan(
                    text: value,
                    style: const TextStyle(color: Colors.black, fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
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

  GoogleMapController? _mapController;
  Marker taxiMarker = Marker(
    markerId: const MarkerId("taxi"),
    position: const LatLng(0, 0),
    icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
  );
  List<LatLng> polylineCoordinates = [];

  Future<void> getRoute(LatLng start, LatLng end) async {
    const String googleApiKey = "AIzaSyAWzUqf3Z8xvkjYV7F4gOGBBJ5d_i9HZhs";

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
      if (_mapController != null) {
        _moveCameraToFitBounds();
      }
    } else {
      print('Error getting directions: ${result.errorMessage}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final trip = ref.watch(tripProvider);

    // if (trip.isLoading) {
    //   return const Scaffold(
    //     body: Center(child: CircularProgressIndicator()),
    //   );
    // }

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
                Marker(markerId: const MarkerId("pickup"), position: trip.pickupLatLng),
              if (trip.dropRouteVisible)
                Marker(markerId: const MarkerId("drop"), position: trip.dropLatLng),
              taxiMarker,
            },
            onMapCreated: (controller) {
              _mapController = controller;
              _moveCameraToFitBounds();
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
                final trip = ref.read(tripProvider);
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
                if (trip.status == TripStatus.accepted && trip.canStartTrip)
                  ElevatedButton(
                    onPressed: () {
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
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),

                if (trip.status == TripStatus.onTrip && trip.canCompleteTrip)
                  const SizedBox(height: 12),

                if (trip.status == TripStatus.onTrip && trip.canCompleteTrip)
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
                        Text("Complete Ride"),
                      ],
                    ),
                  ),

                const SizedBox(height: 12),

                // Pickup / Drop Side-by-Side Buttons
                if(SharedPrefsHelper.getDriverMobile() == "8870602962")
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _testmoveTaxiToPickup,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade600,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 6,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.navigation, size: 20),
                            SizedBox(width: 8),
                            Text("Pickup"),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: trip.canStartTrip ? _testmoveTaxiToDrop : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: trip.canStartTrip
                              ? Colors.blue.shade600
                              : Colors.grey.shade400,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: trip.canStartTrip ? 6 : 2,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.flag, size: 20),
                            SizedBox(width: 8),
                            Text("Drop"),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );

  }


}
