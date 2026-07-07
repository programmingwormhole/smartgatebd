import 'dart:convert';
import 'api_service.dart';
import '../core/constants/api_constants.dart';

class VisitorService {
  final ApiService _apiService = ApiService();

  Future<List<dynamic>> getVisitorHistory() async {
    final response = await _apiService.get('/my-visitors');

    if (response.statusCode == 200) {
      return jsonDecode(response.body)['visitors'] ?? [];
    } else {
      throw Exception('Failed to load visitor history');
    }
  }

  Future<Map<String, dynamic>> preApproveVisitor(
    Map<String, dynamic> data,
  ) async {
    final response = await _apiService.post(ApiConstants.visitors, data);
    // print(response.body);
    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to pre-approve visitor');
    }
  }

  Future<Map<String, dynamic>> getGatepass(int visitorId) async {
    final endpoint = ApiConstants.visitorGatepass.replaceAll(
      '{id}',
      visitorId.toString(),
    );
    final response = await _apiService.get(endpoint);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to get gatepass');
    }
  }

  Future<void> deleteVisitor(dynamic id) async {
    final response = await _apiService.delete('${ApiConstants.visitors}/$id');
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete visitor');
    }
  }

  Future<Map<String, dynamic>> approveVisitor(int visitorId) async {
    final response = await _apiService.put('/visitors/$visitorId/approve', {});
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to approve visitor');
  }

  Future<Map<String, dynamic>> rejectVisitor(
    int visitorId, {
    required String reason,
  }) async {
    final response = await _apiService.put('/visitors/$visitorId/reject', {
      'reason': reason,
    });
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to reject visitor');
  }
}
