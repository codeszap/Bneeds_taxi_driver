import 'package:bneeds_taxi_driver/screens/onTrip/widget/TripCustomerInfoDialog.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:bneeds_taxi_driver/utils/storage.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../../models/Api Modal/AcceptBookingRequest.dart';
import '../../models/BookingDetail.dart';
import '../../models/TripState.dart';
import '../../providers/params/booking_params.dart';
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
  double routeUpdateThreshold = 20;
  List<LatLng> pickupPolyline = [];
  List<LatLng> dropPolyline = [];
  bool showInfoPanel = false;
  bool _otpShown = false;
  List<LatLng> polylineCoordinates = [];
  GoogleMapController? _mapController;
  int? bookingId;
  int? riderId;
  String? _apiTripStatus;
  BookingDetail? _bookingDetail;
  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _loadIds();
    WakelockPlus.enable();
    Future.microtask(() async {
      await _initForTrip();
    });
  }

  Future<void> _loadIds() async {
    final bId = await SharedPrefsHelper.getBookingId();
    final rId = await SharedPrefsHelper.getRiderId();

    setState(() {
      bookingId = int.tryParse(bId);
      riderId = int.tryParse(rId);
    });
  }

  Future<void> _initForTrip() async {
    final hasPermission = await _checkLocationPermission();
    if (!hasPermission) return;

    // ✅ Step 1: Fetch booking list from API
    final bookingList = await ref.read(
      fetchBookingDetailProvider(
        BookingParams(bookingId: bookingId!, riderId: riderId!),
      ).future,
    );

    if (bookingList.isEmpty) {
      print("❌ No booking data found from API");
      return;
    }

    final booking = bookingList.first;
    final tripStatus = booking.tripStatus ?? '';
    _apiTripStatus = tripStatus;
    _bookingDetail = booking;

    // ✅ Step 2: Parse coordinates
    final fromLatLong = booking.fromLatLong.split(',');
    final toLatLong = booking.toLatLong.split(',');

    if (fromLatLong.length < 2 || toLatLong.length < 2) {
      print("⚠️ Invalid coordinates in API data");
      return;
    }

    final pickupLatLng = LatLng(
      double.parse(fromLatLong[0]),
      double.parse(fromLatLong[1]),
    );
    final dropLatLng = LatLng(
      double.parse(toLatLong[0]),
      double.parse(toLatLong[1]),
    );

    // ✅ Step 3: Get current driver location
    final pos = await Geolocator.getCurrentPosition();
    _currentPosition = pos;
    final driverLatLng = LatLng(pos.latitude, pos.longitude);

    // ✅ Step 4: Update provider with pickup/drop info
    ref.read(tripProvider.notifier).setPickupAndDrop(pickupLatLng, dropLatLng);
    ref.read(tripProvider.notifier).setDriverCurrentLocation(driverLatLng);

    // ✅ Step 5: Determine route start and end
    LatLng startLatLng;
    LatLng endLatLng;

    // --- 👇👇 புதிய குறியீடு START 👇👇 ---
    // வரைபடத்தில் marker-களைக் காண்பிக்கவும்
    final tripNotifier = ref.read(tripProvider.notifier);

    if (tripStatus == "O") {
      startLatLng = driverLatLng;
      endLatLng = pickupLatLng;

      // Pickup marker-ஐ மட்டும் காண்பிக்கவும்
      tripNotifier.updateRouteVisibility(
        pickupVisible: true,
        dropVisible: false,
      );
      setState(() {
        _markers.add(
          Marker(markerId: MarkerId('driver'), position: driverLatLng),
        );
        _markers.add(
          Marker(markerId: MarkerId('pickup'), position: pickupLatLng),
        );
      });
      print("📍 TripStatus O → route: current → pickup");
    } else if (tripStatus == "P") {
      startLatLng = driverLatLng;
      endLatLng = dropLatLng;

      // Drop marker-ஐ மட்டும் காண்பிக்கவும்
      tripNotifier.updateRouteVisibility(
        pickupVisible: false,
        dropVisible: true,
      );

      print("🚖 TripStatus P → route: current → drop");
    } else {
      print("⚠️ Unknown TripStatus: $tripStatus");
      return;
    }
    // --- 👆👆 புதிய குறியீடு END 👆👆 ---

    // ✅ Step 6: Draw route
    await getRoute(startLatLng, endLatLng);

    // ✅ Step 7: Focus camera properly
    await Future.delayed(const Duration(milliseconds: 400));
    if (_mapController != null) {
      if (tripStatus == "O") {
        _focusDriverAndPickup();
      } else if (tripStatus == "P") {
        _focusPickupAndDrop();
      }
    }

    // ✅ Step 8: Start live tracking
    _startLiveTracking();

    if (mounted) {
      setState(() {
        // ஆரம்பத்தில் marker-களையும் polyline-ஐயும் காண்பிக்க,
        // UI-ஐப் புதுப்பிக்க இந்த setState() உதவுகிறது.
      });
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
        Geolocator.getPositionStream(locationSettings: locationSettings).listen(
          (Position pos) async {
            _currentPosition = pos;
            final newLatLng = LatLng(pos.latitude, pos.longitude);

            ref.read(tripProvider.notifier).setDriverCurrentLocation(newLatLng);

            setState(() {
              taxiMarker = taxiMarker.copyWith(positionParam: newLatLng);
            });

            _mapController?.animateCamera(CameraUpdate.newLatLng(newLatLng));

            // -----------------------------
            // Pickup Geofence (TripStatus = "O")
            // -----------------------------
            if (_apiTripStatus == "O" && !_otpShown) {
              double radius = 50; // meters
              double distanceToPickup = Geolocator.distanceBetween(
                pos.latitude,
                pos.longitude,
                ref.read(tripProvider).pickupLatLng.latitude,
                ref.read(tripProvider).pickupLatLng.longitude,
              );

              if (distanceToPickup <= radius) {
                _otpShown = true; // prevent duplicate
                ref.read(tripProvider.notifier).updateCanStartTrip(true);

                // push notification to customer, etc.
              }
            }
            // -----------------------------
            // Auto Drop Geofence (TripStatus = "P")
            // -----------------------------
            else if (_apiTripStatus == "P") {
              double dropRadius = 30;
              double distanceToDrop = Geolocator.distanceBetween(
                pos.latitude,
                pos.longitude,
                ref.read(tripProvider).dropLatLng.latitude,
                ref.read(tripProvider).dropLatLng.longitude,
              );

              // if (distanceToDrop <= dropRadius) {
              //   _stopLiveTracking();
              //   ref.read(tripProvider.notifier).completeTrip();
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

              if (_apiTripStatus == "O") {
                await getRoute(newLatLng, ref.read(tripProvider).pickupLatLng);
              } else if (_apiTripStatus == "P") {
                await getRoute(newLatLng, ref.read(tripProvider).dropLatLng);
              }
            }
          },
        );
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
        if (_apiTripStatus == "O") {
          _focusDriverAndPickup();
        } else if (_apiTripStatus == "P") {
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

// In OnTripScreen.dart

  void _moveTaxiToDrop() async {
    // Step 1: Check if essential data is available
    if (_bookingDetail == null || riderId == null || _currentPosition == null) {
      print("❌ Cannot complete trip: Booking/Rider/Position details are null.");
      return;
    }

    // Step 2: Show confirmation dialog
    final bool? confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        // Unga confirmation dialog code inga (no changes needed here)
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.check_circle_outline,
                  size: 60,
                  color: Colors.green,
                ),
                const SizedBox(height: 16),
                const Text(
                  "Complete Trip?",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text("Cancel"),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        backgroundColor: Colors.green,
                      ),
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text(
                        "Confirm",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    // Step 3: If driver confirms, call the API
    if (confirm == true) {
      try {
        // --- 👇 ITHA SARI PANNUNGA START 👇 ---
        final tripUpdateDetail = RiderTripUpdateDetail(
          riderId: riderId.toString(),
          bookingId: _bookingDetail!.bookingId.toString(),
          tripStatus: "D", // "D" for Dropped/Completed
          toLatLong:
          "${_currentPosition!.latitude},${_currentPosition!.longitude}",
        );
        // --- 👆 ITHA SARI PANNUNGA END 👆 ---

        final tripUpdateRequest = RiderTripUpdateRequest(
          updateTripStatus: [tripUpdateDetail],
        );

        print("🚀 Calling updateTripStatusProvider API for trip completion...");
        final response = await ref.read(
          updateTripStatusProvider(tripUpdateRequest).future,
        );

        // Step 4: If API call is successful, navigate to the next screen
        if (response.status == 'success') {
          print("✅ API Success: Trip status updated to 'D' (Completed).");
          _stopLiveTracking();

          if (mounted) {
            context.go(AppRoutes.tripComplete);
          }
        } else {
          // Handle API failure
          print("❌ API Error on trip completion: ${response.message}");
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    response.message ?? 'Failed to complete trip. Try again.'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        // Handle any other exceptions
        print("❌ Exception while completing trip: $e");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                "An error occurred. Please check your connection.",
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
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


  void _onOtpVerified() async {
    // Step 1: Mudal'la thevayana data ellam irukkaanu check pannikonga
    if (_bookingDetail == null || _currentPosition == null || riderId == null) {
      print("❌ Cannot proceed: Booking/Rider/Position details are null.");
      return;
    }

    final tripUpdateDetail = RiderTripUpdateDetail(
      riderId: riderId.toString(),
      bookingId: _bookingDetail!.bookingId.toString(),
      tripStatus: "P",
      fromLatLong:
      "${_currentPosition!.latitude},${_currentPosition!.longitude}",
    );

    final tripUpdateRequest = RiderTripUpdateRequest(
      updateTripStatus: [tripUpdateDetail],
    );

    // Step 3: API-a call panni, response-a handle pannunga
    try {
      print("🚀 Calling updateTripStatusProvider API...");
      final response = await ref.read(
        updateTripStatusProvider(tripUpdateRequest).future,
      );

      // Step 4: API call success aana, UI-a update pannunga
      if (response.status == 'success') {
        print('✅ API Success: Trip status updated to "P" (Picked Up).');

        // Driver-oda current location and drop location eduthukonga
        final driverLatLng = LatLng(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
        );

        final toLatLong = _bookingDetail!.toLatLong.split(',');
        if (toLatLong.length < 2) {
          print("⚠️ Invalid DROP coordinates from API");
          return;
        }
        final dropLatLng = LatLng(
          double.parse(toLatLong[0]),
          double.parse(toLatLong[1]),
        );

        // setState-kulla UI-a update pannunga
        setState(() {
          _apiTripStatus = "P"; // Local status-a maathunga
          polylineCoordinates.clear(); // Pazhaya route-a azhikkavum
          _markers.clear(); // Pazhaya markers-a azhikkavum

          // Puthusa 'drop' marker-a add pannunga
          _markers.add(
            Marker(
              markerId: const MarkerId('drop'),
              position: dropLatLng,
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueAzure, // Drop marker-ku vera color
              ),
            ),
          );
        });

        // Puthu route-a varaiyavum (Driver -> Drop)
        await getRoute(driverLatLng, dropLatLng);

        // Map camera-va puthu route-ku focus pannunga
        _focusCameraOnRoute(driverLatLng, dropLatLng);

      } else {
        // API fail aagum pothu
        print('❌ API Error: Trip update failed. Message: ${response.message}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
              Text(response.message ?? 'Could not update trip. Try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      // Internet illa, server down maari error-ku
      print('❌ Exception during trip update API call: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('An error occurred. Check your connection.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }


  void _focusCameraOnRoute(LatLng start, LatLng end) {
    if (_mapController == null) return;

    final south = [start.latitude, end.latitude].reduce(min);
    final north = [start.latitude, end.latitude].reduce(max);
    final west = [start.longitude, end.longitude].reduce(min);
    final east = [start.longitude, end.longitude].reduce(max);

    final bounds = LatLngBounds(
      southwest: LatLng(south, west),
      northeast: LatLng(north, east),
    );

    _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 100));
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

  void showTripCustomerInfoDialog(
    BuildContext context,
      BookingDetail? booking,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return TripCustomerInfoDialog(
          bookingDetail: booking,
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
    if (bookingId == null || riderId == null) {
      return const Center(child: CircularProgressIndicator());
    }

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
            markers: {..._markers, taxiMarker},
            onMapCreated: (controller) {
              _mapController = controller;

              if (_apiTripStatus == "O") {
                _focusDriverAndPickup();
              } else if (_apiTripStatus == "P") {
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
                showTripCustomerInfoDialog(context, _bookingDetail);
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
                // --- 👇👇 இங்கேதான் முக்கியமான மாற்றம் 👇👇 ---

                // நிலை 1: பயணம் ACCEPTED நிலையில் இருந்தால் "Start Trip" பட்டனைக் காட்டு
                // ... உள்ளே build method-ல், Positioned widget-க்கு உள்ளே ...

                // நிலை 1: பயணம் ACCEPTED நிலையில் இருந்தால் "Start Trip" பட்டனைக் காட்டு
                if (_apiTripStatus == "O")
                  ElevatedButton(
                    // --- 👇👇 புதிய மாற்றம் இங்கே START 👇👇 ---
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green, // பட்டனின் நிறம் பச்சை
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 6,
                    ),
                    // --- 👆👆 புதிய மாற்றம் இங்கே END 👆👆 ---
                    onPressed: () async {
                      final booking = _bookingDetail;

                      if (booking == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Booking data not loaded!"),
                          ),
                        );
                        return;
                      }

                      final correctOtp = booking.otp?.trim();

                      if (correctOtp == null || correctOtp.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("OTP not found in booking data!"),
                          ),
                        );
                        return;
                      }

                      showOtpDialog(
                        context,
                        ref,
                        () async {
                          _onOtpVerified();
                          setState(() {
                            _apiTripStatus = "P";
                          });
                        },
                        correctOtp!,
                        trip.fcmToken,
                        trip.bookingId,
                        trip.pickupLatLng,
                        trip.pickup,
                      );
                    },
                    child: const Text(
                      "Start Trip",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ), // எழுத்து நிறம் வெள்ளை
                    ),
                  ),

                // நிலை 2: பயணம் ON_TRIP நிலையில் இருந்தால் "Complete Trip" பட்டனைக் காட்டு
                if (_apiTripStatus == "P")
                  ElevatedButton(
                    onPressed: _moveTaxiToDrop, // பயணத்தை முடிக்கும் செயல்பாடு
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
                        Text(
                          'Complete Trip', // பட்டனின் பெயர்
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                // --- 👆👆 மாற்றம் இங்கே முடிகிறது 👆👆 ---
              ],
            ),
          ),
        ],
      ),
    );
  }
}
