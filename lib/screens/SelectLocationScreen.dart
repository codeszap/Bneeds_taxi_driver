import 'dart:convert';
import 'package:bneeds_taxi_driver/providers/location_provider.dart';
import 'package:bneeds_taxi_driver/widgets/common_main_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:go_router/go_router.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

// Google Places API Key
const String _googleApiKey = 'AIzaSyAWzUqf3Z8xvkjYV7F4gOGBBJ5d_i9HZhs';

// Recent locations
final recentLocationsProvider =
    StateNotifierProvider<RecentLocationsNotifier, List<Map<String, String>>>(
      (ref) => RecentLocationsNotifier(),
    );

// Google Place Suggestions
final placeSuggestionsProvider = FutureProvider.family<List<String>, String>((
  ref,
  query,
) async {
  if (query.isEmpty) return [];
  final url = Uri.parse(
    'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=${Uri.encodeComponent(query)}&key=$_googleApiKey&components=country:in',
  );

  final response = await http.get(url);
  final jsonBody = jsonDecode(response.body);

  if (jsonBody['status'] == 'OK') {
    return (jsonBody['predictions'] as List)
        .map((e) => e['description'] as String)
        .toList();
  } else {
    throw Exception(
      jsonBody['error_message'] ?? 'Error: ${jsonBody['status']}',
    );
  }
});

class RecentLocationsNotifier extends StateNotifier<List<Map<String, String>>> {
  RecentLocationsNotifier() : super([]);

  void addLocation(String location, {String subLocation = "Recent"}) {
    if (state.any((e) => e['location'] == location)) return;
    state = [
      {"location": location, "subLocation": subLocation},
      ...state,
    ];
    if (state.length > 10) state = state.sublist(0, 10);
  }
}

// Helper: Position -> Address
Future<String> getAddressFromPosition(Position position) async {
  List<Placemark> placemarks = await placemarkFromCoordinates(
    position.latitude,
    position.longitude,
  );
  if (placemarks.isNotEmpty) {
    final placemark = placemarks.first;
    return "${placemark.name}, ${placemark.locality}, ${placemark.country}";
  }
  return "${position.latitude}, ${position.longitude}";
}

