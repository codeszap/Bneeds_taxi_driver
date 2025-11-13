import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationHelper {
  /// Check GPS + Permission
  static Future<bool> checkAndRequestPermission(BuildContext context) async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showLocationDialog(context);
      return false;
    }

    // Check permission
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showLocationDialog(context);
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _showLocationDialog(context);
      return false;
    }

    return true;
  }

  /// Get current position
  static Future<Position?> getCurrentPosition(BuildContext context) async {
    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      debugPrint("Error getting location: $e");
      return null;
    }
  }

  /// Convert lat/long → address
  static Future<String?> getAddressFromPosition(Position pos) async {
    try {
      final placemarks = await placemarkFromCoordinates(
        pos.latitude,
        pos.longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        return "${place.name}, ${place.locality}, ${place.administrativeArea}";
      }
    } catch (e) {
      debugPrint("Error reverse geocoding: $e");
    }
    return null;
  }

  /// Dialog box
  static void _showLocationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Enable Location"),
        content: const Text("Please turn on GPS to get your current location."),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // close dialog
              await Geolocator.openLocationSettings(); // open phone location settings
            },
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

}
