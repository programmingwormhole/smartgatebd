import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../controllers/activity_log_controller.dart';
import '../../core/constants/colors.dart';

class AdminActivityLogScreen extends StatefulWidget {
  const AdminActivityLogScreen({super.key});

  @override
  State<AdminActivityLogScreen> createState() => _AdminActivityLogScreenState();
}

class _AdminActivityLogScreenState extends State<AdminActivityLogScreen> {
  late ActivityLogController controller;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    controller = Get.put(ActivityLogController());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      controller.fetchAdminLogs();
      controller.fetchStatistics();
    });

    _scrollController.addListener(() {
      if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
        controller.loadNextPage();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Activity Logs',
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
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list, color: Colors.white),
            onPressed: _showAdvancedFilters,
          ),
          IconButton(
            icon: const Icon(Icons.download, color: Colors.white),
            onPressed: _showExportOptions,
          ),
        ],
      ),
      body: Obx(
        () => Stack(
          children: [
            Column(
              children: [
                _buildStatisticsBar(),
                Expanded(
                  child: controller.logs.isEmpty && !controller.isLoading.value
                      ? _buildEmptyState()
                      : _buildLogsList(),
                ),
              ],
            ),
            if (controller.isLoading.value && controller.logs.isEmpty)
              const Center(
                child: CircularProgressIndicator(color: AppColors.primaryNavy),
              ),
            if (controller.errorMessage.value.isNotEmpty)
              _buildErrorBanner(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsBar() {
    return Obx(
      () => Container(
        color: Colors.white,
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildStatCard(
                'Today Entries',
                '${controller.statistics['today']?['entries'] ?? 0}',
                Icons.login,
                Colors.green,
              ),
              const SizedBox(width: 12),
              _buildStatCard(
                'Today Exits',
                '${controller.statistics['today']?['exits'] ?? 0}',
                Icons.logout,
                Colors.red,
              ),
              const SizedBox(width: 12),
              _buildStatCard(
                'This Week',
                '${(controller.statistics['this_week']?['entries'] ?? 0) + (controller.statistics['this_week']?['exits'] ?? 0)}',
                Icons.calendar_today,
                Colors.blue,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Column(
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
        ],
      ),
    );
  }

  Widget _buildLogsList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: controller.logs.length + (controller.isLoading.value ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == controller.logs.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(color: AppColors.primaryNavy),
            ),
          );
        }

        final log = controller.logs[index];
        return _buildLogCard(log);
      },
    );
  }

  Widget _buildLogCard(Map<String, dynamic> log) {
    final visitorName = log['visitor_name'] ?? 'Unknown';
    final visitorType = log['visitor_type'] ?? 'temporary';
    final action = log['action'] ?? 'unknown';
    final activityDate = log['activity_date'] ?? DateTime.now();
    final purpose = log['purpose'] ?? 'No purpose';
    final guardName = log['guard']?['user']?['name'] ?? 'N/A';
    final residentName = log['resident']?['user']?['name'] ?? 'N/A';
    final visitorPhone = log['visitor_phone'] ?? '-';
    final entryCode = log['entry_code'] ?? '-';

    final date = DateTime.tryParse(activityDate.toString());
    final formattedDate = date != null
        ? DateFormat('MMM dd, yyyy - hh:mm a').format(date)
        : 'N/A';

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
            // Header
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              controller.getVisitorTypeLabel(visitorType),
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.blue,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: actionColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              controller.getActionLabel(action),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: actionColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
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
                  child: _buildDetailItem('Phone', visitorPhone),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildDetailItem('Entry Code', entryCode),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildDetailItem('Guard', guardName),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildDetailItem('Resident', residentName),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildDetailItem('Purpose', purpose),
            const SizedBox(height: 12),
            _buildDetailItem('Date & Time', formattedDate),
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
            'No Activity Logs',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No visitor activity records found',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              controller.resetFilters();
              controller.fetchAdminLogs();
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

  void _showAdvancedFilters() {
    Get.bottomSheet(
      _buildAdvancedFilterPanel(),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: true,
    );
  }

  Widget _buildAdvancedFilterPanel() {
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
                    'Advanced Filters',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      controller.resetFilters();
                      controller.fetchAdminLogs();
                      Get.back();
                    },
                    child: const Text('Reset All'),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Search box
              const Text(
                'Search',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search by name, phone, or entry code',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {});
                          },
                        )
                      : null,
                ),
                onChanged: (value) => setState(() {}),
                onSubmitted: (value) {
                  controller.setSearchQuery(value);
                },
              ),
              const SizedBox(height: 20),

              // Visitor Type Filter
              const Text(
                'Visitor Type',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Obx(
                () => Wrap(
                  spacing: 8,
                  children: ['', 'temporary', 'family', 'daily_help', 'pre_approved']
                      .map((type) => FilterChip(
                            label: Text(type.isEmpty ? 'All' : controller.getVisitorTypeLabel(type)),
                            selected: controller.selectedVisitorType.value == type,
                            onSelected: (selected) {
                              if (selected) {
                                controller.setVisitorTypeFilter(type);
                              }
                            },
                          ))
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
                          .map((action) => FilterChip(
                                label: Text(action.isEmpty ? 'All' : controller.getActionLabel(action)),
                                selected: controller.selectedAction.value == action,
                                onSelected: (selected) {
                                  if (selected) {
                                    controller.setActionFilter(action);
                                  }
                                },
                              ))
                          .toList(),
                ),
              ),
              const SizedBox(height: 20),

              // Apply Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (_searchController.text.isNotEmpty) {
                      controller.setSearchQuery(_searchController.text);
                    }
                    controller.fetchAdminLogs();
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

  void _showExportOptions() {
    Get.bottomSheet(
      Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Export Logs',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.table_chart, color: AppColors.primaryNavy),
                title: const Text('Export as CSV'),
                subtitle: const Text('Download all logs as CSV file'),
                onTap: () {
                  Get.back();
                  // TODO: Implement CSV export
                  Get.snackbar('Export', 'CSV export feature coming soon');
                },
              ),
              ListTile(
                leading: const Icon(Icons.picture_as_pdf, color: AppColors.primaryNavy),
                title: const Text('Export as PDF'),
                subtitle: const Text('Download all logs as PDF file'),
                onTap: () {
                  Get.back();
                  // TODO: Implement PDF export
                  Get.snackbar('Export', 'PDF export feature coming soon');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
