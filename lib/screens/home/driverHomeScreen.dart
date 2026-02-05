import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bneeds_taxi_driver/utils/storage.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../../core/locationHelper.dart';
import '../../services/RideOverlayHelper.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/app_update_service.dart';
import '../../services/firebase_service.dart';
import '../onTrip/TripNotifier.dart';

class DriverHomeScreen extends ConsumerStatefulWidget {
  final double? initialLat;
  final double? initialLng;

  const DriverHomeScreen({super.key, this.initialLat, this.initialLng});

  @override
  ConsumerState<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends ConsumerState<DriverHomeScreen>
    with WidgetsBindingObserver {
  GoogleMapController? _mapController;
  LatLng? _currentLocation;
  Set<Marker> _markers = {};
  final AudioPlayer _audioPlayer = AudioPlayer();
  StreamSubscription<Position>? _positionStreamSubscription;
  bool _isFirstLocationUpdate = true;

  // @override
  // void initState() {
  //   super.initState();
  //   _startListeningLocation();
  //
  //   Future.microtask(() async {
  //     // bool granted = await FlutterOverlayWindow.isPermissionGranted();
  //     // if (!granted) {
  //     //   await FlutterOverlayWindow.requestPermission();
  //     // }
  //
  //     final savedStatus = await SharedPrefsHelper.getDriverStatus();
  //     final statusToSet = savedStatus ?? "OF";
  //     if (statusToSet == "OL" || statusToSet == "OF") {
  //       print("Driver is not on a trip. Clearing any stale trip data...");
  //       await ref.read(tripProvider.notifier).reset();
  //     }
  //     if (ref.read(driverStatusProvider) != statusToSet) {
  //       await setDriverStatus(statusToSet);
  //     }
  //    // if (granted && statusToSet == "OL") {
  //     if (statusToSet == "OL") {
  //       final pos = SharedPrefsHelper.getOverlayPosition();
  //       final savedX = pos["x"]?.toDouble();
  //       final savedY = pos["y"]?.toDouble();
  //       // await RideOverlayHelper.showOverlay(
  //       //   context,
  //       //   posX: savedX,
  //       //   posY: savedY,
  //       // );
  //     }
  //     initFirebaseMessaging(rootNavigatorKey, ref);
  //   });
  // }

  // @override
  // void initState() {
  //   super.initState();
  //   _startListeningLocation();
  //   WidgetsBinding.instance.addPostFrameCallback((_) async {
  //     final savedStatus = await SharedPrefsHelper.getDriverStatus();
  //     final statusToSet = savedStatus ?? "OF";
  //     ref.read(driverStatusProvider.notifier).state = statusToSet;
  //     if (statusToSet == "OL" || statusToSet == "OF") {
  //       print("Driver is not on a trip. Clearing any stale trip data...");
  //       await ref.read(tripProvider.notifier).reset();
  //     }
  //
  //     if (statusToSet == "OL") {
  //       final pos = SharedPrefsHelper.getOverlayPosition();
  //       final savedX = pos["x"]?.toDouble();
  //       final savedY = pos["y"]?.toDouble();
  //       // await RideOverlayHelper.showOverlay(
  //       //   context,
  //       //   posX: savedX,
  //       //   posY: savedY,
  //       // );
  //     }
  //     initFirebaseMessaging(rootNavigatorKey, ref);
  //   });
  // }

  @override
  void initState() {
    super.initState();
    // Check for updates
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForUpdates();
    });

    WakelockPlus.enable();

    if (widget.initialLat != null && widget.initialLng != null) {
      _currentLocation = LatLng(widget.initialLat!, widget.initialLng!);

      _markers = {
        Marker(
          markerId: const MarkerId("currentLocation"),
          position: _currentLocation!,
          infoWindow: const InfoWindow(title: "You are here"),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ),
      };
    }
    _startListeningLocation();
    _checkOverlayPermission();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final savedStatus = await SharedPrefsHelper.getDriverStatus();
      final statusToSet = savedStatus ?? "OF";
      ref.read(driverStatusProvider.notifier).state = statusToSet;
      if (statusToSet == "OL" || statusToSet == "OF") {
        print("Driver is not on a trip. Clearing any stale trip data...");
        await ref.read(tripProvider.notifier).reset();
      }

