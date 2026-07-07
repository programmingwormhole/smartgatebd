import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/colors.dart';
import '../../../controllers/admin_controller.dart';
import '../../../services/admin_service.dart';
import '../../../widgets/user_avatar_widget.dart';

class SuperadminGuardDetailScreen extends StatefulWidget {
  const SuperadminGuardDetailScreen({super.key, required this.guard});

  final Map<String, dynamic> guard;

  @override
  State<SuperadminGuardDetailScreen> createState() => _SuperadminGuardDetailScreenState();
}

class _SuperadminGuardDetailScreenState extends State<SuperadminGuardDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  final AdminService _adminService = AdminService();
  final AdminController _adminController = Get.find<AdminController>();

  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _notesController;
  bool _isSubmitting = false;
  late String _selectedStatus;
  bool _isEditing = false;

  final List<String> _statusOptions = ['on_duty', 'off_duty', 'leave', 'inactive'];

  @override
  void initState() {
    super.initState();
    final user = widget.guard['user'] ?? {};
    _nameController = TextEditingController(text: user['name'] ?? '');
    _phoneController = TextEditingController(text: user['phone'] ?? '');
    _emailController = TextEditingController(text: user['email'] ?? '');
    _notesController = TextEditingController(text: widget.guard['notes'] ?? '');
    _selectedStatus = widget.guard['status'] ?? 'on_duty';
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final success = await _adminService.updateGuardSuperadmin(
        widget.guard['id'],
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        email: _emailController.text.isEmpty ? null : _emailController.text.trim(),
        status: _selectedStatus,
        notes: _notesController.text.isEmpty ? null : _notesController.text.trim(),
      );

      if (mounted) {
        setState(() => _isSubmitting = false);
        if (success) {
          setState(() => _isEditing = false);
          Get.snackbar('Success', 'Guard updated successfully', backgroundColor: Colors.green, colorText: Colors.white);
        } else {
          Get.snackbar('Error', 'Failed to update guard', backgroundColor: Colors.red, colorText: Colors.white);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        Get.snackbar('Error', 'Failed to update guard: $e', backgroundColor: Colors.red, colorText: Colors.white);
      }
    }
  }

  Future<void> _updateStatus(String newStatus) async {
    try {
      final success = await _adminService.updateGuardStatusSuperadmin(widget.guard['id'], newStatus);
      if (success) {
        setState(() => _selectedStatus = newStatus);
        Get.snackbar('Success', 'Status updated', backgroundColor: Colors.green, colorText: Colors.white);
      } else {
        Get.snackbar('Error', 'Failed to update status', backgroundColor: Colors.red, colorText: Colors.white);
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to update status: $e', backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  Future<void> _deleteGuard() async {
    Get.dialog(
      AlertDialog(
        title: const Text('Delete Guard'),
        content: const Text('Are you sure you want to delete this guard?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Get.back();
              try {
                final success = await _adminService.deleteGuardSuperadmin(widget.guard['id']);
                if (success) {
                  await _adminController.fetchGuards();
                  Get.back(result: true);
                  Get.snackbar('Success', 'Guard deleted', backgroundColor: Colors.green, colorText: Colors.white);
                } else {
                  Get.snackbar('Error', 'Failed to delete guard', backgroundColor: Colors.red, colorText: Colors.white);
                }
              } catch (e) {
                Get.snackbar('Error', 'Failed to delete guard: $e', backgroundColor: Colors.red, colorText: Colors.white);
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
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

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'on_duty':
        return Colors.green;
      case 'off_duty':
        return Colors.orange;
      case 'leave':
        return Colors.blue;
      case 'inactive':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _textField(String label, TextEditingController controller,
      {TextInputType? keyboardType, String? Function(String?)? validator, bool enabled = true}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      enabled: enabled && _isEditing,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.guard['user'] ?? {};
    final building = widget.guard['building'] ?? {};
    final statusColor = _getStatusColor(_selectedStatus);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Guard Details', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primaryNavy,
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => setState(() => _isEditing = false),
            )
          else
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.white),
              onPressed: () => setState(() => _isEditing = true),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 3))],
                ),
                child: Row(
                  children: [
                    UserAvatarWidget(
                      radius: 30,
                      userName: (user['name'] ?? 'Guard').toString(),
                      profilePictureUrl: user['profile_picture']?.toString(),
                      backgroundColor: statusColor.withOpacity(0.12),
                      textColor: statusColor,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(user['name'] ?? 'N/A', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          Text(user['phone'] ?? 'N/A', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                          Text(building['name'] ?? 'N/A', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _selectedStatus.replaceAll('_', ' ').toUpperCase(),
                        style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Status Options
              if (!_isEditing) ...[
                const Text('Change Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 10),
                Row(
                  children: _statusOptions
                      .map((status) => Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: OutlinedButton(
                                onPressed: () => _updateStatus(status),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                ),
                                child: Text(
                                  status.replaceAll('_', ' ').toUpperCase(),
                                  style: const TextStyle(fontSize: 10),
                                ),
                              ),
                            ),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 20),
              ],

              // Edit Form
              if (_isEditing) ...[
                _textField('Full Name', _nameController, validator: _validateName),
                const SizedBox(height: 12),
                _textField('Phone', _phoneController, keyboardType: TextInputType.phone, validator: _validatePhone),
                const SizedBox(height: 12),
                _textField('Email', _emailController, keyboardType: TextInputType.emailAddress, validator: _validateEmail),
                const SizedBox(height: 12),
                _textField('Notes', _notesController, enabled: true),
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
                Row(
                  children: [
                    Expanded(
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
                            : const Text('Save Changes', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                const Text('Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 10),
                _buildDetailRow('Name', user['name'] ?? 'N/A'),
                _buildDetailRow('Phone', user['phone'] ?? 'N/A'),
                _buildDetailRow('Email', user['email'] ?? 'N/A'),
                _buildDetailRow('Building', building['name'] ?? 'N/A'),
                _buildDetailRow('Notes', widget.guard['notes'] ?? '-'),
              ],

              const SizedBox(height: 24),
              if (_isEditing)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _deleteGuard,
                    icon: const Icon(Icons.delete, color: Colors.red),
                    label: const Text('Delete Guard', style: TextStyle(color: Colors.red)),
                    style: OutlinedButton.styleFrom(
                      // borderSide: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          ),
          Expanded(
            flex: 2,
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}
