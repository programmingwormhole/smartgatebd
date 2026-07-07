import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../controllers/visitor_controller.dart';
import '../../core/constants/colors.dart';
import '../../core/widgets/gatepass_dialog.dart';
import 'add_visitor_screen.dart';
import '../../core/widgets/shimmer_loader.dart';

class VisitorsScreen extends StatefulWidget {
  const VisitorsScreen({super.key});

  @override
  State<VisitorsScreen> createState() => _VisitorsScreenState();
}

class _VisitorsScreenState extends State<VisitorsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final controller = Get.find<VisitorController>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        controller.fetchVisitors();
      }
    });
    Future.microtask(() {
      if (mounted) {
        controller.fetchVisitors();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Visitors'),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: AppColors.primaryNavy),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primaryNavy,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppColors.primaryNavy,
          tabs: const [
            Tab(text: 'Pre-Approve'),
            Tab(text: 'History'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildHistoryTab(true), _buildHistoryTab(false)],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(20),
        child: ElevatedButton(
          onPressed: () {
            Get.to(() => const AddVisitorScreen());
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryNavy,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            'Pre approve visitors',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryTab(bool isPreApprove) {

    final visitorController = Get.put(VisitorController());

    return RefreshIndicator(
      onRefresh: () async => controller.fetchVisitors(),
      child: Obx(() {
        if (visitorController.isLoading.value || visitorController.visitors.isEmpty) {
          return const ShimmerList();
        }

        final allVisitors = visitorController.visitors;
        final filteredVisitors = isPreApprove
            ? allVisitors
            .where(
              (v) =>
          v['status'] == 'pending' ||
              v['status'] == 'approved' ||
              v['status'] == 'inside' ||
              v['status'] == 'resident_rejected',
        )
            .toList()
            : allVisitors
            .where(
              (v) =>
          v['status'] == 'exited' || v['status'] == 'rejected',
        )
            .toList();

        if (filteredVisitors.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.history_outlined,
                  size: 64,
                  color: Colors.grey.shade300,
                ),
                const SizedBox(height: 16),
                Text(
                  isPreApprove ? 'No active approvals' : 'No visitor history',
                  style: TextStyle(color: Colors.grey.shade400),
                ),

                const SizedBox(height: 20),

                TextButton(
                  onPressed: () => controller.fetchVisitors(),
                  child: Text('Refresh Visitors'),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: filteredVisitors.length,
          itemBuilder: (context, index) {
            final item = filteredVisitors[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildHighFidelityVisitorCard(item),
            );
          },
        );
      }),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'inside':
        return AppColors.errorRed;
      case 'approved':
        return AppColors.successGreen;
      case 'pending':
        return AppColors.warningOrange;
      case 'exited':
        return Colors.grey;
      case 'rejected':
      case 'resident_rejected':
        return AppColors.errorRed;
      default:
        return AppColors.primaryNavy;
    }
  }

  Widget _buildHighFidelityVisitorCard(Map<String, dynamic> item) {
    String name = item['name'] ?? 'Unknown';
    String type = item['type'] ?? 'Visitor';
    String time = item['visit_date'] ?? 'N/A';
    String status = item['status'] ?? 'pending';
    Color statusColor = _getStatusColor(status);
    dynamic gatepass = item['gatepass'];
    String? phone = item['phone'];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: AppColors.primaryNavy.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getVisitorIcon(type),
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
                        '$name ($type)',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        time,
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        status.replaceAll('_', ' ').capitalizeFirst ?? status,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (status == 'resident_rejected' || item['reject_reason'] != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.errorRed.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.errorRed.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: AppColors.errorRed,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Reject Reason: ${item['reject_reason']}',
                        style: const TextStyle(
                          color: AppColors.errorRed,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                if (status.toLowerCase() == 'pending') ...[
                  TextButton.icon(
                    onPressed: () => _approveVisitor(item['id']),
                    icon: const Icon(
                      Icons.check_circle_outline,
                      size: 20,
                      color: AppColors.successGreen,
                    ),
                    label: const Text(
                      'Approve',
                      style: TextStyle(color: AppColors.successGreen),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => _rejectVisitor(item['id']),
                    icon: const Icon(
                      Icons.cancel_outlined,
                      size: 20,
                      color: AppColors.errorRed,
                    ),
                    label: const Text(
                      'Reject',
                      style: TextStyle(color: AppColors.errorRed),
                    ),
                  ),
                ] else ...[
                  TextButton.icon(
                    onPressed: phone != null && phone.isNotEmpty
                        ? () => _makeCall(phone)
                        : null,
                    icon: Icon(
                      Icons.call_outlined,
                      size: 20,
                      color: phone != null && phone.isNotEmpty
                          ? AppColors.primaryNavy
                          : Colors.grey,
                    ),
                    label: Text(
                      'Call',
                      style: TextStyle(
                        color: phone != null && phone.isNotEmpty
                            ? AppColors.primaryNavy
                            : Colors.grey,
                      ),
                    ),
                  ),
                  if (status.toLowerCase() != 'inside' &&
                      status.toLowerCase() != 'exited')
                    TextButton.icon(
                      onPressed: () => _confirmDelete(item['id']),
                      icon: const Icon(
                        Icons.delete_outline,
                        size: 20,
                        color: AppColors.errorRed,
                      ),
                      label: const Text(
                        'Delete',
                        style: TextStyle(color: AppColors.errorRed),
                      ),
                    ),
                  if ((gatepass?['entry_code']?.toString() ?? '').isNotEmpty &&
                      gatepass?['entry_code']?.toString() != 'N/A')
                    TextButton.icon(
                      onPressed: () => _showGatepassDialog(
                        name,
                        type,
                        gatepass?['entry_code']?.toString() ?? 'N/A',
                      ),
                      icon: const Icon(
                        Icons.qr_code_outlined,
                        size: 20,
                        color: AppColors.primaryNavy,
                      ),
                      label: const Text(
                        'Gatepass',
                        style: TextStyle(
                          color: AppColors.primaryNavy,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _approveVisitor(dynamic id) async {
    final success = await Get.find<VisitorController>().approveVisitor(id);
    if (success) {
      if (mounted) setState(() {});
    }
  }

  Future<void> _rejectVisitor(dynamic id) async {
    final reason = await _askRejectReason();
    if (reason == null) {
      return;
    }

    final success = await Get.find<VisitorController>().rejectVisitor(
      id,
      reason,
    );
    if (success && mounted) {
      setState(() {});
    }
  }

  Future<String?> _askRejectReason() async {
    final reasonController = TextEditingController();

    String? validationError;
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Reject Visitor'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: reasonController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Enter reject reason',
                  border: const OutlineInputBorder(),
                  errorText: validationError,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final reason = reasonController.text.trim();
                if (reason.isEmpty) {
                  setDialogState(() {
                    validationError = 'Reject reason is required';
                  });
                  return;
                }
                Navigator.of(dialogContext).pop(reason);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.errorRed,
              ),
              child: const Text(
                'Reject',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );

    reasonController.dispose();
    return result;
  }

  IconData _getVisitorIcon(String type) {
    switch (type.toLowerCase()) {
      case 'delivery':
        return Icons.delivery_dining;
      case 'guest':
        return Icons.person_outline;
      case 'cab':
        return Icons.local_taxi;
      case 'service':
        return Icons.build_outlined;
      default:
        return Icons.people_outline;
    }
  }

  Future<void> _makeCall(String phone) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
  }

  void _confirmDelete(dynamic id) {
    Get.dialog(
      AlertDialog(
        title: const Text('Delete Visitor'),
        content: const Text('Are you sure you want to delete this visitor?'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Get.back();
              Get.find<VisitorController>().deleteVisitor(id);
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: AppColors.errorRed),
            ),
          ),
        ],
      ),
    );
  }

  void _showGatepassDialog(String name, String role, String entryCode) {
    showReusableGatepassDialog(
      context: context,
      title: 'Entry Gatepass',
      name: name,
      subtitle: role,
      entryCode: entryCode,
      hintText: 'Show this QR code at the gate for entry.',
    );
  }
}
