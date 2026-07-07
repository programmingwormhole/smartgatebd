import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/colors.dart';
import '../../controllers/notification_controller.dart';
import '../notices/notices_screen.dart';
import 'guard_dashboard_screen.dart';
import 'guard_in_out_screen.dart';
import 'guard_profile_screen.dart';
import '../../widgets/responsive_layout.dart';
import '../../widgets/web_side_menu.dart';

class GuardMainNavigator extends StatefulWidget {
  const GuardMainNavigator({super.key});

  @override
  State<GuardMainNavigator> createState() => _GuardMainNavigatorState();
}

class _GuardMainNavigatorState extends State<GuardMainNavigator> {
  int _currentIndex = 0;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      const GuardDashboardScreen(),
      const GuardInOutScreen(),
      const NoticesScreen(),
      const GuardProfileScreen(),
    ];

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

  @override
  Widget build(BuildContext context) {
    final mobileLayout = Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.primaryNavy,
        unselectedItemColor: Colors.grey.shade400,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        items: [
          BottomNavigationBarItem(
            icon: Icon(
              _currentIndex == 0 ? Icons.home : Icons.home_outlined,
              size: 28,
            ),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              _currentIndex == 1 ? Icons.people : Icons.people_outlined,
              size: 28,
            ),
            label: 'In/Out',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              _currentIndex == 2
                  ? Icons.notifications
                  : Icons.notifications_outlined,
              size: 28,
            ),
            label: 'Notice',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              _currentIndex == 3 ? Icons.person : Icons.person_outlined,
              size: 28,
            ),
            label: 'Profile',
          ),
        ],
      ),
    );

    final desktopLayout = Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          WebSideMenu(
            currentIndex: _currentIndex,
            onItemSelected: (index) => setState(() => _currentIndex = index),
            roleLabel: 'Guard',
            items: [
              WebSideMenuItem(icon: Icons.home_outlined, label: 'Dashboard', index: 0),
              WebSideMenuItem(icon: Icons.people_outlined, label: 'In/Out', index: 1),
              WebSideMenuItem(icon: Icons.notifications_outlined, label: 'Notice', index: 2),
              WebSideMenuItem(icon: Icons.person_outlined, label: 'Profile', index: 3),
            ],
          ),
          Expanded(
            child: _screens[_currentIndex],
          ),
        ],
      ),
    );

    return ResponsiveLayout(
      mobileLayout: mobileLayout,
      desktopLayout: desktopLayout,
    );
  }
}
