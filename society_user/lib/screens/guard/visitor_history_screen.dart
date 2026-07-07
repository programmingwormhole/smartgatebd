import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/colors.dart';
import '../../controllers/guard_controller.dart';

class VisitorHistoryScreen extends StatefulWidget {
  const VisitorHistoryScreen({super.key});

  @override
  State<VisitorHistoryScreen> createState() => _VisitorHistoryScreenState();
}

class _VisitorHistoryScreenState extends State<VisitorHistoryScreen> {
  final GuardController _controller = Get.find<GuardController>();
  late ScrollController _scrollController;
  int _currentPage = 1;
  int _pageSize = 10;
  bool _isLoadingMore = false;
  final List<Map<String, dynamic>> _allHistory = [];

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    Future.delayed(Duration.zero, () => _loadInitialHistory());
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 500) {
      if (!_isLoadingMore &&
          _allHistory.length >=
              (_currentPage - 1) * _pageSize) {
        _loadMore();
      }
    }
  }

  Future<void> _loadInitialHistory() async {
    _currentPage = 1;
    _allHistory.clear();
    await _loadMore();
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore) return;

    setState(() => _isLoadingMore = true);

    try {
      await _controller.fetchVisitorHistory();
      final history = _controller.visitorHistory;

      // Filter to only show exited visitors
      final exitedVisitors = history
          .where((visitor) => (visitor['status'] as String?) == 'exited' || (visitor['status'] as String?) == 'rejected')
          .toList();

      setState(() {
        _allHistory.clear();
        _allHistory.addAll(exitedVisitors);
      });
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to load visitor history: $e',
        backgroundColor: Colors.red.withOpacity(0.1),
        colorText: Colors.red,
      );
    } finally {
      setState(() => _isLoadingMore = false);
    }
  }

  String _formatDateTime(String? dateTime) {
    if (dateTime == null || dateTime.isEmpty) return '-';
    try {
      final dt = DateTime.parse(dateTime);
      return '${dt.day.toString().padLeft(2, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateTime;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'inside':
        return Colors.green;
      case 'exited':
        return Colors.blue;
      case 'approved':
        return Colors.orange;
      case 'rejected':
        return Colors.red;
      case 'pending':
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'inside':
        return 'Currently Inside';
      case 'exited':
        return 'Exited';
      case 'approved':
        return 'Approved';
      case 'rejected':
        return 'Rejected';
      case 'pending':
        return 'Pending';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Exited Visitors',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.primaryNavy,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
      ),
      body: Obx(
        () {
          if (_controller.isLoading.value && _allHistory.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppColors.primaryBlue,
                ),
              ),
            );
          }

          if (_allHistory.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.history,
                    size: 64,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No exited visitors yet',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Exited visitor records will appear here',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            itemCount: _allHistory.length + (_isLoadingMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == _allHistory.length) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: SizedBox(
                      height: 40,
                      width: 40,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.primaryBlue,
                        ),
                      ),
                    ),
                  ),
                );
              }

              final visitor = _allHistory[index];
              final guestName = visitor['guest_name'] as String? ?? 'Unknown';
              final residentName =
                  visitor['resident_name'] as String? ?? 'Not assigned';
              final status = visitor['status'] as String? ?? 'pending';
              final entryTime = visitor['entry_time'] as String?;
              final exitTime = visitor['exit_time'] as String?;
              final purpose = visitor['purpose'] as String? ?? '-';
              final createdAt = visitor['created_at'] as String?;
              final guestInitials = guestName.isNotEmpty
                  ? guestName.split(' ').map((e) => e[0]).join('').toUpperCase().substring(0, 1)
                  : 'U';

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: InkWell(
                  onTap: () {
                    _showVisitorDetails(visitor);
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header Row
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 28,
                              backgroundColor: AppColors.primaryBlue.withOpacity(0.1),
                              child: Text(
                                guestInitials,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryBlue,
                                ),
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
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    residentName,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: _getStatusColor(status).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _getStatusLabel(status),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: _getStatusColor(status),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Divider(height: 1),
                        const SizedBox(height: 12),
                        // Details Row
                        Row(
                          children: [
                            Expanded(
                              child: _buildDetailItem(
                                'Visit Date',
                                _formatDateTime(createdAt),
                                Icons.date_range,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildDetailItem(
                                'Purpose',
                                purpose.length > 15
                                    ? '${purpose.substring(0, 15)}...'
                                    : purpose,
                                Icons.info_outline,
                              ),
                            ),
                          ],
                        ),
                        if (entryTime != null || exitTime != null) ...[
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              if (entryTime != null)
                                Expanded(
                                  child: _buildDetailItem(
                                    'Entry Time',
                                    _formatDateTime(entryTime),
                                    Icons.login,
                                  ),
                                ),
                              if (exitTime != null) ...[
                                if (entryTime != null)
                                  const SizedBox(width: 12),
                                Expanded(
                                  child: _buildDetailItem(
                                    'Exit Time',
                                    _formatDateTime(exitTime),
                                    Icons.logout,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: Colors.grey.shade600),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  void _showVisitorDetails(Map<String, dynamic> visitor) {
    final guestName = visitor['guest_name'] as String? ?? 'Unknown';
    final residentName = visitor['resident_name'] as String? ?? 'Not assigned';
    final residentPhone = visitor['resident_phone'] as String? ?? '-';
    final purpose = visitor['purpose'] as String? ?? 'Not specified';
    final status = visitor['status'] as String? ?? 'pending';
    final entryTime = visitor['entry_time'] as String?;
    final exitTime = visitor['exit_time'] as String?;
    final phone = visitor['phone'] as String? ?? '-';
    final vehicleNo = visitor['vehicle_no'] as String? ?? '-';
    final companyName = visitor['company_name'] as String? ?? '-';
    final visitorType = visitor['type'] as String? ?? 'personal';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: ListView(
            controller: scrollController,
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            children: [
              // Header
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Visitor Details',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade900,
                ),
              ),
              const SizedBox(height: 24),
              // Visitor Info - Type-based
              _buildDetailSection('Visitor Information', _buildVisitorInfoRows(visitorType, guestName, phone, companyName, vehicleNo)),
              const SizedBox(height: 20),
              // Resident Info
              _buildDetailSection('Resident Information', [
                _buildDetailRow('Name', residentName),
                _buildDetailRow('Phone', residentPhone),
              ]),
              const SizedBox(height: 20),
              // Visit Details
              _buildDetailSection('Visit Details', [
                _buildDetailRow('Type', _formatVisitorType(visitorType)),
                _buildDetailRow('Purpose', purpose),
                _buildDetailRow(
                  'Status',
                  _getStatusLabel(status),
                ),
              ]),
              const SizedBox(height: 20),
              // Timing Details
              _buildDetailSection('Timing', [
                _buildDetailRow('Entry Time', _formatDateTime(entryTime)),
                _buildDetailRow('Exit Time', _formatDateTime(exitTime)),
              ]),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () => Get.back(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Close',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailSection(
    String title,
    List<Widget> details,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          ...List.generate(
            details.length,
            (index) => Column(
              children: [
                details[index],
                if (index < details.length - 1)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Divider(height: 1, color: Colors.grey.shade300),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade700,
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
  List<Widget> _buildVisitorInfoRows(
    String type,
    String guestName,
    String phone,
    String companyName,
    String vehicleNo,
  ) {
    final rows = <Widget>[_buildDetailRow('Name', guestName)];

    // Add phone for all types except personal
    if (type != 'personal') {
      rows.add(_buildDetailRow('Phone', phone));
    }

    // Add company name for delivery and cab types
    if (type == 'delivery' || type == 'cab') {
      rows.add(_buildDetailRow('Company', companyName));
    }

    // Add vehicle number for cab and delivery types
    if (type == 'cab' || type == 'delivery') {
      rows.add(_buildDetailRow('Vehicle', vehicleNo));
    }

    return rows;
  }

  String _formatVisitorType(String type) {
    final typeMap = {
      'personal': 'Personal Guest',
      'cab': 'Cab Driver',
      'delivery': 'Delivery Partner',
      'service': 'Service Provider',
      'contractor': 'Contractor',
    };
    if (typeMap.containsKey(type)) {
      return typeMap[type]!;
    }
    // Fallback: capitalize first letter
    return type.isEmpty
        ? 'Unknown'
        : type[0].toUpperCase() + type.substring(1).replaceAll('_', ' ');
  }}
