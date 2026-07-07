import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/colors.dart';
import '../../controllers/bill_controller.dart';
import '../../core/widgets/shimmer_loader.dart';
import '../../core/utils/date_formatter.dart';

class BillHistoryScreen extends StatelessWidget {
  const BillHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Get.find<BillController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Payment History'),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
          onPressed: () => Get.back(),
        ),
      ),
      body: Obx(() {
        if (provider.isLoading && provider.historyBills.isEmpty) {
          return const ShimmerList();
        }

        if (provider.historyBills.isEmpty) {
          return const Center(child: Text('No payment history found'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: provider.historyBills.length,
          itemBuilder: (context, index) {
            final bill = provider.historyBills[index];
            return _buildHistoryCard(bill);
          },
        );
      }),
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> bill) {
    final title = bill['type']?.toString().capitalizeFirst ?? 'Bill';
    final monthYear = bill['month_year'] ?? '';
    final amount = bill['amount']?.toString() ?? '0';
    final status = (bill['status'] ?? '').toString().toUpperCase();
    final payments = bill['payments'] as List? ?? [];

    Color statusColor = status == 'PAID' ? Colors.green : Colors.red;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ExpansionTile(
        title: Text(
          '$title - $monthYear',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          'Amount: ৳$amount',
          style: TextStyle(color: statusColor, fontWeight: FontWeight.w500),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            status,
            style: TextStyle(
              color: statusColor,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        children: [
          if (payments.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('No payment attempts recorded.'),
            )
          else
            ...payments.map(
              (p) => ListTile(
                dense: true,
                title: Text(
                  p['method']?.toString().toLowerCase() == 'cash'
                      ? 'Note: ${p['notes'] ?? 'Cash payment'}'
                      : 'TrxID: ${p['trx_id']}',
                ),
                subtitle: Text(
                  'Via: ${p['method']?.toString().toUpperCase() ?? 'Manual'}${p['gateway']?['name'] != null ? ' • ${p['gateway']['name']}' : ''} | ${DateFormatter.formatDateTime(p['created_at'])}',
                ),
                trailing: Text(
                  '৳${p['amount']}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
