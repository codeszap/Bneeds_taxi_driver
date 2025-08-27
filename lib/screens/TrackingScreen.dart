import 'dart:async';
import 'package:bneeds_taxi_driver/widgets/common_drawer.dart';
import 'package:bneeds_taxi_driver/widgets/common_main_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TrackingScreen extends ConsumerStatefulWidget {
  const TrackingScreen({super.key});

  @override
  ConsumerState<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends ConsumerState<TrackingScreen> {
  final Completer<GoogleMapController> _controller = Completer();

  static const LatLng _driverLatLng = LatLng(9.9300, 78.1200);
  static const LatLng _customerLatLng = LatLng(9.9350, 78.1240);

  final Set<Polyline> _polylines = {};
  final List<LatLng> _polylineCoordinates = [];

  double _progress = 0.0;
  Timer? _progressTimer;
  String _generatedOtp = '';
  bool _driverReached = false;

  @override
  void initState() {
    super.initState();

    // Generate OTP immediately
    _generatedOtp = _generateOtp();
    _driverReached = false;

    _getPolyline();
    _startProgressSimulation();
  }

  void _startProgressSimulation() {
    const duration = Duration(milliseconds: 500);
    _progressTimer = Timer.periodic(duration, (timer) {
      setState(() {
        _progress += 0.1;
        if (_progress >= 1.0) {
          _progress = 1.0;
          timer.cancel();

          // After progress finishes, go to next screen
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              context.go(
                '/ride-on-trip', // <- change this route as per your flow
              ); // <- change this route as per your flow
            }
          });
        }
      });
    });
  }

  void _getPolyline() {
    _polylineCoordinates.add(_driverLatLng);
    _polylineCoordinates.add(_customerLatLng);

    setState(() {
      _polylines.add(
        Polyline(
          polylineId: const PolylineId('route'),
          points: _polylineCoordinates,
          width: 5,
          color: Colors.deepPurple,
        ),
      );
    });
  }

  String _generateOtp() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final otp = now.remainder(10000).toString().padLeft(4, '0');
    return otp;
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    super.dispose();
  }

  void showCancelDialog(BuildContext context) {
    List<String> reasons = [
      "Driver took too long",
      "Wrong address",
      "Changed my mind",
      "Booked by mistake",
    ];

    String? selectedReason;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text(
                "Cancel Ride?",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: reasons.map((reason) {
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedReason = reason;
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: selectedReason == reason
                            ? Colors.deepPurple.withOpacity(0.1)
                            : Colors.transparent,
                        border: Border.all(
                          color: selectedReason == reason
                              ? Colors.deepPurple
                              : Colors.grey.shade300,
                        ),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            selectedReason == reason
                                ? Icons.radio_button_checked
                                : Icons.radio_button_off,
                            color: selectedReason == reason
                                ? Colors.deepPurple
                                : Colors.grey,
                          ),
                          const SizedBox(width: 10),
                          Text(reason),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              actions: [
                TextButton(
                  child: const Text("Close"),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                ElevatedButton(
                  onPressed: selectedReason != null
                      ? () {
                          Navigator.of(context).pop();

                          Future.delayed(const Duration(milliseconds: 200), () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  "Ride cancelled: $selectedReason",
                                ),
                                backgroundColor: Colors.redAccent,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          });

                          context.go('/home');
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text("Confirm Cancel"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
       title:('Tracking Ride'),
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(
              height: 400,
              child: GoogleMap(
                initialCameraPosition: const CameraPosition(
                  target: _customerLatLng,
                  zoom: 14.5,
                ),
                onMapCreated: (GoogleMapController controller) {
                  _controller.complete(controller);
                },
                markers: {
                  const Marker(
                    markerId: MarkerId('driver'),
                    position: _driverLatLng,
                    infoWindow: InfoWindow(title: 'Driver'),
                  ),
                  const Marker(
                    markerId: MarkerId('customer'),
                    position: _customerLatLng,
                    infoWindow: InfoWindow(title: 'You'),
                  ),
                },
                polylines: _polylines,
                zoomControlsEnabled: false,
                myLocationButtonEnabled: false,
              ),
            ),

            const SizedBox(height: 5),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Driver Info
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          radius: 30,
                          backgroundImage: AssetImage('assets/images/logo.png'),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'Arun Kumar',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text('White Swift - TN 58 AB 1234'),
                              SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.star,
                                    size: 16,
                                    color: Colors.amber,
                                  ),
                                  SizedBox(width: 4),
                                  Text('4.9'),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

            
                  // Always show OTP section
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
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
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text(
                          "Tell this OTP to the driver",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.black87,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: _generatedOtp.split('').map((digit) {
                            return Container(
                              margin: const EdgeInsets.symmetric(horizontal: 8),
                              padding: const EdgeInsets.symmetric(
                                vertical: 16,
                                horizontal: 20,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.deepPurple.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.deepPurple,
                                  width: 1.5,
                                ),
                              ),
                              child: Text(
                                digit,
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.deepPurple,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 20),

                        // Show progress bar always
                        Column(
                          children: [
                            const Text(
                              "Driver is arriving...",
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.black54,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            LinearProgressIndicator(
                              value: _progress,
                              backgroundColor: Colors.grey.shade200,
                              color: Colors.deepPurple,
                              minHeight: 6,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

              
                  const SizedBox(height: 20),

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
                            showCancelDialog(context);
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
          ],
        ),
      ),
    );
  }
}
