import 'dart:convert';
import 'api_service.dart';

class BillApiService {
  final ApiService _apiService = ApiService();

  // Get all bills for the building
  Future<Map<String, dynamic>> getBills({int page = 1}) async {
    final response = await _apiService.get('/admin/bills?page=$page');
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load bills');
    }
  }

  // Get bill details with statistics
  Future<Map<String, dynamic>> getBillDetails(int billId) async {
    final response = await _apiService.get('/admin/bills/$billId');
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load bill details');
    }
  }
}
