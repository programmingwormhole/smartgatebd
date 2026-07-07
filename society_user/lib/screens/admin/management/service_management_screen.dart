import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/constants/colors.dart';
import '../../../controllers/service_controller.dart';
import 'create_edit_service_screen.dart';

class ServiceManagementScreen extends StatefulWidget {
  const ServiceManagementScreen({super.key});

  @override
  State<ServiceManagementScreen> createState() =>
      _ServiceManagementScreenState();
}

class _ServiceManagementScreenState extends State<ServiceManagementScreen> {
  final ServiceController _serviceController = Get.find<ServiceController>();

  @override
  void initState() {
    super.initState();
    _serviceController.fetchServices();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Service Management',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primaryNavy,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _serviceController.fetchServices,
          ),
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () {
              Get.to(() => const CreateEditServiceScreen());
            },
          ),
        ],
      ),
      body: Obx(() {
        if (_serviceController.isLoading.value) {
          return _buildShimmer();
        }

        final services = _serviceController.services;

        if (services.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.handyman_outlined,
                    size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                const Text('No services found.'),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () {
                    Get.to(() => const CreateEditServiceScreen());
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add Service'),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: _serviceController.fetchServices,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: services.length,
            itemBuilder: (context, index) {
              final service = services[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(
                        color: Colors.black12,
                        blurRadius: 8,
                        offset: Offset(0, 3))
                  ],
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.blue.withOpacity(0.12),
                      child: const Icon(Icons.handyman_outlined,
                          color: Colors.blue),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(service['name'] ?? 'N/A',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 15)),
                          const SizedBox(height: 4),
                          Text(service['category'] ?? 'No category',
                              style: TextStyle(
                                  color: Colors.grey[700], fontSize: 12)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () {
                        Get.to(() =>
                            CreateEditServiceScreen(service: service));
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        Get.dialog(
                          AlertDialog(
                            title: const Text('Delete Service?'),
                            content: Text(
                                'Are you sure you want to delete ${service['name']}?'),
                            actions: [
                              TextButton(
                                  onPressed: () => Get.back(),
                                  child: const Text('Cancel')),
                              ElevatedButton(
                                onPressed: () async {
                                  final success =
                                      await _serviceController.deleteService(
                                    service['id'],
                                  );
                                  if (success) {
                                    Get.back();
                                    Get.snackbar(
                                      'Deleted',
                                      'Service deleted successfully',
                                      backgroundColor: Colors.green,
                                      colorText: Colors.white,
                                    );
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
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12)),
            child: Row(
              children: [
                Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                        shape: BoxShape.circle, color: Colors.white)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                          height: 14,
                          width: 140,
                          color: Colors.grey[300]),
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
