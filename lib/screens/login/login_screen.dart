import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../widgets/common_textfield.dart';
import 'otp_dialog.dart';
import 'package:bneeds_taxi_driver/config/auth_service.dart' as authService;

final usernameProvider = StateProvider<String>((ref) => '');
final mobileProvider = StateProvider<String>((ref) => '');
final isLoadingProvider = StateProvider<bool>((ref) => false);

class DriverLoginScreen extends ConsumerWidget {
  const DriverLoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final username = ref.watch(usernameProvider);
    final mobile = ref.watch(mobileProvider);
    final isFormValid = username.isNotEmpty && mobile.length == 10;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF9C4), // Light Yellow background
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 50),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Logo + Welcome Text
              Center(
                child: Column(
                  children: [
                    Image.asset(
                      'assets/images/logo.png',
                      width: 120,
                      height: 120,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "Welcome Driver!",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87, // Dark text on yellow background
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      "Sign in to manage your rides",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black54, // Slightly lighter
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 50),

              // Form Card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white, // Card remains white for contrast
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 12,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    CommonTextField(
                      label: 'Username',
                      keyboardType: TextInputType.text,
                      fillColor: Colors.grey[200], // light gray background
                      focusedBorderColor:
                          Colors.black, // green when focused
                      enabledBorderColor:
                          Colors.grey[500], // darker gray border
                      prefixIcon: Icons.person,
                      prefixIconColor: Colors.black54,
                      onChanged: (val) =>
                          ref.read(usernameProvider.notifier).state = val,
                    ),

                    SizedBox(height: 20),

                    CommonTextField(
                      label: 'Mobile Number',
                      keyboardType: TextInputType.phone,
                      maxLength: 10,
                      fillColor: Colors.grey[200],
                      focusedBorderColor: Colors.black,
                      enabledBorderColor: Colors.grey[500],
                      prefixIcon: Icons.phone,
                      prefixIconColor: Colors.black54,
                      onChanged: (val) =>
                          ref.read(mobileProvider.notifier).state = val,
                    ),

                    const SizedBox(height: 20),

                    // Terms & Privacy
                    Text.rich(
                      TextSpan(
                        text: 'By continuing, you agree to our ',
                        style: TextStyle(color: Colors.grey[700], fontSize: 12),
                        children: [
                          TextSpan(
                            text: 'Terms of Service',
                            style: const TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () => print('Terms tapped'),
                          ),
                          const TextSpan(text: ' and '),
                          TextSpan(
                            text: 'Privacy Policy',
                            style: const TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () => print('Privacy tapped'),
                          ),
                          const TextSpan(text: '.'),
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Next Button
                    ElevatedButton(
                      onPressed: isFormValid
                          ? () async {
                              ref.read(isLoadingProvider.notifier).state = true;
                              await authService.sendOTP(
                                ref: ref,
                                phoneNumber: mobile,
                                onCodeSent: () {
                                  ref.read(isLoadingProvider.notifier).state =
                                      false;
                                  showDialog(
                                    context: context,
                                    builder: (context) => OTPDialog(ref: ref),
                                  );
                                },
                                onError: (error) {
                                  ref.read(isLoadingProvider.notifier).state =
                                      false;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(error),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                },
                              );
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isFormValid
                            ? Colors.black
                            : Colors.grey[400],
                        foregroundColor: Colors.black87,
                        minimumSize: const Size.fromHeight(50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 5,
                      ),
                      child: ref.watch(isLoadingProvider)
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Next',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.white
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
