import 'dart:convert';
import 'api_service.dart';

class NotificationApiService {
  final ApiService _apiService = ApiService();

  // Get all notifications
  Future<Map<String, dynamic>> getNotifications({int page = 1}) async {
    final response = await _apiService.get('/notifications?page=$page');
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load notifications');
    }
  }

  // Get unread notification count
  Future<int> getUnreadCount() async {
    try {
      final response = await _apiService.get('/notifications/unread-count');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['unread_count'] ?? 0;
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  // Mark notification as read
  Future<Map<String, dynamic>> markAsRead(int notificationId) async {
    final response = await _apiService.post(
      '/notifications/$notificationId/read',
      {},
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to mark notification as read');
    }
  }

  // Mark all as read
  Future<Map<String, dynamic>> markAllAsRead() async {
    final response = await _apiService.post('/notifications/read-all', {});
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to mark all as read');
    }
  }

  // Delete notification
  Future<Map<String, dynamic>> deleteNotification(int notificationId) async {
    final response = await _apiService.delete('/notifications/$notificationId');
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to delete notification');
    }
  }
}
