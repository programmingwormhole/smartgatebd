import 'dart:convert';
import 'api_service.dart';

class DailyHelpService {
  final ApiService _apiService = ApiService();

  Future<List<dynamic>> getDailyHelp() async {
    final response = await _apiService.get('/my-daily-help');
    if (response.statusCode == 200) {
      return jsonDecode(response.body)['daily_helps'] ?? [];
    } else {
      throw Exception('Failed to load daily help');
    }
  }

  Future<Map<String, dynamic>> addDailyHelp(Map<String, dynamic> data) async {
    final response = await _apiService.post('/my-daily-help', data);
    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body)['daily_help'] ??
          jsonDecode(response.body);
    } else {
      throw Exception('Failed to add daily help');
    }
  }

  Future<Map<String, dynamic>> updateDailyHelp(
    int dailyHelpId,
    Map<String, dynamic> data,
  ) async {
    final response = await _apiService.put('/daily-help/$dailyHelpId', data);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to update daily help');
    }
  }
}
