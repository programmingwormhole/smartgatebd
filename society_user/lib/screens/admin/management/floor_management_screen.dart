import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/colors.dart';
import '../../../controllers/admin_controller.dart';
import 'flat_management_screen.dart';

class FloorManagementScreen extends StatefulWidget {
  final Map<String, dynamic> block;

  const FloorManagementScreen({super.key, required this.block});

  @override
  State<FloorManagementScreen> createState() => _FloorManagementScreenState();
}

class _FloorManagementScreenState extends State<FloorManagementScreen> {
  final AdminController _adminController = Get.find<AdminController>();
  late TextEditingController _floorNumberController;
  late final int _blockId;

  @override
  void initState() {
    super.initState();
    _blockId = widget.block['id'];
    _floorNumberController = TextEditingController();
  }

  @override
  void dispose() {
    _floorNumberController.dispose();
    super.dispose();
  }

  void _showAddFloorDialog() {
    _floorNumberController.clear();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add New Floor'),
          content: TextField(
            controller: _floorNumberController,
            decoration: const InputDecoration(
              labelText: 'Floor Number (e.g., 1, 2nd Floor, Ground)',
              border: OutlineInputBorder(),
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_floorNumberController.text.isNotEmpty) {
                  final success = await _adminController.createFloor(
                    widget.block['id'],
                    _floorNumberController.text,
                  );
                  if (success && mounted) {
                    Get.back();
                    _showSnackbar('Floor added successfully', Colors.green);
                  } else if (mounted) {
                    Get.back();
                    _showSnackbar('Failed to add floor', Colors.red);
                  }
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _showEditFloorDialog(Map<String, dynamic> floor) {
    _floorNumberController.text = floor['floor_number'] ?? '';
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Floor'),
          content: TextField(
            controller: _floorNumberController,
            decoration: const InputDecoration(
              labelText: 'Floor Number',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_floorNumberController.text.isNotEmpty) {
                  final success = await _adminController.updateFloor(
                    floor['id'],
                    _floorNumberController.text,
                  );
                  if (success && mounted) {
                    Get.back();
                    _showSnackbar('Floor updated successfully', Colors.green);
                  } else if (mounted) {
                    Get.back();
                    _showSnackbar('Failed to update floor', Colors.red);
                  }
                }
              },
              child: const Text('Update'),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteConfirmation(Map<String, dynamic> floor) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Floor'),
          content: Text(
            'Are you sure you want to delete Floor ${floor['floor_number']}? '
            'All flats in this floor will also be deleted.',
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final success = await _adminController.deleteFloor(floor['id']);
                if (success && mounted) {
                  Get.back();
                  _showSnackbar('Floor deleted successfully', Colors.green);
                } else if (mounted) {
                  Get.back();
                  _showSnackbar('Failed to delete floor', Colors.red);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _showSnackbar(String message, Color backgroundColor) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: backgroundColor,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final structure = _adminController.buildingStructure;
      final blocks = structure['blocks'] as List? ?? [];
      final block = blocks.cast<Map<String, dynamic>?>().firstWhere(
            (b) => b?['id'] == _blockId,
            orElse: () => null,
          ) ??
          widget.block;

      final floors = block['floors'] as List? ?? [];

      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text('Floors in ${block['name'] ?? 'Block'}'),
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: IconThemeData(color: AppColors.primaryNavy),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, color: AppColors.primaryNavy),
              onPressed: _adminController.fetchBuildingStructure,
            ),
            IconButton(
              icon: const Icon(Icons.add, color: AppColors.primaryNavy),
              onPressed: _showAddFloorDialog,
            ),
          ],
        ),
        body: _adminController.isLoading
            ? const Center(child: CircularProgressIndicator())
            : floors.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.layers_clear,
                          size: 80,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No floors found',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _showAddFloorDialog,
                          icon: const Icon(Icons.add),
                          label: const Text('Add First Floor'),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: floors.length,
                    itemBuilder: (context, index) {
                      final floor = floors[index] as Map<String, dynamic>;
                      return _buildFloorCard(floor, blockName: block['name']);
                    },
                  ),
      );
    });
  }

  Widget _buildFloorCard(Map<String, dynamic> floor, {String? blockName}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.layers, color: Colors.orange),
            title: Text(
              'Floor ${floor['floor_number'] ?? 'N/A'}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            subtitle: Text(
              'Block: ${blockName ?? 'N/A'} • Flats: ${(floor['flats'] as List? ?? []).length}',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') {
                  _showEditFloorDialog(floor);
                } else if (value == 'delete') {
                  _showDeleteConfirmation(floor);
                }
              },
              itemBuilder: (BuildContext context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 18, color: Colors.blue),
                      SizedBox(width: 8),
                      Text('Edit'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, size: 18, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Delete'),
                    ],
                  ),
                ),
              ],
            ),
            onTap: () {
              Get.to(
                () => FlatManagementScreen(
                  floor: floor,
                  blockId: _blockId,
                ),
                transition: Transition.rightToLeft,
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Get.to(
                        () => FlatManagementScreen(
                          floor: floor,
                          blockId: _blockId,
                        ),
                        transition: Transition.rightToLeft,
                      );
                    },
                    icon: const Icon(Icons.house),
                    label: const Text('Manage Flats'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
