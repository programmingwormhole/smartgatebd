import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../core/constants/colors.dart';
import '../../core/widgets/gatepass_dialog.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/visitor_controller.dart';

class AddVisitorScreen extends StatefulWidget {
  const AddVisitorScreen({super.key});

  @override
  State<AddVisitorScreen> createState() => _AddVisitorScreenState();
}

class _AddVisitorScreenState extends State<AddVisitorScreen> {
  DateTime _selectedDate = DateTime.now();

  // Controllers for general inputs
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _cabCompanyController = TextEditingController();
  final TextEditingController _deliveryCompanyController =
      TextEditingController();
  final TextEditingController _serviceCategoryController =
      TextEditingController();

  // Controllers for vehicle digits (Cab)
  final List<TextEditingController> _vehicleDigitControllers = List.generate(
    4,
    (_) => TextEditingController(),
  );

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _cabCompanyController.dispose();
    _deliveryCompanyController.dispose();
    _serviceCategoryController.dispose();
    for (var controller in _vehicleDigitControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _resetInputs() {
    _nameController.clear();
    _phoneController.clear();
    _cabCompanyController.clear();
    _deliveryCompanyController.clear();
    _serviceCategoryController.clear();
    for (var controller in _vehicleDigitControllers) {
      controller.clear();
    }
    _selectedDate = DateTime.now();
  }

  String _getFormattedDate(DateTime date) {
    final now = DateTime.now();
    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      return 'Today';
    }
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Visitors'),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
          onPressed: () => Get.back(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pre approve Visitors',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const Text(
              'Add visitor detail for quick action',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              children: [
                _buildCategoryCard(
                  'Add Guest',
                  Colors.orange.shade100,
                  () => _showAddGuestDialog(),
                ),
                _buildCategoryCard(
                  'Add Cab',
                  Colors.blue.shade100,
                  () => _showAddCabDialog(),
                ),
                _buildCategoryCard(
                  'Add Delivery',
                  Colors.red.shade100,
                  () => _showAddDeliveryDialog(),
                ),
                _buildCategoryCard(
                  'Add Service',
                  Colors.green.shade100,
                  () => _showAddServiceDialog(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Helper Widgets
  Widget _buildCategoryCard(String title, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getIconForCategory(title),
                size: 32,
                color: AppColors.primaryNavy,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: AppColors.textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconForCategory(String title) {
    if (title.contains('Guest')) return Icons.person_add_alt_1;
    if (title.contains('Cab')) return Icons.local_taxi;
    if (title.contains('Delivery')) return Icons.delivery_dining;
    if (title.contains('Service')) return Icons.build;
    return Icons.person;
  }

  // Dialogs
  void _showAddGuestDialog() {
    _resetInputs();
    _showVisitorFormDialog(
      title: 'Allow my guest',
      icon: Icons.person,
      color: Colors.orange,
      fields: (ctx, setStateIn) => [
        _buildDatePickerField(
          ctx,
          'Visit date',
          _getFormattedDate(_selectedDate),
          () async {
            final DateTime? picked = await showDatePicker(
              context: ctx,
              initialDate: _selectedDate,
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 365)),
            );
            if (picked != null) {
              setStateIn(() => _selectedDate = picked);
            }
          },
        ),
        const SizedBox(height: 16),
        _buildDialogTextField(
          'Guest name',
          Icons.person_outline,
          controller: _nameController,
        ),
        const SizedBox(height: 16),
        _buildDialogTextField(
          'Phone number',
          Icons.phone_android_outlined,
          controller: _phoneController,
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Checkbox(
              value: true,
              onChanged: (v) {},
              activeColor: AppColors.primaryNavy,
            ),
            const Text(
              'Send gate pass to the guest',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
      ],
      onSubmit: () {
        _submitVisitor({
          'name': _nameController.text.trim(),
          'phone': _phoneController.text.trim(),
          'type': 'guest',
        });
      },
    );
  }

  void _showAddCabDialog() {
    _resetInputs();
    _showVisitorFormDialog(
      title: 'Allow my Cab',
      icon: Icons.local_taxi,
      color: Colors.blue,
      fields: (ctx, setStateIn) => [
        const Text(
          'Add last 4 digit of vehicle no.',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(4, (index) => _buildOtpField(index, ctx)),
        ),
        const SizedBox(height: 16),
        _buildSelectionField(
          ctx,
          'Company name',
          _cabCompanyController.text.isEmpty
              ? 'Select company name'
              : _cabCompanyController.text,
          ['Uber', 'Pathao', 'InDrive'],
          onSelected: (val) =>
              setStateIn(() => _cabCompanyController.text = val),
        ),
        const SizedBox(height: 16),
        _buildDatePickerField(
          ctx,
          'Entry date',
          _getFormattedDate(_selectedDate),
          () async {
            final DateTime? picked = await showDatePicker(
              context: ctx,
              initialDate: _selectedDate,
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 365)),
            );
            if (picked != null) {
              setStateIn(() => _selectedDate = picked);
            }
          },
        ),
      ],
      onSubmit: () {
        final vehicleNo = _vehicleDigitControllers.map((c) => c.text).join();
        _submitVisitor({
          'name': _cabCompanyController.text,
          'type': 'cab',
          'vehicle_no': vehicleNo,
        });
      },
    );
  }

  void _showAddDeliveryDialog() {
    _resetInputs();
    _showVisitorFormDialog(
      title: 'Allow my delivery',
      icon: Icons.delivery_dining,
      color: Colors.red,
      fields: (ctx, setStateIn) => [
        _buildSelectionField(
          ctx,
          'Delivery company name',
          _deliveryCompanyController.text.isEmpty
              ? 'Select delivery company'
              : _deliveryCompanyController.text,
          ['Foodpanda', 'Daraz', 'FedEx', 'UPS', 'Amazon'],
          onSelected: (val) =>
              setStateIn(() => _deliveryCompanyController.text = val),
        ),
        const SizedBox(height: 16),
        _buildDatePickerField(
          ctx,
          'Entry date',
          _getFormattedDate(_selectedDate),
          () async {
            final DateTime? picked = await showDatePicker(
              context: ctx,
              initialDate: _selectedDate,
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 365)),
            );
            if (picked != null) {
              setStateIn(() => _selectedDate = picked);
            }
          },
        ),
      ],
      onSubmit: () {
        _submitVisitor({
          'name': _deliveryCompanyController.text,
          'type': 'delivery',
        });
      },
    );
  }

  void _showAddServiceDialog() {
    _resetInputs();
    _showVisitorFormDialog(
      title: 'Allow my Serviceman',
      icon: Icons.build,
      color: Colors.green,
      fields: (ctx, setStateIn) => [
        _buildDialogTextField(
          'Serviceman/ company name',
          Icons.business_outlined,
          controller: _nameController,
        ),
        const SizedBox(height: 16),
        _buildDialogTextField(
          'Phone number',
          Icons.phone_android_outlined,
          controller: _phoneController,
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 16),
        _buildSelectionField(
          ctx,
          'Service category',
          _serviceCategoryController.text.isEmpty
              ? 'Select service category'
              : _serviceCategoryController.text,
          ['Plumber', 'Electrician', 'Carpenter', 'Pest Control'],
          onSelected: (val) =>
              setStateIn(() => _serviceCategoryController.text = val),
        ),
        const SizedBox(height: 16),
        _buildDatePickerField(
          ctx,
          'Entry date',
          _getFormattedDate(_selectedDate),
          () async {
            final DateTime? picked = await showDatePicker(
              context: ctx,
              initialDate: _selectedDate,
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 365)),
            );
            if (picked != null) {
              setStateIn(() => _selectedDate = picked);
            }
          },
        ),
      ],
      onSubmit: () {
        _submitVisitor({
          'name': _nameController.text.trim(),
          'phone': _phoneController.text.trim(),
          'type': 'service',
          'purpose': _serviceCategoryController.text,
        });
      },
    );
  }

