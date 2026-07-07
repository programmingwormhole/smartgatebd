import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/constants/colors.dart';
import '../../../services/admin_service.dart';
import '../../../widgets/user_avatar_widget.dart';
import 'superadmin_guard_create_screen.dart';
import 'superadmin_guard_detail_screen.dart';

class SuperadminGuardListScreen extends StatefulWidget {
  const SuperadminGuardListScreen({super.key});

  @override
  State<SuperadminGuardListScreen> createState() => _SuperadminGuardListScreenState();
}

class _SuperadminGuardListScreenState extends State<SuperadminGuardListScreen> {
  final AdminService _adminService = AdminService();
  final RxBool _loading = true.obs;
  final RxList<dynamic> _guards = <dynamic>[].obs;
  final RxString _selectedStatus = 'all'.obs;
  final TextEditingController _searchController = TextEditingController();

  final List<String> _statusOptions = ['all', 'on_duty', 'off_duty', 'leave', 'inactive'];

  @override
  void initState() {
    super.initState();
    _loadGuards();
  }

  Future<void> _loadGuards() async {
    try {
      _loading.value = true;
      final data = await _adminService.getAllGuards(
        status: _selectedStatus.value == 'all' ? null : _selectedStatus.value,
        search: _searchController.text.isEmpty ? null : _searchController.text,
      );
      _guards.assignAll(data['data'] ?? []);
    } catch (e) {
      Get.snackbar('Error', 'Failed to load guards: $e', backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      _loading.value = false;
    }
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
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              height: 90,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        );
      },
    );
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
              final created = await Get.to(() => const SuperadminGuardCreateScreen());
              if (created == true) _loadGuards();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.primaryNavy,
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search by name or phone...',
                hintStyle: TextStyle(color: Colors.white70),
                prefixIcon: const Icon(Icons.search, color: Colors.white70),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.white30),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.white30),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.white),
                ),
              ),
              onChanged: (_) => _loadGuards(),
            ),
          ),

          // Status Filter
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.white,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Obx(
                () => Row(
                  children: _statusOptions.map((status) {
                    final isSelected = _selectedStatus.value == status;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(status.replaceAll('_', ' ').toUpperCase()),
                        selected: isSelected,
                        onSelected: (selected) {
                          _selectedStatus.value = status;
                          _loadGuards();
                        },
                        backgroundColor: Colors.grey[200],
                        selectedColor: AppColors.primaryNavy,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),

          // Guards List
          Expanded(
            child: Obx(() {
              if (_loading.value) {
                return _buildShimmer();
              }

              if (_guards.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.security_outlined, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text('No guards found', style: TextStyle(fontSize: 16, color: Colors.grey)),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: () async {
                          final created = await Get.to(() => const SuperadminGuardCreateScreen());
                          if (created == true) _loadGuards();
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Add Guard'),
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: _loadGuards,
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _guards.length,
                  itemBuilder: (context, index) {
                    final guard = _guards[index];
                    final user = guard['user'] ?? {};
                    final status = (guard['status'] ?? 'on_duty').toString().toLowerCase();
                    final statusColor = _getStatusColor(status);
                    final building = guard['building'] ?? {};
                    final userName = (user['name'] ?? 'Guard').toString();
                    final profilePicture = user['profile_picture']?.toString();

                    return GestureDetector(
                      onTap: () async {
                        final updated = await Get.to(() => SuperadminGuardDetailScreen(guard: guard));
                        if (updated == true) _loadGuards();
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 3))],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
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
                                      Text(user['phone'] ?? 'N/A', style: TextStyle(color: Colors.grey[700], fontSize: 12)),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: statusColor.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    status.replaceAll('_', ' ').toUpperCase(),
                                    style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.location_on, size: 14, color: Colors.grey),
                                const SizedBox(width: 4),
                                Text(building['name'] ?? 'N/A', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
