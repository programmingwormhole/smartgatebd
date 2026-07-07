import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/auth_controller.dart';
import '../../core/constants/colors.dart';
import '../../widgets/profile_picture_widget.dart';
import '../auth/login_screen.dart';
import '../settings/settings_screen.dart';
import 'guard_personal_details_screen.dart';

class GuardProfileScreen extends StatelessWidget {
  const GuardProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AuthController>(
      builder: (authController) {
        final user = authController.user;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: const Text('Guard Profile', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            backgroundColor: AppColors.primaryNavy,
            centerTitle: true,
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.logout, color: Colors.white),
                onPressed: () {
                  // Sign out flow
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Logout'),
                      content: const Text('Are you sure you want to logout?'),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Get.back(),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.errorRed,
                          ),
                          onPressed: () {
                            authController.logout();
                            Get.offAll(() => const LoginScreen());
                          },
                          child: const Text('Logout'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
          body: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 30),

                // Profile Avatar with Name
                Center(
                  child: ProfilePictureWidget(
                    profilePictureUrl: user?.profilePicture,
                    userName: user?.name ?? 'Guard',
                    editable: true,
                    radius: 60,
                    onPictureUpdated: () {
                      authController.update();
                    },
                  ),
                ),
                const SizedBox(height: 20),

                // Guard Name
                Text(
                  user?.name ?? 'Guard',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),

                // Role Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryNavy.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'GUARD',
                    style: TextStyle(
                      color: AppColors.primaryNavy,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 30),

                // Guard Info Cards
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoRow('Phone', user?.phone ?? '-'),
                      const SizedBox(height: 12),
                      Divider(color: Colors.grey.shade200, height: 1),
                      const SizedBox(height: 12),
                      _buildInfoRow('Email', user?.email ?? 'Not provided'),
                      const SizedBox(height: 12),
                      Divider(color: Colors.grey.shade200, height: 1),
                      const SizedBox(height: 12),
                      _buildInfoRow(
                        'Building',
                        user?.buildingName ?? 'Not assigned',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),

                // Profile Options List
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _buildListTile(
                        Icons.person_outline,
                        'Edit Profile',
                        'Update your personal information',
                        const GuardPersonalDetailsScreen(),
                      ),
                      Divider(
                        color: Colors.grey.shade200,
                        height: 1,
                        indent: 60,
                      ),
                      _buildListTile(
                        Icons.settings_outlined,
                        'Settings',
                        'App preferences and notifications',
                        const SettingsScreen(),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade600,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
            textAlign: TextAlign.right,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildListTile(
    IconData icon,
    String title,
    String subtitle,
    Widget? route,
  ) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.primaryBlue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppColors.primaryBlue, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey.shade600,
        ),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
      onTap: () {
        if (route != null) {
          Get.to(() => route);
        }
      },
    );
  }
}
