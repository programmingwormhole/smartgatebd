import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/colors.dart';
import '../../controllers/auth_controller.dart';
import '../../services/auth_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _pushNotificationsEnabled = true;
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _loadNotificationPreference();
  }

  Future<void> _loadNotificationPreference() async {
    final pref = await _authService.getPushNotificationPreference();
    setState(() {
      _pushNotificationsEnabled = pref;
    });
  }

  Future<void> _toggleNotifications(bool value) async {
    await _authService.setPushNotificationPreference(value);
    setState(() {
      _pushNotificationsEnabled = value;
    });
  }

  void _showChangePasswordDialog() {
    final passwordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Change Password'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Current Password',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: newPasswordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'New Password',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: confirmPasswordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Confirm New Password',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Get.back(),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      if (newPasswordController.text !=
                          confirmPasswordController.text) {
                        Get.snackbar(
                          'Error',
                          'New passwords do not match',
                          backgroundColor: AppColors.errorRed,
                          colorText: Colors.white,
                        );
                        return;
                      }

                      if (newPasswordController.text.length < 6) {
                        Get.snackbar(
                          'Error',
                          'Password must be at least 6 characters',
                          backgroundColor: AppColors.errorRed,
                          colorText: Colors.white,
                        );
                        return;
                      }

                      setDialogState(() {
                        isLoading = true;
                      });

                      try {
                        final authController = Get.find<AuthController>();
                        final result =
                            await authController.changePassword(
                          passwordController.text,
                          newPasswordController.text,
                        );

                        if (result['success'] ?? false) {
                          Get.back();
                          Get.snackbar(
                            'Success',
                            result['message'] ?? 'Password changed successfully',
                            backgroundColor: Colors.green,
                            colorText: Colors.white,
                          );
                        } else {
                          Get.snackbar(
                            'Error',
                            result['message'] ?? 'Failed to change password',
                            backgroundColor: AppColors.errorRed,
                            colorText: Colors.white,
                          );
                        }
                      } catch (e) {
                        Get.back();
                        Get.snackbar(
                          'Error',
                          'An error occurred: ${e.toString()}',
                          backgroundColor: AppColors.errorRed,
                          colorText: Colors.white,
                        );
                      }

                      setDialogState(() {
                        isLoading = false;
                      });
                    },
              child: isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Change Password'),
            ),
          ],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.primaryNavy),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildSectionTitle('App Preferences'),
          _buildSettingTile(
            Icons.notifications_active,
            'Push Notifications',
            trailing: Switch(
              value: _pushNotificationsEnabled,
              onChanged: _toggleNotifications,
            ),
          ),
          // Dark Mode - Commented out
          // _buildSettingTile(
          //   Icons.dark_mode,
          //   'Dark Mode',
          //   trailing: Switch(value: false, onChanged: (v) {}),
          // ),
          // Language - Commented out
          // _buildSettingTile(Icons.language, 'Language', subtitle: 'English'),

          const SizedBox(height: 30),
          _buildSectionTitle('Privacy & Security'),
          _buildSettingTile(
            Icons.lock_reset,
            'Change Password',
            onTap: _showChangePasswordDialog,
          ),
          // Two-Factor Authentication - Commented out
          // _buildSettingTile(
          //   Icons.security,
          //   'Two-Factor Authentication',
          //   subtitle: 'Disabled',
          // ),

          const SizedBox(height: 30),
          _buildSectionTitle('About'),
          _buildSettingTile(Icons.info_outline, 'Terms & Conditions'),
          _buildSettingTile(Icons.privacy_tip_outlined, 'Privacy Policy'),
          _buildSettingTile(Icons.star_rate_outlined, 'Rate the App'),

          const SizedBox(height: 40),
          Center(
            child: Text(
              'Version 1.0.0',
              style: TextStyle(color: Colors.grey.shade500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, left: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: AppColors.primaryNavy,
        ),
      ),
    );
  }

  Widget _buildSettingTile(
    IconData icon,
    String title, {
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        leading: Icon(icon, color: AppColors.primaryNavy),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: subtitle != null
            ? Text(
                subtitle,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              )
            : null,
        trailing:
            trailing ?? const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: onTap ?? (trailing is Switch ? null : () {}),
      ),
    );
  }
}
