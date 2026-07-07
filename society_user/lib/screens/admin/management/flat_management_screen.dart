import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/colors.dart';
import '../../../controllers/admin_controller.dart';
import 'create_resident_in_flat_screen.dart';

class FlatManagementScreen extends StatefulWidget {
  final Map<String, dynamic> floor;
  final int blockId;

  const FlatManagementScreen({
    super.key,
    required this.floor,
    required this.blockId,
  });

  @override
  State<FlatManagementScreen> createState() => _FlatManagementScreenState();
}

class _FlatManagementScreenState extends State<FlatManagementScreen> {
  final AdminController _adminController = Get.find<AdminController>();
  late TextEditingController _flatNumberController;
  late final int _floorId;

  @override
  void initState() {
    super.initState();
    _floorId = widget.floor['id'];
    _flatNumberController = TextEditingController();
  }

  @override
  void dispose() {
    _flatNumberController.dispose();
    super.dispose();
  }

  void _showAddFlatDialog() {
    _flatNumberController.clear();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add New Flat'),
          content: TextField(
            controller: _flatNumberController,
            decoration: const InputDecoration(
              labelText: 'Flat Number (e.g., A-101, 201)',
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
                if (_flatNumberController.text.isNotEmpty) {
                  final success = await _adminController.createFlat(
                    widget.floor['id'],
                    _flatNumberController.text,
                  );
                  if (success && mounted) {
                    Get.back();
                    _showSnackbar('Flat added successfully', Colors.green);
                  } else if (mounted) {
                    Get.back();
                    _showSnackbar('Failed to add flat', Colors.red);
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

  void _showEditFlatDialog(Map<String, dynamic> flat) {
    _flatNumberController.text = flat['flat_number'] ?? '';
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Flat'),
          content: TextField(
            controller: _flatNumberController,
            decoration: const InputDecoration(
              labelText: 'Flat Number',
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
                if (_flatNumberController.text.isNotEmpty) {
                  final success = await _adminController.updateFlat(
                    flat['id'],
                    _flatNumberController.text,
                  );
                  if (success && mounted) {
                    Get.back();
                    _showSnackbar('Flat updated successfully', Colors.green);
                  } else if (mounted) {
                    Get.back();
                    _showSnackbar('Failed to update flat', Colors.red);
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

  void _showDeleteConfirmation(Map<String, dynamic> flat) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Flat'),
          content: Text(
            'Are you sure you want to delete Flat ${flat['flat_number']}?',
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final success = await _adminController.deleteFlat(flat['id']);
                if (success && mounted) {
                  Get.back();
                  _showSnackbar('Flat deleted successfully', Colors.green);
                } else if (mounted) {
                  Get.back();
                  _showSnackbar('Failed to delete flat', Colors.red);
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
        (b) => b?['id'] == widget.blockId,
        orElse: () => null,
      );

      final floorFromStructure = block == null
          ? null
          : (block['floors'] as List? ?? [])
                .cast<Map<String, dynamic>?>()
                .firstWhere((f) => f?['id'] == _floorId, orElse: () => null);

      final floor = floorFromStructure ?? widget.floor;
      final flats = floor['flats'] as List? ?? [];

      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text('Flats in Floor ${floor['floor_number'] ?? 'N/A'}'),
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
              onPressed: _showAddFlatDialog,
            ),
          ],
        ),
        body: _adminController.isLoading
            ? const Center(child: CircularProgressIndicator())
            : flats.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.house, size: 80, color: Colors.grey.shade400),
                    const SizedBox(height: 16),
                    Text(
                      'No flats found',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _showAddFlatDialog,
                      icon: const Icon(Icons.add),
                      label: const Text('Add First Flat'),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: flats.length,
                itemBuilder: (context, index) {
                  final flat = flats[index] as Map<String, dynamic>;
                  return _buildFlatCard(flat, floor);
                },
              ),
      );
    });
  }

  Widget _buildFlatCard(Map<String, dynamic> flat, Map<String, dynamic> floor) {
    final residents = flat['residents'] as List? ?? [];
    final residentCount = residents.isNotEmpty
        ? residents.length
        : (flat['residents_count'] ?? flat['resident_count'] ?? 0);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.house, color: Colors.blue),
            title: Text(
              'Flat ${flat['flat_number'] ?? 'N/A'}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            subtitle: Text(
              'Residents: $residentCount',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') {
                  _showEditFlatDialog(flat);
                } else if (value == 'delete') {
                  _showDeleteConfirmation(flat);
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
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Get.to(
                        () => CreateResidentInFlatScreen(
                          flat: flat,
                          floor: floor,
                        ),
                        transition: Transition.rightToLeft,
                      );
                    },
                    icon: const Icon(Icons.person_add),
                    label: const Text('Add Resident'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
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
