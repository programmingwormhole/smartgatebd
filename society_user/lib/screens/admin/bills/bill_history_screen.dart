import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/colors.dart';
import '../../../services/bill_api_service.dart';
import 'bill_details_screen.dart';

class BillHistoryScreen extends StatefulWidget {
  const BillHistoryScreen({super.key});

  @override
  State<BillHistoryScreen> createState() => _BillHistoryScreenState();
}

class _BillHistoryScreenState extends State<BillHistoryScreen> {
  late ScrollController _scrollController;
  final BillApiService _billApiService = BillApiService();
  List<dynamic> bills = [];
  bool isLoading = false;
  int currentPage = 1;
  bool hasMore = true;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    _loadBills();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      if (hasMore && !isLoading) {
        _loadBills(page: currentPage + 1);
      }
    }
  }

  Future<void> _loadBills({int page = 1}) async {
    if (isLoading) return;

    setState(() {
      isLoading = page == 1;
      if (page == 1) bills.clear();
    });

    try {
      final response = await _billApiService.getBills(page: page);
      setState(() {
        final billsList = response['bills'] ?? [];
        bills.addAll(billsList);
        currentPage = page;
        hasMore = (billsList as List).length == 20;
      });
    } catch (e) {
      Get.snackbar('Error', 'Failed to load bills: $e',
          backgroundColor: AppColors.errorRed, colorText: Colors.white);
    } finally {
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
        title: const Text('Bill History'),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
          onPressed: () => Get.back(),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async => _loadBills(),
        child: bills.isEmpty && !isLoading
            ? _buildEmptyState()
            : ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: bills.length + (hasMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == bills.length) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  final bill = bills[index];
                  return _buildBillCard(bill);
                },
              ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_outlined,
                size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No Bills',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No bills generated yet',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBillCard(dynamic bill) {
    final Color typeColor = _getTypeColor(bill['type']);
    final double amountPaid = bill['payments']?.length > 0 ? double.tryParse(bill['total_collected']?.toString() ?? '0') ?? 0 : 0;
    final double totalAmount = double.tryParse(bill['amount']?.toString() ?? '0') ?? 0;
    final double progress = totalAmount > 0 ? (amountPaid / totalAmount) : 0;

    return GestureDetector(
      onTap: () {
        Get.to(() => BillDetailsScreen(billId: bill['id']));
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border(
            left: BorderSide(color: typeColor, width: 4),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bill['type']?.toString().toUpperCase() ?? 'Bill',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        bill['month_year'] ?? 'N/A',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(bill['status'] ?? 'unpaid')
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    bill['status'] ?? 'unpaid',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _getStatusColor(bill['status'] ?? 'unpaid'),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Amount
            Text(
              '৳ ${_formatCurrency(totalAmount)}',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryNavy,
              ),
            ),
            const SizedBox(height: 12),
            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: Colors.grey.shade300,
                valueColor:
                    AlwaysStoppedAnimation<Color>(typeColor.withValues(alpha: 0.7)),
              ),
            ),
            const SizedBox(height: 8),
            // Status text
            Text(
              '৳ ${_formatCurrency(amountPaid)} collected of ৳ ${_formatCurrency(totalAmount)}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 12),
            // Due date
            Row(
              children: [
                Icon(Icons.calendar_today,
                    size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 6),
                Text(
                  'Due: ${bill['due_date'] ?? 'N/A'}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
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

  Color _getTypeColor(String type) {
    switch (type.toLowerCase()) {
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

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return Colors.green;
      case 'unpaid':
        return Colors.red;
      case 'pending_approval':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}
