import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/colors.dart';
import '../../controllers/pet_controller.dart';
import '../../core/widgets/shimmer_loader.dart';

class PetsScreen extends StatefulWidget {
  const PetsScreen({super.key});

  @override
  State<PetsScreen> createState() => _PetsScreenState();
}

class _PetsScreenState extends State<PetsScreen> {
  final _nameController = TextEditingController();
  final _breedController = TextEditingController();
  String? _selectedType;
  bool _isVaccinated = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.find<PetController>().fetchPets();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _breedController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Pets'),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
          onPressed: () => Get.back(),
        ),
      ),
      body: GetBuilder<PetController>(
        builder: (provider) {
          if (provider.isLoading && provider.pets.isEmpty) {
            return const ShimmerList();
          }

          if (provider.pets.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.pets, size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  const Text('No pets added yet'),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: provider.pets.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final pet = provider.pets[index];
              return _buildPetCard(
                pet['breed'] ?? 'N/A',
                pet['name'] ?? 'Pet',
                pet['type'] ?? 'Dog',
                pet['status'] ??
                    (pet['is_vaccinated'] == 1
                        ? 'Vaccinated'
                        : 'Not Vaccinated'),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddPetDialog(),
        backgroundColor: AppColors.primaryNavy,
        icon: const Icon(Icons.pets, color: Colors.white),
        label: const Text(
          'Add Pet',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildPetCard(String breed, String name, String type, String status) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              type.toLowerCase() == 'dog' ? Icons.pets : Icons.category,
              color: Colors.orange,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  '$type • $breed',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color:
                        status.contains('Vaccinated') && !status.contains('Not')
                        ? AppColors.successGreen.withValues(alpha: 0.1)
                        : AppColors.warningOrange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      color:
                          status.contains('Vaccinated') &&
                              !status.contains('Not')
                          ? AppColors.successGreen
                          : AppColors.warningOrange,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
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

  void _showAddPetDialog() {
    _nameController.clear();
    _breedController.clear();
    _selectedType = null;
    _isVaccinated = true;

    final types = ['Dog', 'Cat', 'Bird', 'Rabbit', 'Other'];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Add New Pet',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  _buildInputField('Pet Name', 'e.g. Buddy', _nameController),
                  const SizedBox(height: 16),
                  const Text(
                    'Pet Type',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                    hint: const Text(
                      'Select pet type',
                      style: TextStyle(fontSize: 13),
                    ),
                    initialValue: _selectedType,
                    items: types
                        .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                        .toList(),
                    onChanged: (val) =>
                        setDialogState(() => _selectedType = val),
                  ),
                  const SizedBox(height: 16),
                  _buildInputField(
                    'Breed',
                    'e.g. Golden Retriever',
                    _breedController,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Checkbox(
                        value: _isVaccinated,
                        onChanged: (v) =>
                            setDialogState(() => _isVaccinated = v ?? true),
                        activeColor: AppColors.primaryNavy,
                      ),
                      const Text('Vaccinated', style: TextStyle(fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: GetBuilder<PetController>(
                      builder: (provider) {
                        return ElevatedButton(
                          onPressed: provider.isLoading
                              ? null
                              : () async {
                                  if (_nameController.text.isEmpty ||
                                      _selectedType == null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Please fill name and type',
                                        ),
                                      ),
                                    );
                                    return;
                                  }
                                  final success = await provider.addPet({
                                    'name': _nameController.text.trim(),
                                    'type': _selectedType,
                                    'breed': _breedController.text.trim(),
                                    'is_vaccinated': _isVaccinated ? 1 : 0,
                                  });
                                  if (success) {
                                    Get.back();
                                    Get.snackbar(
                                      'Success',
                                      'Pet added successfully',
                                    );
                                  } else {
                                    Get.snackbar(
                                      'Error',
                                      'Failed to add pet',
                                      backgroundColor: Colors.red.withValues(
                                        alpha: 0.1,
                                      ),
                                      colorText: Colors.red,
                                    );
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryNavy,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: provider.isLoading
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : const Text(
                                  'Add Pet',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField(
    String label,
    String hint,
    TextEditingController controller,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
            filled: true,
            fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primaryNavy),
            ),
          ),
        ),
      ],
    );
  }
}
