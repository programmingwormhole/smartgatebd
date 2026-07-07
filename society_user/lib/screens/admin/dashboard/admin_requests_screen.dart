import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/admin_controller.dart';
import '../../../core/constants/colors.dart';
import '../../../core/utils/date_formatter.dart';

class AdminRequestsScreen extends StatefulWidget {
  const AdminRequestsScreen({super.key, this.initialTabIndex = 0});

  final int initialTabIndex;

  @override
  State<AdminRequestsScreen> createState() => _AdminRequestsScreenState();
}

class _AdminRequestsScreenState extends State<AdminRequestsScreen> {
  final AdminController _adminController = Get.find<AdminController>();
  String _selectedComplaintStatus = 'all';
  String _selectedComplaintCategory = 'all';

  Future<void> _showRejectReasonDialog({
    required String title,
    required Future<bool> Function(String? reason) onConfirm,
  }) async {
    final reasonController = TextEditingController();

    await Get.dialog(
      AlertDialog(
        title: Text(title),
        content: TextField(
          controller: reasonController,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Optional reject reason',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final success = await onConfirm(reasonController.text.trim());
              if (success) {
                Get.back();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  Future<void> _showAcceptCommentDialog({
    required Future<bool> Function(String? comment) onConfirm,
  }) async {
    final commentController = TextEditingController();

    await Get.dialog(
      AlertDialog(
        title: const Text('Accept Service Request'),
        content: TextField(
          controller: commentController,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Optional instructions/comment for resident',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final success = await onConfirm(commentController.text.trim());
              if (success) {
                Get.back();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: const Text('Accept'),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () {
      _adminController.fetchAmenityRequests();
      _adminController.fetchServiceRequests();
      _adminController.fetchComplaintRequests();
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      initialIndex: widget.initialTabIndex,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Requests Management'),
          backgroundColor: Colors.white,
          elevation: 0,
          bottom: const TabBar(
            labelColor: AppColors.primaryBlue,
            unselectedLabelColor: Colors.grey,
            indicatorColor: AppColors.primaryBlue,
            tabs: [
              Tab(text: 'Amenities'),
              Tab(text: 'Services'),
              Tab(text: 'Complaints'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildAmenityRequests(),
            _buildServiceRequests(),
            _buildComplaintRequests(),
          ],
        ),
      ),
    );
  }

  Widget _buildAmenityRequests() {
    return Obx(() {
      if (_adminController.isLoading &&
          _adminController.amenityRequests.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }

      if (_adminController.amenityRequests.isEmpty) {
        return RefreshIndicator(
          onRefresh: () => _adminController.fetchAmenityRequests(),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: const [
              SizedBox(
                height: 400,
                child: Center(child: Text('No amenity requests found.')),
              ),
            ],
          ),
        );
      }

      return RefreshIndicator(
        onRefresh: () => _adminController.fetchAmenityRequests(),
        child: ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          itemCount: _adminController.amenityRequests.length,
          itemBuilder: (context, index) {
            final booking = _adminController.amenityRequests[index];
            final amenity = booking['amenity'] ?? {};
            final resident = booking['resident']?['user'] ?? {};
            final status = (booking['status'] ?? 'pending')
                .toString()
                .toUpperCase();

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Column(
                children: [
                  ListTile(
                    title: Text(amenity['name'] ?? 'Unknown Amenity'),
                    subtitle: Text(
                      'By: ${resident['name'] ?? 'N/A'}\nDate: ${DateFormatter.formatDate(booking['booking_date'])}\nTime: ${DateFormatter.formatTime(booking['from_time'])} to ${DateFormatter.formatTime(booking['to_time'])}',
                    ),
                    trailing: _buildStatusChip(status),
                  ),
                  if (status == 'PENDING')
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: () => _showRejectReasonDialog(
                                title: 'Reject Amenity Booking',
                                onConfirm: (reason) =>
                                    _adminController.updateAmenityStatus(
                                      booking['id'],
                                      'rejected',
                                      rejectionReason: reason,
                                    ),
                              ),
                              child: const Text(
                                'Reject',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () =>
                                  _adminController.updateAmenityStatus(
                                    booking['id'],
                                    'approved',
                                  ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Approve'),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      );
    });
  }

  Widget _buildServiceRequests() {
    return Obx(() {
      if (_adminController.isLoading &&
          _adminController.serviceRequests.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }

      if (_adminController.serviceRequests.isEmpty) {
        return RefreshIndicator(
          onRefresh: () => _adminController.fetchServiceRequests(),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: const [
              SizedBox(
                height: 400,
                child: Center(child: Text('No service requests found.')),
              ),
            ],
          ),
        );
      }

      return RefreshIndicator(
        onRefresh: () => _adminController.fetchServiceRequests(),
        child: ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          itemCount: _adminController.serviceRequests.length,
          itemBuilder: (context, index) {
            final booking = _adminController.serviceRequests[index];
            final service = booking['service'] ?? {};
            final resident = booking['resident']?['user'] ?? {};
            final status = (booking['status'] ?? 'pending')
                .toString()
                .toUpperCase();

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Column(
                children: [
                  ListTile(
                    title: Text(service['name'] ?? 'Unknown Service'),
                    subtitle: Text(
                      'By: ${resident['name'] ?? 'N/A'}\nDate: ${DateFormatter.formatDate(booking['booking_date'])}\nDescription: ${booking['description'] ?? 'N/A'}',
                    ),
                    trailing: _buildStatusChip(status),
                  ),
                  if (status == 'PENDING' || status == 'APPROVED')
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (status == 'PENDING') ...[
                            Expanded(
                              child: TextButton(
                                onPressed: () => _showRejectReasonDialog(
                                  title: 'Reject Service Request',
                                  onConfirm: (reason) =>
                                      _adminController.updateServiceStatus(
                                        booking['id'],
                                        'rejected',
                                        rejectionReason: reason,
                                      ),
                                ),
                                child: const Text(
                                  'Reject',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () => _showAcceptCommentDialog(
                                  onConfirm: (comment) =>
                                      _adminController.updateServiceStatus(
                                        booking['id'],
                                        'approved',
                                        adminComment: comment,
                                      ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('Accept'),
                              ),
                            ),
                          ] else if (status == 'APPROVED') ...[
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () =>
                                    _adminController.updateServiceStatus(
                                      booking['id'],
                                      'completed',
                                    ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('Mark Completed'),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      );
    });
  }

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status) {
      case 'APPROVED':
      case 'COMPLETED':
      case 'RESOLVED':
        color = Colors.green;
        break;
      case 'REJECTED':
        color = Colors.red;
        break;
      case 'IN PROGRESS':
      case 'IN_PROGRESS':
        color = Colors.blue;
        break;
      default:
        color = Colors.orange;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildComplaintRequests() {
    return Obx(() {
      if (_adminController.isLoading &&
          _adminController.complaintRequests.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }

      if (_adminController.complaintRequests.isEmpty) {
        return const Center(child: Text('No complaints found.'));
      }

      final allComplaints = _adminController.complaintRequests
          .cast<Map<String, dynamic>>();
      final categories = <String>{'all'}
        ..addAll(
          allComplaints
              .map((c) => (c['category'] ?? '').toString().trim())
              .where((category) => category.isNotEmpty),
        );

      final filteredComplaints = allComplaints.where((complaint) {
        final normalizedStatus = _normalizedComplaintStatus(
          complaint['status'],
        );
        final normalizedCategory = (complaint['category'] ?? '')
            .toString()
            .trim()
            .toLowerCase();

        final statusMatched =
            _selectedComplaintStatus == 'all' ||
            normalizedStatus == _selectedComplaintStatus;
        final categoryMatched =
            _selectedComplaintCategory == 'all' ||
            normalizedCategory == _selectedComplaintCategory;

        return statusMatched && categoryMatched;
      }).toList();

      return RefreshIndicator(
        onRefresh: () => _adminController.fetchComplaintRequests(),
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: filteredComplaints.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              return _buildComplaintFilters(
                categories: categories.toList()..sort(),
                resultCount: filteredComplaints.length,
              );
            }

            final complaint = filteredComplaints[index - 1];
            final resident = complaint['resident'] as Map<String, dynamic>?;
            final residentUser = resident?['user'] as Map<String, dynamic>?;
            final flat = resident?['flat'] as Map<String, dynamic>?;
            final floor = flat?['floor'] as Map<String, dynamic>?;
            final block = floor?['block'] as Map<String, dynamic>?;
            final status = _formatComplaintStatus(complaint['status']);

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListTile(
                    title: Text(
                      complaint['title']?.toString() ?? 'Untitled Complaint',
                    ),
                    subtitle: Text(
                      'By: ${residentUser?['name'] ?? 'N/A'}\n'
                      'Category: ${complaint['category'] ?? 'General'}\n'
                      'Flat: ${flat?['flat_number'] ?? 'N/A'}, Floor: ${floor?['floor_number'] ?? 'N/A'}, Block: ${block?['name'] ?? 'N/A'}\n'
                      'Date: ${DateFormatter.formatDate(complaint['created_at']?.toString())}\n'
                      'Description: ${complaint['description'] ?? 'N/A'}',
                    ),
                    trailing: _buildStatusChip(status),
                  ),
                  if (status != 'RESOLVED')
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        alignment: WrapAlignment.end,
                        children: [
                          if (status == 'OPEN')
                            OutlinedButton(
                              onPressed: () =>
                                  _adminController.updateComplaintStatus(
                                    _toInt(complaint['id']),
                                    'in_progress',
                                  ),
                              child: const Text('Mark In Progress'),
                            ),
                          if (status == 'IN PROGRESS')
                            OutlinedButton(
                              onPressed: () =>
                                  _adminController.updateComplaintStatus(
                                    _toInt(complaint['id']),
                                    'open',
                                  ),
                              child: const Text('Reopen'),
                            ),
                          ElevatedButton(
                            onPressed: () =>
                                _adminController.updateComplaintStatus(
                                  _toInt(complaint['id']),
                                  'resolved',
                                ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Resolve'),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      );
    });
  }

  Widget _buildComplaintFilters({
    required List<String> categories,
    required int resultCount,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _buildFilterDropdown(
              label: 'Status',
              value: _selectedComplaintStatus,
              options: const ['all', 'open', 'in_progress', 'resolved'],
              displayText: (value) {
                switch (value) {
                  case 'in_progress':
                    return 'In Progress';
                  case 'resolved':
                    return 'Resolved';
                  case 'open':
                    return 'Open';
                  default:
                    return 'All';
                }
              },
              onChanged: (value) {
                setState(() {
                  _selectedComplaintStatus = value;
                });
              },
            ),
            _buildFilterDropdown(
              label: 'Category',
              value: _selectedComplaintCategory,
              options:
                  categories
                      .map((c) => c == 'all' ? 'all' : c.toLowerCase())
                      .toSet()
                      .toList()
                    ..sort(),
              displayText: (value) {
                if (value == 'all') return 'All';
                if (value.isEmpty) return 'N/A';
                return value[0].toUpperCase() + value.substring(1);
              },
              onChanged: (value) {
                setState(() {
                  _selectedComplaintCategory = value;
                });
              },
            ),
            Text(
              '$resultCount result${resultCount == 1 ? '' : 's'}',
              style: TextStyle(
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterDropdown({
    required String label,
    required String value,
    required List<String> options,
    required String Function(String value) displayText,
    required ValueChanged<String> onChanged,
  }) {
    final uniqueOptions = options.toSet().toList();
    final currentValue = uniqueOptions.contains(value)
        ? value
        : uniqueOptions.first;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: currentValue,
          items: uniqueOptions
              .map(
                (option) => DropdownMenuItem<String>(
                  value: option,
                  child: Text('$label: ${displayText(option)}'),
                ),
              )
              .toList(),
          onChanged: (newValue) {
            if (newValue != null) {
              onChanged(newValue);
            }
          },
        ),
      ),
    );
  }

  String _formatComplaintStatus(dynamic rawStatus) {
    final status = _normalizedComplaintStatus(rawStatus);
    switch (status) {
      case 'in_progress':
        return 'IN PROGRESS';
      case 'resolved':
        return 'RESOLVED';
      default:
        return 'OPEN';
    }
  }

  String _normalizedComplaintStatus(dynamic rawStatus) {
    return (rawStatus ?? 'open').toString().trim().toLowerCase();
  }

  int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
