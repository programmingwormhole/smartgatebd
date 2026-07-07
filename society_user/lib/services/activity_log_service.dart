import 'dart:convert';
import 'api_service.dart';

class ActivityLogService {
  final ApiService _apiService = ApiService();

  /// Build query string from map of parameters
  String _buildQueryString(Map<String, dynamic> params) {
    final filtered = params.entries
        .where((e) => e.value != null)
        .toList();
    
    if (filtered.isEmpty) return '';
    
    final query = filtered
        .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value.toString())}')
        .join('&');
    
    return '?$query';
  }

  /// Get resident's visitor logs
  Future<Map<String, dynamic>> getResidentLogs({
    String? visitorType,
    String? action,
    String? fromDate,
    String? toDate,
    int perPage = 20,
    int page = 1,
  }) async {
    try {
      final params = <String, dynamic>{
        'per_page': perPage,
        'page': page,
      };

      if (visitorType != null) params['visitor_type'] = visitorType;
      if (action != null) params['action'] = action;
      if (fromDate != null) params['from_date'] = fromDate;
      if (toDate != null) params['to_date'] = toDate;

      final response = await _apiService.get(
        '/resident/logs${_buildQueryString(params)}',
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to fetch resident logs: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching resident logs: $e');
    }
  }

  /// Get admin's visitor logs with comprehensive filtering
  Future<Map<String, dynamic>> getAdminLogs({
    String? visitorType,
    String? action,
    int? guardId,
    int? residentId,
    String? fromDate,
    String? toDate,
    String? search,
    int perPage = 20,
    int page = 1,
  }) async {
    try {
      final params = <String, dynamic>{
        'per_page': perPage,
        'page': page,
      };

      if (visitorType != null) params['visitor_type'] = visitorType;
      if (action != null) params['action'] = action;
      if (guardId != null) params['guard_id'] = guardId;
      if (residentId != null) params['resident_id'] = residentId;
      if (fromDate != null) params['from_date'] = fromDate;
      if (toDate != null) params['to_date'] = toDate;
      if (search != null) params['search'] = search;

      final response = await _apiService.get(
        '/admin/logs/activity${_buildQueryString(params)}',
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to fetch admin logs: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching admin logs: $e');
    }
  }

  /// Get guard's activity logs
  Future<Map<String, dynamic>> getGuardLogs({
    String? visitorType,
    String? action,
    String? fromDate,
    String? toDate,
    String? search,
    int perPage = 20,
    int page = 1,
  }) async {
    try {
      final params = <String, dynamic>{
        'per_page': perPage,
        'page': page,
      };

      if (visitorType != null) params['visitor_type'] = visitorType;
      if (action != null) params['action'] = action;
      if (fromDate != null) params['from_date'] = fromDate;
      if (toDate != null) params['to_date'] = toDate;
      if (search != null) params['search'] = search;

      final response = await _apiService.get(
        '/guard/activity-logs${_buildQueryString(params)}',
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to fetch guard logs: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching guard logs: $e');
    }
  }

  /// Get activity statistics for admin dashboard
  Future<Map<String, dynamic>> getStatistics() async {
    try {
      final response = await _apiService.get('/admin/logs/statistics');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to fetch statistics: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching statistics: $e');
    }
  }

  /// Export logs as CSV
  Future<String> exportLogs({
    String? visitorType,
    String? action,
    String? fromDate,
    String? toDate,
  }) async {
    try {
      final params = <String, dynamic>{};

      if (visitorType != null) params['visitor_type'] = visitorType;
      if (action != null) params['action'] = action;
      if (fromDate != null) params['from_date'] = fromDate;
      if (toDate != null) params['to_date'] = toDate;

      final response = await _apiService.get(
        '/admin/logs/export${_buildQueryString(params)}',
      );

      if (response.statusCode == 200) {
        return response.body;
      } else {
        throw Exception('Failed to export logs: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error exporting logs: $e');
    }
  }
}
