import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:society_user/core/utils/date_formatter.dart';
import '../../core/constants/colors.dart';
import '../../controllers/bill_controller.dart';
import '../../controllers/auth_controller.dart';

class PayBillScreen extends StatefulWidget {
  final Map<String, dynamic> bill;
  const PayBillScreen({super.key, required this.bill});

  @override
  State<PayBillScreen> createState() => _PayBillScreenState();
}

class _PayBillScreenState extends State<PayBillScreen> {
  final _trxController = TextEditingController();
  final _notesController = TextEditingController();
  final _billController = Get.find<BillController>();
  Map<String, dynamic>? _selectedGateway;
  bool _isCashSelected = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final buildingId = Get.find<AuthController>().user?.buildingId;
    if (buildingId != null) {
      _billController.fetchGateways(buildingId);
    }
  }

  void _submitPayment() async {
    if (!_isCashSelected &&
        (_selectedGateway == null || _trxController.text.isEmpty)) {
      Get.snackbar(
        'Error',
        'Please select a gateway and enter transaction ID',
        backgroundColor: Colors.red.withOpacity(0.1),
        colorText: Colors.red,
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final success = await _billController.payBillManual(
      billId: widget.bill['id'],
      amount: double.parse(widget.bill['amount'].toString()),
      gatewayId: _isCashSelected ? null : _selectedGateway!['id'],
      trxId: _isCashSelected ? null : _trxController.text.trim(),
      method: _isCashSelected ? 'cash' : 'gateway',
      notes: _isCashSelected ? _notesController.text.trim() : null,
    );

    setState(() => _isSubmitting = false);

    if (success) {
      Get.back();
      Get.snackbar(
        'Success',
        'Payment submitted successfully. Waiting for admin approval.',
        backgroundColor: Colors.green.withOpacity(0.1),
        colorText: Colors.green,
      );
    } else {
      Get.snackbar(
        'Error',
        'Failed to submit payment',
        backgroundColor: Colors.red.withOpacity(0.1),
        colorText: Colors.red,
      );
    }
  }

  Widget _buildMethodChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryNavy : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.primaryNavy : Colors.grey.shade200,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : AppColors.textDark,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Manual Payment',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primaryNavy,
        elevation: 0,
      ),
      body: Obx(() {
        if (_billController.isGettingGateways &&
            _billController.gateways.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBillSummary(),
              const SizedBox(height: 32),
              const Text(
                'Select Payment Method',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildMethodChip(
                      label: 'Cash',
                      selected: _isCashSelected,
                      onTap: () {
                        setState(() {
                          _isCashSelected = true;
                          _selectedGateway = null;
                          _trxController.clear();
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMethodChip(
                      label: 'Online Payment',
                      selected: !_isCashSelected,
                      onTap: () {
                        setState(() {
                          _isCashSelected = false;
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                _isCashSelected ? 'Cash Note' : 'Select Gateway',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              if (!_isCashSelected) _buildGatewayList(_billController.gateways),
              if (!_isCashSelected && _selectedGateway != null) ...[
                const SizedBox(height: 24),
                _buildGatewayDetails(),
                const SizedBox(height: 24),
                _buildTrxIdField(),
              ] else if (_isCashSelected) ...[
                const SizedBox(height: 24),
                _buildCashNoteField(),
              ],
              const SizedBox(height: 40),
              _buildSubmitButton(),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildBillSummary() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primaryNavy,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.bill['type']?.toString().toUpperCase() ?? 'BILL',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Due Date: ${DateFormatter.formatDate(widget.bill['due_date'])}',
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ],
          ),
          Text(
            '৳${widget.bill['amount']}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGatewayList(List<dynamic> gateways) {
    return SizedBox(
      height: 100,
      child: gateways.isEmpty
          ? const Text('No payment gateways available!')
          : ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: gateways.length,
              itemBuilder: (context, index) {
                final gateway = gateways[index];
                final isSelected = _selectedGateway?['id'] == gateway['id'];
                return GestureDetector(
                  onTap: () => setState(() => _selectedGateway = gateway),
                  child: Container(
                    width: 120,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primaryBlue.withOpacity(0.1)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primaryBlue
                            : Colors.grey.shade200,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.account_balance_wallet,
                          color: AppColors.primaryNavy,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          gateway['name'],
                          style: TextStyle(
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildGatewayDetails() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Payment Instructions:',
            style: TextStyle(
              color: Colors.blue.shade900,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Complete payment to the following ${_selectedGateway!['name']} account:',
            style: const TextStyle(fontSize: 13),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Account Number:',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
              Text(
                _selectedGateway!['account_number'],
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Account Type:',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
              Text(
                _selectedGateway!['account_type'].toString().capitalizeFirst ??
                    'N/A',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          if ((_selectedGateway!['notes'] ?? '')
              .toString()
              .trim()
              .isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.blue.withOpacity(0.15)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Notes',
                    style: TextStyle(
                      color: Colors.blue.shade900,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _selectedGateway!['notes'].toString(),
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade800,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTrxIdField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Transaction Note',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _trxController,
          minLines: 5,
          maxLines: 5,
          decoration: InputDecoration(
            hintText: 'Write some notes about the transaction you made...',
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCashNoteField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Notes / Comments',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _notesController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Optional note, e.g. Paid to Admin',
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submitPayment,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryNavy,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isSubmitting
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Text(
                'Submit Payment',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }
}
