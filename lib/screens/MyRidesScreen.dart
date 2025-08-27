import 'package:bneeds_taxi_driver/widgets/common_main_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

enum RideFilter { all, week, month, year }

class RideInfo {
  final String pickup;
  final String drop;
  final DateTime dateTime;
  final String fare;
  final String status;

  RideInfo({
    required this.pickup,
    required this.drop,
    required this.dateTime,
    required this.fare,
    required this.status,
  });
}

final rideFilterProvider = StateProvider<RideFilter>((ref) => RideFilter.all);

final rideListProvider = Provider<List<RideInfo>>((ref) {
  return [
    RideInfo(
      pickup: "Anna Nagar",
      drop: "Periyar Bus Stand",
      dateTime: DateTime(2025, 8, 1, 16, 30),
      fare: "₹210",
      status: "Completed",
    ),
    RideInfo(
      pickup: "Mattuthavani",
      drop: "Railway Junction",
      dateTime: DateTime(2025, 7, 28, 13, 10),
      fare: "₹180",
      status: "Completed",
    ),
    RideInfo(
      pickup: "Kalavasal",
      drop: "Airport",
      dateTime: DateTime(2025, 7, 25, 9, 45),
      fare: "₹320",
      status: "Cancelled",
    ),
  ];
});

final filteredRidesProvider = Provider<List<RideInfo>>((ref) {
  final filter = ref.watch(rideFilterProvider);
  final allRides = ref.watch(rideListProvider);
  final now = DateTime.now();

  return allRides.where((ride) {
    final rideDate = ride.dateTime;
    switch (filter) {
      case RideFilter.week:
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        return rideDate.isAfter(startOfWeek);
      case RideFilter.month:
        return rideDate.month == now.month && rideDate.year == now.year;
      case RideFilter.year:
        return rideDate.year == now.year;
      default:
        return true;
    }
  }).toList();
});

class MyRidesScreen extends ConsumerWidget {
  const MyRidesScreen({super.key});

  @override
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rides = ref.watch(filteredRidesProvider);
    final selectedFilter = ref.watch(rideFilterProvider);

    return MainScaffold(
        title: ("My Rides"),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildFilterChips(ref, selectedFilter),
            const SizedBox(height: 16),
            Expanded(
              child: rides.isEmpty
                  ? const Center(
                      child: Text(
                        'No rides found.',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    )
                  : ListView.separated(
                      itemCount: rides.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final ride = rides[index];
                        return _buildRideCard(ride);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChips(WidgetRef ref, RideFilter selected) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: RideFilter.values.map((filter) {
          final isSelected = selected == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              label: Text(_filterLabel(filter)),
              selected: isSelected,
              onSelected: (_) =>
                  ref.read(rideFilterProvider.notifier).state = filter,
              selectedColor: Colors.deepPurple,
              backgroundColor: Colors.grey.shade200,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.black,
                fontWeight: FontWeight.w500,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  String _filterLabel(RideFilter filter) {
    switch (filter) {
      case RideFilter.week:
        return 'This Week';
      case RideFilter.month:
        return 'This Month';
      case RideFilter.year:
        return 'This Year';
      case RideFilter.all:
      default:
        return 'All';
    }
  }

  Widget _buildRideCard(RideInfo ride) {
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.my_location, color: Colors.green),
              const SizedBox(width: 8),
              Text(
                ride.pickup,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.location_on, color: Colors.red),
              const SizedBox(width: 8),
              Text(ride.drop),
            ],
          ),
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                DateFormat('MMM d, yyyy • h:mm a').format(ride.dateTime),
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
              Row(
                children: [
                  Text(
                    ride.fare,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: ride.status == "Completed"
                          ? Colors.green.shade100
                          : Colors.red.shade100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      ride.status,
                      style: TextStyle(
                        color: ride.status == "Completed"
                            ? Colors.green
                            : Colors.red,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
