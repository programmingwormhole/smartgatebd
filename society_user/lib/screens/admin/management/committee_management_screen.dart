import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/constants/colors.dart';
import '../../../controllers/admin_controller.dart';
import '../../../widgets/user_avatar_widget.dart';

class CommitteeManagementScreen extends StatefulWidget {
  const CommitteeManagementScreen({super.key});

  @override
  State<CommitteeManagementScreen> createState() =>
      _CommitteeManagementScreenState();
}

class _CommitteeManagementScreenState extends State<CommitteeManagementScreen> {
  final AdminController _adminController = Get.find<AdminController>();
  final RxBool _loading = true.obs;

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () => _loadMembers());
  }

  Future<void> _loadMembers() async {
    _loading.value = true;
    await _adminController.fetchBuildingMembers();
    _loading.value = false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Committee Management', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primaryNavy,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadMembers,
          ),
        ],
      ),
      body: Obx(() {
        if (_loading.value || _adminController.isLoading) {
          return _buildShimmer();
        }

        final members = _adminController.members;

        if (members.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('No residents found.'),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: _loadMembers,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reload'),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: _loadMembers,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: members.length,
            itemBuilder: (context, index) {
              final member = members[index];
              final user = member['user'] ?? {};
              final isCommittee = (member['role'] ?? '').toString().toLowerCase() == 'committee';
              final flatNumber = member['flat']?['flat_number'] ?? 'N/A';
              final userName = (user['name'] ?? 'Resident').toString();
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
                      backgroundColor: isCommittee ? Colors.orange.withOpacity(0.12) : Colors.grey[200],
                      textColor: isCommittee ? Colors.orange : Colors.grey[700],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(user['name'] ?? 'N/A', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          const SizedBox(height: 4),
                          Text('Flat: $flatNumber', style: TextStyle(color: Colors.grey[700], fontSize: 12)),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              _chip(label: (member['role'] ?? 'resident').toString().capitalizeFirst ?? 'Resident', color: isCommittee ? Colors.orange : AppColors.primaryBlue),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: isCommittee,
                      onChanged: (value) async {
                        final newRole = value ? 'committee' : 'resident';
                        final success = await _adminController.toggleCommitteeStatus(member['id'], newRole);
                        if (success) {
                          Get.snackbar('Updated', 'Role updated', backgroundColor: Colors.green, colorText: Colors.white);
                        } else {
                          Get.snackbar('Error', 'Failed to update role', backgroundColor: Colors.red, colorText: Colors.white);
                        }
                      },
                      activeColor: Colors.orange,
                    ),
                  ],
                ),
              );
            },
          ),
        );
      }),
    );
  }

  Widget _chip({required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
    );
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
                Container(width: 40, height: 40, decoration: BoxDecoration(color: Colors.grey[300], shape: BoxShape.circle)),
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
