import 'dart:convert';
import 'api_service.dart';

class BillService {
  final ApiService _apiService = ApiService();

  Future<List<dynamic>> getBills() async {
    final response = await _apiService.get('/my-bills');
    if (response.statusCode == 200) {
      return jsonDecode(response.body)['bills'] ?? [];
    } else {
      throw Exception('Failed to load bills');
    }
  }

  Future<List<dynamic>> getPaymentGateways(int buildingId) async {
    final response = await _apiService.get(
      '/buildings/$buildingId/payment-gateways',
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body)['gateways'] ?? [];
    } else {
      throw Exception('Failed to load payment gateways');
    }
  }

  Future<bool> payBillManual({
    required int billId,
    required double amount,
    int? gatewayId,
    String? trxId,
    required String method,
    String? notes,
  }) async {
    final payload = <String, dynamic>{
      'amount': amount.toString(),
      'method': method,
      if (gatewayId != null) 'payment_gateway_id': gatewayId.toString(),
      if (trxId != null) 'trx_id': trxId,
      if (notes != null) 'notes': notes,
    };

    final response = await _apiService.post(
      '/bills/$billId/pay',
      payload,
    );
    return response.statusCode == 201;
  }
}
