// import 'package:bneeds_taxi_driver/providers/location_provider.dart'
//     show fromLocationProvider, toLocationProvider;
// import 'package:bneeds_taxi_driver/providers/vehicle_subtype_provider.dart';
// import 'package:bneeds_taxi_driver/screens/ConfirmRideScreen.dart';
// import 'package:bneeds_taxi_driver/widgets/common_main_scaffold.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:intl/intl.dart';

// class ServiceOptionsScreen extends ConsumerWidget {
//   final String vehTypeId;
//   final String totalKms;
//   final String estTime;

//   const ServiceOptionsScreen({
//     super.key,
//     required this.vehTypeId,
//     required this.totalKms,
//     required this.estTime,
//   });
//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final selectedService = ref.watch(selectedServiceProvider);
//     final subTypesAsync = ref.watch(
//       vehicleSubTypeProvider((vehTypeId, totalKms)),
//     );

//     final fromLocation = ref.watch(fromLocationProvider);
//     final toLocation = ref.watch(toLocationProvider);

//     return MainScaffold(
//       title: ("Choose a Service"),
//       body: subTypesAsync.when(
//         data: (subTypes) {
//           return Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // Pickup & Drop locations
//               // Container(
//               //   width: double.infinity,
//               //   padding: const EdgeInsets.all(16),
//               //   color: Colors.grey[100],
//               //   child: Column(
//               //     crossAxisAlignment: CrossAxisAlignment.start,
//               //     children: [
//               //       const Text(
//               //         "Pick-up Location",
//               //         style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
//               //       ),
//               //       const SizedBox(height: 4),
//               //       Text(fromLocation, style: const TextStyle(fontSize: 15)),
//               //       const SizedBox(height: 12),
//               //       const Text(
//               //         "Drop-off Location",
//               //         style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
//               //       ),
//               //       const SizedBox(height: 4),
//               //       Text(toLocation, style: const TextStyle(fontSize: 15)),
//               //     ],
//               //   ),
//               // ),
//               // const SizedBox(height: 10),

//               // List of vehicle subtypes
//               Expanded(
//                 child: ListView.separated(
//                   padding: const EdgeInsets.all(10),
//                   itemCount: subTypes.length,
//                   separatorBuilder: (_, __) => const SizedBox(height: 10),
//                   itemBuilder: (context, index) {
//                     final item = subTypes[index];
//                     final selected = ref.watch(selectedServiceProvider);

//                     // Check if this item is selected
//                     final isSelected =
//                         selected != null &&
//                         selected['typeId'] == item.vehSubTypeId;

//                     return GestureDetector(
//                       onTap: () {
//                         // Update selectedService in provider
//                         ref.read(selectedServiceProvider.notifier).state = {
//                           'typeId': item.vehSubTypeId,
//                           'type': item.vehSubTypeName,
//                           'price': item.totalKms ?? '0',
//                           'distanceKm': totalKms,
//                           'durationMin': estTime, 
//                         };
//                       },
//                       child: Container(
//                         decoration: BoxDecoration(
//                           color: Colors.white,
//                           borderRadius: BorderRadius.circular(10),
//                           border: isSelected
//                               ? Border.all(color: Colors.blue, width: 2)
//                               : Border.all(color: Colors.transparent),
//                           boxShadow: [
//                             BoxShadow(
//                               color: Colors.black.withOpacity(0.05),
//                               blurRadius: 6,
//                               offset: const Offset(0, 2),
//                             ),
//                           ],
//                         ),
//                         child: ListTile(
//                           leading: CircleAvatar(
//                             backgroundColor: Colors.deepPurple.shade100,
//                             child: const Icon(
//                               Icons.local_taxi,
//                               color: Colors.deepPurple,
//                             ),
//                           ),
//                           title: Text(
//                             item.vehSubTypeName ?? '',
//                             style: const TextStyle(
//                               fontWeight: FontWeight.w700,
//                               fontSize: 17,
//                             ),
//                           ),
//                           subtitle: Text(
//                             "Distance: $totalKms km · Est. Drop: $estTime",
//                             style: const TextStyle(
//                               fontSize: 13,
//                               color: Colors.black54,
//                             ),
//                           ),
//                           trailing: Text(
//                             "₹${item.totalKms ?? '0'}",
//                             style: const TextStyle(
//                               fontSize: 16,
//                               fontWeight: FontWeight.bold,
//                               color: Colors.black87,
//                             ),
//                           ),
//                         ),
//                       ),
//                     );
//                   },
//                 ),
//               ),

//               // Book Ride Button
//               SafeArea(
//                 child: Padding(
//                   padding: const EdgeInsets.all(16),
//                   child: SizedBox(
//                     width: double.infinity,
//                     child: ElevatedButton(
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: selectedService != null
//                             ? Colors.deepPurple
//                             : Colors.grey,
//                         padding: const EdgeInsets.symmetric(vertical: 16),
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(10),
//                         ),
//                       ),
//                       onPressed: selectedService == null
//                           ? null
//                           : () {
//                               Navigator.push(
//                                 context,
//                                 MaterialPageRoute(
//                                   builder: (_) => const ConfirmRideScreen(),
//                                 ),
//                               );
//                             },
//                       child: const Text(
//                         "Book Ride",
//                         style: TextStyle(
//                           fontSize: 16,
//                           fontWeight: FontWeight.bold,
//                           color: Colors.white70,
//                         ),
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//             ],
//           );
//         },
//         loading: () => const Center(child: CircularProgressIndicator()),
//         error: (err, stack) => Center(child: Text("Error: $err")),
//       ),
//     );
//   }
// }
