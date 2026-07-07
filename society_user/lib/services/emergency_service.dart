import 'dart:convert';
import 'api_service.dart';
import '../core/constants/api_constants.dart';

class EmergencyService {
  final ApiService _apiService = ApiService();

  Future<List<dynamic>> getSupportContacts(int buildingId) async {
    final response = await _apiService.get(
      '${ApiConstants.emergency}?building_id=$buildingId',
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body)['alerts'] ?? [];
    } else {
      throw Exception('Failed to load support contacts');
    }
  }

  Future<bool> triggerSos(String type, String message) async {
    final response = await _apiService.post(ApiConstants.emergencySos, {
      'type': type,
      'message': message,
      'latitude': '0.0', // Mocked if not available
      'longitude': '0.0',
    });
    return response.statusCode == 200 || response.statusCode == 201;
  }
}
