import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/auth_controller.dart';
import '../../core/constants/colors.dart';
import '../../widgets/profile_picture_widget.dart';
import '../auth/login_screen.dart';
import '../activities/resident_activity_log_screen.dart';
import '../family/family_screen.dart';
import '../vehicles/vehicles_screen.dart';
import '../settings/settings_screen.dart';
import 'personal_details_screen.dart';
import 'apartment_info_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AuthController>(
      builder: (authController) {
        final user = authController.user;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: const Text('My Profile'),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout, color: AppColors.primaryNavy,),
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
                const SizedBox(height: 20),
                Center(
                  child: ProfilePictureWidget(
                    profilePictureUrl: user?.profilePicture,
                    userName: user?.name ?? 'User',
                    editable: true,
                    radius: 50,
                    onPictureUpdated: () {
                      authController.update();
                    },
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  user?.name ?? 'Resident Name',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  user?.role.toUpperCase() ?? 'RESIDENT',
                  style: const TextStyle(
                    color: AppColors.primaryBlue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 30),

                // Profile Options List
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _buildListTile(
                        context,
                        Icons.person_outline,
                        'Personal Details',
                        'Update your information',
                        const PersonalDetailsScreen(),
                      ),
                      const Divider(height: 1),
                      _buildListTile(
                        context,
                        Icons.home_work_outlined,
                        'Apartment Info',
                        user?.flatNo != null && user?.blockNo != null
                            ? 'Apt ${user!.flatNo}, Block ${user.blockNo}'
                            : 'View apartment details',
                        const ApartmentInfoScreen(),
                      ),
                      const Divider(height: 1),
                      _buildListTile(
                        context,
                        Icons.people_outline,
                        'Family Members',
                        'Manage family members',
                        const FamilyScreen(),
                      ),
                      const Divider(height: 1),
                      _buildListTile(
                        context,
                        Icons.receipt_long_outlined,
                        'Visitor Logs',
                        'View your visitor activity',
                        const ResidentActivityLogScreen(),
                      ),
                      const Divider(height: 1),
                      _buildListTile(
                        context,
                        Icons.directions_car_outlined,
                        'Vehicles',
                        'Manage your vehicles',
                        const VehiclesScreen(),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _buildListTile(
                        context,
                        Icons.settings_outlined,
                        'Settings',
                        'App preferences',
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

  Widget _buildListTile(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    Widget? route,
  ) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.lightBlue,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppColors.primaryNavy),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
      ),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: () {
        if (route != null) {
          Get.to(() => route);
        }
      },
    );
  }
}
