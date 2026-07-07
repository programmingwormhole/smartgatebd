import 'dart:convert';
import 'api_service.dart';

class PaymentGatewayService {
  final ApiService _apiService = ApiService();

  // Get all payment gateways for admin
  Future<List<dynamic>> getPaymentGateways() async {
    final response = await _apiService.get('/payment-gateways');
    if (response.statusCode == 200) {
      return jsonDecode(response.body)['gateways'] ?? [];
    } else {
      throw Exception('Failed to load payment gateways');
    }
  }

  // Create payment gateway
  Future<Map<String, dynamic>> createPaymentGateway(
    Map<String, dynamic> data,
  ) async {
    final response = await _apiService.post('/payment-gateways', data);
    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Failed to create payment gateway');
    }
  }

  // Update payment gateway
  Future<Map<String, dynamic>> updatePaymentGateway(
    int gatewayId,
    Map<String, dynamic> data,
  ) async {
    final response =
        await _apiService.put('/payment-gateways/$gatewayId', data);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Failed to update payment gateway');
    }
  }

  // Delete payment gateway
  Future<void> deletePaymentGateway(int gatewayId) async {
    final response = await _apiService.delete('/payment-gateways/$gatewayId');
    if (response.statusCode != 200 && response.statusCode != 204) {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Failed to delete payment gateway');
    }
  }
}
