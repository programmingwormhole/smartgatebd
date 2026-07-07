import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/admin_controller.dart';
import '../../../core/constants/colors.dart';
import '../../../widgets/responsive_web_container.dart';

class GuardEditScreen extends StatefulWidget {
  const GuardEditScreen({super.key, required this.guard});

  final Map<String, dynamic> guard;

  @override
  State<GuardEditScreen> createState() => _GuardEditScreenState();
}

class _GuardEditScreenState extends State<GuardEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  bool _isSubmitting = false;
  late String _selectedStatus;

  final AdminController _adminController = Get.find<AdminController>();
  
  final List<String> _statusOptions = ['on_duty', 'off_duty', 'leave', 'inactive'];

  @override
  void initState() {
    super.initState();
    final user = widget.guard['user'] ?? {};
    _nameController = TextEditingController(text: user['name'] ?? '');
    _phoneController = TextEditingController(text: user['phone'] ?? '');
    _selectedStatus = widget.guard['status'] ?? 'on_duty';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    final data = {
      'name': _nameController.text.trim(),
      'phone': _phoneController.text.trim(),
      'status': _selectedStatus,
    };

    final success = await _adminController.updateGuard(widget.guard['id'], data);
    if (mounted) {
      setState(() => _isSubmitting = false);
      if (success) {
        await _adminController.fetchGuards();
        Get.back(result: true);
        Get.snackbar('Saved', 'Guard updated', backgroundColor: Colors.green, colorText: Colors.white);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Guard', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey, width: 1),
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
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isSubmitting ? null : _submit,
                    icon: _isSubmitting
                        ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.save_outlined),
                    label: const Text('Save Changes'),
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
