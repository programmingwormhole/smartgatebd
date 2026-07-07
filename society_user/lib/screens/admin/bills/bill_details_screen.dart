import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/colors.dart';
import '../../../services/bill_api_service.dart';

class BillDetailsScreen extends StatefulWidget {
  final int billId;

  const BillDetailsScreen({required this.billId, super.key});

  @override
  State<BillDetailsScreen> createState() => _BillDetailsScreenState();
}

class _BillDetailsScreenState extends State<BillDetailsScreen> {
  final BillApiService _billApiService = BillApiService();
  bool isLoading = true;
  Map<String, dynamic>? billData;

  @override
  void initState() {
    super.initState();
    _loadBillDetails();
  }

  Future<void> _loadBillDetails() async {
    try {
      final response = await _billApiService.getBillDetails(widget.billId);
      setState(() {
        billData = response;
        isLoading = false;
      });
    } catch (e) {
      Get.snackbar('Error', 'Failed to load bill details',
          backgroundColor: AppColors.errorRed, colorText: Colors.white);
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Bill Details'),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
          onPressed: () => Get.back(),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : billData == null
              ? Center(
                  child: Text('Failed to load bill details',
                      style: Theme.of(context).textTheme.bodyMedium),
                )
              : Stack(
                  children: [
                    // Scrollable content
                    SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Bill header
                          _buildBillHeader(),
                          const SizedBox(height: 24),

                          // Statistics grid
                          _buildStatisticsGrid(),
                          const SizedBox(height: 24),

                          // Resident details
                          _buildResidentDetails(),
                          const SizedBox(height: 24),

                          // Payments section
                          _buildPaymentsSection(),
                        ],
                      ),
                    ),

                    // Draggable Bottom Summary Sheet
                    _buildDraggableBottomSheet(),
                  ],
                ),
    );
  }

  Widget _buildBillHeader() {
    final statistics = billData?['statistics'] ?? {};
    final bill = billData?['bill'] ?? {};
    final Color typeColor = _getTypeColor(bill['type']);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: typeColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: typeColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    bill['type']?.toString().toUpperCase() ?? 'Bill',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: typeColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    bill['month_year'] ?? 'N/A',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: typeColor.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.receipt_long,
                  color: typeColor,
                  size: 28,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Amount and collection percentage
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bill Amount',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '৳ ${_formatCurrency(statistics['total_amount'])},',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryNavy,
                ),
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: ((statistics['collection_percentage'] ?? 0) / 100)
                      .clamp(0.0, 1.0),
                  minHeight: 8,
                  backgroundColor: Colors.grey.shade300,
                  valueColor: AlwaysStoppedAnimation<Color>(typeColor),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${_formatPercentage(statistics['collection_percentage'])}% collected',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsGrid() {
    final statistics = billData?['statistics'] ?? {};

    final stats = [
      StatItem(
        label: 'Total Amount',
        value: '৳ ${_formatCurrency(statistics['total_amount'])}',
        color: AppColors.primaryNavy,
      ),
      StatItem(
        label: 'Collected',
        value: '৳ ${_formatCurrency(statistics['total_collected'])}',
        color: Colors.green,
      ),
      StatItem(
        label: 'Pending',
        value: '৳ ${_formatCurrency(statistics['total_pending'])}',
        color: Colors.orange,
      ),
      StatItem(
        label: 'Unpaid',
        value: '৳ ${_formatCurrency(statistics['total_unpaid'])}',
        color: Colors.red,
      ),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.1,
      children: stats
          .map((stat) => _buildStatCard(stat.label, stat.value, stat.color))
          .toList(),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResidentDetails() {
    final residentDetails =
        (billData?['resident_details'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Residents',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        ...residentDetails.map((resident) => _buildResidentTile(resident)),
      ],
    );
  }

  Widget _buildResidentTile(Map<String, dynamic> resident) {
    final Color statusColor = _getStatusColor(resident['status']);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  resident['resident_name'] ?? 'Resident',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Flat: ${resident['flat_number'] ?? 'N/A'}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  resident['status']?.toString().toUpperCase() ?? '',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '৳ ${_formatCurrency(resident['amount_paid'])}',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryNavy,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentsSection() {
    final payments =
        (billData?['payments'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Payment History',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        if (payments.isEmpty)
          Center(
            child: Text(
              'No payments yet',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          )
        else
          ...payments
              .map((payment) => _buildPaymentTile(payment)),
      ],
    );
  }

  Widget _buildPaymentTile(Map<String, dynamic> payment) {
    final Color statusColor = _getStatusColor(payment['status']);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(color: statusColor, width: 4),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  payment['trx_id'] ?? 'TXN',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  payment['created_at'] ?? 'N/A',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '৳ ${_formatCurrency(payment['amount'])}',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: statusColor,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  payment['status']?.toString().toUpperCase() ?? '',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDraggableBottomSheet() {
    final statistics = billData?['statistics'] ?? {};

    return DraggableScrollableSheet(
      initialChildSize: 0.25, // Start at 25% of screen height
      minChildSize: 0.15, // Can collapse to 15%
      maxChildSize: 0.9, // Can expand to 90%
      snap: true,
      snapSizes: [0.25, 0.6, 0.9],
      builder: (BuildContext context, ScrollController scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Drag handle indicator
                  Center(
                    child: Container(
                      width: 50,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Title
                  const Text(
                    'Summary',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Summary rows
                  _buildSummaryRow(
                    'Total Amount',
                    '৳ ${_formatCurrency(statistics['total_amount'])}',
                    AppColors.primaryNavy,
                  ),
                  const SizedBox(height: 12),
                  _buildSummaryRow(
                    'Total Collected',
                    '৳ ${_formatCurrency(statistics['total_collected'])}',
                    Colors.green,
                  ),
                  const SizedBox(height: 12),
                  _buildSummaryRow(
                    'Pending Approval',
                    '৳ ${_formatCurrency(statistics['total_pending'])}',
                    Colors.orange,
                  ),
                  const SizedBox(height: 12),
                  _buildSummaryRow(
                    'Outstanding',
                    '৳ ${_formatCurrency(statistics['total_unpaid'])}',
                    Colors.red,
                  ),
                  const SizedBox(height: 20),

                  // Divider
                  Divider(color: Colors.grey.shade200, height: 1),
                  const SizedBox(height: 16),

                  // Total row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Receivable',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      Text(
                        '৳ ${_formatCurrency(statistics['total_amount'])}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryNavy,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSummaryRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade700,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  String _formatCurrency(dynamic value, {int decimals = 2}) {
    try {
      if (value == null) return '0.${'0' * decimals}';
      if (value is String) {
        final parsed = double.tryParse(value) ?? 0;
        return parsed.toStringAsFixed(decimals);
      }
      return (value as num).toStringAsFixed(decimals);
    } catch (e) {
      return '0.${'0' * decimals}';
    }
  }

  String _formatPercentage(dynamic value, {int decimals = 1}) {
    return _formatCurrency(value, decimals: decimals);
  }

  Color _getTypeColor(String? type) {
    switch (type?.toLowerCase()) {
      case 'rent':
        return Colors.blue;
      case 'maintenance':
        return Colors.green;
      case 'utility':
        return Colors.orange;
      case 'security':
        return Colors.purple;
      case 'water':
        return Colors.cyan;
      case 'electricity':
        return Colors.amber;
      default:
        return AppColors.primaryNavy;
    }
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'paid':
        return Colors.green;
      case 'unpaid':
        return Colors.red;
      case 'pending':
      case 'pending_approval':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}

class StatItem {
  final String label;
  final String value;
  final Color color;

  StatItem({
    required this.label,
    required this.value,
    required this.color,
  });
}
