import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:society_user/core/constants/app_config.dart';
import '../../controllers/auth_controller.dart';
import '../../core/constants/colors.dart';
import '../home/main_navigator.dart';
import '../admin/admin_main_navigator.dart';
import '../guard/guard_main_navigator.dart';
import 'otp_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final authController = Get.find<AuthController>();

    try {
      final success = await authController.login(
        _phoneController.text.trim(),
        _passwordController.text,
      );

      if (success && mounted) {
        if (authController.isOtpEnabled) {
          Get.to(() => OtpScreen(phone: _phoneController.text.trim()));
        } else {
          // Route based on user role
          if (authController.user?.isAdmin == true) {
            Get.offAll(() => const AdminMainNavigator());
          } else if (authController.user?.isGuard == true) {
            Get.offAll(() => const GuardMainNavigator());
          } else {
            Get.offAll(() => const MainNavigator());
          }
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
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Minimal Header (Logo can be added here)
                const SizedBox(height: 40),
                const Icon(
                  Icons.home_work_rounded,
                  size: 80,
                  color: AppColors.primaryNavy,
                ),
                const SizedBox(height: 24),

                Text(
                  'Welcome to\n${AppConfig.appName}',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryNavy,
                    height: 1.2,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  'Enter your credentials to access your account.',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 60),

                // Phone Input
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    hintText: 'Phone Number',
                    prefixIcon: Icon(Icons.phone_android),
                  ),
                  validator: (value) => (value == null || value.isEmpty)
                      ? 'Please enter phone number'
                      : null,
                ),

                const SizedBox(height: 20),

                // Password Input
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    hintText: 'Password',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                  validator: (value) => (value == null || value.isEmpty)
                      ? 'Please enter password'
                      : null,
                ),

                const SizedBox(height: 15),

                // Forgot Password Placeholder
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {},
                    child: const Text(
                      'Forgot Password?',
                      style: TextStyle(color: AppColors.primaryBlue),
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // Login Button
                GetBuilder<AuthController>(
                  builder: (authController) => ElevatedButton(
                    onPressed: authController.isLoading ? null : _handleLogin,
                    child: authController.isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 3,
                            ),
                          )
                        : const Text('Login'),
                  ),
                ),

                const SizedBox(height: 40),
                Text(
                  'Accounts are created by the building administrator. Please contact them if you do not have an account.',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
      ),
      ),
      ),
    );
  }
}
