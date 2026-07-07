import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/colors.dart';
import '../../core/widgets/gatepass_dialog.dart';
import '../../controllers/daily_help_controller.dart';
import '../../core/widgets/shimmer_loader.dart';

class DailyHelpScreen extends StatefulWidget {
  const DailyHelpScreen({super.key});

  @override
  State<DailyHelpScreen> createState() => _DailyHelpScreenState();
}

class _DailyHelpScreenState extends State<DailyHelpScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  String? _selectedRole;
  bool _newGatepassEnabled = true;
  final _roles = ['Maid', 'Driver', 'Cook', 'Gardener', 'Nanny', 'Other'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.find<DailyHelpController>().fetchDailyHelpStaff();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Daily Help'),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
          onPressed: () => Get.back(),
        ),
      ),
      body: GetBuilder<DailyHelpController>(
        builder: (controller) {
          if (controller.isLoading && controller.dailyHelpStaff.isEmpty) {
            return const ShimmerList();
          }

          if (controller.dailyHelpStaff.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.person_outline,
                    size: 64,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No staff members added yet',
                    style: TextStyle(color: Colors.grey.shade400),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: controller.dailyHelpStaff.length,
            itemBuilder: (context, index) {
              final staff = controller.dailyHelpStaff[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _buildHelpCard(staff),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddStaffDialog(),
        backgroundColor: AppColors.primaryNavy,
        icon: const Icon(Icons.person_add_outlined, color: Colors.white),
        label: const Text(
          'Add Staff',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildHelpCard(Map<String, dynamic> staff) {
    final name = staff['name'] ?? 'N/A';
    final role = staff['role'] ?? staff['category'] ?? 'Staff';
    final phone = staff['phone'] ?? 'N/A';
    final isInSociety = staff['is_checked_in'] ?? false;
    final gatepassEnabled = _toBool(
      staff['gatepass_enabled'],
      defaultValue: true,
    );
    final staffId = staff['id'] as int?;

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
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.lightBlue,
                child: const Icon(
                  Icons.person,
                  color: AppColors.primaryNavy,
                  size: 30,
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
                      role,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isInSociety
                          ? AppColors.successGreen.withValues(alpha: 0.1)
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: isInSociety
                                ? AppColors.successGreen
                                : Colors.grey,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isInSociety ? 'In Society' : 'Outside',
                          style: TextStyle(
                            color: isInSociety
                                ? AppColors.successGreen
                                : Colors.grey.shade600,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Pass',
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                      Switch(
                        value: gatepassEnabled,
                        onChanged: staffId == null
                            ? null
                            : (value) async {
                                final ok = await Get.find<DailyHelpController>()
                                    .toggleGatepass(staffId, value);
                                if (!ok) {
                                  Get.snackbar(
                                    'Error',
                                    'Failed to update gatepass status',
                                  );
                                }
                              },
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            children: [
              Icon(Icons.phone_outlined, size: 14, color: Colors.grey.shade400),
              const SizedBox(width: 6),
              Text(
                phone,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
              const Spacer(),
              Row(
                children: [
                  _buildActionButton(Icons.history, Colors.blue, () {}),
                  const SizedBox(width: 8),
                  _buildActionButton(
                    Icons.qr_code_2,
                    AppColors.primaryNavy,
                    gatepassEnabled
                        ? () => _showGatepassDialog(staff)
                        : () => Get.snackbar(
                            'Gatepass Disabled',
                            'Enable gatepass first to use this pass',
                            backgroundColor: Colors.red.withOpacity(0.1),
                            colorText: Colors.red,
                          ),
                  ),
                  const SizedBox(width: 8),
                  _buildActionButton(Icons.call, AppColors.successGreen, () {}),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showGatepassDialog(Map<String, dynamic> staff) {
    final name = staff['name'] ?? 'N/A';
    final role = staff['role'] ?? staff['category'] ?? 'Staff';
    final gatepassEnabled = _toBool(
      staff['gatepass_enabled'],
      defaultValue: true,
    );
    final entryCode = staff['entry_code'] ?? staff['qr_code'] ?? 'N/A';

    showReusableGatepassDialog(
      context: context,
      title: 'Staff Gatepass',
      name: name.toString(),
      subtitle: role.toString(),
      entryCode: entryCode.toString(),
      gatepassEnabled: gatepassEnabled,
      disabledMessage: 'Gatepass is disabled for this staff member.',
    );
  }

  Widget _buildActionButton(IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }

  void _showAddStaffDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Add Daily Help',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                _buildInputField('Staff Name', 'Enter name', _nameController),
                const SizedBox(height: 16),
                const Text(
                  'Role',
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
                    'Select role',
                    style: TextStyle(fontSize: 13),
                  ),
                  initialValue: _selectedRole,
                  items: _roles
                      .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                      .toList(),
                  onChanged: (val) => setDialogState(() => _selectedRole = val),
                ),
                const SizedBox(height: 16),
                _buildInputField(
                  'Phone Number',
                  'Enter phone number',
                  _phoneController,
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'Enable Permanent Gatepass',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  value: _newGatepassEnabled,
                  onChanged: (value) {
                    setDialogState(() => _newGatepassEnabled = value);
                  },
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (_nameController.text.isEmpty ||
                          _selectedRole == null) {
                        Get.snackbar(
                          'Error',
                          'Please fill all required fields',
                        );
                        return;
                      }

                      final staff = await Get.find<DailyHelpController>()
                          .addDailyHelpStaff({
                            'name': _nameController.text.trim(),
                            'role': _selectedRole,
                            'phone': _phoneController.text.trim(),
                            'gatepass_enabled': _newGatepassEnabled,
                          });

                      if (staff != null && staff is Map<String, dynamic>) {
                        Get.back();
                        _showGatepassDialog(staff);
                        _nameController.clear();
                        _phoneController.clear();
                        _selectedRole = null;
                        _newGatepassEnabled = true;
                        Get.snackbar('Success', 'Staff added successfully');
                      } else {
                        Get.snackbar(
                          'Error',
                          'Failed to add staff',
                          backgroundColor: Colors.red.withValues(alpha: 0.1),
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
                    child: const Text(
                      'Add Staff',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField(
    String label,
    String hint,
    TextEditingController? controller,
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

  bool _toBool(dynamic value, {bool defaultValue = false}) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final v = value.trim().toLowerCase();
      if (v == 'true' || v == '1') return true;
      if (v == 'false' || v == '0') return false;
    }
    return defaultValue;
  }
}
