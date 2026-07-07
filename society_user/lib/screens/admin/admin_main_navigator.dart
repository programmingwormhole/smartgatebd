import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/colors.dart';
import '../../controllers/navigation_controller.dart';
import '../../controllers/notification_controller.dart';
import '../profile/profile_screen.dart';
import 'dashboard/admin_dashboard_screen.dart';
import 'dashboard/admin_residents_screen.dart';
import 'dashboard/admin_bills_screen.dart';
import 'dashboard/admin_requests_screen.dart';
import '../../widgets/responsive_layout.dart';
import '../../widgets/web_side_menu.dart';

class AdminMainNavigator extends StatefulWidget {
  const AdminMainNavigator({super.key});

  @override
  State<AdminMainNavigator> createState() => _AdminMainNavigatorState();
}

class _AdminMainNavigatorState extends State<AdminMainNavigator> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (Get.isRegistered<NavigationController>()) {
        Get.find<NavigationController>().setIndex(0);
      }
    });

    if (Get.isRegistered<NotificationController>()) {
      Get.find<NotificationController>().setMainPageActive(true);
    }
  }

  @override
  void dispose() {
    if (Get.isRegistered<NotificationController>()) {
      Get.find<NotificationController>().setMainPageActive(false);
    }
    super.dispose();
  }

  List<Widget> _buildScreens(NavigationController navController) {
    return [
      const AdminDashboardScreen(),
      const AdminResidentsScreen(),
      const AdminBillsScreen(),
      AdminRequestsScreen(
        initialTabIndex: navController.adminRequestsInitialTabIndex,
      ),
      const ProfileScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<NavigationController>(
      builder: (navController) {
        final screens = _buildScreens(navController);
        // Ensure index is within bounds for admin tabs (5 tabs)
        final currentIndex = navController.selectedIndex < screens.length
            ? navController.selectedIndex
            : 0;

        final mobileLayout = Scaffold(
          body: screens[currentIndex],
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: BottomNavigationBar(
              currentIndex: currentIndex,
              onTap: (index) {
                navController.setIndex(index);
              },
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.white,
              selectedItemColor: AppColors.primaryNavy,
              unselectedItemColor: Colors.grey.shade400,
              showUnselectedLabels: true,
              selectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 10,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 10,
              ),
              elevation: 0,
              items: const [
                BottomNavigationBarItem(
                  icon: Padding(
                    padding: EdgeInsets.only(bottom: 4),
                    child: Icon(Icons.dashboard_outlined),
                  ),
                  label: 'Dashboard',
                ),
                BottomNavigationBarItem(
                  icon: Padding(
                    padding: EdgeInsets.only(bottom: 4),
                    child: Icon(Icons.people_outline),
                  ),
                  label: 'Residents',
                ),
                BottomNavigationBarItem(
                  icon: Padding(
                    padding: EdgeInsets.only(bottom: 4),
                    child: Icon(Icons.receipt_long_outlined),
                  ),
                  label: 'Bills',
                ),
                BottomNavigationBarItem(
                  icon: Padding(
                    padding: EdgeInsets.only(bottom: 4),
                    child: Icon(Icons.assignment_outlined),
                  ),
                  label: 'Requests',
                ),
                BottomNavigationBarItem(
                  icon: Padding(
                    padding: EdgeInsets.only(bottom: 4),
                    child: Icon(Icons.person_outline),
                  ),
                  label: 'Profile',
                ),
              ],
            ),
          ),
        );

        final desktopLayout = Scaffold(
          backgroundColor: AppColors.background,
          body: Row(
            children: [
              WebSideMenu(
                currentIndex: currentIndex,
                onItemSelected: (index) => navController.setIndex(index),
                roleLabel: 'Building Admin',
                items: [
                  WebSideMenuItem(icon: Icons.dashboard_outlined, label: 'Dashboard', index: 0),
                  WebSideMenuItem(icon: Icons.people_outline, label: 'Residents', index: 1),
                  WebSideMenuItem(icon: Icons.receipt_long_outlined, label: 'Bills', index: 2),
                  WebSideMenuItem(icon: Icons.assignment_outlined, label: 'Requests', index: 3),
                  WebSideMenuItem(icon: Icons.person_outline, label: 'Profile', index: 4),
                ],
              ),
              Expanded(
                child: screens[currentIndex],
              ),
            ],
          ),
        );

        return ResponsiveLayout(
          mobileLayout: mobileLayout,
          desktopLayout: desktopLayout,
        );
      },
    );
  }
}
