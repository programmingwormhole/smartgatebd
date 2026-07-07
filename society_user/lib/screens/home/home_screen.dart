import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/notification_controller.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/app_config.dart';
import '../../widgets/user_avatar_widget.dart';
import '../auth/login_screen.dart';
import '../notifications/notification_screen.dart';
import '../profile/apartment_info_screen.dart';
import 'widgets/quick_action_grid.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AuthController>(
      builder: (authController) {
        final user = authController.user;

        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Custom App Bar / Header
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
                  decoration: const BoxDecoration(
                    color: AppColors.primaryNavy,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(30),
                      bottomRight: Radius.circular(30),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              UserAvatarWidget(
                                radius: 24,
                                userName: user?.name ?? 'User',
                                profilePictureUrl: user?.profilePicture,
                                backgroundColor: AppColors.lightBlue,
                                textColor: AppColors.primaryNavy,
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Good Morning,',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 13,
                                    ),
                                  ),
                                  Text(
                                    user?.name ?? 'Resident',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              if (AppConfig.showDBNotification)
                                GetBuilder<NotificationController>(
                                  builder: (notificationController) {
                                    return Stack(
                                      children: [
                                        IconButton(
                                          icon: const Icon(
                                            Icons.notifications_none,
                                            color: Colors.white,
                                          ),
                                          onPressed: () {
                                            Get.to(
                                              () => const NotificationScreen(),
                                            );
                                          },
                                        ),
                                        if (notificationController.unreadCount >
                                            0)
                                          Positioned(
                                            top: 8,
                                            right: 8,
                                            child: Container(
                                              padding: const EdgeInsets.all(4),
                                              decoration: const BoxDecoration(
                                                color: Colors.red,
                                                shape: BoxShape.circle,
                                              ),
                                              child: Text(
                                                notificationController
                                                            .unreadCount >
                                                        99
                                                    ? '99+'
                                                    : '${notificationController.unreadCount}',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    );
                                  },
                                ),
                              IconButton(
                                icon: const Icon(
                                  Icons.logout,
                                  color: Colors.white70,
                                ),
                                onPressed: () {
                                  authController.logout();
                                  Get.offAll(() => const LoginScreen());
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Apartment info card embedded in header
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () =>
                              Get.to(() => const ApartmentInfoScreen()),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.white24),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.home_work,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Apt ${user?.flatNo ?? 'N/A'}, Block ${user?.blockNo ?? 'N/A'}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      Text(
                                        user?.buildingName ?? 'Building',
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(
                                  Icons.chevron_right,
                                  color: Colors.white70,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
                // Dashboard Title
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: const Text(
                    'Quick Actions',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Grid of modules
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: const QuickActionGrid(),
                ),

                // Main Content Area
                // SliverPadding(
                // padding: const EdgeInsets.all(20),
                // sliver: SliverList(
                //   delegate: SliverChildListDelegate([

                // const SizedBox(height: 32),

                // // Recent Visitors Section (Mock)
                // Row(
                //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                //   children: [
                //     const Text(
                //       'Recent Visitors',
                //       style: TextStyle(
                //         fontSize: 18,
                //         fontWeight: FontWeight.bold,
                //         color: AppColors.textDark,
                //       ),
                //     ),
                //     TextButton(
                //       onPressed: () {},
                //       child: const Text(
                //         'View All',
                //         style: TextStyle(color: AppColors.primaryBlue),
                //       ),
                //     ),
                //   ],
                // ),

                // const SizedBox(height: 12),

                // _buildVisitorCard(
                //   context,
                //   'John Doe',
                //   'Courier',
                //   'Today, 10:30 AM',
                //   Colors.green,
                // ),
                // const SizedBox(height: 12),
                // _buildVisitorCard(
                //   context,
                //   'Alice Smith',
                //   'Guest',
                //   'Yesterday, 5:00 PM',
                //   Colors.grey,
                // ),

                // const SizedBox(
                //   height: 80,
                // ), // Padding for bottom nav bar later
                // ]),
                // ),
                // ),
              ],
            ),
          ),
        );
      },
    );
  }
}
