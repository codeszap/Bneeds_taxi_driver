import 'dart:async';
import 'package:bneeds_taxi_driver/widgets/common_main_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class RideOnTripScreen extends StatefulWidget {
  const RideOnTripScreen({super.key});

  @override
  State<RideOnTripScreen> createState() => _RideOnTripScreenState();
}

class _RideOnTripScreenState extends State<RideOnTripScreen> {
  final Completer<GoogleMapController> _mapController = Completer();

  final LatLng _driverPosition = const LatLng(9.9272, 78.1198); // Example
  final LatLng _destination = const LatLng(9.9252, 78.1198); // Example
  final Set<Polyline> _polylines = {};
  final double _progress = 0.4; // Dummy progress for now

  @override
  void initState() {
    super.initState();
    _addDummyPolyline(); // For visual route
  }

  void _addDummyPolyline() {
    _polylines.add(
      Polyline(
        polylineId: const PolylineId('route'),
        color: Colors.deepPurple,
        width: 4,
        points: [_driverPosition, _destination],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      title:("Ride in Progress"),
      body: Stack(
        children: [
          // MAP
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _driverPosition,
              zoom: 14.5,
            ),
            onMapCreated: (controller) => _mapController.complete(controller),
            markers: {
              Marker(
                markerId: const MarkerId('driver'),
                position: _driverPosition,
                infoWindow: const InfoWindow(title: 'Driver'),
              ),
              Marker(
                markerId: const MarkerId('destination'),
                position: _destination,
                infoWindow: const InfoWindow(title: 'Destination'),
              ),
            },
            polylines: _polylines,
            zoomControlsEnabled: false,
            myLocationButtonEnabled: false,
          ),

          // BOTTOM STATUS CARD
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Driver Info
                  Row(
                    children: [
                      const CircleAvatar(
                        radius: 28,
                        backgroundImage: AssetImage('assets/images/logo.png'),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text('Arun Kumar',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16)),
                            SizedBox(height: 4),
                            Text('White Swift • TN 58 AB 1234'),
                          ],
                        ),
                      ),
                      const Icon(Icons.star, color: Colors.amber, size: 20),
                      const SizedBox(width: 4),
                      const Text("4.9"),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Trip Progress
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Heading to: Periyar Bus Stand",
                          style: TextStyle(
                              fontWeight: FontWeight.w500, fontSize: 14)),
                      const SizedBox(height: 6),
                      LinearProgressIndicator(
                        value: _progress,
                        backgroundColor: Colors.grey.shade200,
                        color: Colors.deepPurple,
                        minHeight: 6,
                      ),
                      const SizedBox(height: 8),
                      const Text("ETA: 12 mins • 3.4 km"),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.call),
                          label: const Text("Call Driver"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            // Add cancel logic or dialog
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text("Cancel Ride"),
                        ),
                      ),
                    ],
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
