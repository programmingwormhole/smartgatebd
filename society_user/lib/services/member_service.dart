import 'dart:convert';
import 'api_service.dart';

class MemberService {
  final ApiService _apiService = ApiService();

  Future<List<dynamic>> getMembers() async {
    final response = await _apiService.get('/members');
    if (response.statusCode == 200) {
      return jsonDecode(response.body)['members'] ?? [];
    } else {
      throw Exception('Failed to load members');
    }
  }
}