class SelectLocationScreen extends ConsumerWidget {
  final String vehTypeId;
  const SelectLocationScreen({super.key, required this.vehTypeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fromLocation = ref.watch(fromLocationProvider);
    final toLocation = ref.watch(toLocationProvider);
    final query = ref.watch(placeQueryProvider);
    final suggestionsAsync = ref.watch(placeSuggestionsProvider(query));
    final recentLocations = ref.watch(recentLocationsProvider);

    // Filter recent locations matching query
    final matchedRecentLocations = recentLocations
        .where(
          (e) => e['location']!.toLowerCase().contains(query.toLowerCase()),
        )
        .toList();

    // Auto-fetch current location on screen load
    // Inside build() of SelectLocationScreen
    ref.listen<AsyncValue<Position>>(currentLocationProvider, (
      prev,
      next,
    ) async {
      if (next.hasValue) {
        final address = await getAddressFromPosition(next.value!);
        // Update fromLocationProvider with real address
        ref.read(fromLocationProvider.notifier).state = address;
      }
    });

    return MainScaffold(
      title:  ("Select Location"),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // From Location
            _LocationField(
              label: "From",
              initialValue: fromLocation,
              icon: Icons.my_location,
              onChanged: (value) {
                ref.read(fromLocationProvider.notifier).state = value;
                ref.read(placeQueryProvider.notifier).state = value;
              },
              onSuggestionTap: (location) {
                ref.read(fromLocationProvider.notifier).state = location;
                ref.read(placeQueryProvider.notifier).state = '';
                ref
                    .read(recentLocationsProvider.notifier)
                    .addLocation(location);
              },
              suffixIcon: IconButton(
                icon: const Icon(Icons.gps_fixed, color: Colors.deepPurple),
                onPressed: () async {
                  try {
                    final position = await ref.read(
                      currentLocationProvider.future,
                    );
                    final address = await getAddressFromPosition(position);
                    ref.read(fromLocationProvider.notifier).state = address;
                    ref.read(placeQueryProvider.notifier).state = '';
                    ref
                        .read(recentLocationsProvider.notifier)
                        .addLocation(address);
                  } catch (e) {
                    if (!ref.read(locationErrorDialogShownProvider)) {
                      ref
                              .read(locationErrorDialogShownProvider.notifier)
                              .state =
                          true;
                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text("Location Error"),
                          content: Text(e.toString()),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                                ref
                                        .read(
                                          locationErrorDialogShownProvider
                                              .notifier,
                                        )
                                        .state =
                                    false;
                              },
                              child: const Text("OK"),
                            ),
                          ],
                        ),
                      );
                    }
                  }
                },
              ),
            ),
            const SizedBox(height: 12),
            // To Location
            _LocationField(
              label: "To",
              initialValue: toLocation,
              icon: Icons.place_outlined,
              onChanged: (value) {
                ref.read(toLocationProvider.notifier).state = value;
                ref.read(placeQueryProvider.notifier).state = value;
              },
              onSuggestionTap: (location) {
                ref.read(toLocationProvider.notifier).state = location;
                ref.read(placeQueryProvider.notifier).state = '';
                ref
                    .read(recentLocationsProvider.notifier)
                    .addLocation(location);
                context.push('/service-options', extra: vehTypeId);
              },
            ),
            const SizedBox(height: 20),
            _buildMapButton(context, ref),
            const SizedBox(height: 20),
            // Suggestions
            Expanded(
              child: suggestionsAsync.when(
                data: (googleSuggestions) {
                  final newSuggestions = googleSuggestions
                      .where(
                        (s) => !matchedRecentLocations.any(
                          (r) => r['location'] == s,
                        ),
                      )
                      .toList();

                  final combinedList = [
                    ...matchedRecentLocations,
                    ...newSuggestions.map(
                      (s) => {"location": s, "subLocation": "Suggested"},
                    ),
                  ];

                  if (combinedList.isEmpty) return const SizedBox();

                  return ListView.separated(
                    itemCount: combinedList.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final item = combinedList[index];
                      final isEditingFrom = query == fromLocation;
                      return _buildSuggestionTile(
                        context,
                        ref,
                        item['location']!,
                        item['subLocation']!,
                        isFrom: isEditingFrom,
                      );
                    },
                  );
                },
                loading: () => const LinearProgressIndicator(),
                error: (_, __) => const SizedBox(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapButton(BuildContext context, WidgetRef ref) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () async {
          final selectedAddress = await context.push<String>('/select-on-map');
          if (selectedAddress != null && selectedAddress.isNotEmpty) {
            ref.read(toLocationProvider.notifier).state = selectedAddress;
            ref.read(placeQueryProvider.notifier).state = '';
            ref
                .read(recentLocationsProvider.notifier)
                .addLocation(selectedAddress);
          }
        },
        icon: const Icon(Icons.map_outlined),
        label: const Text("Select on Map"),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestionTile(
    BuildContext context,
    WidgetRef ref,
    String location,
    String subLocation, {
    required bool isFrom,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: const Icon(Icons.place_outlined, color: Colors.deepPurple),
        title: Text(
          location,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          subLocation,
          style: const TextStyle(fontSize: 13, color: Colors.black54),
        ),
        onTap: () {
          if (isFrom) {
            ref.read(fromLocationProvider.notifier).state = location;
          } else {
            ref.read(toLocationProvider.notifier).state = location;
            context.push('/service-options', extra: vehTypeId);
          }
          ref.read(placeQueryProvider.notifier).state = '';
          ref.read(recentLocationsProvider.notifier).addLocation(location);
        },
      ),
    );
  }
}

// Reusable Location Field
class _LocationField extends ConsumerStatefulWidget {
  final String label;
  final String initialValue;
  final IconData icon;
  final Widget? suffixIcon;
  final Function(String) onChanged;
  final Function(String) onSuggestionTap;

  const _LocationField({
    required this.label,
    required this.initialValue,
    required this.icon,
    required this.onChanged,
    required this.onSuggestionTap,
    this.suffixIcon,
  });

  @override
  ConsumerState<_LocationField> createState() => _LocationFieldState();
}

class _LocationFieldState extends ConsumerState<_LocationField> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentValue = ref.watch(fromLocationProvider) == widget.initialValue
        ? ref.watch(fromLocationProvider)
        : ref.watch(toLocationProvider);

    if (_controller.text != currentValue) {
      _controller.value = TextEditingValue(
        text: currentValue,
        selection: TextSelection.collapsed(offset: currentValue.length),
      );
    }

    return TextField(
      controller: _controller,
      onChanged: widget.onChanged,
      decoration: InputDecoration(
        labelText: widget.label,
        prefixIcon: Icon(widget.icon, color: Colors.deepPurple),
        suffixIcon: widget.suffixIcon,
        filled: true,
        fillColor: Colors.grey[100],
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.deepPurple, width: 2),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
