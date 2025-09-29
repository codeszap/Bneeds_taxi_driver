import 'package:bneeds_taxi_driver/screens/onTrip/widget/InfoCard.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:bneeds_taxi_driver/utils/storage.dart';

import '../../models/TripState.dart';
import '../../repositories/vehicle_type_repository.dart';

Future<void> showOtpDialog(
    BuildContext context,
    WidgetRef ref,
    Function onOtpVerified,
    String realOtp,
    String customerFcm,
    String bookingId,
    LatLng pickupLatLng,
    String pickup,
    ) async {
  const int otpLength = 4;

  final List<TextEditingController> controllers = List.generate(
    otpLength,
        (_) => TextEditingController(),
  );
  final List<FocusNode> focusNodes = List.generate(
    otpLength,
        (_) => FocusNode(),
  );

  bool isError = false;

  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setState) {
          void submitOtp() async {
            final otp = controllers.map((c) => c.text).join();
            if (otp == realOtp) {
              Navigator.of(dialogContext).pop();
              onOtpVerified();

              if (customerFcm.isNotEmpty) {
                await FirebasePushService.sendPushNotification(
                  fcmToken: customerFcm,
                  title: "Ride Started✅",
                  body: "Your ride has started. Sit back and relax!",
                  data: {
                    "bookingId": bookingId,
                    "status": "start trip",
                    "driverLatLong": pickupLatLng.toString(),
                    "otp": otp,
                  },
                );
              }
            } else {
              setState(() => isError = true);
            }
          }

          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Center(
              child: Text(
                Strings.enterOtp,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(Strings.enterOtpDesc),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(otpLength, (index) {
                    return SizedBox(
                      width: 50,
                      child: TextField(
                        controller: controllers[index],
                        focusNode: focusNodes[index],
                        maxLength: 1,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                        decoration: InputDecoration(
                          counterText: '',
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: Colors.grey,
                              width: 2,
                            ),
                          ),
                        ),
                        onChanged: (value) {
                          if (value.isNotEmpty && index < otpLength - 1)
                            focusNodes[index + 1].requestFocus();
                          if (value.isEmpty && index > 0)
                            focusNodes[index - 1].requestFocus();
                          if (controllers.every((c) => c.text.isNotEmpty))
                            submitOtp();
                        },
                      ),
                    );
                  }),
                ),
                if (isError)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      Strings.invalidOtp,
                      style: TextStyle(
                        color: Colors.red[700],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            actionsAlignment: MainAxisAlignment.center,
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text(Strings.cancel),
              ),
            ],
          );
        },
      );
    },
  );
}