      if (statusToSet == "OL") {
        final pos = SharedPrefsHelper.getOverlayPosition();
        final savedX = pos["x"]?.toDouble();
        final savedY = pos["y"]?.toDouble();
        // await RideOverlayHelper.showOverlay(...);
      }
      initFirebaseMessaging(rootNavigatorKey, ref);
    });
  }

  void _centerMapOnDriver() {
    if (_mapController != null && _currentLocation != null) {
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: _currentLocation!, zoom: 16),
        ),
      );
    }
  }

  Future<void> _checkOverlayPermission() async {
    bool granted = await FlutterOverlayWindow.isPermissionGranted();
    if (!granted) {
      await _showOverlayPermissionDialog();
    }
  }

  Future<void> _showOverlayPermissionDialog() async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.layers_outlined, color: AppColors.primary, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                "Overlay Permission",
                style: AppTextStyles.heading(size: 18),
              ),
            ),
          ],
        ),
        content: const Text(
          "To receive ride requests while the app is in the background, please enable 'Display over other apps' permission.",
          style: TextStyle(fontSize: 15, color: Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "Later",
              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            onPressed: () async {
              Navigator.pop(context);
              await FlutterOverlayWindow.requestPermission();
            },
            child: const Text(
              "Enable Now",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    print("📱 AppLifecycleState changed to: $state");
    if (state == AppLifecycleState.paused) {
      // App is truly in background
      _showOverlayIfOnline();
    } else if (state == AppLifecycleState.resumed) {
      // App returned to foreground
      _hideOverlay();
    }
  }

  Future<void> _showOverlayIfOnline() async {
    final status = ref.read(driverStatusProvider);
    print("🔍 Checking if should show overlay. Status: $status");
    if (status == "OL") {
      bool granted = await FlutterOverlayWindow.isPermissionGranted();
      if (granted) {
        bool alreadyActive = await FlutterOverlayWindow.isActive();
        if (!alreadyActive) {
          print("🚀 Showing Overlay Bubble...");
          await SharedPrefsHelper.reload(); // Refresh from other isolates
          final pos = SharedPrefsHelper.getOverlayPosition();
          double? savedX = pos["x"]?.toDouble();
          double? savedY = pos["y"]?.toDouble();

          print("📊 Loaded coordinates for overlay: X=$savedX, Y=$savedY");

          // If 0,0 (untouched), use a nice default
          if ((savedX == null || savedX == 0) &&
              (savedY == null || savedY == 0)) {
            print("💡 Using default coordinates (center-top)");
            savedX = 100;
            savedY = 200;
          }

          await RideOverlayHelper.showOverlay(
            context,
            posX: savedX,
            posY: savedY,
          );
        } else {
          print("ℹ️ Overlay is already active.");
        }
      } else {
        print("⚠️ Overlay permission not granted.");
      }
    }
  }

  Future<void> _hideOverlay() async {
    await RideOverlayHelper.closeOverlay();
  }

  Future<void> _startListeningLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    if (permission == LocationPermission.deniedForever) return;

    _positionStreamSubscription =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 10,
          ),
        ).listen((Position position) {
          if (!mounted) return;

          setState(() {
            _currentLocation = LatLng(position.latitude, position.longitude);
            _markers = {
              Marker(
                markerId: const MarkerId("currentLocation"),
                position: _currentLocation!,
                infoWindow: const InfoWindow(title: "You are here"),
                icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueBlue,
                ),
              ),
            };
          });

          if (_isFirstLocationUpdate) {
            _centerMapOnDriver();
            setState(() {
              _isFirstLocationUpdate = false;
            });
          }
        });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _positionStreamSubscription?.cancel();
    _audioPlayer.dispose();
    WakelockPlus.disable();
    super.dispose();
  }

  void _checkForUpdates() async {
    await RemoteConfigHelper.init();
    if (await RemoteConfigHelper.shouldUpdate()) {
      if (mounted) {
        _showUpdateDialog(RemoteConfigHelper.isForceUpdate);
      }
    }
  }

  void _showUpdateDialog(bool isForceUpdate) {
    showDialog(
      context: context,
      barrierDismissible: !isForceUpdate,
      builder: (context) {
        return WillPopScope(
          onWillPop: () async => !isForceUpdate,
          child: AlertDialog(
            title: const Text("Update Available 🚀"),
            content: Text(
              isForceUpdate
                  ? "A critical update is available. You must update to continue using the app."
                  : "A new version of the app is available. Would you like to update now?",
            ),
            actions: [
              if (!isForceUpdate)
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Later"),
                ),
              ElevatedButton(
                onPressed: () {
                  _launchStoreUrl();
                },
                child: const Text("Update Now"),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _launchStoreUrl() async {
    const url =
        "https://play.google.com/store/apps/details?id=com.nminfotech.bneeds_taxi_driver";
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _getCurrentLocation() async {
    final hasPermission = await LocationHelper.checkAndRequestPermission(
      context,
    );

    if (!hasPermission) return;

    final pos = await LocationHelper.getCurrentPosition(context);
    if (pos == null) return;

    final address = await LocationHelper.getAddressFromPosition(pos);

    setState(() {
      _currentLocation = LatLng(pos.latitude, pos.longitude);
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

  Future<void> setDriverStatus(String newStatus) async {
    final startTime = DateTime.now();
    print(
      "🚀 setDriverStatus STARTED at $startTime with newStatus: $newStatus",
    );

    ref.read(driverStatusProvider.notifier).state = "CK";

    try {
      // ✅ Use already available current location if available
      LatLng? loc = _currentLocation;

      if (loc == null) {
        print("⚠️ _currentLocation null — fetching once via Geolocator...");
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium, // Faster
        );
        loc = LatLng(position.latitude, position.longitude);
      }

      final fromLatLong = "${loc.latitude},${loc.longitude}";
      print("✅ Using location: $fromLatLong");

      final repo = ref.read(driverRepositoryProvider);
      final riderId = SharedPrefsHelper.getRiderId();

      print("🛰️ Calling API: updateDriverStatus($riderId, $newStatus)");

      final apiStart = DateTime.now();
      final response = await repo.updateDriverStatus(
        riderId: riderId,
        riderStatus: newStatus,
        fromLatLong: fromLatLong,
      );
      final apiEnd = DateTime.now();
      print(
        "📦 API response received in "
        "${apiEnd.difference(apiStart).inMilliseconds} ms",
      );

      if (response.status == "success") {
        ref.read(driverStatusProvider.notifier).state = newStatus;
        await SharedPrefsHelper.setDriverStatus(newStatus);
        print("✅ Status updated successfully to $newStatus");
      } else {
        final oldStatus = await SharedPrefsHelper.getDriverStatus() ?? "OF";
        ref.read(driverStatusProvider.notifier).state = oldStatus;
        print("❌ API failed: ${response.message}");
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("❌ ${response.message}")));
      }
    } catch (e, st) {
      final oldStatus = await SharedPrefsHelper.getDriverStatus() ?? "OF";
      ref.read(driverStatusProvider.notifier).state = oldStatus;
      print("💥 Exception in setDriverStatus: $e");
      print(st);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }

    final endTime = DateTime.now();
    print(
      "🏁 setDriverStatus COMPLETED in "
      "${endTime.difference(startTime).inMilliseconds} ms",
    );
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
            if (_currentLocation == null)
              const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text("Fetching your location..."),
                  ],
                ),
              )
            else
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
                  // bool granted =
                  //     await FlutterOverlayWindow.isPermissionGranted();
                  //  if (granted && newStatus == "OL") {
                  if (newStatus == "OL") {
                    final pos = SharedPrefsHelper.getOverlayPosition();
                    final savedX = pos["x"]?.toDouble();
                    final savedY = pos["y"]?.toDouble();
                    // Optional: show only if background, but usually we don't show when in app
                  }
                  if (newStatus == "OF") {
                    await RideOverlayHelper.closeOverlay();
                  }
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
                onPressed: _centerMapOnDriver,
                child: Icon(Icons.my_location, color: textColor),
              ),
            ),
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
                        : status == "CK"
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
