import 'package:bneeds_taxi_driver/widgets/common_main_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:location/location.dart' as loc; 
import 'package:go_router/go_router.dart';

class SelectOnMapScreen extends StatefulWidget {
  const SelectOnMapScreen({super.key});

  @override
  State<SelectOnMapScreen> createState() => _SelectOnMapScreenState();
}

class _SelectOnMapScreenState extends State<SelectOnMapScreen> {
  GoogleMapController? _mapController;
  LatLng? _selectedLatLng;
  String? _address;
  bool _loading = false;

final loc.Location _location = loc.Location();


  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initializeLocation());
  }

  Future<void> _initializeLocation() async {
    bool serviceEnabled = await _location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _location.requestService();
      if (!serviceEnabled) return;
    }

    loc.PermissionStatus permissionGranted = await _location.hasPermission();
    if (permissionGranted == loc.PermissionStatus.denied) {
      permissionGranted = await _location.requestPermission();
      if (permissionGranted != loc.PermissionStatus.granted) return;
    }

    final currentLoc = await _location.getLocation();
    final userLatLng = LatLng(currentLoc.latitude!, currentLoc.longitude!);
    _mapController?.animateCamera(CameraUpdate.newLatLngZoom(userLatLng, 16));
  }

  void _onTapMap(LatLng position) {
    setState(() {
      _selectedLatLng = position;
      _address = null;
      _loading = true;
    });
    _getAddressFromLatLng(position);
  }

  Future<void> _getAddressFromLatLng(LatLng position) async {
    try {
      final placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        setState(() {
          _address = "${p.name}, ${p.locality}, ${p.administrativeArea}";
        });
      } else {
        setState(() => _address = "Address not found");
      }
    } catch (e) {
      setState(() => _address = "Failed to fetch address");
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
       title:("Select Location on Map"),
      body: Column(
        children: [
          Expanded(
            child: GoogleMap(
              initialCameraPosition: const CameraPosition(
                target: LatLng(10.0014, 77.4838), // Madurai
                zoom: 14,
              ),
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              onMapCreated: (controller) => _mapController = controller,
              onTap: _onTapMap,
              markers: _selectedLatLng != null
                  ? {
                      Marker(
                        markerId: const MarkerId("selected_location"),
                        position: _selectedLatLng!,
                      )
                    }
                  : {},
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Selected Address",
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Text(
                  _loading
                      ? "Fetching address..."
                      : _address ?? "Tap on the map to choose a location",
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: _selectedLatLng == null || _loading
                      ? null
                      : () {
                          // Return to previous screen with selected address
                          context.pop(_address);
                        },
                  icon: const Icon(Icons.check),
                  label: const Text("Select Location"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
