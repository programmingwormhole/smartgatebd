import 'dart:convert';
import 'api_service.dart';

class NoticeService {
  final ApiService _apiService = ApiService();

  Future<List<dynamic>> getNotices(int buildingId) async {
    final response = await _apiService.get('/buildings/$buildingId/notices');
    if (response.statusCode == 200) {
      return jsonDecode(response.body)['notices'] ?? [];
    } else {
      throw Exception('Failed to load notices');
    }
  }

  Future<bool> createNotice(int buildingId, Map<String, dynamic> data) async {
    final response = await _apiService.post('/buildings/$buildingId/notices', data);
    return response.statusCode == 201;
  }

  Future<bool> updateNotice(int noticeId, Map<String, dynamic> data) async {
    final response = await _apiService.put('/notices/$noticeId', data);
    return response.statusCode == 200;
  }

  Future<bool> deleteNotice(int noticeId) async {
    final response = await _apiService.delete('/notices/$noticeId');
    return response.statusCode == 200;
  }
}
