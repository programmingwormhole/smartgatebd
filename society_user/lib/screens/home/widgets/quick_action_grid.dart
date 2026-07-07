import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/colors.dart';
import '../../../controllers/navigation_controller.dart';
import '../../visitors/visitors_screen.dart';
import '../../activities/resident_activity_log_screen.dart';
import '../../bills/bills_screen.dart';
import '../../amenities/amenities_screen.dart';
import '../../complaints/complaints_screen.dart';
import '../../emergency/emergency_screen.dart';
import '../../pets/pets_screen.dart';
import '../../daily_help/daily_help_screen.dart';
import '../../members/members_screen.dart';

class QuickActionGrid extends StatelessWidget {
  const QuickActionGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> actions = [
      {
        'icon': Icons.group_outlined,
        'label': 'Members',
        'color': Colors.indigo,
        'screen': const MembersScreen(),
      },
      {
        'icon': Icons.people_outline,
        'label': 'Visitors',
        'color': Colors.blue,
        'screen': const VisitorsScreen(),
      },
      {
        'icon': Icons.receipt_long_outlined,
        'label': 'Visitor Logs',
        'color': Colors.green,
        'screen': const ResidentActivityLogScreen(),
      },
      {
        'icon': Icons.receipt_long_outlined,
        'label': 'Bills',
        'color': Colors.orange,
        'screen': const BillsScreen(),
      },
      {
        'icon': Icons.pool_outlined,
        'label': 'Amenities',
        'color': Colors.teal,
        'screen': const AmenitiesScreen(),
      },
      {
        'icon': Icons.build_outlined,
        'label': 'Services',
        'color': Colors.purple,
        'tabIndex': 2,
      },
      {
        'icon': Icons.campaign_outlined,
        'label': 'Notices',
        'color': Colors.red,
        'tabIndex': 1,
      },
      {
        'icon': Icons.support_agent_outlined,
        'label': 'Complaints',
        'color': Colors.indigo,
        'screen': const ComplaintsScreen(),
      },
      {
        'icon': Icons.emergency_outlined,
        'label': 'Emergency',
        'color': Colors.redAccent,
        'screen': const EmergencyScreen(),
      },
      {
        'icon': Icons.pets_outlined,
        'label': 'Pets',
        'color': Colors.brown,
        'screen': const PetsScreen(),
      },
      {
        'icon': Icons.person_search_outlined,
        'label': 'Daily Help',
        'color': Colors.green,
        'screen': const DailyHelpScreen(),
      },
    ];

    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 12,
        mainAxisSpacing: 16,
        childAspectRatio: 0.8,
      ),
      itemCount: actions.length,
      itemBuilder: (context, index) {
        final action = actions[index];
        return InkWell(
          onTap: () {
            if (action['screen'] != null) {
              Get.to(() => action['screen'] as Widget);
            } else if (action['tabIndex'] != null) {
              Get.find<NavigationController>().setIndex(
                action['tabIndex'] as int,
              );
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (action['color'] as Color).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  action['icon'] as IconData,
                  color: action['color'] as Color,
                  size: 28,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                action['label'] as String,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textDark,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      },
    );
  }
}
