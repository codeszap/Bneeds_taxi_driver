import 'dart:async';
import 'package:bneeds_taxi_driver/widgets/common_main_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';


class RideOnTripScreen extends StatefulWidget {
  const RideOnTripScreen({super.key});

  @override
  State<RideOnTripScreen> createState() => _RideOnTripScreenState();
}

class _RideOnTripScreenState extends State<RideOnTripScreen> {
  final Completer<GoogleMapController> _mapController = Completer();

  final LatLng _pickup = const LatLng(9.9272, 78.1198);
  final LatLng _destination = const LatLng(9.9252, 78.1198);
  late LatLng _driverLocation;

  final Set<Polyline> _polylines = {};
  final Set<Marker> _markers = {};
  double _progress = 0.0;

  Timer? _movementTimer;
  int _step = 0;
  List<LatLng> _routePoints = [];

  @override
  void initState() {
    super.initState();
    _driverLocation = _pickup;
    _setupMap();
    _startDriverMovementSimulation();
  }

  @override
  void dispose() {
    _movementTimer?.cancel();
    super.dispose();
  }

  void _setupMap() {
    _routePoints = [_pickup, _destination];

    _markers.addAll([
      Marker(
        markerId: const MarkerId('pickup'),
        position: _pickup,
        infoWindow: const InfoWindow(title: 'Pickup'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      ),
      Marker(
        markerId: const MarkerId('destination'),
        position: _destination,
        infoWindow: const InfoWindow(title: 'Destination'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ),
    ]);

    _polylines.add(Polyline(
      polylineId: const PolylineId('route'),
      color: Colors.deepPurple,
      width: 4,
      points: _routePoints,
    ));
  }

  void _startDriverMovementSimulation() {
    _movementTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (_step >= 21) {
        timer.cancel();

        await Future.delayed(const Duration(seconds: 1));

        if (mounted) {
          context.go(
            '/ride-complete', // <- change this route as per your flow
          );
        }
        return;
      }

      setState(() {
        _driverLocation = _interpolate(_pickup, _destination, _step / 20);
        _progress = _step / 20;
        _step++;
        _updateDriverMarker();
      });

      final controller = await _mapController.future;
      controller.animateCamera(CameraUpdate.newLatLng(_driverLocation));
    });
  }

  LatLng _interpolate(LatLng start, LatLng end, double t) {
    return LatLng(
      start.latitude + (end.latitude - start.latitude) * t,
      start.longitude + (end.longitude - start.longitude) * t,
    );
  }

  void _updateDriverMarker() {
    _markers.removeWhere((m) => m.markerId.value == 'driver');
    _markers.add(
      Marker(
        markerId: const MarkerId('driver'),
        position: _driverLocation,
        infoWindow: const InfoWindow(title: 'Driver'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
       title: ("Ride in Progress"),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _pickup,
              zoom: 15,
            ),
            onMapCreated: (controller) => _mapController.complete(controller),
            markers: _markers,
            polylines: _polylines,
            zoomControlsEnabled: false,
            myLocationButtonEnabled: false,
          ),
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Heading to: Periyar Bus Stand",
                    style: TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: _progress,
                    minHeight: 6,
                    color: Colors.deepPurple,
                    backgroundColor: Colors.grey.shade200,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "ETA: ${12 - (_progress * 10).round()} mins • 3.4 km",
                    style: const TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
