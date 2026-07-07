import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import '../core/constants/api_constants.dart';
import 'auth_service.dart';

class AdminService {
  final AuthService _authService = AuthService();

  Future<Map<String, dynamic>> getDashboardStats() async {
    final token = await _authService.getToken();
    final url = Uri.parse('${ApiConstants.baseUrl}/admin/dashboard/stats');

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    _logResponse(url.toString(), response);

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      return decoded['stats'] ?? {};
    } else {
      throw Exception('Failed to load dashboard stats');
    }
  }

  Future<List<dynamic>> getPendingPayments() async {
    final token = await _authService.getToken();
    final url = Uri.parse('${ApiConstants.baseUrl}/admin/payments/pending');

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    _logResponse(url.toString(), response);

    if (response.statusCode == 200) {
      return jsonDecode(response.body)['payments'] ?? [];
    } else {
      throw Exception('Failed to load pending payments');
    }
  }

  Future<bool> approvePayment(int paymentId) async {
    final token = await _authService.getToken();
    final url = Uri.parse(
      '${ApiConstants.baseUrl}/admin/payments/$paymentId/approve',
    );

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    _logResponse(url.toString(), response);

    return response.statusCode == 200;
  }

  Future<bool> markBillAsPaid(int billId, {String? note}) async {
    final token = await _authService.getToken();
    final url = Uri.parse(
      '${ApiConstants.baseUrl}/admin/bills/$billId/mark-paid',
    );

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
      }),
    );

    _logResponse(url.toString(), response);

    return response.statusCode == 200;
  }

  Future<bool> rejectPayment(int paymentId, String reason) async {
    final token = await _authService.getToken();
    final url = Uri.parse(
      '${ApiConstants.baseUrl}/admin/payments/$paymentId/reject',
    );

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'rejection_reason': reason}),
    );

    _logResponse(url.toString(), response);

    return response.statusCode == 200;
  }

  Future<List<dynamic>> getBuildingMembers({int? buildingId}) async {
    final token = await _authService.getToken();
    final url = Uri.parse('${ApiConstants.baseUrl}/members').replace(
      queryParameters: {
        if (buildingId != null) 'building_id': buildingId.toString(),
      },
    );

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    _logResponse(url.toString(), response);

    if (response.statusCode == 200) {
      return jsonDecode(response.body)['members'] ?? [];
    } else {
      throw Exception('Failed to load building members');
    }
  }

  Future<List<dynamic>> getFlatBills(int flatId) async {
    final token = await _authService.getToken();
    final url = Uri.parse('${ApiConstants.baseUrl}/flats/$flatId/bills');

    final response = await http.get(url, headers: _headers(token));

    _logResponse(url.toString(), response);

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded is List) return decoded;
      return decoded['bills'] ?? [];
    }

    throw Exception('Failed to load flat bills');
  }

  Future<List<dynamic>> getResidentFamilyMembers(int residentId) async {
    final token = await _authService.getToken();
    final url = Uri.parse(
      '${ApiConstants.baseUrl}/residents/$residentId/family',
    );

    final response = await http.get(url, headers: _headers(token));

    _logResponse(url.toString(), response);

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded is List) return decoded;
      return decoded['family'] ?? decoded['members'] ?? [];
    }

    throw Exception('Failed to load resident family members');
  }

  Future<List<dynamic>> getResidentVehicles(int residentId) async {
    final token = await _authService.getToken();
    final url = Uri.parse(
      '${ApiConstants.baseUrl}/residents/$residentId/vehicles',
    );

    final response = await http.get(url, headers: _headers(token));

    _logResponse(url.toString(), response);

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded is List) return decoded;
      return decoded['vehicles'] ?? [];
    }

    throw Exception('Failed to load resident vehicles');
  }

  Future<bool> generateBulkBills(Map<String, dynamic> data) async {
    final token = await _authService.getToken();
    final url = Uri.parse('${ApiConstants.baseUrl}/admin/bills/bulk-generate');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    );

    _logResponse(url.toString(), response);

    return response.statusCode == 201;
  }

  Future<bool> addResident(int buildingId, Map<String, dynamic> data) async {
    final token = await _authService.getToken();
    final url = Uri.parse(
      '${ApiConstants.baseUrl}/buildings/$buildingId/residents',
    );

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    );

    _logResponse(url.toString(), response);

    if (response.statusCode != 201) {
      Get.snackbar(
        'Error',
        'Failed to add resident: ${jsonDecode(response.body)['message'] ?? 'Unknown error'}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }

    return response.statusCode == 201;
  }

  Future<bool> updateResident(int residentId, Map<String, dynamic> data) async {
    final token = await _authService.getToken();
    final url = Uri.parse('${ApiConstants.baseUrl}/residents/$residentId');

    final response = await http.put(
      url,
      headers: _headers(token),
      body: jsonEncode(data),
    );

    _logResponse(url.toString(), response);

    if (response.statusCode != 200) {
      Get.snackbar(
        'Error',
        'Failed to update resident: ${jsonDecode(response.body)['message'] ?? 'Unknown error'}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }

    return response.statusCode == 200;
  }

  Future<bool> deleteResident(int residentId) async {
    final token = await _authService.getToken();
    final url = Uri.parse('${ApiConstants.baseUrl}/residents/$residentId');

    final response = await http.delete(url, headers: _headers(token));

    _logResponse(url.toString(), response);

    if (response.statusCode != 200) {
      Get.snackbar(
        'Error',
        'Failed to delete resident: ${jsonDecode(response.body)['message'] ?? 'Unknown error'}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }

    return response.statusCode == 200;
  }

  Future<List<dynamic>> getAmenityRequests() async {
    final token = await _authService.getToken();
    final url = Uri.parse('${ApiConstants.baseUrl}/admin/requests/amenities');

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    _logResponse(url.toString(), response);

    if (response.statusCode == 200) {
      return jsonDecode(response.body)['bookings'] ?? [];
    } else {
      throw Exception('Failed to load amenity requests');
    }
  }

  Future<List<dynamic>> getServiceRequests() async {
    final token = await _authService.getToken();
    final url = Uri.parse('${ApiConstants.baseUrl}/admin/requests/services');

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    _logResponse(url.toString(), response);

    if (response.statusCode == 200) {
      return jsonDecode(response.body)['bookings'] ?? [];
    } else {
      throw Exception('Failed to load service requests');
    }
  }

  // Get all buildings (for superadmin building selection)
  Future<List<dynamic>> getAllBuildings() async {
    final token = await _authService.getToken();
    final url = Uri.parse('${ApiConstants.baseUrl}/buildings');

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    _logResponse(url.toString(), response);

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      return decoded['data'] ?? decoded['buildings'] ?? [];
    } else {
      throw Exception('Failed to load buildings');
    }
  }

  void _logResponse(String url, http.Response response) {
    debugPrint('--- API Response ---');
    debugPrint('URL: $url');
    debugPrint('Status: ${response.statusCode}');
    debugPrint('Body: ${response.body}');
    debugPrint('--------------------');
  }

  Future<bool> updateAmenityRequestStatus(
    int bookingId,
    String status, {
    String? rejectionReason,
    String? adminComment,
  }) async {
    final token = await _authService.getToken();
    final url = Uri.parse(
      '${ApiConstants.baseUrl}/admin/requests/amenities/$bookingId/status',
    );

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'status': status.toLowerCase(),
        if (rejectionReason != null && rejectionReason.trim().isNotEmpty)
          'rejection_reason': rejectionReason.trim(),
        if (adminComment != null && adminComment.trim().isNotEmpty)
          'admin_comment': adminComment.trim(),
      }),
    );

    _logResponse(url.toString(), response);

    return response.statusCode == 200;
  }

  Future<bool> updateServiceRequestStatus(
    int bookingId,
    String status, {
    String? rejectionReason,
    String? adminComment,
  }) async {
    final token = await _authService.getToken();
    final url = Uri.parse(
      '${ApiConstants.baseUrl}/admin/requests/services/$bookingId/status',
    );

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'status': status.toLowerCase(),
        if (rejectionReason != null && rejectionReason.trim().isNotEmpty)
          'rejection_reason': rejectionReason.trim(),
        if (adminComment != null && adminComment.trim().isNotEmpty)
          'admin_comment': adminComment.trim(),
      }),
    );

    _logResponse(url.toString(), response);

    return response.statusCode == 200;
  }

  Future<List<dynamic>> getComplaintRequests({int? buildingId}) async {
    final token = await _authService.getToken();
    final url = Uri.parse('${ApiConstants.baseUrl}/admin/complaints').replace(
      queryParameters: {
        if (buildingId != null) 'building_id': buildingId.toString(),
      },
    );

    final response = await http.get(url, headers: _headers(token));
    _logResponse(url.toString(), response);

    if (response.statusCode == 200) {
      return jsonDecode(response.body)['complaints'] ?? [];
    }

    throw Exception('Failed to load complaint requests');
  }

  Future<bool> updateComplaintStatus(int complaintId, String status) async {
    final token = await _authService.getToken();
    final url = Uri.parse(
      '${ApiConstants.baseUrl}/complaints/$complaintId/status',
    );

    final response = await http.put(
      url,
      headers: _headers(token),
      body: jsonEncode({'status': status}),
    );
    _logResponse(url.toString(), response);

    return response.statusCode == 200;
  }

  Future<bool> updateResidentRole(int residentId, String role) async {
    final token = await _authService.getToken();
    final url = Uri.parse('${ApiConstants.baseUrl}/residents/$residentId');

    final response = await http.put(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'role': role}),
    );

    _logResponse(url.toString(), response);

    return response.statusCode == 200;
  }

  Future<List<dynamic>> getGuards(int buildingId) async {
    final token = await _authService.getToken();
    final url = Uri.parse(
      '${ApiConstants.baseUrl}/buildings/$buildingId/guards',
    );

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    _logResponse(url.toString(), response);

    if (response.statusCode == 200) {
      return jsonDecode(response.body)['guards'] ?? [];
    }
    return [];
  }

  Future<bool> createGuard(int buildingId, Map<String, dynamic> data) async {
    final token = await _authService.getToken();
    final url = Uri.parse(
      '${ApiConstants.baseUrl}/buildings/$buildingId/guards',
    );

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    );

    _logResponse(url.toString(), response);
    if (response.statusCode != 201) {
      try {
        final decoded = jsonDecode(response.body);
        final message = decoded['message'] ?? 'Failed to create guard';
        Get.snackbar(
          'Error',
          message.toString(),
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      } catch (_) {}
    }

    return response.statusCode == 201;
  }

  Future<bool> updateGuard(int guardId, Map<String, dynamic> data) async {
    final token = await _authService.getToken();
    final url = Uri.parse('${ApiConstants.baseUrl}/guards/$guardId');

    final response = await http.put(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    );

    _logResponse(url.toString(), response);
    if (response.statusCode != 200) {
      try {
        final decoded = jsonDecode(response.body);
        final message = decoded['message'] ?? 'Failed to update guard';
        Get.snackbar(
          'Error',
          message.toString(),
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      } catch (_) {}
    }

    return response.statusCode == 200;
  }

  Future<bool> deleteGuard(int guardId) async {
    final token = await _authService.getToken();
    final url = Uri.parse('${ApiConstants.baseUrl}/guards/$guardId');

    final response = await http.delete(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    _logResponse(url.toString(), response);

    return response.statusCode == 200;
  }

  Future<bool> updateGuardStatus(int guardId, String statusValue) async {
    final token = await _authService.getToken();
    final url = Uri.parse('${ApiConstants.baseUrl}/guards/$guardId/status');

    final response = await http.put(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'status': statusValue}),
    );

    _logResponse(url.toString(), response);

    return response.statusCode == 200;
  }

  Future<Map<String, dynamic>> getBuildingStructure(int buildingId) async {
    final token = await _authService.getToken();
    final url = Uri.parse(
      '${ApiConstants.baseUrl}/buildings/$buildingId/structure',
    );

    final response = await http.get(url, headers: _headers(token));

    _logResponse(url.toString(), response);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return {};
  }

  // Block CRUD
  Future<bool> createBlock(int buildingId, String name) async {
    final token = await _authService.getToken();
    final url = Uri.parse(
      '${ApiConstants.baseUrl}/buildings/$buildingId/blocks',
    );
    final response = await http.post(
      url,
      headers: _headers(token),
      body: jsonEncode({'name': name}),
    );
    _logResponse(url.toString(), response);
    if (response.statusCode != 201) {
      try {
        final decoded = jsonDecode(response.body);
        final message =
            decoded['message']?.toString() ?? 'Failed to create block';
        Get.snackbar(
          'Error',
          message,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      } catch (_) {
        Get.snackbar(
          'Error',
          'Failed to create block',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    }
    return response.statusCode == 201;
  }

  Future<bool> updateBlock(int blockId, String name) async {
    final token = await _authService.getToken();
    final url = Uri.parse('${ApiConstants.baseUrl}/blocks/$blockId');
    final response = await http.put(
      url,
      headers: _headers(token),
      body: jsonEncode({'name': name}),
    );
    _logResponse(url.toString(), response);
    return response.statusCode == 200;
  }

  Future<bool> deleteBlock(int blockId) async {
    final token = await _authService.getToken();
    final url = Uri.parse('${ApiConstants.baseUrl}/blocks/$blockId');
    final response = await http.delete(url, headers: _headers(token));
    _logResponse(url.toString(), response);
    return response.statusCode == 200;
  }

  // Floor CRUD
  Future<bool> createFloor(int blockId, String floorNumber) async {
    final token = await _authService.getToken();
    final url = Uri.parse('${ApiConstants.baseUrl}/blocks/$blockId/floors');
    final response = await http.post(
      url,
      headers: _headers(token),
      body: jsonEncode({'floor_number': floorNumber}),
    );
    _logResponse(url.toString(), response);
    return response.statusCode == 201;
  }

  Future<bool> updateFloor(int floorId, String floorNumber) async {
    final token = await _authService.getToken();
    final url = Uri.parse('${ApiConstants.baseUrl}/floors/$floorId');
    final response = await http.put(
      url,
      headers: _headers(token),
      body: jsonEncode({'floor_number': floorNumber}),
    );
    _logResponse(url.toString(), response);
    return response.statusCode == 200;
  }

  Future<bool> deleteFloor(int floorId) async {
    final token = await _authService.getToken();
    final url = Uri.parse('${ApiConstants.baseUrl}/floors/$floorId');
    final response = await http.delete(url, headers: _headers(token));
    _logResponse(url.toString(), response);
    return response.statusCode == 200;
  }

  // Flat CRUD
  Future<bool> createFlat(int floorId, String flatNumber) async {
    final token = await _authService.getToken();
    final url = Uri.parse('${ApiConstants.baseUrl}/floors/$floorId/flats');
    final response = await http.post(
      url,
      headers: _headers(token),
      body: jsonEncode({'flat_number': flatNumber}),
    );
    _logResponse(url.toString(), response);
    return response.statusCode == 201;
  }

  Future<bool> updateFlat(int flatId, String flatNumber) async {
    final token = await _authService.getToken();
    final url = Uri.parse('${ApiConstants.baseUrl}/flats/$flatId');
    final response = await http.put(
      url,
      headers: _headers(token),
      body: jsonEncode({'flat_number': flatNumber}),
    );
    _logResponse(url.toString(), response);
    return response.statusCode == 200;
  }

  Future<bool> deleteFlat(int flatId) async {
    final token = await _authService.getToken();
    final url = Uri.parse('${ApiConstants.baseUrl}/flats/$flatId');
    final response = await http.delete(url, headers: _headers(token));
    _logResponse(url.toString(), response);
    return response.statusCode == 200;
  }

  // =====================================================================
  // SUPERADMIN GUARD MANAGEMENT
  // =====================================================================

  /// Get all guards across all buildings
  Future<Map<String, dynamic>> getAllGuards({
    int page = 1,
    String? status,
    String? search,
  }) async {
    final token = await _authService.getToken();
    final queryParams = {
      'page': page.toString(),
      if (status != null) 'status': status,
      if (search != null) 'search': search,
    };

    final url = Uri.parse(
      '${ApiConstants.baseUrl}/admin/guards/all',
    ).replace(queryParameters: queryParams);

    final response = await http.get(url, headers: _headers(token));
    _logResponse(url.toString(), response);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load guards');
    }
  }

  /// Get guards for a specific building
  Future<List<dynamic>> getGuardsByBuilding(
    int buildingId, {
    String? status,
  }) async {
    final token = await _authService.getToken();
    final queryParams = {if (status != null) 'status': status};

    final url = Uri.parse(
      '${ApiConstants.baseUrl}/admin/guards/building/$buildingId',
    ).replace(queryParameters: queryParams);

    final response = await http.get(url, headers: _headers(token));
    _logResponse(url.toString(), response);

    if (response.statusCode == 200) {
      return jsonDecode(response.body)['guards'] ?? [];
    } else {
      throw Exception('Failed to load guards');
    }
  }

  /// Get guards by status (superadmin view)
  Future<Map<String, dynamic>> getGuardsByStatus(
    String status, {
    int page = 1,
  }) async {
    final token = await _authService.getToken();
    final url = Uri.parse(
      '${ApiConstants.baseUrl}/admin/guards/status/$status',
    ).replace(queryParameters: {'page': page.toString()});

    final response = await http.get(url, headers: _headers(token));
    _logResponse(url.toString(), response);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load guards');
    }
  }

  /// Get guard statistics
  Future<Map<String, dynamic>> getGuardStatistics({int? buildingId}) async {
    final token = await _authService.getToken();
    final queryParams = {
      if (buildingId != null) 'building_id': buildingId.toString(),
    };

    final url = Uri.parse(
      '${ApiConstants.baseUrl}/admin/guards/statistics',
    ).replace(queryParameters: queryParams);

    final response = await http.get(url, headers: _headers(token));
    _logResponse(url.toString(), response);

    if (response.statusCode == 200) {
      return jsonDecode(response.body)['statistics'] ?? {};
    } else {
      throw Exception('Failed to load statistics');
    }
  }

  /// Create a guard (superadmin)
  Future<bool> createGuardSuperadmin(
    int buildingId,
    String name,
    String phone, {
    String? email,
    String? status,
  }) async {
    final token = await _authService.getToken();
    final url = Uri.parse('${ApiConstants.baseUrl}/admin/guards');

    final body = {
      'building_id': buildingId,
      'name': name,
      'phone': phone,
      if (email != null) 'email': email,
      if (status != null) 'status': status,
    };

    final response = await http.post(
      url,
      headers: _headers(token),
      body: jsonEncode(body),
    );

    _logResponse(url.toString(), response);
    return response.statusCode == 201;
  }

  /// Update a guard (superadmin)
  Future<bool> updateGuardSuperadmin(
    int guardId, {
    String? name,
    String? phone,
    String? email,
    String? status,
    String? notes,
  }) async {
    final token = await _authService.getToken();
    final url = Uri.parse('${ApiConstants.baseUrl}/admin/guards/$guardId');

    final body = {
      if (name != null) 'name': name,
      if (phone != null) 'phone': phone,
      if (email != null) 'email': email,
      if (status != null) 'status': status,
      if (notes != null) 'notes': notes,
    };

    final response = await http.put(
      url,
      headers: _headers(token),
      body: jsonEncode(body),
    );

    _logResponse(url.toString(), response);
    return response.statusCode == 200;
  }

  /// Update guard status (superadmin)
  Future<bool> updateGuardStatusSuperadmin(int guardId, String status) async {
    final token = await _authService.getToken();
    final url = Uri.parse(
      '${ApiConstants.baseUrl}/admin/guards/$guardId/status',
    );

    final response = await http.put(
      url,
      headers: _headers(token),
      body: jsonEncode({'status': status}),
    );

    _logResponse(url.toString(), response);
    return response.statusCode == 200;
  }

  /// Delete a guard (superadmin)
  Future<bool> deleteGuardSuperadmin(int guardId) async {
    final token = await _authService.getToken();
    final url = Uri.parse('${ApiConstants.baseUrl}/admin/guards/$guardId');

    final response = await http.delete(url, headers: _headers(token));
    _logResponse(url.toString(), response);
    return response.statusCode == 200;
  }

  Map<String, String> _headers(String? token) => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    if (token != null) 'Authorization': 'Bearer $token',
  };
}
