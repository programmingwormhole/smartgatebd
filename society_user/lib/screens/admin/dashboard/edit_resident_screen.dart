import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/admin_controller.dart';
import '../../../controllers/auth_controller.dart';
import '../../../core/constants/colors.dart';
import '../../../services/admin_service.dart';

class EditResidentScreen extends StatefulWidget {
  const EditResidentScreen({super.key, required this.resident});

  final Map<String, dynamic> resident;

  @override
  State<EditResidentScreen> createState() => _EditResidentScreenState();
}

class _EditResidentScreenState extends State<EditResidentScreen> {
  final AdminController _adminController = Get.find<AdminController>();
  final AuthController _authController = Get.find<AuthController>();
  final AdminService _adminService = AdminService();

  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _maintenanceFeeController;
  late TextEditingController _rentController;
  late TextEditingController _billGenerateDayController;

  String _selectedRole = 'resident';
  bool _isSubmitting = false;
  bool _isLoadingStructure = false;
  bool _isSuperadmin = false;

  int? _selectedBuildingId;
  int? _selectedBlockId;
  int? _selectedFloorId;
  int? _selectedFlatId;

  List<Map<String, dynamic>> _buildings = [];
  List<Map<String, dynamic>> _blocks = [];
  List<Map<String, dynamic>> _floors = [];
  List<Map<String, dynamic>> _flats = [];

  @override
  void initState() {
    super.initState();
    final user = widget.resident['user'] ?? {};
    _nameController = TextEditingController(text: user['name'] ?? '');
    _phoneController = TextEditingController(text: user['phone'] ?? '');
    _emailController = TextEditingController(text: user['email'] ?? '');
    _maintenanceFeeController = TextEditingController(
      text: (widget.resident['monthly_maintenance_fee'] ?? '').toString(),
    );
    _rentController = TextEditingController(
      text: (widget.resident['rent'] ?? '').toString(),
    );
    _billGenerateDayController = TextEditingController(
      text: (widget.resident['bill_generate_day'] ?? 1).toString(),
    );
    _selectedRole = (widget.resident['role'] ?? 'resident').toString().toLowerCase();

    _selectedBlockId = widget.resident['block_id'] ?? widget.resident['block']?['id'] ?? widget.resident['flat']?['block_id'];
    _selectedFloorId = widget.resident['floor_id'] ?? widget.resident['floor']?['id'] ?? widget.resident['flat']?['floor_id'];
    _selectedFlatId = widget.resident['flat_id'] ?? widget.resident['flat']?['id'];

    // Check if user is superadmin
    _isSuperadmin = _authController.user != null && 
                    _authController.user!.role.toLowerCase() == 'superadmin';
    
    // Set building ID
    _selectedBuildingId = _authController.user?.buildingId;

    _loadBuildingStructureData();
  }

