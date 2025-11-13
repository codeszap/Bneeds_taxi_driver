import 'package:bneeds_taxi_driver/providers/booking_provider.dart';
import 'package:bneeds_taxi_driver/providers/params/booking_params.dart';
import 'package:bneeds_taxi_driver/repositories/profile_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/Api Modal/AcceptBookingRequest.dart';
import 'models/CancelModel.dart';

class RideActionButton extends StatelessWidget {
  final String action;
  final VoidCallback onPressed;
  final Color? color;

  const RideActionButton({
    super.key,
    required this.action,
    required this.onPressed,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            textStyle: const TextStyle(fontSize: 18),
            backgroundColor: color ?? Colors.deepPurple,
            foregroundColor: Colors.white,
          ),
          child: Text(action),
        ),
      ),
    );
  }
}

// ConsumerStatefulWidget
class Demo extends ConsumerStatefulWidget {
  const Demo({super.key});

  @override
  ConsumerState<Demo> createState() => _DemoState();
}

class _DemoState extends ConsumerState<Demo> {
  final String _bookingId = "92";
  final String _riderId = "28";
  final int _bookingIdInt = 92;
  final int _riderIdInt = 28;
  final String _finalAmount = "20000";
  final String _currentLatLong = "12.9941,80.1709";

  final List<String> actions = const [
    'RIDE ACCEPT',
    'BOOKING DETAILS',
    'CANCEL',
    'TRIP UPDATE',
    'FETCH RATE',
    'COMPLETE',
  ];

  // Utility function to show Snackbar
  void _showSnackbar(String message, Color color) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // Action: RIDE ACCEPT
  Future<void> _handleRideAccept() async {
    _showSnackbar('Processing: RIDE ACCEPT...', Colors.blueGrey);
    // Common variables use panrom
    final dummyRequest = BookingRequest(
      bookingId: _bookingId,
      riderId: _riderId,
      action: "G",
    );

    try {
      final response = await ref.read(
        acceptBookingProvider(dummyRequest).future,
      );
      if (response.status == 'success') {
        _showSnackbar('✅ RIDE ACCEPTED! ${response.message}', Colors.green);
      } else {
        _showSnackbar('❌ RIDE ACCEPT FAILED: ${response.message}', Colors.red);
      }
    } catch (e) {
      _showSnackbar('❌ RIDE ACCEPT FAILED: API Error', Colors.red);
    }
  }

  // Action: BOOKING DETAILS
  Future<void> _handleBookingDetails() async {
    _showSnackbar('Processing: BOOKING DETAILS...', Colors.blueGrey);
    // Common variables use panrom
    final detailsParams = BookingParams(
      bookingId: _bookingIdInt, // int version
      riderId: _riderIdInt, // int version
    );

    try {
      final detailsList = await ref.read(
        fetchBookingDetailProvider(detailsParams).future,
      );
      if (detailsList.isNotEmpty) {
        final firstDetail = detailsList.first;
        _showSnackbar(
          '✅ Details: ID ${firstDetail.bookingId}, Rider: ${firstDetail.riderName}',
          Colors.blueGrey,
        );
      } else {
        _showSnackbar(
          '⚠️ No Booking Details Found or API Failed.',
          Colors.orange,
        );
      }
    } catch (e) {
      _showSnackbar('❌ BOOKING DETAILS FAILED: API Error', Colors.red);
    }
  }

  // Action: CANCEL
  Future<void> _handleCancel() async {
    _showSnackbar('Processing: CANCEL...', Colors.red.shade400);
    // Common variables use panrom
    final cancelModel = CancelModel(
      decline_reason: "Unknow reason",
      Bookingid: _bookingId,
    );

    // NOTE: Idhu oru example dhaan, real API result-eh use pannunga.
    final success = await ProfileRepository().cancelBooking(cancelModel);

    if (success) {
      _showSnackbar('❌ Booking Cancelled Successfully.', Colors.red);
    } else {
      _showSnackbar('⚠️ Cancel Request Failed.', Colors.orange);
    }
  }

