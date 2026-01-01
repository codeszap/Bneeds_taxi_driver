import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:bneeds_taxi_driver/utils/storage.dart';
import 'package:bneeds_taxi_driver/utils/constants.dart';
import 'package:geolocator/geolocator.dart';

import '../models/rideRequest.dart';
import '../screens/home/driver_location_service.dart';

// ---- Google Suggestions Provider ----
final placeSuggestionsProvider = FutureProvider.family<List<String>, String>((
  ref,
  query,
) async {
  if (query.isEmpty) return [];
  String urlString =
      "https://maps.googleapis.com/maps/api/place/autocomplete/json?input=${Uri.encodeComponent(query)}&key=${Strings.googleApiKey}&components=country:in";

  if (kIsWeb) {
    // Use thingproxy as alternative
    urlString = "https://thingproxy.freeboard.io/fetch/$urlString";
  }

  final response = await http.get(Uri.parse(urlString));

  Map<String, dynamic> jsonBody = jsonDecode(response.body);

  if (jsonBody["status"] == "OK") {
    return (jsonBody["predictions"] as List)
        .map((e) => e["description"] as String)
        .toList();
  } else {
    return [];
  }
});

final locationErrorDialogShownProvider = StateProvider<bool>((ref) => false);
final selectedServiceProvider = StateProvider<Map<String, dynamic>?>(
  (ref) => null,
);

final fromLocationProvider = StateProvider<String>(
  (ref) => 'Current Locations',
);
final toLocationProvider = StateProvider<String>((ref) => '');
final placeQueryProvider = StateProvider<String>((ref) => '');

// final fromLatLngProvider = StateProvider<LatLng?>((ref) => null);
// final toLatLngProvider = StateProvider<LatLng?>((ref) => null);

final currentLocationProvider = FutureProvider<Position>((ref) async {
  bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    throw Exception('Location services are disabled.');
  }

  LocationPermission permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      throw Exception('Location permissions are denied.');
    }
  }

  if (permission == LocationPermission.deniedForever) {
    throw Exception('Location permissions are permanently denied.');
  }

  return await Geolocator.getCurrentPosition(
    desiredAccuracy: LocationAccuracy.high,
  );
});

// Stores current ride request, null if none
final rideRequestProvider = StateProvider<RideRequest?>((ref) => null);

// Stores whether the ride has been cancelled
final rideCancelledProvider = StateProvider<bool>((ref) => false);
