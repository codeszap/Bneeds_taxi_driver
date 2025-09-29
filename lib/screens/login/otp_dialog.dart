import 'package:bneeds_taxi_driver/config/auth_service.dart' as authService;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bneeds_taxi_driver/utils/storage.dart';

class OTPDialog extends StatefulWidget {
  final WidgetRef ref;
  const OTPDialog({super.key, required this.ref});

  @override
  State<OTPDialog> createState() => _OTPDialogState();
}

class _OTPDialogState extends State<OTPDialog> {
  final List<TextEditingController> otpControllers = List.generate(
    4,
    (_) => TextEditingController(),
  );
  final List<FocusNode> focusNodes = List.generate(4, (_) => FocusNode());

  int _secondsRemaining = 180;
  Timer? _timer;
  bool _showResend = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _secondsRemaining = 180;
    _showResend = false;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
      } else {
        setState(() => _showResend = true);
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    otpControllers.forEach((c) => c.dispose());
    focusNodes.forEach((f) => f.dispose());
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _saveMobileNo(
    String mobileno,
    String username,
    bool isProfileCompleted,
  ) async {
    await SharedPrefsHelper.setDriverMobile(mobileno);
    await SharedPrefsHelper.setDriverUsername(username);
    await SharedPrefsHelper.setDriverProfileCompleted(isProfileCompleted);
  }

  void _submitOTP() async {
    final otp = otpControllers.map((c) => c.text).join();
    if (otp.length == 4) {
      try {
        final username = widget.ref.read(usernameProvider);
        final mobileNo = widget.ref.read(mobileProvider);
        final profileRepo = ProfileRepository();

        final userExists = await authService.verifyOTPAndCheckUser(
          ref: widget.ref,
          otp: otp,
          username: username,
          mobileNo: mobileNo,
        //  mobileNo: "9654120321",
          profileRepo: profileRepo,
        );

        // ✅ Save with isProfileCompleted
        await _saveMobileNo(mobileNo, username, userExists);

        Navigator.pop(context); // close OTP dialog
        print("User exists: $userExists");

        if (userExists) {
          context.go(AppRoutes.driverHome);
        } else {
          context.go(
            AppRoutes.driverProfile,
            extra: {'isNewUser': true},
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    final minutes = (_secondsRemaining ~/ 60).toString().padLeft(2, '0');
    final seconds = (_secondsRemaining % 60).toString().padLeft(2, '0');

    return Dialog(
      backgroundColor: AppColors.buttonText,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        child: SizedBox(
          height: 240,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Enter OTP",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.black,
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(4, (index) {
                  return SizedBox(
                    width: 50,
                    height: 60,
                    child: TextField(
                      controller: otpControllers[index],
                      focusNode: focusNodes[index],
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      maxLength: 1,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.buttonText,
                      ),
                      decoration: InputDecoration(
                        counterText: '',
                        filled: true,
                        fillColor: Colors.black,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppColors.buttonText),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Colors.greenAccent,
                            width: 2,
                          ),
                        ),
                      ),
                      onChanged: (value) {
                        if (value.isNotEmpty && index < 3)
                          FocusScope.of(
                            context,
                          ).requestFocus(focusNodes[index + 1]);
                        else if (value.isEmpty && index > 0)
                          FocusScope.of(
                            context,
                          ).requestFocus(focusNodes[index - 1]);
                        else if (index == 3 && value.isNotEmpty)
                          _submitOTP();
                      },
                    ),
                  );
                }),
              ),
              Text(
                "Enter the 4-digit OTP sent to your number.",
                style: TextStyle(fontSize: 12, color: Colors.black),
              ),
              _showResend
                  ? TextButton(
                      onPressed: () async {
                        final mobileNo = widget.ref.read(mobileProvider);
                        await authService.sendOTP(
                          ref: widget.ref,
                          phoneNumber: mobileNo,
                          onCodeSent: () => _startTimer(),
                          onError: (error) =>
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(error),
                                  backgroundColor: Colors.red,
                                ),
                              ),
                        );
                      },
                      child: const Text(
                        "Resend OTP",
                        style: TextStyle(
                          color: Colors.greenAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  : Text(
                      "Expires in $minutes:$seconds",
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
