
// --- Trip Complete Screen ---
import 'package:bneeds_taxi_driver/screens/OnTripScreen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class TripCompleteScreen extends ConsumerWidget {
  const TripCompleteScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trip = ref.watch(tripProvider);

    return Scaffold(
    //  appBar: AppBar(title: const Text("Trip Completed"), backgroundColor: Colors.green),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, size: 80, color: Colors.green),
            const SizedBox(height: 16),
            Text("Trip Completed Successfully!", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Text("Fare: ₹${trip.fare}", style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            const Text("Payment: Cash", style: TextStyle(fontSize: 18)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                ref.read(tripProvider.notifier).reset();
               context.go('/driverHome');
              },
              child: const Text("Back to Home"),
            ),
          ],
        ),
      ),
    );
  }
}
