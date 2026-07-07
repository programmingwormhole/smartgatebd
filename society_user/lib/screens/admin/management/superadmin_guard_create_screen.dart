import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/colors.dart';
import '../../../controllers/admin_controller.dart';
import '../../../services/admin_service.dart';

class SuperadminGuardCreateScreen extends StatefulWidget {
  const SuperadminGuardCreateScreen({super.key});

  @override
  State<SuperadminGuardCreateScreen> createState() => _SuperadminGuardCreateScreenState();
}

class _SuperadminGuardCreateScreenState extends State<SuperadminGuardCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final AdminService _adminService = AdminService();
  final AdminController _adminController = Get.find<AdminController>();

  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  bool _isSubmitting = false;
  late int _selectedBuildingId;
  late String _selectedStatus;

  final List<String> _statusOptions = ['on_duty', 'off_duty', 'leave', 'inactive'];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    _emailController = TextEditingController();
    _selectedBuildingId = 1; // Default, you can make this dynamic
    _selectedStatus = 'off_duty';

    // Load buildings if needed
    _loadBuildings();
  }

  Future<void> _loadBuildings() async {
    // Fetch buildings list - you may need to update AdminController or AdminService
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final success = await _adminService.createGuardSuperadmin(
        _selectedBuildingId,
        _nameController.text.trim(),
        _phoneController.text.trim(),
        email: _emailController.text.isEmpty ? null : _emailController.text.trim(),
        status: _selectedStatus,
      );

      if (mounted) {
        setState(() => _isSubmitting = false);
        if (success) {
          await _adminController.fetchGuards();
          Get.back(result: true);
          Get.snackbar('Success', 'Guard created successfully', backgroundColor: Colors.green, colorText: Colors.white);
        } else {
          Get.snackbar('Error', 'Failed to create guard', backgroundColor: Colors.red, colorText: Colors.white);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        Get.snackbar('Error', 'Failed to create guard: $e', backgroundColor: Colors.red, colorText: Colors.white);
      }
    }
  }

  String? _validateName(String? value) => value?.isEmpty ?? true ? 'Name is required' : null;
  String? _validatePhone(String? value) => value?.isEmpty ?? true ? 'Phone is required' : null;
  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) return null;
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
      return 'Enter a valid email';
    }
    return null;
  }

  Widget _textField(String label, TextEditingController controller,
      {TextInputType? keyboardType, String? Function(String?)? validator, bool obscure = false}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscure,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Guard', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primaryNavy,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _textField('Full Name', _nameController, validator: _validateName),
              const SizedBox(height: 12),
              _textField('Phone', _phoneController, keyboardType: TextInputType.phone, validator: _validatePhone),
              const SizedBox(height: 12),
              _textField('Email (Optional)', _emailController, keyboardType: TextInputType.emailAddress, validator: _validateEmail),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButton<String>(
                  isExpanded: true,
                  underline: const SizedBox(),
                  value: _selectedStatus,
                  items: _statusOptions
                      .map((status) => DropdownMenuItem(
                            value: status,
                            child: Text(status.replaceAll('_', ' ').toUpperCase()),
                          ))
                      .toList(),
                  onChanged: (newStatus) {
                    if (newStatus != null) {
                      setState(() => _selectedStatus = newStatus);
                    }
                  },
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryNavy,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('Create Guard', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }
}
