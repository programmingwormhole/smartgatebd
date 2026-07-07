import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/admin_controller.dart';
import '../../../controllers/auth_controller.dart';
import '../../../core/constants/colors.dart';
import '../../../widgets/responsive_web_container.dart';

class GuardCreateScreen extends StatefulWidget {
  const GuardCreateScreen({super.key});

  @override
  State<GuardCreateScreen> createState() => _GuardCreateScreenState();
}

class _GuardCreateScreenState extends State<GuardCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  bool _isSubmitting = false;
  bool _isActive = true;

  final AdminController _adminController = Get.find<AdminController>();
  final AuthController _authController = Get.find<AuthController>();

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    final buildingId = _authController.user?.buildingId;
    if (buildingId == null) {
      Get.snackbar('Error', 'Building not found', backgroundColor: Colors.red, colorText: Colors.white);
      setState(() => _isSubmitting = false);
      return;
    }

    final data = {
      'name': _nameController.text.trim(),
      'phone': _phoneController.text.trim(),
      'email': _emailController.text.trim().isEmpty 
          ? '${_phoneController.text.trim()}@guardapp.local'
          : _emailController.text.trim(),
      'status': _isActive ? 'on_duty' : 'off_duty',
    };

    final success = await _adminController.createGuard(data);
    if (mounted) {
      setState(() => _isSubmitting = false);
      if (success) {
        await _adminController.fetchGuards();
        Get.back(result: true);
        Get.snackbar('Success', 'Guard & user created successfully', backgroundColor: Colors.green, colorText: Colors.white);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Guard', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primaryNavy,
      ),
      body: ResponsiveWebContainer(
        maxWidth: 600,
        wrapInCard: true,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                _textField('Full Name', _nameController, validator: _required),
                const SizedBox(height: 12),
                _textField('Phone', _phoneController, keyboardType: TextInputType.phone, validator: _required),
                const SizedBox(height: 12),
                _textField('Email (optional)', _emailController, keyboardType: TextInputType.emailAddress),
                const SizedBox(height: 12),
                SwitchListTile(
                  value: _isActive,
                  onChanged: (v) => setState(() => _isActive = v),
                  title: const Text('On Duty'),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isSubmitting ? null : _submit,
                    icon: _isSubmitting
                        ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.save_outlined),
                    label: const Text('Create Guard & User'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _textField(String label, TextEditingController controller,
      {String? Function(String?)? validator, TextInputType keyboardType = TextInputType.text}) {
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

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) return 'Required';
    return null;
  }
}
