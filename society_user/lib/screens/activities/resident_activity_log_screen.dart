import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../controllers/activity_log_controller.dart';
import '../../core/constants/colors.dart';

class ResidentActivityLogScreen extends StatefulWidget {
  const ResidentActivityLogScreen({super.key});

  @override
  State<ResidentActivityLogScreen> createState() =>
      _ResidentActivityLogScreenState();
}

class _ResidentActivityLogScreenState extends State<ResidentActivityLogScreen> {
  late ActivityLogController controller;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    controller = Get.put(ActivityLogController());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      controller.fetchResidentLogs();
    });

    _scrollController.addListener(() {
      if (_scrollController.position.pixels ==
          _scrollController.position.maxScrollExtent) {
        controller.loadNextPage();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Visitor Logs',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primaryNavy,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list, color: Colors.white),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: Obx(
        () => Stack(
          children: [
            controller.logs.isEmpty && !controller.isLoading.value
                ? _buildEmptyState()
                : _buildLogsList(),
            if (controller.isLoading.value && controller.logs.isEmpty)
              const Center(
                child: CircularProgressIndicator(color: AppColors.primaryNavy),
              ),
            if (controller.errorMessage.value.isNotEmpty) _buildErrorBanner(),
          ],
        ),
      ),
    );
  }

  Widget _buildLogsList() {
    final displayLogs = _buildDisplayLogs(controller.logs);

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: displayLogs.length + (controller.isLoading.value ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == displayLogs.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(color: AppColors.primaryNavy),
            ),
          );
        }

        final log = displayLogs[index];
        return _buildLogCard(log);
      },
    );
  }

  List<Map<String, dynamic>> _buildDisplayLogs(List<dynamic> rawLogs) {
    final groupedTemporary = <String, Map<String, dynamic>>{};
    final otherLogs = <Map<String, dynamic>>[];

    for (final raw in rawLogs) {
      if (raw is! Map) continue;

      final log = Map<String, dynamic>.from(raw);
      final visitorType = (log['visitor_type'] ?? '').toString().toLowerCase();

      if (visitorType != 'temporary') {
        otherLogs.add(log);
        continue;
      }

      final key = _temporaryGroupKey(log);
      final existing = groupedTemporary[key];
      if (existing == null) {
        groupedTemporary[key] = _buildTemporaryAggregate(log);
      } else {
        _mergeTemporaryAggregate(existing, log);
      }
    }

    final merged = [...groupedTemporary.values, ...otherLogs];

    merged.sort((a, b) {
      final aDate = _extractPrimaryDate(a);
      final bDate = _extractPrimaryDate(b);
      return bDate.compareTo(aDate);
    });

    return merged;
  }

  String _temporaryGroupKey(Map<String, dynamic> log) {
    final visitorId = log['visitor_id']?.toString();
    if (visitorId != null && visitorId.isNotEmpty) {
      return 'visitor:$visitorId';
    }

    final entryCode = (log['entry_code'] ?? '').toString();
    if (entryCode.isNotEmpty) {
      return 'entry:$entryCode';
    }

    final name = (log['visitor_name'] ?? '').toString().trim().toLowerCase();
    final phone = (log['visitor_phone'] ?? '').toString().trim();
    final purpose = (log['purpose'] ?? '').toString().trim().toLowerCase();

    return 'fallback:$name|$phone|$purpose';
  }

  Map<String, dynamic> _buildTemporaryAggregate(Map<String, dynamic> source) {
    final aggregate = Map<String, dynamic>.from(source);
    aggregate['_is_temporary_aggregate'] = true;
    aggregate['_entry_activity_date'] = null;
    aggregate['_exit_activity_date'] = null;
    aggregate['_visit_activity_date'] = _parseDate(source['activity_date']);

    _mergeTemporaryAggregate(aggregate, source);
    return aggregate;
  }

  void _mergeTemporaryAggregate(
    Map<String, dynamic> aggregate,
    Map<String, dynamic> source,
  ) {
    final action = (source['action'] ?? '').toString().toLowerCase();
    final sourceActivityDate = _parseDate(source['activity_date']);

    DateTime? currentVisitDate = aggregate['_visit_activity_date'] as DateTime?;
    if (sourceActivityDate != null &&
        (currentVisitDate == null ||
            sourceActivityDate.isBefore(currentVisitDate))) {
      aggregate['_visit_activity_date'] = sourceActivityDate;
    }

    if (action == 'entry' || action == 'verified') {
      final entryDate = aggregate['_entry_activity_date'] as DateTime?;
      if (sourceActivityDate != null &&
          (entryDate == null || sourceActivityDate.isBefore(entryDate))) {
        aggregate['_entry_activity_date'] = sourceActivityDate;
      }
    }

    if (action == 'exit') {
      final exitDate = aggregate['_exit_activity_date'] as DateTime?;
      if (sourceActivityDate != null &&
          (exitDate == null || sourceActivityDate.isAfter(exitDate))) {
        aggregate['_exit_activity_date'] = sourceActivityDate;
      }
    }

    final existingActivityDate = _parseDate(aggregate['activity_date']);
    if (sourceActivityDate != null &&
        (existingActivityDate == null ||
            sourceActivityDate.isAfter(existingActivityDate))) {
      aggregate['activity_date'] = source['activity_date'];
      aggregate['action'] = source['action'];
      aggregate['purpose'] = source['purpose'] ?? aggregate['purpose'];
    }
  }

  DateTime _extractPrimaryDate(Map<String, dynamic> log) {
    final activityDate = _parseDate(log['activity_date']);
    if (activityDate != null) return activityDate;

    final visitDate = log['_visit_activity_date'];
    if (visitDate is DateTime) return visitDate;

    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }

  String _formatDateTimeValue(dynamic value) {
    final date = _parseDate(value);
    if (date == null) return '-';
    return DateFormat('dd-MM-yyyy HH:mm').format(date);
  }

  String _formatStayDuration(DateTime? entryDate, DateTime? exitDate) {
    if (entryDate == null || exitDate == null || exitDate.isBefore(entryDate)) {
      return '-';
    }

    final diff = exitDate.difference(entryDate);
    final hours = diff.inHours;
    final minutes = diff.inMinutes.remainder(60);

    if (hours == 0) {
      return '${minutes}m';
    }
    if (minutes == 0) {
      return '${hours}h';
    }
    return '${hours}h ${minutes}m';
  }

  Widget _buildLogCard(Map<String, dynamic> log) {
    final visitorName = log['visitor_name'] ?? 'Unknown';
    final visitorType = log['visitor_type'] ?? 'temporary';
    final action = log['action'] ?? 'unknown';
    final activityDate = log['activity_date'] ?? DateTime.now();
    final purpose = log['purpose'] ?? 'No purpose';
    final visitorPhone = log['visitor_phone'] ?? '-';

    final date = DateTime.tryParse(activityDate.toString());
    final formattedDate = date != null
        ? DateFormat('MMM dd, yyyy - hh:mm a').format(date)
        : 'N/A';
    final isTemporaryAggregate = log['_is_temporary_aggregate'] == true;
    final visitDate = isTemporaryAggregate
        ? _formatDateTimeValue(log['_visit_activity_date'])
        : formattedDate;
    final entryDate = isTemporaryAggregate
        ? (log['_entry_activity_date'] as DateTime?)
        : null;
    final exitDate = isTemporaryAggregate
        ? (log['_exit_activity_date'] as DateTime?)
        : null;
    final entryLabel = _formatDateTimeValue(entryDate);
    final exitLabel = _formatDateTimeValue(exitDate);
    final stayDuration = _formatStayDuration(entryDate, exitDate);

    final actionColor = controller.getActionColor(action);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with visitor name and action badge
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        visitorName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        controller.getVisitorTypeLabel(visitorType),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
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
                    color: actionColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    controller.getActionLabel(action),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: actionColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),

            // Details grid
            Row(
              children: [
                Expanded(
                  child: _buildDetailItem(
                    isTemporaryAggregate ? 'Visit Date' : 'Phone',
                    isTemporaryAggregate ? visitDate : visitorPhone,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(child: _buildDetailItem('Purpose', purpose)),
              ],
            ),
            if (isTemporaryAggregate) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildDetailItem('Entry Time', entryLabel)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildDetailItem('Exit Time', exitLabel)),
                ],
              ),
              const SizedBox(height: 12),
              _buildDetailItem('Stay Duration', stayDuration),
            ] else ...[
              const SizedBox(height: 12),
              _buildDetailItem('Date & Time', formattedDate),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade600,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 64,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'No Visitor Logs',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No visitor activity records found',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              controller.resetFilters();
              controller.fetchResidentLogs();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryNavy,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('Refresh'),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(12),
        color: Colors.red.shade50,
        child: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                controller.errorMessage.value,
                style: TextStyle(color: Colors.red.shade700, fontSize: 12),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            IconButton(
              icon: Icon(Icons.close, color: Colors.red.shade700, size: 20),
              onPressed: () => controller.errorMessage.value = '',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterDialog() {
    Get.bottomSheet(
      _buildFilterPanel(),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: true,
    );
  }

  Widget _buildFilterPanel() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Filters',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: () {
                      controller.resetFilters();
                      controller.fetchResidentLogs();
                      Get.back();
                    },
                    child: const Text('Reset'),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Visitor Type Filter
              const Text(
                'Visitor Type',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Obx(
                () => Wrap(
                  spacing: 8,
                  children:
                      ['', 'temporary', 'family', 'daily_help', 'pre_approved']
                          .map(
                            (type) => FilterChip(
                              label: Text(
                                type.isEmpty
                                    ? 'All'
                                    : controller.getVisitorTypeLabel(type),
                              ),
                              selected:
                                  controller.selectedVisitorType.value == type,
                              onSelected: (selected) {
                                if (selected) {
                                  controller.setVisitorTypeFilter(type);
                                }
                              },
                            ),
                          )
                          .toList(),
                ),
              ),
              const SizedBox(height: 20),

              // Action Filter
              const Text(
                'Action',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Obx(
                () => Wrap(
                  spacing: 8,
                  children:
                      ['', 'entry', 'exit', 'created', 'approved', 'rejected']
                          .map(
                            (action) => FilterChip(
                              label: Text(
                                action.isEmpty
                                    ? 'All'
                                    : controller.getActionLabel(action),
                              ),
                              selected:
                                  controller.selectedAction.value == action,
                              onSelected: (selected) {
                                if (selected) {
                                  controller.setActionFilter(action);
                                }
                              },
                            ),
                          )
                          .toList(),
                ),
              ),
              const SizedBox(height: 20),

              // Apply Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    controller.fetchResidentLogs();
                    Get.back();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryNavy,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Apply Filters'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
