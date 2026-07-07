import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/constants/colors.dart';
import '../../../controllers/amenity_controller.dart';
import 'create_edit_amenity_screen.dart';

class AmenityManagementScreen extends StatefulWidget {
  const AmenityManagementScreen({super.key});

  @override
  State<AmenityManagementScreen> createState() =>
      _AmenityManagementScreenState();
}

class _AmenityManagementScreenState extends State<AmenityManagementScreen> {
  final AmenityController _amenityController = Get.find<AmenityController>();

  @override
  void initState() {
    super.initState();
    _amenityController.fetchAmenities();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Amenity Management', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primaryNavy,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _amenityController.fetchAmenities,
          ),
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () {
              Get.to(() => const CreateEditAmenityScreen());
            },
          ),
        ],
      ),
      body: Obx(() {
        if (_amenityController.isLoading.value) {
          return _buildShimmer();
        }

        final amenities = _amenityController.amenities;

        if (amenities.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('No amenities found.'),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () {
                    Get.to(() => const CreateEditAmenityScreen());
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add Primary Amenity'),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: _amenityController.fetchAmenities,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: amenities.length,
            itemBuilder: (context, index) {
              final amenity = amenities[index];
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
                    CircleAvatar(
                      backgroundColor: Colors.purple.withOpacity(0.12),
                      child: const Icon(Icons.pool, color: Colors.purple),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(amenity['name'] ?? 'N/A', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          const SizedBox(height: 4),
                          Text('Price: ${amenity['price_per_day'] ?? '-'} | Capacity: ${amenity['max_capacity'] ?? '-'}', style: TextStyle(color: Colors.grey[700], fontSize: 12)),
                          if (amenity['open_time'] != null || amenity['close_time'] != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                'Hours: ${amenity['open_time'] ?? '--'} - ${amenity['close_time'] ?? '--'}',
                                style: TextStyle(color: Colors.grey[600], fontSize: 12),
                              ),
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () {
                        Get.to(() => CreateEditAmenityScreen(amenity: amenity));
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        Get.dialog(
                          AlertDialog(
                            title: const Text('Delete Amenity?'),
                            content: Text('Are you sure you want to delete ${amenity['name']}?'),
                            actions: [
                              TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
                              ElevatedButton(
                                onPressed: () async {
                                  final success = await _amenityController.deleteAmenity(amenity['id']);
                                  if (success) {
                                    Get.back();
                                    Get.snackbar('Deleted', 'Amenity deleted successfully', backgroundColor: Colors.green, colorText: Colors.white);
                                  }
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
                      },
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
                Container(width: 32, height: 32, color: Colors.grey[300]),
              ],
            ),
          ),
        );
      },
    );
  }
}
