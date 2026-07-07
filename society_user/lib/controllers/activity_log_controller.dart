import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../services/activity_log_service.dart';

class ActivityLogController extends GetxController {
  final ActivityLogService _service = ActivityLogService();

  // Observable variables
  final RxBool isLoading = false.obs;
  final RxList<dynamic> logs = <dynamic>[].obs;
  final RxString errorMessage = ''.obs;
  final RxMap<String, dynamic> statistics = <String, dynamic>{}.obs;

  // Pagination
  final RxInt currentPage = 1.obs;
  final RxInt totalPages = 1.obs;
  final RxInt perPage = 20.obs;
  final RxBool hasMorePages = true.obs;

  // Filtering
  final RxString selectedVisitorType = ''.obs;
  final RxString selectedAction = ''.obs;
  final RxString selectedFromDate = ''.obs;
  final RxString selectedToDate = ''.obs;
  final RxString searchQuery = ''.obs;

  // Additional filters for admin and guard
  final RxInt selectedGuardId = 0.obs;
  final RxInt selectedResidentId = 0.obs;

  /// Fetch resident logs
  Future<void> fetchResidentLogs({bool resetPage = true}) async {
    try {
      if (resetPage) currentPage.value = 1;

      isLoading.value = true;
      errorMessage.value = '';

      final response = await _service.getResidentLogs(
        visitorType: selectedVisitorType.value.isEmpty ? null : selectedVisitorType.value,
        action: selectedAction.value.isEmpty ? null : selectedAction.value,
        fromDate: selectedFromDate.value.isEmpty ? null : selectedFromDate.value,
        toDate: selectedToDate.value.isEmpty ? null : selectedToDate.value,
        perPage: perPage.value,
        page: currentPage.value,
      );

      // Handle paginated response
      if (response.containsKey('data')) {
        logs.assignAll(response['data'] ?? []);
        totalPages.value = response['last_page'] ?? 1;
        hasMorePages.value = currentPage.value < (response['last_page'] ?? 1);
      } else {
        logs.assignAll(response['data'] ?? []);
      }

      isLoading.value = false;
    } catch (e) {
      isLoading.value = false;
      errorMessage.value = e.toString().replaceAll('Exception: ', '');
      debugPrint('Error fetching resident logs: $e');
    }
  }

  /// Fetch admin logs
  Future<void> fetchAdminLogs({bool resetPage = true}) async {
    try {
      if (resetPage) currentPage.value = 1;

      isLoading.value = true;
      errorMessage.value = '';

      final response = await _service.getAdminLogs(
        visitorType: selectedVisitorType.value.isEmpty ? null : selectedVisitorType.value,
        action: selectedAction.value.isEmpty ? null : selectedAction.value,
        guardId: selectedGuardId.value == 0 ? null : selectedGuardId.value,
        residentId: selectedResidentId.value == 0 ? null : selectedResidentId.value,
        fromDate: selectedFromDate.value.isEmpty ? null : selectedFromDate.value,
        toDate: selectedToDate.value.isEmpty ? null : selectedToDate.value,
        search: searchQuery.value.isEmpty ? null : searchQuery.value,
        perPage: perPage.value,
        page: currentPage.value,
      );

      // Handle paginated response
      if (response.containsKey('data')) {
        logs.assignAll(response['data'] ?? []);
        totalPages.value = response['last_page'] ?? 1;
        hasMorePages.value = currentPage.value < (response['last_page'] ?? 1);
      } else {
        logs.assignAll(response['data'] ?? []);
      }

      isLoading.value = false;
    } catch (e) {
      isLoading.value = false;
      errorMessage.value = e.toString().replaceAll('Exception: ', '');
      debugPrint('Error fetching admin logs: $e');
    }
  }

  /// Fetch guard logs
  Future<void> fetchGuardLogs({bool resetPage = true}) async {
    try {
      if (resetPage) currentPage.value = 1;

      isLoading.value = true;
      errorMessage.value = '';

      final response = await _service.getGuardLogs(
        visitorType: selectedVisitorType.value.isEmpty ? null : selectedVisitorType.value,
        action: selectedAction.value.isEmpty ? null : selectedAction.value,
        fromDate: selectedFromDate.value.isEmpty ? null : selectedFromDate.value,
        toDate: selectedToDate.value.isEmpty ? null : selectedToDate.value,
        search: searchQuery.value.isEmpty ? null : searchQuery.value,
        perPage: perPage.value,
        page: currentPage.value,
      );

      // Handle paginated response
      if (response.containsKey('data')) {
        logs.assignAll(response['data'] ?? []);
        totalPages.value = response['last_page'] ?? 1;
        hasMorePages.value = currentPage.value < (response['last_page'] ?? 1);
      } else {
        logs.assignAll(response['data'] ?? []);
      }

      isLoading.value = false;
    } catch (e) {
      isLoading.value = false;
      errorMessage.value = e.toString().replaceAll('Exception: ', '');
      debugPrint('Error fetching guard logs: $e');
    }
  }

  /// Fetch statistics
  Future<void> fetchStatistics() async {
    try {
      final response = await _service.getStatistics();
      statistics.assignAll(response);
    } catch (e) {
      debugPrint('Error fetching statistics: $e');
    }
  }

  /// Load next page
  Future<void> loadNextPage() async {
    if (hasMorePages.value) {
      currentPage.value++;
      // Call appropriate fetch method based on context
      await fetchAdminLogs(resetPage: false);
    }
  }

  /// Reset filters
  void resetFilters() {
    selectedVisitorType.value = '';
    selectedAction.value = '';
    selectedFromDate.value = '';
    selectedToDate.value = '';
    searchQuery.value = '';
    selectedGuardId.value = 0;
    selectedResidentId.value = 0;
    currentPage.value = 1;
  }

  /// Update visitor type filter
  void setVisitorTypeFilter(String type) {
    selectedVisitorType.value = type;
    currentPage.value = 1;
  }

  /// Update action filter
  void setActionFilter(String action) {
    selectedAction.value = action;
    currentPage.value = 1;
  }

  /// Update date range
  void setDateRange(String fromDate, String toDate) {
    selectedFromDate.value = fromDate;
    selectedToDate.value = toDate;
    currentPage.value = 1;
  }

  /// Update search query
  void setSearchQuery(String query) {
    searchQuery.value = query;
    currentPage.value = 1;
  }

  /// Get human readable visitor type
  String getVisitorTypeLabel(String type) {
    final labels = {
      'temporary': 'Temporary Visitor',
      'family': 'Family Member',
      'daily_help': 'Daily Help',
      'pre_approved': 'Pre-Approved Visitor',
    };
    return labels[type] ?? type.replaceAll('_', ' ');
  }

  /// Get human readable action
  String getActionLabel(String action) {
    final labels = {
      'entry': 'Entry',
      'exit': 'Exit',
      'created': 'Created',
      'approved': 'Approved',
      'rejected': 'Rejected',
      'verified': 'Verified',
    };
    return labels[action] ?? action;
  }

  /// Get action color
  Color getActionColor(String action) {
    switch (action) {
      case 'entry':
        return Colors.green;
      case 'exit':
        return Colors.red;
      case 'created':
        return Colors.blue;
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'verified':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }
}
