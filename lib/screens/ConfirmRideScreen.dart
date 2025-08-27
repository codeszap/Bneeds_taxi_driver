import 'package:bneeds_taxi_driver/providers/location_provider.dart';
import 'package:bneeds_taxi_driver/repositories/booking_repository.dart';
import 'package:bneeds_taxi_driver/models/booking_model.dart';
import 'package:bneeds_taxi_driver/widgets/common_main_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Providers with default current date & time
final selectedServiceProvider = StateProvider<Map<String, dynamic>?>((ref) => null);
final selectedDateProvider = StateProvider<DateTime?>((ref) => DateTime.now());
final selectedTimeProvider = StateProvider<TimeOfDay?>((ref) => TimeOfDay.now());
final bookingRepositoryProvider = Provider<BookingRepository>((ref) => BookingRepository());

class ConfirmRideScreen extends ConsumerWidget {
  const ConfirmRideScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedServiceProvider);
    final selectedDate = ref.watch(selectedDateProvider);
    final selectedTime = ref.watch(selectedTimeProvider);

    final pickupLocation = ref.watch(fromLocationProvider);
    final dropLocation = ref.watch(toLocationProvider);

    final pickupAddress = pickupLocation.isNotEmpty ? pickupLocation : "Not selected";
    final dropAddress = dropLocation.isNotEmpty ? dropLocation : "Not selected";

    if (selected == null) {
      return const Scaffold(body: Center(child: Text("No service selected")));
    }

  Future<void> confirmBooking() async {
  final repository = ref.read(bookingRepositoryProvider);


final prefs = await SharedPreferences.getInstance();


final userId = prefs.getString('userid') ?? "";
final mobileNo = prefs.getString('mobileno') ?? "";

final booking = BookingModel(
  userid: userId,
  mobileNo: mobileNo,
  riderId: "",
  bookDate: DateTime.now().toIso8601String(), 
  scheduled: "Y", 
  rideDate: "${selectedDate!.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}", // yyyy-MM-dd
  pickupLocation: pickupAddress,
  dropLocation: dropAddress,
  mapLoc: "",
  distance: selected['distanceKm']?.toString() ?? "0", 
  fareAmount: selected['price'] ?? "0",
  vehSubTypeId: selected['typeId']?.toString() ?? "0",
  bookStatus: "B", 
  paymentMethod: "Cash",
  driverRate: "0", 
);

  // Show loading
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => const Center(child: CircularProgressIndicator()),
  );

  try {
    // Call API
  await repository.addBooking(booking);
 print("Booking payload (simulate API):");
    print(booking.toMap());
    Navigator.pop(context); // Remove loading

    // Show Ride Confirmed dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 30),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.deepPurple.shade50,
                ),
                child: const Icon(Icons.check_circle,
                    size: 48, color: Colors.deepPurple),
              ),
              const SizedBox(height: 16),
              const Text(
                "Ride Confirmed",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text(
                "Your ${selected['type']} is scheduled for "
                "${selectedDate.day}/${selectedDate.month} at ${selectedTime!.format(context)}.\n"
                "Pickup: $pickupAddress\nDrop: $dropAddress",
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  color: Colors.black87,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // ref.read(selectedServiceProvider.notifier).state = null;
                    // context.go('/searching');
                    ref.read(selectedServiceProvider.notifier).state = null;
                    context.go('/home');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    "OK",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  } catch (e) {
    Navigator.pop(context); // Remove loading
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Failed to confirm ride: $e")),
    );
  }
}

    return MainScaffold(
      title: "Confirm Ride",
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ride Type Card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.deepPurple.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: Colors.deepPurple.shade100,
                    child: Icon(selected['icon'] ?? Icons.local_taxi, color: Colors.deepPurple),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(selected['type'] ?? '', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                      Text(selected['price'] ?? '', style: const TextStyle(fontSize: 15, color: Colors.black54)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            // Address Box
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: const [Icon(Icons.location_on, size: 18, color: Colors.green), SizedBox(width: 6), Text("Pickup Address", style: TextStyle(fontWeight: FontWeight.w500, color: Colors.black54))]),
                  const SizedBox(height: 4),
                  Text(pickupAddress, style: const TextStyle(fontSize: 16)),
                  const Divider(height: 30),
                  Row(children: const [Icon(Icons.flag, size: 18, color: Colors.red), SizedBox(width: 6), Text("Drop Address", style: TextStyle(fontWeight: FontWeight.w500, color: Colors.black54))]),
                  const SizedBox(height: 4),
                  Text(dropAddress, style: const TextStyle(fontSize: 16)),
                ],
              ),
            ),
            const SizedBox(height: 30),
            // Date & Time Picker
            const Text("Schedule Ride", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      final pickedDate = await showDatePicker(
                        context: context,
                        initialDate: selectedDate ?? DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 30)),
                      );
                      if (pickedDate != null) ref.read(selectedDateProvider.notifier).state = pickedDate;
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                      decoration: BoxDecoration(color: Colors.deepPurple.shade50, border: Border.all(color: Colors.deepPurple.shade100), borderRadius: BorderRadius.circular(10)),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 20, color: Colors.deepPurple),
                          const SizedBox(width: 8),
                          Expanded(child: Text(selectedDate != null ? "${selectedDate.day}/${selectedDate.month}/${selectedDate.year}" : "Select Date", style: const TextStyle(fontSize: 14))),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      final pickedTime = await showTimePicker(context: context, initialTime: selectedTime ?? TimeOfDay.now());
                      if (pickedTime != null) ref.read(selectedTimeProvider.notifier).state = pickedTime;
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                      decoration: BoxDecoration(color: Colors.deepPurple.shade50, border: Border.all(color: Colors.deepPurple.shade100), borderRadius: BorderRadius.circular(10)),
                      child: Row(
                        children: [
                          const Icon(Icons.access_time, size: 20, color: Colors.deepPurple),
                          const SizedBox(width: 8),
                          Expanded(child: Text(selectedTime != null ? selectedTime.format(context) : "Select Time", style: const TextStyle(fontSize: 14))),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const Spacer(),
            // Confirm Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: Icon(Icons.check_circle_outline, color: Colors.white.withOpacity(0.7), size: 20),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                onPressed: () {
                  if (pickupAddress == "Not selected" || dropAddress == "Not selected") {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select pickup & drop locations")));
                    return;
                  }
                  if (selectedDate == null || selectedTime == null) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select date & time")));
                    return;
                  }

                  // Show confirmation dialog
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text("Confirm Ride"),
                      content: const Text("Are you sure you want to confirm this ride?"),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context), child: const Text("No")),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context); // Close confirmation
                            confirmBooking(); // Call API and show confirmed dialog
                          },
                          child: const Text("Yes"),
                        ),
                      ],
                    ),
                  );
                },
                label: Text("Confirm Ride", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white.withOpacity(0.7))),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
