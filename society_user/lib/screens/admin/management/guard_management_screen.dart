import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/constants/colors.dart';
import '../../../controllers/admin_controller.dart';
import '../../../widgets/user_avatar_widget.dart';
import 'guard_create_screen.dart';
import 'guard_edit_screen.dart';
import '../../../widgets/responsive_web_container.dart';

class GuardManagementScreen extends StatefulWidget {
  const GuardManagementScreen({super.key});

  @override
  State<GuardManagementScreen> createState() => _GuardManagementScreenState();
}

class _GuardManagementScreenState extends State<GuardManagementScreen> {
  final AdminController _adminController = Get.find<AdminController>();
  final RxBool _loading = true.obs;

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () => _loadGuards());
  }

  Future<void> _loadGuards() async {
    _loading.value = true;
    await _adminController.fetchGuards();
    _loading.value = false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Guard Management', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primaryNavy,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadGuards,
          ),
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () async {
              final created = await Get.to(() => const GuardCreateScreen());
              if (created == true) _loadGuards();
            },
          ),
        ],
      ),
      body: ResponsiveWebContainer(
        maxWidth: 800,
        child: Obx(() {
          if (_loading.value || _adminController.isLoading) {
            return _buildShimmer();
          }

        final guards = _adminController.guards;

        if (guards.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('No guards found.'),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () async {
                    final created = await Get.to(() => const GuardCreateScreen());
                    if (created == true) _loadGuards();
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add Primary Guard'),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: _loadGuards,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: guards.length,
            itemBuilder: (context, index) {
              final guard = guards[index];
              final user = guard['user'] ?? {};
              final status = (guard['status'] ?? 'on_duty').toString().toLowerCase();
              final statusColor = _getStatusColor(status);
              final userName = (user['name'] ?? 'Guard').toString();
              final profilePicture = user['profile_picture']?.toString();

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 3))],
                ),
                child: Row(
                  children: [
                    UserAvatarWidget(
                      radius: 20,
                      userName: userName,
                      profilePictureUrl: profilePicture,
                      backgroundColor: statusColor.withOpacity(0.12),
                      textColor: statusColor,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(user['name'] ?? 'N/A', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text('Phone: ${user['phone'] ?? 'N/A'}', style: TextStyle(color: Colors.grey[700], fontSize: 12)),
                              const SizedBox(width: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(color: statusColor.withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
                                child: Text(
                                  status.replaceAll('_', ' ').toUpperCase(),
                                  style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton(
                      itemBuilder: (context) {
                        return [
                          PopupMenuItem(
                            child: const Text('On Duty'),
                            onTap: () => _updateGuardStatus(guard['id'], 'on_duty'),
                          ),
                          PopupMenuItem(
                            child: const Text('Off Duty'),
                            onTap: () => _updateGuardStatus(guard['id'], 'off_duty'),
                          ),
                          PopupMenuItem(
                            child: const Text('Leave'),
                            onTap: () => _updateGuardStatus(guard['id'], 'leave'),
                          ),
                          PopupMenuItem(
                            child: const Text('Inactive'),
                            onTap: () => _updateGuardStatus(guard['id'], 'inactive'),
                          ),
                        ];
                      },
                      child: const Icon(Icons.more_vert),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () async {
                        final updated = await Get.to(() => GuardEditScreen(guard: guard));
                        if (updated == true) _loadGuards();
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        Get.dialog(
                          AlertDialog(
                            title: const Text('Delete Guard?'),
                            content: Text('Are you sure you want to delete ${guard['name']}?'),
                            actions: [
                              TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
                              ElevatedButton(
                                onPressed: () async {
                                  final success = await _adminController.deleteGuard(guard['id']);
                                  if (success) {
                                    Get.back();
                                    Get.snackbar('Deleted', 'Guard deleted successfully', backgroundColor: Colors.green, colorText: Colors.white);
                                    await _loadGuards();
                                  }
                                },
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                                child: const Text('Delete'),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        );
      }),
      ),
    );
  }

  void _updateGuardStatus(int guardId, String newStatus) {
    _adminController.updateGuardStatus(guardId, newStatus);
    _loadGuards();
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'on_duty':
        return Colors.green;
      case 'off_duty':
        return Colors.orange;
      case 'leave':
        return Colors.blue;
      case 'inactive':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildShimmer() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 6,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
            child: Row(
              children: [
                Container(width: 40, height: 40, decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(height: 14, width: 140, color: Colors.grey[300]),
                      const SizedBox(height: 8),
                      Container(height: 12, width: 100, color: Colors.grey[300]),
                    ],
                  ),
                ),
                Container(width: 40, height: 24, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(12))),
              ],
            ),
          ),
        );
      },
    );
  }
}
