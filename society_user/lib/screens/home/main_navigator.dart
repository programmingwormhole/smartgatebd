import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/colors.dart';
import '../../controllers/navigation_controller.dart';
import '../../controllers/notification_controller.dart';
import 'home_screen.dart';
import '../profile/profile_screen.dart';
import '../notices/notices_screen.dart';
import '../services/services_screen.dart';
import '../../widgets/responsive_layout.dart';
import '../../widgets/web_side_menu.dart';

class MainNavigator extends StatefulWidget {
  const MainNavigator({super.key});

  @override
  State<MainNavigator> createState() => _MainNavigatorState();
}

class _MainNavigatorState extends State<MainNavigator> {
  final List<Widget> _screens = const [
    HomeScreen(),
    NoticesScreen(),
    ServicesScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
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
    return GetBuilder<NavigationController>(
      builder: (navController) {
        final mobileLayout = Scaffold(
          body: _screens[navController.selectedIndex],
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
              currentIndex: navController.selectedIndex,
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
                fontSize: 12,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
              elevation: 0,
              items: const [
                BottomNavigationBarItem(
                  icon: Padding(
                    padding: EdgeInsets.only(bottom: 4),
                    child: Icon(Icons.home_filled),
                  ),
                  label: 'Home',
                ),
                BottomNavigationBarItem(
                  icon: Padding(
                    padding: EdgeInsets.only(bottom: 4),
                    child: Icon(Icons.campaign_outlined),
                  ),
                  label: 'Notices',
                ),
                BottomNavigationBarItem(
                  icon: Padding(
                    padding: EdgeInsets.only(bottom: 4),
                    child: Icon(Icons.build_circle_outlined),
                  ),
                  label: 'Services',
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
                currentIndex: navController.selectedIndex,
                onItemSelected: (index) => navController.setIndex(index),
                roleLabel: 'Resident',
                items: [
                  WebSideMenuItem(icon: Icons.home_filled, label: 'Home', index: 0),
                  WebSideMenuItem(icon: Icons.campaign_outlined, label: 'Notices', index: 1),
                  WebSideMenuItem(icon: Icons.build_circle_outlined, label: 'Services', index: 2),
                  WebSideMenuItem(icon: Icons.person_outline, label: 'Profile', index: 3),
                ],
              ),
              Expanded(
                child: _screens[navController.selectedIndex],
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