  // Action: TRIP UPDATE
  Future<void> _handleTripUpdate() async {
    _showSnackbar('Processing: TRIP UPDATE...', Colors.blueGrey);
    // Common variables use panrom
    final tripUpdateDetail = RiderTripUpdateDetail(
      riderId: _riderId,
      bookingId: _bookingId,
      tripStatus: "D", // Driver has Reached
      toLatLong: "13.9941,90.1709", // Example destination update
    );
    final tripUpdateRequest = RiderTripUpdateRequest(
      updateTripStatus: [tripUpdateDetail],
    );

    try {
      final response = await ref.read(
        updateTripStatusProvider(tripUpdateRequest).future,
      );
      if (response.status == 'success') {
        _showSnackbar(
          '🚗 TRIP STATUS UPDATED to ${tripUpdateDetail.tripStatus}!',
          Colors.blue.shade700,
        );
      } else {
        _showSnackbar('❌ TRIP UPDATE FAILED: ${response.message}', Colors.red);
      }
    } catch (e) {
      _showSnackbar('❌ TRIP UPDATE FAILED: API Error', Colors.red);
    }
  }

  // Action: FETCH RATE
  Future<void> _handleFetchRate() async {
    _showSnackbar('Processing: FETCH RATE...', Colors.blueGrey);
    // Common variables use panrom
    final fareParams = FareCalculationParams(
      bookingId: _bookingId,
      riderId: _riderId,
      CurrentLatlong: '', // API needs current location here
    );

    try {
      final fareMap = await ref.read(calculateFareProvider(fareParams).future);
      if (fareMap != null && fareMap.containsKey('finalFare')) {
        final finalFare = fareMap['finalFare'] ?? 'N/A';
        final distance = fareMap['distanceKm'] ?? 'N/A';
        _showSnackbar(
          '💰 FARE CALCULATED! Total: ₹$finalFare, Distance: $distance km',
          Colors.indigo,
        );
      } else {
        _showSnackbar(
          '❌ FARE CALCULATION FAILED: Check booking status.',
          Colors.red,
        );
      }
    } catch (e) {
      _showSnackbar('❌ FARE CALCULATION FAILED: API Error', Colors.red);
    }
  }

  // Action: COMPLETE
  Future<void> _handleComplete() async {
    _showSnackbar('Processing: COMPLETE...', Colors.blueGrey);
    // Common variables use panrom
    final finalBookingParams = FinalBookingParams(
      bookingId: _bookingId,
      finalAmt: _finalAmount,
      driverCurrentLatLong: _currentLatLong,
      riderId: _riderId,
      riderStatus: "OL", // "Offload"
    );

    try {
      final response = await ref.read(
        finalBookingProvider(finalBookingParams).future,
      );
      if (response.status == 'success') {
        _showSnackbar(
          '✅ TRIP COMPLETE! Final Amount: ₹$_finalAmount',
          Colors.green.shade800,
        );
      } else {
        _showSnackbar(
          '❌ TRIP COMPLETION FAILED: ${response.message}',
          Colors.red,
        );
      }
    } catch (e) {
      _showSnackbar('❌ TRIP COMPLETION FAILED: API Error', Colors.red);
    }
  }

  // Main Handler to delegate
  Future<void> _handleButtonPress(String action) async {
    print('Action Triggered: $action');
    switch (action) {
      case 'RIDE ACCEPT':
        return _handleRideAccept();
      case 'BOOKING DETAILS':
        return _handleBookingDetails();
      case 'CANCEL':
        return _handleCancel();
      case 'TRIP UPDATE':
        return _handleTripUpdate();
      case 'FETCH RATE':
        return _handleFetchRate();
      case 'COMPLETE':
        return _handleComplete();
      default:
        return _showSnackbar('$action button pressed!', Colors.grey);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter Ride Actions'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: actions.map((action) {
              return RideActionButton(
                action: action,
                onPressed: () => _handleButtonPress(action),
                color: action == 'CANCEL'
                    ? Colors.red
                    : action == 'RIDE ACCEPT'
                    ? Colors.green
                    : Colors.deepPurple,
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
