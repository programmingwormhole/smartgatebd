import 'dart:convert';
import 'api_service.dart';
import '../core/constants/api_constants.dart';

class ComplaintService {
  final ApiService _apiService = ApiService();

  Future<List<dynamic>> getComplaints({String? status}) async {
    final endpoint = status == null || status.isEmpty
        ? ApiConstants.complaints
        : '${ApiConstants.complaints}?status=$status';

    final response = await _apiService.get(endpoint);
    if (response.statusCode == 200) {
      return jsonDecode(response.body)['complaints'] ?? [];
    } else {
      throw Exception('Failed to load complaints');
    }
  }

  Future<Map<String, dynamic>> raiseComplaint(Map<String, dynamic> data) async {
    final response = await _apiService.post(ApiConstants.complaints, data);
    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to raise complaint');
    }
  }
}
