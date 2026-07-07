import 'dart:convert';
import 'api_service.dart';
import '../core/constants/api_constants.dart';

class AmenityService {
  final ApiService _apiService = ApiService();

  Future<List<dynamic>> getAmenities(int buildingId) async {
    final response = await _apiService.get('/buildings/$buildingId/amenities');
    if (response.statusCode == 200) {
      return jsonDecode(response.body)['amenities'] ?? [];
    } else {
      throw Exception('Failed to load amenities');
    }
  }

  Future<List<dynamic>> getAmenityBookings() async {
    final response = await _apiService.get(ApiConstants.amenityBookings);
    if (response.statusCode == 200) {
      return jsonDecode(response.body)['bookings'] ?? [];
    } else {
      throw Exception('Failed to load bookings');
    }
  }

  Future<List<dynamic>> getSlots(int amenityId, String date) async {
    final response = await _apiService.get(
      '/amenities/$amenityId/slots?date=$date',
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body)['slots'] ?? [];
    } else {
      throw Exception('Failed to load slots');
    }
  }

  Future<Map<String, dynamic>> bookAmenity(
    int amenityId,
    Map<String, dynamic> data,
  ) async {
    final response = await _apiService.post('/amenities/$amenityId/book', data);
    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to book amenity');
    }
  }

  Future<Map<String, dynamic>> createAmenity(
    int buildingId,
    Map<String, dynamic> data,
  ) async {
    final response = await _apiService.post(
      '/buildings/$buildingId/amenities',
      data,
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to create amenity');
    }
  }

  Future<Map<String, dynamic>> updateAmenity(
    int amenityId,
    Map<String, dynamic> data,
  ) async {
    final response = await _apiService.put('/amenities/$amenityId', data);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to update amenity');
    }
  }

  Future<void> deleteAmenity(int amenityId) async {
    final response = await _apiService.delete('/amenities/$amenityId');
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete amenity');
    }
  }
}
