import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:society_user/core/utils/date_formatter.dart';
import '../../core/constants/colors.dart';
import '../../controllers/bill_controller.dart';
import 'pay_bill_screen.dart';
import 'bill_history_screen.dart';

class BillsScreen extends StatefulWidget {
  const BillsScreen({super.key});

  @override
  State<BillsScreen> createState() => _BillsScreenState();
}

class _BillsScreenState extends State<BillsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.find<BillController>().fetchBills();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Bills & Payments'),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
          onPressed: () => Get.back(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history, color: AppColors.primaryBlue),
            onPressed: () => Get.to(() => const BillHistoryScreen()),
            tooltip: 'Bill History',
          ),
        ],
      ),
      body: Obx(() {
        final provider = Get.find<BillController>();
        if (provider.activeBills.isEmpty) {
          return const Center(child: Text('No active bills found'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: provider.activeBills.length,
          itemBuilder: (context, index) {
            final bill = provider.activeBills[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildBillCard(bill, provider),
            );
          },
        );
      }),
    );
  }

  Widget _buildBillCard(Map<String, dynamic> bill, BillController provider) {
    final title = bill['type'] ?? 'Bill';
    final amount = bill['amount']?.toString() ?? '0';
    final dueDate = bill['due_date'] ?? 'N/A';
    final status = bill['status'] ?? 'Unpaid';
    final isPaid = status.toLowerCase() == 'paid';
    final isPending = status.toLowerCase() == 'pending_for_approval';
    final isUnpaid = status.toLowerCase() == 'unpaid';

    Color statusColor = Colors.orange;
    IconData statusIcon = Icons.pending_actions;

    if (isPaid) {
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;
    } else if (isPending) {
      statusColor = Colors.blue;
      statusIcon = Icons.hourglass_top;
    } else if (isUnpaid) {
      statusColor = Colors.red;
      statusIcon = Icons.error_outline;
    }

    return Container(
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
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(statusIcon, color: statusColor),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title.toString().capitalizeFirst ?? 'Bill',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Bill Date: ${bill['month_year'] ?? ''}',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Due Date: ${DateFormatter.formatDate(dueDate)}',
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
                    Text(
                      '৳$amount',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppColors.primaryNavy,
                      ),
                    ),
                    Text(
                      status.replaceAll('_', ' ').toUpperCase(),
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (isUnpaid)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.grey.shade100)),
              ),
              child: TextButton(
                onPressed: () => Get.to(() => PayBillScreen(bill: bill)),
                child: const Text(
                  'Pay Now',
                  style: TextStyle(
                    color: AppColors.primaryBlue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
