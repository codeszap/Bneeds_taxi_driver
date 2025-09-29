import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:bneeds_taxi_driver/utils/storage.dart';

import '../screens/home/driver_location_service.dart';


// ---- Google Suggestions Provider ----
final placeSuggestionsProvider = FutureProvider.family<List<String>, String>((
  ref,
  query,
) async {
  if (query.isEmpty) return [];
  final url = Uri.parse(
    "https://maps.googleapis.com/maps/api/place/autocomplete/json?input=${Uri.encodeComponent(query)}&key=${Strings.googleApiKey}&components=country:in",
  );
  final response = await http.get(url);
  final jsonBody = jsonDecode(response.body);
  if (jsonBody["status"] == "OK") {
    return (jsonBody["predictions"] as List)
        .map((e) => e["description"] as String)
        .toList();
  } else {
    return [];
  }
});

final locationErrorDialogShownProvider = StateProvider<bool>((ref) => false);
final selectedServiceProvider = StateProvider<Map<String, dynamic>?>((ref) => null);

final fromLocationProvider = StateProvider<String>((ref) => 'Current Locations');
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



