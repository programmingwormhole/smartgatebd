import 'dart:convert';
import 'api_service.dart';

class FamilyService {
  final ApiService _apiService = ApiService();

  Future<List<dynamic>> getFamilyMembers() async {
    final response = await _apiService.get('/my-family');
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    } else {
      throw Exception('Failed to load family members');
    }
  }

  Future<Map<String, dynamic>> addFamilyMember(
    Map<String, dynamic> data,
  ) async {
    final response = await _apiService.post('/my-family', data);
    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to add family member');
    }
  }

  Future<Map<String, dynamic>> updateFamilyMember(
    int familyId,
    Map<String, dynamic> data,
  ) async {
    final response = await _apiService.put('/family/$familyId', data);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to update family member');
    }
  }
}
