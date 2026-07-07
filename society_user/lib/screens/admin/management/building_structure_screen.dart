import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/constants/colors.dart';
import '../../../controllers/admin_controller.dart';
import 'floor_management_screen.dart';
import '../../../widgets/responsive_web_grid.dart';
import '../../../widgets/responsive_web_container.dart';

class BuildingStructureScreen extends StatefulWidget {
  const BuildingStructureScreen({super.key});

  @override
  State<BuildingStructureScreen> createState() =>
      _BuildingStructureScreenState();
}

class _BuildingStructureScreenState extends State<BuildingStructureScreen> {
  final AdminController _adminController = Get.find<AdminController>();
  final RxBool _loading = true.obs;

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () => _load());
  }

  Future<void> _load() async {
    _loading.value = true;
    await _adminController.fetchBuildingStructure();
    _loading.value = false;
  }

  void _showInputDialog({
    required String title,
    String? initialValue,
    required Function(String) onSave,
  }) {
    final controller = TextEditingController(text: initialValue);
    Get.dialog(
      AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Name/Number'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                onSave(controller.text);
                Get.back();
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Building Structure', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primaryNavy,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _load,
          ),
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () => _showInputDialog(
              title: 'Add Block',
              onSave: (name) async {
                await _adminController.createBlock(name);
                await _load();
              },
            ),
          ),
        ],
      ),
      body: ResponsiveWebContainer(
        maxWidth: 1200,
        child: Obx(() {
          if (_loading.value || _adminController.isLoading) {
            return _buildShimmerList();
          }

          final structure = _adminController.buildingStructure;
          final blocks = structure['blocks'] as List? ?? [];

          if (blocks.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('No blocks found. Add one to start.'),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () => _showInputDialog(
                      title: 'Add Block',
                      onSave: (name) async {
                        await _adminController.createBlock(name);
                        await _load();
                      },
                    ),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Block'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _load,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: ResponsiveWebGrid(
                desktopCrossAxisCount: 3,
                childAspectRatioDesktop: 1.5,
                children: blocks.map((block) => _buildBlockCard(block)).toList(),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildBlockCard(Map<String, dynamic> block) {
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.business, color: Colors.blue),
            title: Text(
              block['name'] ?? 'N/A',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            subtitle: Text(
              'Floors: ${(block['floors'] as List? ?? []).length}',
            ),
            trailing: PopupMenuButton(
              itemBuilder: (context) => [
                PopupMenuItem(
                  child: const Row(
                    children: [Icon(Icons.edit, size: 18), SizedBox(width: 8), Text('Edit')],
                  ),
                  onTap: () => _showInputDialog(
                    title: 'Edit Block',
                    initialValue: block['name'],
                    onSave: (name) => _adminController.updateBlock(block['id'], name),
                  ),
                ),
                PopupMenuItem(
                  child: const Row(
                    children: [Icon(Icons.delete, size: 18, color: Colors.red), SizedBox(width: 8), Text('Delete', style: TextStyle(color: Colors.red))],
                  ),
                  onTap: () => _confirmDelete(
                    'Block',
                    () async {
                      await _adminController.deleteBlock(block['id']);
                      await _load();
                    },
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Manage Floors'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  Get.to(
                    () => FloorManagementScreen(block: block),
                    transition: Transition.rightToLeft,
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  void _confirmDelete(String type, Function onConfirm) {
    Get.dialog(
      AlertDialog(
        title: Text('Delete $type?'),
        content: Text(
          'Are you sure you want to delete this $type? This might delete nested items too.',
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              onConfirm();
              Get.back();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerList() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: ResponsiveWebGrid(
        desktopCrossAxisCount: 3,
        childAspectRatioDesktop: 1.5,
        children: List.generate(4, (index) => Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            margin: EdgeInsets.zero,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(width: 40, height: 40, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(12))),
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
                    Container(width: 32, height: 32, color: Colors.grey[300]),
                  ],
                ),
                const SizedBox(height: 12),
                Container(height: 44, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(8))),
              ],
            ),
          ),
        )),
      ),
    );
  }
}
