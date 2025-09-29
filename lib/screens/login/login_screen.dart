import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'otp_dialog.dart';
import 'package:bneeds_taxi_driver/config/auth_service.dart' as authService;
import 'package:bneeds_taxi_driver/utils/storage.dart';


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
                      Strings.logo,
                      width: 120,
                      height: 120,
                    ),
                    const SizedBox(height: 16),
                     Text(
                      "Welcome Driver!",
                      style: AppTextStyles.appBarTitle.copyWith(fontSize: 28),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Sign in to manage your rides",
                      style: AppTextStyles.bodyText.copyWith(
                        fontSize: 14,
                        color: AppColors.text.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.background,
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
                      fillColor: Colors.grey[200],
                      focusedBorderColor: AppColors.text,
                      enabledBorderColor: Colors.grey[500],
                      prefixIcon: Icons.person,
                      prefixIconColor: Colors.black54,
                      onChanged: (val) =>
                      ref.read(usernameProvider.notifier).state = val,
                    ),
                    const SizedBox(height: 20),
                    CommonTextField(
                      label: 'Mobile Number',
                      keyboardType: TextInputType.phone,
                      maxLength: 10,
                      fillColor: Colors.grey[200],
                      focusedBorderColor: AppColors.text,
                      enabledBorderColor: Colors.grey[500],
                      prefixIcon: Icons.phone,
                      prefixIconColor: Colors.black54,
                      onChanged: (val) =>
                      ref.read(mobileProvider.notifier).state = val,
                    ),
                    const SizedBox(height: 30),
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
                            ? AppColors.text
                            : AppColors.secondary,
                        foregroundColor: AppColors.buttonText,
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
                          color: AppColors.buttonText,
                        ),
                      )
                          : Text(
                        'Next',
                        style: AppTextStyles.buttonText,
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
