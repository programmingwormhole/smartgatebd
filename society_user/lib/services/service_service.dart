import 'dart:convert';
import 'package:get/get.dart';
import 'api_service.dart';
import '../core/constants/api_constants.dart';
import '../controllers/auth_controller.dart';

class ServiceService {
  final ApiService _apiService = ApiService();

  int? _getBuildingId() {
    return Get.find<AuthController>().user?.buildingId;
  }

  Future<List<dynamic>> getServices(int buildingId) async {
    final response = await _apiService.get('/buildings/$buildingId/services');
    if (response.statusCode == 200) {
      return jsonDecode(response.body)['services'] ?? [];
    } else {
      throw Exception('Failed to load services');
    }
  }

  Future<List<dynamic>> getServiceBookings() async {
    final response = await _apiService.get(ApiConstants.serviceBookings);
    if (response.statusCode == 200) {
      return jsonDecode(response.body)['bookings'] ?? [];
    } else {
      throw Exception('Failed to load service bookings');
    }
  }

  Future<Map<String, dynamic>> bookService(Map<String, dynamic> data) async {
    final response = await _apiService.post(ApiConstants.serviceBookings, data);
    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body)['booking'] ?? jsonDecode(response.body);
    } else {
      throw Exception('Failed to book service');
    }
  }

  Future<Map<String, dynamic>> createService(Map<String, dynamic> data) async {
    final buildingId = _getBuildingId();
    if (buildingId == null) {
      throw Exception('Building ID not found');
    }
    final response =
        await _apiService.post('/buildings/$buildingId/services', data);
    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body)['service'] ?? jsonDecode(response.body);
    } else {
      throw Exception('Failed to create service');
    }
  }

  Future<Map<String, dynamic>> updateService(
    dynamic serviceId,
    Map<String, dynamic> data,
  ) async {
    final response = await _apiService.post('/services/$serviceId', data);
    if (response.statusCode == 200) {
      return jsonDecode(response.body)['service'] ?? jsonDecode(response.body);
    } else {
      throw Exception('Failed to update service');
    }
  }

  Future<void> deleteService(dynamic serviceId) async {
    final response = await _apiService.delete('/services/$serviceId');
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete service');
    }
  }
}
