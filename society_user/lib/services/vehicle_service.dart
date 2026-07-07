import 'dart:convert';
import 'api_service.dart';

class VehicleService {
  final ApiService _apiService = ApiService();

  Future<List<dynamic>> getVehicles() async {
    final response = await _apiService.get('/my-vehicles');
    if (response.statusCode == 200) {
      return jsonDecode(response.body)['vehicles'] ?? [];
    } else {
      throw Exception('Failed to load vehicles');
    }
  }

  Future<Map<String, dynamic>> addVehicle(Map<String, dynamic> data) async {
    final response = await _apiService.post('/my-vehicles', data);
    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body)['vehicle'] ?? jsonDecode(response.body);
    } else {
      throw Exception('Failed to add vehicle');
    }
  }
}
