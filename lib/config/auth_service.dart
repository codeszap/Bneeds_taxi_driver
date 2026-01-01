import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bneeds_taxi_driver/utils/storage.dart';
import 'package:flutter/foundation.dart';

final generatedOtpProvider = StateProvider<String?>((ref) => null);

Future<void> sendOTP({
  required WidgetRef ref,
  required String phoneNumber,
  required Function onCodeSent,
  required Function(String error) onError,
}) async {
  try {
    // 1. Generate a random 4-digit OTP
    final otp = (Random().nextInt(9000) + 1000).toString(); // 1000–9999

    // 2. Store OTP locally for later verification
    ref.read(generatedOtpProvider.notifier).state = otp;

    // 3. Prepare message
    final message = "microotp~$otp";

    // 4. Build URL for SMS API
    var urlString =
        "https://nminfotech.in/smsautosend.aspx"
        "?id=RAMMTR"
        "&PWD=RAMMTR"
        "&mob=$phoneNumber"
        "&msg=$message"
        "&tm=T";

    // If on Web, use a CORS proxy to bypass browser restrictions
    if (kIsWeb) {
      // Use thingproxy as alternative
      urlString = "https://thingproxy.freeboard.io/fetch/$urlString";
    }

    final url = Uri.parse(urlString);

    // Print URL in console for debugging
    print("OTP URL: $url");

    // 5. Send OTP via SMS API
    final response = await http.get(url);

    if (kIsWeb) {
      // Check proxy response
      if (response.statusCode == 200) {
        onCodeSent();
      } else {
        print("Proxy Error Body: ${response.body}");
        onError("Failed to send OTP via proxy: ${response.statusCode}");
      }
    } else {
      if (response.statusCode == 200) {
        onCodeSent();
      } else {
        onError("Failed to send OTP: ${response.body}");
      }
    }
  } catch (e) {
    onError("Error sending OTP: ${e.toString()}");
  }
}

Future<bool> verifyOTPAndCheckUser({
  required WidgetRef ref,
  required String otp,
  required String username,
  required String mobileNo,
  required ProfileRepository profileRepo,
}) async {
  final generatedOtp = ref.read(generatedOtpProvider);

  if (generatedOtp == null) {
    throw Exception("No OTP generated");
  }

  if (otp != generatedOtp) {
    throw Exception("Invalid OTP");
  }

  try {
    // fetch rider profiles as list
    final riders = await profileRepo.getRiderLogin(mobileno: mobileNo);

    if (riders.isNotEmpty) {
      await SharedPrefsHelper.setRiderId(riders.first.riderId);
      await SharedPrefsHelper.setDriverMobile(mobileNo);
      await SharedPrefsHelper.setBookingId(riders.first.userName);
      await SharedPrefsHelper.setIsDriverProfileCompleted(true);
      return true;
    }

    // No rider found
    return false;
  } catch (e) {
    print("Error fetching rider login: $e");
    return false;
  }
}
