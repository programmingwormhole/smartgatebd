import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/colors.dart';
import '../../../controllers/payment_gateway_controller.dart';

class CreateEditPaymentGatewayScreen extends StatefulWidget {
  final Map<String, dynamic>? paymentGateway;

  const CreateEditPaymentGatewayScreen({super.key, this.paymentGateway});

  @override
  State<CreateEditPaymentGatewayScreen> createState() =>
      _CreateEditPaymentGatewayScreenState();
}

class _CreateEditPaymentGatewayScreenState
    extends State<CreateEditPaymentGatewayScreen> {
  late TextEditingController nameController;
  late TextEditingController accountNumberController;
  late TextEditingController notesController;

  final PaymentGatewayController _controller =
      Get.find<PaymentGatewayController>();
  final _formKey = GlobalKey<FormState>();

  String _selectedAccountType = 'personal';
  bool _isActive = true;
  bool isLoading = false;

  final List<String> accountTypes = ['personal', 'agent', 'merchant'];

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(
      text: widget.paymentGateway?['name'] ?? '',
    );
    accountNumberController = TextEditingController(
      text: widget.paymentGateway?['account_number'] ?? '',
    );
    notesController = TextEditingController(
      text: widget.paymentGateway?['notes'] ?? '',
    );
    _selectedAccountType = widget.paymentGateway?['account_type'] ?? 'personal';
    _isActive = widget.paymentGateway?['is_active'] ?? true;
  }

  @override
  void dispose() {
    nameController.dispose();
    accountNumberController.dispose();
    notesController.dispose();
    super.dispose();
  }

  Future<void> _saveGateway() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => isLoading = true);

    try {
      final gatewayData = {
        'name': nameController.text.trim(),
        'account_type': _selectedAccountType,
        'account_number': accountNumberController.text.trim(),
        'notes': notesController.text.trim(),
        'is_active': _isActive ? 1 : 0,
      };

      bool success;
      String successMessage;

      if (widget.paymentGateway == null) {
        // Create new gateway
        success = await _controller.createPaymentGateway(gatewayData);
        successMessage = '✓ Payment gateway created successfully';
      } else {
        // Update existing gateway
        success = await _controller.updatePaymentGateway(
          widget.paymentGateway!['id'],
          gatewayData,
        );
        successMessage = '✓ Payment gateway updated successfully';
      }

      setState(() => isLoading = false);

      if (success) {
        // Show success snackbar
        Get.snackbar(
          'Success',
          successMessage,
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
          snackPosition: SnackPosition.BOTTOM,
          borderRadius: 12,
          margin: const EdgeInsets.all(16),
        );
        // Navigate back after a brief delay
        Future.delayed(const Duration(milliseconds: 500), () {
          Get.back();
        });
      } else {
        Get.snackbar(
          'Error',
          '✗ ${_controller.errorMessage.value.isNotEmpty ? _controller.errorMessage.value : 'Failed to save payment gateway'}',
          backgroundColor: AppColors.errorRed,
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
          snackPosition: SnackPosition.BOTTOM,
          borderRadius: 12,
          margin: const EdgeInsets.all(16),
        );
      }
    } catch (e) {
      setState(() => isLoading = false);
      Get.snackbar(
        'Error',
        '✗ ${e.toString().replaceAll('Exception: ', '')}',
        backgroundColor: AppColors.errorRed,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
        snackPosition: SnackPosition.BOTTOM,
        borderRadius: 12,
        margin: const EdgeInsets.all(16),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          widget.paymentGateway == null
              ? 'Add Payment Gateway'
              : 'Edit Payment Gateway',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        backgroundColor: AppColors.primaryNavy,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Info
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.primaryBlue.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        widget.paymentGateway == null
                            ? Icons.add_circle_outline
                            : Icons.edit_outlined,
                        color: AppColors.primaryBlue,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.paymentGateway == null
                                  ? 'Create New Payment Gateway'
                                  : 'Edit Payment Gateway Details',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primaryBlue,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Fill in the details below',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // Gateway Name Field
                Text(
                  'Gateway Name',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: nameController,
                  enabled: !isLoading,
                  decoration: InputDecoration(
                    hintText: 'e.g., Primary Bank Account',
                    prefixIcon: const Icon(Icons.account_balance_wallet),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppColors.primaryBlue,
                        width: 2,
                      ),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.red.shade400),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                ),
                const SizedBox(height: 24),

                // Account Type Dropdown
                Text(
                  'Account Type',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.grey.shade50,
                  ),
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: _selectedAccountType.toLowerCase(),
                    onChanged: isLoading
                        ? null
                        : (String? value) {
                            if (value != null) {
                              setState(() => _selectedAccountType = value);
                            }
                          },
                    underline: Container(),
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                    items: accountTypes.map((type) {
                      return DropdownMenuItem<String>(
                        value: type.toLowerCase(),
                        child: Text(type[0].toUpperCase() + type.substring(1)),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 24),

                // Account Number Field
                Text(
                  'Account Number / ID',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: accountNumberController,
                  enabled: !isLoading,
                  decoration: InputDecoration(
                    hintText: 'e.g., +8801700000000 or AC2023001',
                    prefixIcon: const Icon(Icons.credit_card),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppColors.primaryBlue,
                        width: 2,
                      ),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.red.shade400),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                ),
                const SizedBox(height: 24),

                // Notes Field
                Text(
                  'Notes',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: notesController,
                  enabled: !isLoading,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText:
                        'Optional bank details, account instructions, branch info, or payment notes',
                    alignLabelWithHint: true,
                    prefixIcon: const Icon(Icons.note_alt_outlined),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppColors.primaryBlue,
                        width: 2,
                      ),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.red.shade400),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                ),
                const SizedBox(height: 24),

                // Active Status Toggle
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.grey.shade50,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _isActive
                                ? Icons.check_circle
                                : Icons.cancel_outlined,
                            color: _isActive ? Colors.green : Colors.orange,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Gateway Status',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                _isActive ? 'Active' : 'Inactive',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Switch(
                        value: _isActive,
                        onChanged: isLoading
                            ? null
                            : (value) {
                                setState(() => _isActive = value);
                              },
                        activeColor: Colors.green,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Save Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _saveGateway,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      disabledBackgroundColor: Colors.grey.shade400,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                widget.paymentGateway == null
                                    ? Icons.add_circle_outline
                                    : Icons.save_outlined,
                                color: Colors.white,
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                widget.paymentGateway == null
                                    ? 'Create Gateway'
                                    : 'Update Gateway',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
