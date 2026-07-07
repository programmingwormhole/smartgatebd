import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/colors.dart';
import '../../core/widgets/gatepass_dialog.dart';
import '../../controllers/family_controller.dart';
import '../../core/widgets/shimmer_loader.dart';

class FamilyScreen extends StatefulWidget {
  const FamilyScreen({super.key});

  @override
  State<FamilyScreen> createState() => _FamilyScreenState();
}

class _FamilyScreenState extends State<FamilyScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  String? _selectedRelation;
  bool _newGatepassEnabled = true;
  final _relations = ['Spouse', 'Child', 'Parent', 'Sibling', 'Other'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.find<FamilyController>().fetchFamilyMembers();
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
        title: const Text('Family Members'),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
          onPressed: () => Get.back(),
        ),
      ),
      body: GetBuilder<FamilyController>(
        builder: (controller) {
          if (controller.isLoading && controller.familyMembers.isEmpty) {
            return const ShimmerList();
          }

          if (controller.familyMembers.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.people_outline,
                    size: 64,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No family members added yet',
                    style: TextStyle(color: Colors.grey.shade400),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: controller.familyMembers.length,
            itemBuilder: (context, index) {
              final member = controller.familyMembers[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _buildMemberCard(member),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddMemberDialog(),
        backgroundColor: AppColors.primaryNavy,
        icon: const Icon(Icons.person_add, color: Colors.white),
        label: const Text(
          'Add Member',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildMemberCard(Map<String, dynamic> member) {
    final name = member['name'] ?? 'N/A';
    final relation = member['relation'] ?? 'Other';
    final phone = member['phone'] ?? 'N/A';
    final gatepassEnabled = _toBool(
      member['gatepass_enabled'],
      defaultValue: true,
    );
    final memberId = member['id'] as int?;

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
                radius: 30,
                backgroundColor: AppColors.lightBlue,
                child: Text(
                  name.isNotEmpty ? name[0] : '?',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryNavy,
                  ),
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
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.lightBlue,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        relation,
                        style: const TextStyle(
                          color: AppColors.primaryNavy,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
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
                    onChanged: memberId == null
                        ? null
                        : (value) async {
                            final ok = await Get.find<FamilyController>()
                                .toggleGatepass(memberId, value);
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
          const Divider(height: 24),
          Row(
            children: [
              Icon(Icons.phone, size: 14, color: Colors.grey.shade400),
              const SizedBox(width: 4),
              Text(
                phone,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: gatepassEnabled
                    ? () => _showGatepassDialog(member)
                    : null,
                icon: const Icon(Icons.qr_code_2, size: 18),
                label: Text(gatepassEnabled ? 'Gatepass' : 'Pass Disabled'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primaryNavy,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  backgroundColor: AppColors.lightBlue.withValues(alpha: 0.3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showGatepassDialog(Map<String, dynamic> member) {
    final name = member['name'] ?? 'N/A';
    final role = member['relation'] ?? 'Other';
    final gatepassEnabled = _toBool(
      member['gatepass_enabled'],
      defaultValue: true,
    );
    final entryCode = member['entry_code'] ?? member['qr_code'] ?? 'N/A';

    showReusableGatepassDialog(
      context: context,
      title: 'Entry Gatepass',
      name: name.toString(),
      subtitle: role.toString(),
      entryCode: entryCode.toString(),
      gatepassEnabled: gatepassEnabled,
      disabledMessage: 'Gatepass is disabled for this member.',
    );
  }

  void _showAddMemberDialog() {
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
                  'Add Family Member',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                _buildInputField('Full Name', 'Enter name', _nameController),
                const SizedBox(height: 16),
                const Text(
                  'Relation',
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
                    'Select relation',
                    style: TextStyle(fontSize: 13),
                  ),
                  initialValue: _selectedRelation,
                  items: _relations
                      .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                      .toList(),
                  onChanged: (val) {
                    setDialogState(() => _selectedRelation = val);
                  },
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
                          _selectedRelation == null) {
                        Get.snackbar(
                          'Error',
                          'Please fill all required fields',
                        );
                        return;
                      }

                      final member = await Get.find<FamilyController>()
                          .addFamilyMember({
                            'name': _nameController.text.trim(),
                            'relation': _selectedRelation,
                            'phone': _phoneController.text.trim(),
                            'gatepass_enabled': _newGatepassEnabled,
                          });

                      if (member != null && member is Map<String, dynamic>) {
                        Get.back();
                        _showGatepassDialog(member);
                        _nameController.clear();
                        _phoneController.clear();
                        _selectedRelation = null;
                        _newGatepassEnabled = true;
                        Get.snackbar('Success', 'Family member added');
                      } else {
                        Get.snackbar(
                          'Error',
                          'Failed to add family member',
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
                      'Add Member',
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
