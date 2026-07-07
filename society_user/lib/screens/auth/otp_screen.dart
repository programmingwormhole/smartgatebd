import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pinput/pinput.dart';
import '../../controllers/auth_controller.dart';
import '../../core/constants/colors.dart';
import '../home/main_navigator.dart';
import '../admin/admin_main_navigator.dart';
import '../guard/guard_main_navigator.dart';

class OtpScreen extends StatefulWidget {
  final String phone;
  const OtpScreen({super.key, required this.phone});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _otpController = TextEditingController();

  void _verifyOtp() async {
    if (_otpController.text.length != 6) return;

    final authController = Get.find<AuthController>();
    try {
      final success = await authController.verifyOtp(
        widget.phone,
        _otpController.text,
      );
      if (success && mounted) {
        // Navigation is a stack replacement to prevent going back to OTP
        if (authController.user?.isAdmin == true) {
          Get.offAll(() => const AdminMainNavigator());
        } else if (authController.user?.isGuard == true) {
          Get.offAll(() => const GuardMainNavigator());
        } else {
          Get.offAll(() => const MainNavigator());
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final defaultPinTheme = PinTheme(
      width: 56,
      height: 60,
      textStyle: const TextStyle(
        fontSize: 22,
        color: AppColors.primaryNavy,
        fontWeight: FontWeight.bold,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
    );

    final focusedPinTheme = defaultPinTheme.copyDecorationWith(
      border: Border.all(color: AppColors.primaryNavy, width: 2),
    );

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Get.back(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Verify your\nphone number',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryNavy,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 12),
              RichText(
                text: TextSpan(
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 16,
                    height: 1.5,
                  ),
                  children: [
                    const TextSpan(
                      text:
                          'We\'ve sent an SMS with an activation code to your phone ',
                    ),
                    TextSpan(
                      text: widget.phone,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 48),

              Pinput(
                length: 6,
                controller: _otpController,
                defaultPinTheme: defaultPinTheme,
                focusedPinTheme: focusedPinTheme,
                onCompleted: (pin) => _verifyOtp(),
              ),

              const SizedBox(height: 48),

              GetBuilder<AuthController>(
                builder: (authController) => ElevatedButton(
                  onPressed: authController.isLoading ? null : _verifyOtp,
                  child: authController.isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 3,
                          ),
                        )
                      : const Text('Verify'),
                ),
              ),

              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Didn\'t receive the code? ',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  TextButton(
                    onPressed: () {
                      // Call resend OTP API
                    },
                    child: const Text(
                      'Resend',
                      style: TextStyle(
                        color: AppColors.primaryBlue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