  Future<void> _loadBuildingStructureData() async {
    setState(() => _isLoadingStructure = true);
    try {
      // If superadmin, load all buildings
      if (_isSuperadmin) {
        final buildings = await _adminService.getAllBuildings();
        setState(() {
          _buildings = List<Map<String, dynamic>>.from(buildings);
        });
      }

      if (_adminController.buildingStructure.isEmpty) {
        await _adminController.fetchBuildingStructure();
      }

      if (_adminController.buildingStructure.isNotEmpty) {
        setState(() {
          _blocks = List<Map<String, dynamic>>.from(
            _adminController.buildingStructure['blocks'] ?? [],
          );
        });
      }

      if (_selectedBlockId != null) {
        final block = _blocks.firstWhere((b) => b['id'] == _selectedBlockId, orElse: () => {});
        _floors = List<Map<String, dynamic>>.from(block['floors'] ?? []);
      }
      if (_selectedFloorId != null) {
        final floor = _floors.firstWhere((f) => f['id'] == _selectedFloorId, orElse: () => {});
        _flats = List<Map<String, dynamic>>.from(floor['flats'] ?? []);
      }
    } catch (e) {
      debugPrint('Error loading building structure: $e');
      if (mounted) {
        Get.snackbar('Error', 'Failed to load ${_isSuperadmin ? 'buildings' : 'building structure'}', backgroundColor: Colors.red, colorText: Colors.white);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingStructure = false);
      }
    }
  }

  void _onBuildingChanged(int? buildingId) {
    setState(() {
      _selectedBuildingId = buildingId;
      _selectedBlockId = null;
      _selectedFloorId = null;
      _selectedFlatId = null;
      _blocks = [];
      _floors = [];
      _flats = [];
    });

    // Reload building structure for the selected building
    if (buildingId != null) {
      setState(() => _isLoadingStructure = true);
      _adminController.fetchBuildingStructure().then((_) {
        if (mounted && _adminController.buildingStructure.isNotEmpty) {
          setState(() {
            _blocks = List<Map<String, dynamic>>.from(
              _adminController.buildingStructure['blocks'] ?? [],
            );
            _isLoadingStructure = false;
          });
        }
      }).catchError((e) {
        if (mounted) {
          setState(() => _isLoadingStructure = false);
          Get.snackbar(
            'Error',
            'Failed to load building structure',
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
        }
      });
    }
  }

  void _onBlockChanged(int? blockId) {
    setState(() {
      _selectedBlockId = blockId;
      _selectedFloorId = null;
      _selectedFlatId = null;
      _floors = [];
      _flats = [];

      if (blockId != null) {
        final selectedBlock = _blocks.firstWhere((b) => b['id'] == blockId, orElse: () => {});
        if (selectedBlock.isNotEmpty) {
          _floors = List<Map<String, dynamic>>.from(selectedBlock['floors'] ?? []);
        }
      }
    });
  }

  void _onFloorChanged(int? floorId) {
    setState(() {
      _selectedFloorId = floorId;
      _selectedFlatId = null;
      _flats = [];

      if (floorId != null) {
        final selectedFloor = _floors.firstWhere((f) => f['id'] == floorId, orElse: () => {});
        if (selectedFloor.isNotEmpty) {
          _flats = List<Map<String, dynamic>>.from(selectedFloor['flats'] ?? []);
        }
      }
    });
  }

  void _onFlatChanged(int? flatId) {
    setState(() => _selectedFlatId = flatId);
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      Get.snackbar('Validation Error', 'Please fill in all required fields', backgroundColor: Colors.orange, colorText: Colors.white);
      return;
    }

    if (_selectedBlockId == null || _selectedFloorId == null || _selectedFlatId == null) {
      Get.snackbar('Validation Error', 'Please select block, floor and flat', backgroundColor: Colors.orange, colorText: Colors.white);
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final buildingId = _selectedBuildingId ?? _authController.user?.buildingId ?? 1;
      final data = {
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        if (_emailController.text.isNotEmpty) 'email': _emailController.text.trim(),
        'role': _selectedRole,
        'flat_id': _selectedFlatId,
        'block_id': _selectedBlockId,
        'floor_id': _selectedFloorId,
        'building_id': buildingId,
        'monthly_maintenance_fee': _parseAmount(_maintenanceFeeController.text),
        'rent': _parseAmount(_rentController.text),
        'bill_generate_day': _parseBillingDay(_billGenerateDayController.text),
      };

      final success = await _adminController.updateResident(widget.resident['id'], data);
      if (mounted && success) {
        Get.back();
        Get.snackbar('Updated', 'Resident updated successfully', backgroundColor: Colors.green, colorText: Colors.white);
      }
    } catch (e) {
      debugPrint('Error updating resident: $e');
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _maintenanceFeeController.dispose();
    _rentController.dispose();
    _billGenerateDayController.dispose();
    super.dispose();
  }

  double? _parseAmount(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    return double.tryParse(trimmed);
  }

  int? _parseBillingDay(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    return int.tryParse(trimmed);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Resident', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primaryNavy,
        
      ),
      body: _isLoadingStructure
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _textField('Full Name', _nameController, validator: _requiredValidator),
                    const SizedBox(height: 12),
                    _textField('Phone', _phoneController, keyboardType: TextInputType.phone, validator: _requiredValidator),
                    const SizedBox(height: 12),
                    _textField('Email (optional)', _emailController, keyboardType: TextInputType.emailAddress),
                    const SizedBox(height: 12),
                    _textField(
                      'Monthly Maintenance Fee (optional)',
                      _maintenanceFeeController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: _amountValidator,
                    ),
                    const SizedBox(height: 12),
                    _textField(
                      'Monthly Rent (optional)',
                      _rentController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: _amountValidator,
                    ),
                    const SizedBox(height: 12),
                    _textField(
                      'Billing Date (Day 1-28)',
                      _billGenerateDayController,
                      keyboardType: TextInputType.number,
                      validator: _billingDayValidator,
                    ),
                    const SizedBox(height: 12),
                    _roleSelector(),
                    const SizedBox(height: 12),
                    _locationSelectors(),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isSubmitting ? null : _submitForm,
                        icon: const Icon(Icons.save_outlined),
                        label: _isSubmitting
                            ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Text('Save Changes'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _textField(
    String label,
    TextEditingController controller, {
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) return 'This field is required';
    return null;
  }

  String? _amountValidator(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final amount = double.tryParse(value.trim());
    if (amount == null || amount < 0) return 'Enter a valid non-negative amount';
    return null;
  }

  String? _billingDayValidator(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final day = int.tryParse(value.trim());
    if (day == null || day < 1 || day > 28) {
      return 'Billing day must be between 1 and 28';
    }
    return null;
  }

  Widget _roleSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Role', style: TextStyle(fontWeight: FontWeight.w600)),
          DropdownButton<String>(
            value: _selectedRole,
            underline: const SizedBox.shrink(),
            items: const [
              DropdownMenuItem(value: 'resident', child: Text('Resident')),
              DropdownMenuItem(value: 'committee', child: Text('Committee')),
              DropdownMenuItem(value: 'admin', child: Text('Admin')),
            ],
            onChanged: (value) => setState(() => _selectedRole = value ?? 'resident'),
          ),
        ],
      ),
    );
  }

  Widget _locationSelectors() {
    return Column(
      children: [
        // Building Selection (for superadmin)
        if (_isSuperadmin)
          Column(
            children: [
              DropdownButtonFormField<int>(
                value: _selectedBuildingId,
                decoration: _dropdownDecoration('Select Building'),
                items: _buildings
                    .map((building) => DropdownMenuItem<int>(
                          value: building['id'],
                          child: Text(building['name'] ?? ''),
                        ))
                    .toList(),
                onChanged: _onBuildingChanged,
                validator: (val) => val == null ? 'Required' : null,
              ),
              const SizedBox(height: 12),
            ],
          ),

        DropdownButtonFormField<int>(
          value: _selectedBlockId,
          decoration: _dropdownDecoration('Select Block'),
          items: _blocks
              .map((block) => DropdownMenuItem<int>(
                    value: block['id'],
                    child: Text(block['name'] ?? ''),
                  ))
              .toList(),
          onChanged: _onBlockChanged,
          validator: (val) => val == null ? 'Required' : null,
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<int>(
          value: _selectedFloorId,
          decoration: _dropdownDecoration('Select Floor'),
          items: _floors
              .map((floor) => DropdownMenuItem<int>(
                    value: floor['id'],
                    child: Text('Floor ${floor['floor_number']}'),
                  ))
              .toList(),
          onChanged: _onFloorChanged,
          validator: (val) => val == null ? 'Required' : null,
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<int>(
          value: _selectedFlatId,
          decoration: _dropdownDecoration('Select Flat'),
          items: _flats
              .map((flat) => DropdownMenuItem<int>(
                    value: flat['id'],
                    child: Text(flat['flat_number'] ?? ''),
                  ))
              .toList(),
          onChanged: _onFlatChanged,
          validator: (val) => val == null ? 'Required' : null,
        ),
      ],
    );
  }

  InputDecoration _dropdownDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      filled: true,
      fillColor: Colors.white,
    );
  }
}
