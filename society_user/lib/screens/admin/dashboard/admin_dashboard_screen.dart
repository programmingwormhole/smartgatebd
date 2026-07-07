import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/admin_controller.dart';
import '../../../controllers/navigation_controller.dart';
import '../../../controllers/notification_controller.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/app_config.dart';
import '../../notifications/notification_screen.dart';
import '../management/society_management_screen.dart';
import '../management/notice_management_screen.dart';
import '../activity_log_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final AdminController _adminController = Get.put(AdminController());

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _adminController.fetchDashboardStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (AppConfig.showDBNotification)
            GetBuilder<NotificationController>(
              builder: (notificationController) {
                return Stack(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.notifications_outlined,
                        color: AppColors.textDark,
                      ),
                      onPressed: () {
                        Get.to(() => const NotificationScreen());
                      },
                    ),
                    if (notificationController.unreadCount > 0)
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
                            notificationController.unreadCount > 99
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
        ],
      ),
      body: Obx(() {
        if (_adminController.isLoading && _adminController.stats.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        final stats = _adminController.stats;

        return RefreshIndicator(
          onRefresh: () async {
            await _adminController.fetchDashboardStats();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isDesktop = constraints.maxWidth > 800;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Overview',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryNavy,
                      ),
                    ),
                    const SizedBox(height: 16),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: isDesktop ? 4 : 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: isDesktop ? 1.6 : 1.3,
                  children: [
                    _buildStatCard(
                      'Total Residents',
                      stats['total_residents']?.toString() ?? '0',
                      Icons.people_alt,
                      Colors.blue,
                    ),
                    _buildStatCard(
                      'Pending Payments',
                      stats['pending_payments']?.toString() ?? '0',
                      Icons.pending_actions,
                      Colors.orange,
                    ),
                    _buildStatCard(
                      'Open Complaints',
                      stats['open_complaints']?.toString() ?? '0',
                      Icons.report_problem,
                      Colors.red,
                    ),
                    _buildStatCard(
                      'Visitors Today',
                      stats['visitors_today']?.toString() ?? '0',
                      Icons.emoji_people,
                      Colors.green,
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                const Text(
                  'Quick Actions',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryNavy,
                  ),
                ),
                const SizedBox(height: 16),
                // Quick Actions List
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: isDesktop ? 3 : 1,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: isDesktop ? 3.5 : 5.0,
                  children: [
                    _buildQuickAction(
                      'Review Pending Bills',
                      Icons.receipt_long,
                      () => Get.find<NavigationController>().setIndex(2),
                    ),
                    _buildQuickAction(
                      'Manage Requests',
                      Icons.assignment_outlined,
                      () => Get.find<NavigationController>().openAdminRequests(
                        initialTabIndex: 0,
                      ),
                    ),
                    _buildQuickAction(
                      'Manage Complaints',
                      Icons.report_problem_outlined,
                      () => Get.find<NavigationController>().openAdminRequests(
                        initialTabIndex: 2,
                      ),
                    ),
                    _buildQuickAction(
                      'Manage Society Building',
                      Icons.business_center_outlined,
                      () => Get.to(() => const SocietyManagementScreen()),
                    ),
                    _buildQuickAction(
                      'Notice Management',
                      Icons.campaign_outlined,
                      () => Get.to(() => const NoticeManagementScreen()),
                    ),
                    _buildQuickAction(
                      'Activity Logs',
                      Icons.receipt_long_outlined,
                      () => Get.to(() => const AdminActivityLogScreen()),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
        );
      }),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryNavy,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAction(String title, IconData icon, VoidCallback onTap) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primaryBlue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.primaryBlue),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      ),
    );
  }
}
