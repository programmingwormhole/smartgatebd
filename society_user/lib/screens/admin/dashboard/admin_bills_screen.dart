import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/admin_controller.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/utils/date_formatter.dart';
import '../bills/bill_history_screen.dart';

class AdminBillsScreen extends StatefulWidget {
  const AdminBillsScreen({super.key});

  @override
  State<AdminBillsScreen> createState() => _AdminBillsScreenState();
}

class _AdminBillsScreenState extends State<AdminBillsScreen> {
  final AdminController _adminController = Get.find<AdminController>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _adminController.fetchPendingPayments();
    });
  }

  void _showApprovalDialog(int paymentId, double amount, String reference) {
    Get.defaultDialog(
      title: 'Approve Payment',
      middleText:
          'Are you sure you want to approve this payment of ৳$amount? (Reference: $reference)',
      textConfirm: 'Approve',
      textCancel: 'Cancel',
      confirmTextColor: Colors.white,
      buttonColor: Colors.green,
      onConfirm: () async {
        Get.back();
        final success = await _adminController.approvePayment(paymentId);
        if (success) {
          Get.snackbar(
            'Success',
            'Payment approved successfully',
            snackPosition: SnackPosition.BOTTOM,
          );
        }
      },
    );
  }

  void _showRejectionDialog(int paymentId) {
    final reasonController = TextEditingController();
    Get.defaultDialog(
      title: 'Reject Payment',
      content: TextField(
        controller: reasonController,
        decoration: const InputDecoration(
          labelText: 'Reason for rejection',
          border: OutlineInputBorder(),
        ),
      ),
      textConfirm: 'Reject',
      textCancel: 'Cancel',
      confirmTextColor: Colors.white,
      buttonColor: Colors.red,
      onConfirm: () async {
        if (reasonController.text.trim().isEmpty) {
          Get.snackbar(
            'Error',
            'Please provide a reason',
            snackPosition: SnackPosition.BOTTOM,
          );
          return;
        }
        Get.back();
        final success = await _adminController.rejectPayment(
          paymentId,
          reasonController.text.trim(),
        );
        if (success) {
          Get.snackbar(
            'Success',
            'Payment rejected',
            snackPosition: SnackPosition.BOTTOM,
          );
        }
      },
    );
  }

  void _showMarkBillPaidDialog(int billId) {
    final noteController = TextEditingController();
    Get.defaultDialog(
      title: 'Mark Bill as Paid',
      content: TextField(
        controller: noteController,
        maxLines: 3,
        decoration: const InputDecoration(
          labelText: 'Optional comment or note',
          border: OutlineInputBorder(),
        ),
      ),
      textConfirm: 'Mark Paid',
      textCancel: 'Cancel',
      confirmTextColor: Colors.white,
      buttonColor: Colors.green,
      onConfirm: () async {
        Get.back();
        final success = await _adminController.markBillAsPaid(
          billId,
          note: noteController.text.trim(),
        );
        if (success) {
          Get.snackbar(
            'Success',
            'Bill marked as paid',
            snackPosition: SnackPosition.BOTTOM,
          );
        } else {
          Get.snackbar(
            'Error',
            'Failed to mark bill as paid',
            snackPosition: SnackPosition.BOTTOM,
          );
        }
      },
    );
  }

  void _showGenerateBillsDialog() {
    final amountController = TextEditingController();
    final descriptionController = TextEditingController();
    String selectedType = 'maintenance';
    String selectedMonth = 'March 2026'; // Default, ideally built dynamically

    Get.defaultDialog(
      title: 'Generate Bulk Bills',
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: selectedType,
              items: ['maintenance', 'utility', 'security', 'other']
                  .map(
                    (e) => DropdownMenuItem(
                      value: e,
                      child: Text(e.capitalizeFirst!),
                    ),
                  )
                  .toList(),
              onChanged: (val) {
                if (val != null) selectedType = val;
              },
              decoration: const InputDecoration(labelText: 'Bill Type'),
            ),
            TextField(
              controller: amountController,
              decoration: const InputDecoration(labelText: 'Amount (৳)'),
              keyboardType: TextInputType.number,
            ),
            DropdownButtonFormField<String>(
              value: selectedMonth,
              items: [
                'February 2026',
                'March 2026',
                'April 2026',
              ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (val) {
                if (val != null) selectedMonth = val;
              },
              decoration: const InputDecoration(labelText: 'Billing Month'),
            ),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(labelText: 'Description (Opt)'),
            ),
          ],
        ),
      ),
      textConfirm: 'Generate',
      textCancel: 'Cancel',
      confirmTextColor: Colors.white,
      buttonColor: AppColors.primaryBlue,
      onConfirm: () async {
        if (amountController.text.trim().isEmpty) {
          Get.snackbar('Error', 'Please enter amount');
          return;
        }

        Get.back(); // close dialog

        // Show loading
        Get.dialog(
          const Center(child: CircularProgressIndicator()),
          barrierDismissible: false,
        );

        final success = await _adminController.generateBulkBills({
          'type': selectedType,
          'amount': double.parse(amountController.text.trim()),
          'month_year': selectedMonth,
          'due_date': '2026-03-31', // Example static due date for brevity
          'description': descriptionController.text.trim(),
        });

        Get.back(); // close loading

        if (success) {
          Get.snackbar(
            'Success',
            'Bulk bills generated successfully',
            backgroundColor: Colors.green,
            colorText: Colors.white,
          );
        } else {
          Get.snackbar('Error', 'Failed to generate bills');
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Pending Payments'),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.history, color: AppColors.primaryBlue),
            tooltip: 'View Bill History',
            onPressed: () => Get.to(() => const BillHistoryScreen()),
          ),
          IconButton(
            icon: const Icon(Icons.receipt_long, color: AppColors.primaryBlue),
            tooltip: 'Generate Bulk Bills',
            onPressed: _showGenerateBillsDialog,
          ),
        ],
      ),
      body: Obx(() {
        if (_adminController.isLoading &&
            _adminController.pendingPayments.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (_adminController.pendingPayments.isEmpty) {
          return const Center(child: Text('No pending payments for approval.'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _adminController.pendingPayments.length,
          itemBuilder: (context, index) {
            final payment = _adminController.pendingPayments[index];
            final bill = payment['bill'] ?? {};
            final billId = bill['id'];
            final parsedBillId = int.tryParse(billId.toString());
            final flat = bill['flat'] ?? {};
            final residents = flat['residents'] as List? ?? [];
            final residentData = residents.isNotEmpty
                ? residents[0]['user']
                : {};
            final residentName = residentData['name'] ?? 'Unknown Resident';

            final floor = flat['floor'] ?? {};
            final block = floor['block'] ?? {};
            final building = block['building'] ?? {};

            final buildingName = building['name'] ?? 'N/A';
            final blockName = block['name'] ?? 'N/A';
            final floorNo = floor['floor_number'] ?? 'N/A';
            final flatNo = flat['flat_number'] ?? 'N/A';

            final amount = double.tryParse(payment['amount'].toString()) ?? 0.0;
            final billAmount =
                double.tryParse(bill['amount'].toString()) ?? 0.0;
            final paymentMethod = (payment['method'] ?? '')
                .toString()
                .toLowerCase();
            final trxId = payment['trx_id'] ?? 'N/A';
            final paymentNote = payment['notes'] ?? 'N/A';
            final gateway = payment['gateway']?['name'] ?? 'Manual';

            return Card(
              margin: const EdgeInsets.only(bottom: 20),
              elevation: 4,
              shadowColor: Colors.black12,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Theme(
                data: Theme.of(
                  context,
                ).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              residentName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: AppColors.primaryNavy,
                              ),
                            ),
                            Text(
                              '$buildingName | $blockName | Floor: $floorNo | Flat: $flatNo',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '৳$amount',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryBlue,
                        ),
                      ),
                    ],
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: _buildDetailItem(
                                  'Bill Details',
                                  '${bill['type']?.toString().capitalizeFirst} - ${bill['month_year']}',
                                  Icons.receipt_long_outlined,
                                ),
                              ),
                              Expanded(
                                child: _buildDetailItem(
                                  'Bill Amount',
                                  '৳$billAmount',
                                  Icons.account_balance_wallet_outlined,
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 24),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: _buildDetailItem(
                                  'Paid via',
                                  gateway,
                                  Icons.payment_outlined,
                                ),
                              ),
                              Expanded(
                                child: _buildDetailItem(
                                  'Paid Amount',
                                  '৳$amount',
                                  Icons.check_circle_outline,
                                  valueColor: AppColors.primaryBlue,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _buildDetailItem(
                            paymentMethod == 'cash'
                                ? 'Cash Note'
                                : 'Transaction ID',
                            paymentMethod == 'cash' ? paymentNote : trxId,
                            Icons.fingerprint_outlined,
                          ),
                          const SizedBox(height: 12),
                          _buildDetailItem(
                            'Submitted On',
                            DateFormatter.formatDateTime(payment['created_at']),
                            Icons.calendar_month_outlined,
                          ),
                          if (bill['description'] != null &&
                              bill['description'].toString().isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 12.0),
                              child: _buildDetailItem(
                                'Note',
                                bill['description'],
                                Icons.note_outlined,
                              ),
                            ),
                          if (payment['screenshot'] != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 16.0),
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  Get.dialog(
                                    Dialog(
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: InteractiveViewer(
                                          child: Image.network(
                                            '${ApiConstants.baseUrl.replaceAll('/api/v1', '')}/storage/${payment['screenshot']}',
                                            fit: BoxFit.contain,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                                icon: const Icon(
                                  Icons.image_outlined,
                                  size: 18,
                                ),
                                label: const Text('View Payment Proof'),
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size(double.infinity, 40),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () =>
                                      _showRejectionDialog(payment['id']),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red.shade50,
                                    foregroundColor: Colors.red,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: const Text('Reject'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () => _showApprovalDialog(
                                    payment['id'],
                                    amount,
                                    paymentMethod == 'cash'
                                        ? paymentNote
                                        : trxId,
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: const Text('Approve'),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: parsedBillId == null
                                  ? null
                                  : () => _showMarkBillPaidDialog(parsedBillId),
                              icon: const Icon(Icons.check_circle_outline),
                              label: const Text('Mark Bill as Paid'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.green,
                                side: BorderSide(color: Colors.green.shade300),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      }),
    );
  }

  Widget _buildDetailItem(
    String label,
    String value,
    IconData icon, {
    Color? valueColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: Colors.grey.shade500),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: valueColor ?? AppColors.textDark,
          ),
        ),
      ],
    );
  }
}
