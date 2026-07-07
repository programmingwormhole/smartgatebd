import 'dart:convert';
import 'api_service.dart';

class PetService {
  final ApiService _apiService = ApiService();

  Future<List<dynamic>> getPets() async {
    final response = await _apiService.get('/my-pets');
    if (response.statusCode == 200) {
      return jsonDecode(response.body)['pets'] ?? [];
    } else {
      throw Exception('Failed to load pets');
    }
  }

  Future<Map<String, dynamic>> addPet(Map<String, dynamic> data) async {
    final response = await _apiService.post('/my-pets', data);
    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body)['pet'] ?? jsonDecode(response.body);
    } else {
      throw Exception('Failed to add pet');
    }
  }
}
