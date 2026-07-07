import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:society_user/screens/guard/visitor_history_screen.dart';
import '../../core/constants/colors.dart';
import '../../controllers/guard_controller.dart';

class GuardInOutScreen extends StatefulWidget {
  const GuardInOutScreen({super.key});

  @override
  State<GuardInOutScreen> createState() => _GuardInOutScreenState();
}

class _GuardInOutScreenState extends State<GuardInOutScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final GuardController _controller = Get.find<GuardController>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _controller.fetchInsideVisitors();
    _controller.fetchPendingVisitors();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _refreshData() async {
    await _controller.refreshAll();
  }

  Future<void> _markVisitorExit(int visitorId) async {
    final success = await _controller.markVisitorExit(visitorId);
    if (success) {
      Get.snackbar(
        'Success',
        'Visitor marked as exited',
        backgroundColor: Colors.green.withOpacity(0.1),
        colorText: Colors.green,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Visitor Management',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(onPressed: _refreshData, icon: const Icon(Icons.refresh, color: Colors.white)),
          const SizedBox(width: 8),

          IconButton(
            onPressed: () => Get.to(() => const VisitorHistoryScreen()),
            icon: const Icon(Icons.history, color: Colors.white),
          ),
        ],
        backgroundColor: AppColors.primaryNavy,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Container(
            color: AppColors.primaryNavy,
            child: TabBar(
              controller: _tabController,
              tabs: [
                _buildTab('Inside', Icons.check_circle),
                _buildTab('Waiting', Icons.person_add_alt_1),
              ],
              indicatorColor: Colors.white,
              indicatorWeight: 3,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white60,
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: TabBarView(
          controller: _tabController,
          children: [
            // Inside Tab
            _buildInsideTab(),
            // Pending Tab
            _buildPendingTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(String label, IconData icon) {
    return Tab(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }

  Widget _buildInsideTab() {
    return Obx(
      () {
        if (_controller.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (_controller.insideVisitors.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.person_off,
                    size: 48,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'No Visitors Inside',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Currently no approved visitors inside the society',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _controller.insideVisitors.length,
          itemBuilder: (context, index) {
            final visitor = _controller.insideVisitors[index];
            return _buildVisitorCard(
              visitor,
              onAction: () => _markVisitorExit(visitor['id'] as int),
              actionLabel: 'Mark Exit',
              actionColor: Colors.red,
            );
          },
        );
      },
    );
  }

  Widget _buildPendingTab() {
    return Obx(() {
      if (_controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      if (_controller.pendingVisitors.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.person_add_alt_1,
                  size: 48,
                  color: Colors.orange.shade600,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'No Pending Visitors',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'No pre-approved visitors waiting for entry',
                style: TextStyle(fontSize: 14, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _controller.pendingVisitors.length,
        itemBuilder: (context, index) {
          final visitor = _controller.pendingVisitors[index];
          final status = (visitor['status'] ?? '').toString();
          final rejectReason = visitor['reject_reason'] as String?;

          if (status == 'pending') {
            // Pending for resident approval
            return _buildVisitorCard(
              visitor,
              onAction: () {},
              actionLabel: 'Pending for Resident Approval',
              actionColor: Colors.grey,
              enabled: false,
            );
          } else if (status == 'approved') {
            // Resident approved, guard can confirm entry
            return _buildVisitorCard(
              visitor,
              onAction: () => _confirmPendingVisitor(visitor['id'] as int),
              actionLabel: 'Confirm Entry',
              actionColor: Colors.green,
              enabled: true,
            );
          } else if (status == 'resident_rejected') {
            // Resident rejected, guard can finalize rejection
            return _buildVisitorCard(
              visitor,
              onAction: () => _rejectPendingVisitor(
                visitor['id'] as int,
                rejectReason ?? 'Rejected by resident',
              ),
              actionLabel: 'Reject Entry',
              actionColor: Colors.red,
              enabled: true,
              rejectReason: rejectReason,
            );
          } else {
            // Fallback for other statuses
            return _buildVisitorCard(
              visitor,
              onAction: () {},
              actionLabel: 'N/A',
              actionColor: Colors.grey,
              enabled: false,
            );
          }
        },
      );
    });
  }

  Future<void> _confirmPendingVisitor(int visitorId) async {
    final success = await _controller.confirmVisitorEntry(visitorId);
    if (success) {
      Get.snackbar(
        'Success',
        'Visitor entry confirmed',
        backgroundColor: Colors.green.withOpacity(0.1),
        colorText: Colors.green,
      );
      return;
    }

    Get.snackbar(
      'Error',
      _controller.errorMessage.value.isNotEmpty
          ? _controller.errorMessage.value
          : 'Failed to confirm visitor entry',
      backgroundColor: Colors.red.withOpacity(0.1),
      colorText: Colors.red,
    );
  }

  Future<void> _rejectPendingVisitor(int visitorId, String reason) async {
    final success = await _controller.rejectVisitorEntry(visitorId, reason);
    if (success) {
      Get.snackbar(
        'Success',
        'Visitor entry rejected',
        backgroundColor: Colors.orange.withOpacity(0.1),
        colorText: Colors.orange,
      );
      return;
    }

    Get.snackbar(
      'Error',
      _controller.errorMessage.value.isNotEmpty
          ? _controller.errorMessage.value
          : 'Failed to reject visitor entry',
      backgroundColor: Colors.red.withOpacity(0.1),
      colorText: Colors.red,
    );
  }

  Widget _buildVisitorCard(
    Map<String, dynamic> visitor, {
    required VoidCallback onAction,
    required String actionLabel,
    required Color actionColor,
    bool enabled = true,
    String? rejectReason,
  }) {
    final guestName = visitor['guest_name'] as String? ?? 'Unknown';
    final residentName = visitor['resident_name'] as String? ?? 'Not assigned';
    final purpose = visitor['purpose'] as String? ?? 'Not specified';
    final entryTime = visitor['entry_time'] as String? ?? '-';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: actionColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.person,
                  color: actionColor,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      guestName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Visiting: $residentName',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(color: Colors.grey.shade200, height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildDetailItem(Icons.info_outline, 'Purpose', purpose),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildDetailItem(Icons.access_time, 'Entry Time', entryTime),
              ),
            ],
          ),
          if (rejectReason != null && rejectReason.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.07),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withOpacity(0.2)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline, color: Colors.red, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Resident Reject Reason: $rejectReason',
                      style: const TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: Obx(
              () => ElevatedButton(
                onPressed: enabled && !_controller.isLoading.value ? onAction : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: actionColor,
                  disabledBackgroundColor: Colors.grey.shade400,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _controller.isLoading.value
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        actionLabel,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
