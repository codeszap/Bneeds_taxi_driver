import '../screens/home/widget/ride_request_card.dart';
import 'package:bneeds_taxi_driver/screens/home/widget/ride_request_card.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bneeds_taxi_driver/utils/storage.dart';
import '../../models/rideRequest.dart';
class GlobalRideRequestOverlay extends ConsumerWidget {
  final Widget child;
  const GlobalRideRequestOverlay({required this.child, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rideRequest = ref.watch(rideRequestProvider);

    return Stack(
      children: [
        child, // your normal app
        if (rideRequest != null)
          RideRequestCard(
            rideRequest: rideRequest,
            audioPlayer: AudioPlayer(),
          ),
      ],
    );
  }
}
