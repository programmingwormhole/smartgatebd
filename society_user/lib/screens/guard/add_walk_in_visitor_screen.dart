import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/guard_controller.dart';
import '../../core/constants/colors.dart';

class AddWalkInVisitorScreen extends StatefulWidget {
  const AddWalkInVisitorScreen({super.key});

  @override
  State<AddWalkInVisitorScreen> createState() => _AddWalkInVisitorScreenState();
}

class _AddWalkInVisitorScreenState extends State<AddWalkInVisitorScreen> {
  final GuardController _controller = Get.find<GuardController>();

  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _purposeController = TextEditingController();
  final _companyController = TextEditingController();
  final _vehicleController = TextEditingController();

  bool _isResidentsLoading = true;
  bool _isSubmitting = false;

  int? _selectedResidentId;
  String _selectedType = 'guest';

  int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }

  String _residentLabel(Map<String, dynamic> resident) {
    final user = resident['user'] as Map<String, dynamic>?;
    final name = (user?['name'] ?? resident['name'] ?? 'Resident').toString();
    final flatNumber =
        (resident['flat']?['flat_number'] ?? resident['flat_number'] ?? '')
            .toString();
    final blockName =
        (resident['flat']?['floor']?['block']?['name'] ?? '').toString();

    if (flatNumber.isEmpty && blockName.isEmpty) {
      return name;
    }

    final location = [blockName, flatNumber].where((e) => e.isNotEmpty).join('-');
    return '$name ($location)';
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadResidents();
    });
  }

  Future<void> _loadResidents() async {
    setState(() => _isResidentsLoading = true);
    await _controller.fetchBuildingResidents();
    if (!mounted) return;
    setState(() => _isResidentsLoading = false);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedResidentId == null) {
      Get.snackbar(
        'Required',
        'Please select a resident.',
        backgroundColor: Colors.red.withValues(alpha: 0.1),
        colorText: Colors.red,
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final result = await _controller.createWalkInVisitor(
      residentId: _selectedResidentId!,
      type: _selectedType,
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim().isEmpty
          ? null
          : _phoneController.text.trim(),
      purpose: _purposeController.text.trim().isEmpty
          ? null
          : _purposeController.text.trim(),
      companyName: _companyController.text.trim().isEmpty
          ? null
          : _companyController.text.trim(),
      vehicleNo: _vehicleController.text.trim().isEmpty
          ? null
          : _vehicleController.text.trim(),
    );

    if (!mounted) return;

    setState(() => _isSubmitting = false);

    if (result == null) {
      Get.snackbar(
        'Failed',
        _controller.errorMessage.value.isNotEmpty
            ? _controller.errorMessage.value
            : 'Could not add walk-in visitor.',
        backgroundColor: Colors.red.withValues(alpha: 0.1),
        colorText: Colors.red,
      );
      return;
    }

    Get.back(result: result);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _purposeController.dispose();
    _companyController.dispose();
    _vehicleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Add Walk-in Visitor'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isResidentsLoading
          ? const Center(child: CircularProgressIndicator())
          : _controller.buildingResidents.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.group_off_outlined, size: 48),
                        const SizedBox(height: 12),
                        const Text(
                          'No residents found for your building.',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _loadResidents,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Column(
                            children: [
                              DropdownButtonFormField<int>(
                                initialValue: _selectedResidentId,
                                decoration: const InputDecoration(
                                  labelText: 'Resident *',
                                  border: OutlineInputBorder(),
                                ),
                                isExpanded: true,
                                items: _controller.buildingResidents
                                    .map((resident) {
                                      final residentId = _asInt(
                                        resident['id'] ?? resident['resident_id'],
                                      );
                                      if (residentId == null) return null;
                                      return DropdownMenuItem<int>(
                                        value: residentId,
                                        child: Text(
                                          _residentLabel(resident),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      );
                                    })
                                    .whereType<DropdownMenuItem<int>>()
                                    .toList(),
                                onChanged: (value) {
                                  setState(() => _selectedResidentId = value);
                                },
                                validator: (value) =>
                                    value == null ? 'Resident is required' : null,
                              ),
                              const SizedBox(height: 12),
                              DropdownButtonFormField<String>(
                                initialValue: _selectedType,
                                decoration: const InputDecoration(
                                  labelText: 'Visitor Type *',
                                  border: OutlineInputBorder(),
                                ),
                                items: const [
                                  DropdownMenuItem(
                                    value: 'guest',
                                    child: Text('Guest'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'cab',
                                    child: Text('Cab'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'delivery',
                                    child: Text('Delivery'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'service',
                                    child: Text('Service'),
                                  ),
                                ],
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() => _selectedType = value);
                                  }
                                },
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _nameController,
                                decoration: const InputDecoration(
                                  labelText: 'Visitor Name *',
                                  border: OutlineInputBorder(),
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Visitor name is required';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _phoneController,
                                keyboardType: TextInputType.phone,
                                decoration: const InputDecoration(
                                  labelText: 'Phone Number',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _purposeController,
                                decoration: const InputDecoration(
                                  labelText: 'Purpose',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _companyController,
                                decoration: const InputDecoration(
                                  labelText: 'Company Name',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _vehicleController,
                                decoration: const InputDecoration(
                                  labelText: 'Vehicle Number',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isSubmitting ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryBlue,
                            ),
                            child: _isSubmitting
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : const Text(
                                    'Add Visitor',
                                    style: TextStyle(color: Colors.white),
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