  // Core Actions
  void _submitVisitor(Map<String, dynamic> data) async {
    final controller = Get.find<VisitorController>();
    final auth = Get.find<AuthController>();

    if (auth.user == null) return;

    final requestData = {
      ...data,
      'visit_date': _selectedDate.toIso8601String().split('T')[0],
    };

    final result = await controller.addPreApprovedVisitor(requestData);
    if (result != null) {
      if (mounted) {
        _showGatePassDialog(
          result['name'] ?? data['name'] ?? 'Visitor',
          'Apt ${auth.user?.flatNo ?? 'N/A'}',
          result['gatepass']?['entry_code']?.toString() ?? 'N/A',
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to pre-approve visitor')),
        );
      }
    }
  }

  void _showVisitorFormDialog({
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> Function(BuildContext, StateSetter) fields,
    required VoidCallback onSubmit,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Align(
                    alignment: Alignment.topRight,
                    child: IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Get.back(),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: color, size: 40),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ...fields(ctx, setDialogState),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Get.back();
                        onSubmit();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryNavy,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Submit',
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
      ),
    );
  }

  void _showGatePassDialog(String name, String flat, String entryCode) {
    showReusableGatepassDialog(
      context: context,
      title: 'Gate pass',
      name: name,
      subtitle: 'Guest at $flat',
      entryCode: entryCode,
    );
  }

  // Builder Methods
  Widget _buildOtpField(int index, BuildContext ctx) {
    return SizedBox(
      width: 50,
      child: TextFormField(
        controller: _vehicleDigitControllers[index],
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        inputFormatters: [
          LengthLimitingTextInputFormatter(1),
          FilteringTextInputFormatter.digitsOnly,
        ],
        decoration: InputDecoration(
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
        onChanged: (value) {
          if (value.length == 1 && index < 3) {
            FocusScope.of(ctx).nextFocus();
          } else if (value.isEmpty && index > 0) {
            FocusScope.of(ctx).previousFocus();
          }
        },
      ),
    );
  }

  Widget _buildDatePickerField(
    BuildContext context,
    String label,
    String value,
    VoidCallback onTap,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_month_outlined,
                  size: 20,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(width: 12),
                Text(
                  value,
                  style: TextStyle(
                    color: value == 'Today'
                        ? AppColors.primaryNavy
                        : Colors.grey.shade700,
                    fontWeight: value == 'Today'
                        ? FontWeight.bold
                        : FontWeight.normal,
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                const Icon(Icons.expand_more, size: 20, color: Colors.grey),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDialogTextField(
    String label,
    IconData icon, {
    TextEditingController? controller,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Enter $label',
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
            prefixIcon: Icon(icon, size: 20, color: Colors.grey.shade400),
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
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSelectionField(
    BuildContext context,
    String label,
    String defaultValue,
    List<String> options, {
    required Function(String) onSelected,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () =>
              _showSelectionBottomSheet(context, label, options, onSelected),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                Text(
                  defaultValue,
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
                ),
                const Spacer(),
                const Icon(Icons.expand_more, size: 20, color: Colors.grey),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showSelectionBottomSheet(
    BuildContext context,
    String title,
    List<String> options,
    Function(String) onSelected,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      builder: (ctx) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            ...options.map(
              (option) => ListTile(
                title: Text(option),
                onTap: () {
                  onSelected(option);
                  Get.back();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
