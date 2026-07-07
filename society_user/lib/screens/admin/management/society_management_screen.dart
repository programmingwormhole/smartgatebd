import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/colors.dart';
import 'committee_management_screen.dart';
import 'amenity_management_screen.dart';
import 'guard_management_screen.dart';
import 'building_structure_screen.dart';
import 'service_management_screen.dart';
import 'payment_gateway_management_screen.dart';
import '../../../widgets/responsive_web_grid.dart';
import '../../../widgets/responsive_web_container.dart';

class SocietyManagementScreen extends StatelessWidget {
  const SocietyManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Society Management', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: AppColors.primaryNavy,
        elevation: 0,
      ),
      body: ResponsiveWebContainer(
        maxWidth: 1200,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ResponsiveWebGrid(
            desktopCrossAxisCount: 3,
            childAspectRatioDesktop: 3.2,
            children: [
              _buildManagementCard(
                context,
                title: 'Building Structure',
                subtitle: 'Blocks, Floors & Flats',
                icon: Icons.apartment_rounded,
                color: Colors.blue,
                onTap: () => Get.to(() => const BuildingStructureScreen()),
              ),
              _buildManagementCard(
                context,
                title: 'Committee Members',
                subtitle: 'Promote/Demote committee roles',
                icon: Icons.workspace_premium_outlined,
                color: Colors.orange,
                onTap: () => Get.to(() => const CommitteeManagementScreen()),
              ),
              _buildManagementCard(
                context,
                title: 'Security Guards',
                subtitle: 'Staff roster and status',
                icon: Icons.security,
                color: Colors.green,
                onTap: () => Get.to(() => const GuardManagementScreen()),
              ),
              _buildManagementCard(
                context,
                title: 'Amenities',
                subtitle: 'Common areas & pricing',
                icon: Icons.pool,
                color: Colors.purple,
                onTap: () => Get.to(() => const AmenityManagementScreen()),
              ),
              _buildManagementCard(
                context,
                title: 'Services',
                subtitle: 'Laundry, Electrician & more',
                icon: Icons.handyman_outlined,
                color: Colors.teal,
                onTap: () => Get.to(() => const ServiceManagementScreen()),
              ),
              _buildManagementCard(
                context,
                title: 'Payment Gateways',
                subtitle: 'Manage offline payment methods',
                icon: Icons.payment,
                color: Colors.indigo,
                onTap: () => Get.to(() => const PaymentGatewayManagementScreen()),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildManagementCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4)),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: TextStyle(color: Colors.grey[700])),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
