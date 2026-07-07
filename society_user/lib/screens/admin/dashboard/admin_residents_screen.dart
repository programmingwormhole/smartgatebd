import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';
import '../../../controllers/admin_controller.dart';
import '../../../core/constants/colors.dart';
import '../../../widgets/user_avatar_widget.dart';
import 'create_resident_screen.dart';
import 'edit_resident_screen.dart';
import 'resident_detail_screen.dart';

class AdminResidentsScreen extends StatefulWidget {
  const AdminResidentsScreen({super.key});

  @override
  State<AdminResidentsScreen> createState() => _AdminResidentsScreenState();
}

class _AdminResidentsScreenState extends State<AdminResidentsScreen> {
  late AdminController _adminController;

  @override
  void initState() {
    super.initState();
    _adminController = Get.find<AdminController>();
    // Fetch building members when screen loads
    _adminController.fetchBuildingMembers();
  }

  void _navigateToCreateResident() {
    final adminCtrl = Get.find<AdminController>();
    // Ensure building structure is loaded
    if (adminCtrl.buildingStructure.isEmpty) {
      adminCtrl.fetchBuildingStructure();
    }

    Get.to(
      () => const CreateResidentScreen(),
      transition: Transition.rightToLeft,
    );
  }

  final controller = Get.find<AdminController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Manage Residents',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: AppColors.primaryNavy,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: _navigateToCreateResident,
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading) {
          return _buildShimmerLoading();
        }

        if (controller.members.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.person_off, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('No residents found'),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: controller.members.length,
          itemBuilder: (context, index) {
            final member = controller.members[index];
            return _ResidentCard(
              member: member,
              onView: () => Get.to(() => ResidentDetailScreen(resident: member)),
              onEdit: () => Get.to(() => EditResidentScreen(resident: member)),
              onToggleRole: () => _toggleRole(member),
              onDelete: () => _confirmDelete(member),
            );
          },
        );
      }),
    );
  }

  Future<void> _toggleRole(Map<String, dynamic> member) async {
    final role = (member['role'] ?? 'resident').toString().toLowerCase();
    final newRole = role == 'committee' ? 'resident' : 'committee';
    final id = member['id'];
    if (id == null) return;

    final success = await _adminController.toggleCommitteeStatus(id, newRole);
    if (success) {
      Get.snackbar(
        'Updated',
        'Role changed to ${newRole.capitalizeFirst}',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    }
  }

  Future<void> _confirmDelete(Map<String, dynamic> member) async {
    final id = member['id'];
    if (id == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Resident'),
        content: const Text('Are you sure you want to remove this resident?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Remove', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm != true) return;

    final success = await _adminController.deleteResident(id);
    if (success) {
      Get.snackbar('Removed', 'Resident removed', backgroundColor: Colors.green, colorText: Colors.white);
    }
  }

  Widget _buildShimmerLoading() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 6,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Card(
            elevation: 2,
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              leading: CircleAvatar(backgroundColor: Colors.grey[300]),
              title: Container(height: 16, color: Colors.grey[300]),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Container(height: 12, color: Colors.grey[300]),
                  const SizedBox(height: 4),
                  Container(height: 12, width: 150, color: Colors.grey[300]),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ResidentCard extends StatelessWidget {
  const _ResidentCard({
    required this.member,
    required this.onView,
    required this.onEdit,
    required this.onToggleRole,
    required this.onDelete,
  });

  final Map<String, dynamic> member;
  final VoidCallback onView;
  final VoidCallback onEdit;
  final VoidCallback onToggleRole;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final user = member['user'] ?? {};
    final flat = member['flat'] ?? {};
    final roleName = (member['role'] ?? 'Resident').toString().capitalizeFirst;
    final flatNumber = flat['flat_number'] ?? 'N/A';
    final phone = user['phone'] ?? 'N/A';
    final userName = (user['name'] ?? 'Unknown').toString();
    final profilePicture = user['profile_picture']?.toString();

    return GestureDetector(
      onTap: onView,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4)),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            UserAvatarWidget(
              radius: 26,
              userName: userName,
              profilePictureUrl: profilePicture,
              backgroundColor: AppColors.primaryBlue.withOpacity(0.12),
              textColor: AppColors.primaryBlue,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          user['name'] ?? 'Unknown',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      PopupMenuButton(
                        elevation: 6,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        itemBuilder: (context) => [
                          const PopupMenuItem(value: 'view', child: Text('View Profile')),
                          const PopupMenuItem(value: 'edit', child: Text('Edit Info')),
                          PopupMenuItem(
                            value: 'role',
                            child: Text(roleName == 'Committee' ? 'Make Resident' : 'Make Committee'),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Text('Remove', style: TextStyle(color: Colors.red)),
                          ),
                        ],
                        onSelected: (value) {
                          switch (value) {
                            case 'view':
                              onView();
                              break;
                            case 'edit':
                              onEdit();
                              break;
                            case 'role':
                              onToggleRole();
                              break;
                            case 'delete':
                              onDelete();
                              break;
                            default:
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _chip(icon: Icons.home_work_outlined, label: 'Flat $flatNumber'),
                      const SizedBox(width: 8),
                      _chip(icon: Icons.verified_user_outlined, label: roleName ?? 'Resident'),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Phone: $phone',
                    style: TextStyle(color: Colors.grey[700], fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primaryBlue.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.primaryBlue),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

}
