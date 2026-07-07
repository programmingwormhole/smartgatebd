import 'dart:convert';
import 'api_service.dart';

class GuardService {
  final ApiService _apiService = ApiService();

  /// Get visitor details by entry code (gatepass)
  Future<Map<String, dynamic>> getVisitorByEntryCode(String entryCode) async {
    try {
      final response = await _apiService.get('/guard/verify?entry_code=$entryCode');
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body)['visitor'] ?? {};
      } else {
        throw Exception(jsonDecode(response.body)['message'] ?? 'Failed to verify entry code');
      }
    } catch (e) {
      throw Exception('Error verifying entry code: ${e.toString()}');
    }
  }

  /// Confirm visitor entry to building
  Future<bool> confirmVisitorEntry(int visitorId) async {
    try {
      final response = await _apiService.post(
        '/guard/visitors/$visitorId/confirm-entry',
        {},
      );
      
      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Error confirming visitor entry: ${e.toString()}');
    }
  }

  /// Mark visitor as exited from building
  Future<bool> markVisitorExit(int visitorId) async {
    try {
      final response = await _apiService.post(
        '/guard/visitors/$visitorId/mark-exit',
        {},
      );
      
      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Error marking visitor exit: ${e.toString()}');
    }
  }

  /// Get all currently inside visitors
  Future<List<Map<String, dynamic>>> getInsideVisitors() async {
    try {
      final response = await _apiService.get('/guard/visitors/inside');
      
      if (response.statusCode == 200) {
        final List<dynamic> visitors = jsonDecode(response.body)['visitors'] ?? [];
        return visitors.cast<Map<String, dynamic>>();
      } else {
        throw Exception(jsonDecode(response.body)['message'] ?? 'Failed to fetch inside visitors');
      }
    } catch (e) {
      throw Exception('Error fetching inside visitors: ${e.toString()}');
    }
  }

  /// Get all pending/waiting visitors
  Future<List<Map<String, dynamic>>> getPendingVisitors() async {
    try {
      final response = await _apiService.get('/guard/visitors/pending');
      
      if (response.statusCode == 200) {
        final List<dynamic> visitors = jsonDecode(response.body)['visitors'] ?? [];
        return visitors.cast<Map<String, dynamic>>();
      } else {
        throw Exception(jsonDecode(response.body)['message'] ?? 'Failed to fetch pending visitors');
      }
    } catch (e) {
      throw Exception('Error fetching pending visitors: ${e.toString()}');
    }
  }

  /// Get visitor history with logs
  Future<List<Map<String, dynamic>>> getVisitorHistory({int limit = 50}) async {
    try {
      final response = await _apiService.get('/guard/visitors/history?limit=$limit');
      
      if (response.statusCode == 200) {
        final List<dynamic> history = jsonDecode(response.body)['history'] ?? [];
        return history.cast<Map<String, dynamic>>();
      } else {
        throw Exception(jsonDecode(response.body)['message'] ?? 'Failed to fetch history');
      }
    } catch (e) {
      throw Exception('Error fetching visitor history: ${e.toString()}');
    }
  }

  /// Reject visitor entry with reason
  Future<bool> rejectVisitorEntry(int visitorId, String reason) async {
    try {
      final response = await _apiService.post(
        '/guard/visitors/$visitorId/reject',
        {'reason': reason},
      );
      
      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Error rejecting visitor: ${e.toString()}');
    }
  }

  Future<List<Map<String, dynamic>>> getBuildingResidents() async {
    try {
      final response = await _apiService.get('/members');

      if (response.statusCode == 200) {
        final List<dynamic> members = jsonDecode(response.body)['members'] ?? [];
        return members
            .where((m) {
              final role = (m['role'] ?? '').toString().toLowerCase();
              return role == 'resident' || role == 'member' || role == 'committee' || role == 'admin';
            })
            .map<Map<String, dynamic>>((m) => Map<String, dynamic>.from(m))
            .toList();
      }

      throw Exception(jsonDecode(response.body)['message'] ?? 'Failed to fetch residents');
    } catch (e) {
      throw Exception('Error fetching residents: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> createWalkInVisitor(Map<String, dynamic> data) async {
    try {
      final response = await _apiService.post('/guard/walk-in-visitors', data);

      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      }

      throw Exception(jsonDecode(response.body)['message'] ?? 'Failed to add walk-in visitor');
    } catch (e) {
      throw Exception('Error adding walk-in visitor: ${e.toString()}');
    }
  }

  Future<bool> markPermanentEntry({
    required String subjectType,
    required int subjectId,
    required String entryCode,
  }) async {
    try {
      final response = await _apiService.post('/guard/permanent/mark-entry', {
        'subject_type': subjectType,
        'subject_id': subjectId,
        'entry_code': entryCode,
      });

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Error logging permanent entry: ${e.toString()}');
    }
  }

  Future<bool> markPermanentExit({
    required String subjectType,
    required int subjectId,
    required String entryCode,
  }) async {
    try {
      final response = await _apiService.post('/guard/permanent/mark-exit', {
        'subject_type': subjectType,
        'subject_id': subjectId,
        'entry_code': entryCode,
      });

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Error logging permanent exit: ${e.toString()}');
    }
  }
}
