import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/colors.dart';
import '../../../controllers/service_controller.dart';
import '../../../widgets/responsive_web_container.dart';

class CreateEditServiceScreen extends StatefulWidget {
  final Map<String, dynamic>? service;

  const CreateEditServiceScreen({super.key, this.service});

  @override
  State<CreateEditServiceScreen> createState() =>
      _CreateEditServiceScreenState();
}

class _CreateEditServiceScreenState extends State<CreateEditServiceScreen> {
  late TextEditingController nameController;
  final ServiceController _serviceController = Get.find<ServiceController>();
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(
      text: widget.service?['name'] ?? widget.service?['category'],
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  Future<void> _saveService() async {
    if (nameController.text.isEmpty) {
      Get.snackbar('Error', 'Service name is required',
          backgroundColor: AppColors.errorRed, colorText: Colors.white);
      return;
    }

    setState(() {
      isLoading = true;
    });

    final data = {
      'name': nameController.text,
      'category': nameController.text,
    };

    bool success;
    if (widget.service == null) {
      success = await _serviceController.createService(data);
    } else {
      success = await _serviceController.updateService(
        widget.service!['id'],
        data,
      );
    }

    setState(() {
      isLoading = false;
    });

    if (success) {
      Get.back();
      Get.snackbar(
        'Success',
        widget.service == null
            ? 'Service created successfully'
            : 'Service updated successfully',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } else {
      Get.snackbar(
        'Error',
        'Failed to save service',
        backgroundColor: AppColors.errorRed,
        colorText: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          widget.service == null ? 'Add Service' : 'Edit Service',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primaryNavy,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
      ),
      body: ResponsiveWebContainer(
        maxWidth: 600,
        wrapInCard: true,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Service Name',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 8),
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                hintText: 'e.g., Laundry, Electrician, Plumbing',
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.grey),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.grey),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                      color: AppColors.primaryBlue, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: isLoading ? null : _saveService,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Save Service',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}
