import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/guard_service.dart';

class GuardController extends GetxController {
  final GuardService _service = GuardService();

  // Observable variables
  final RxBool isLoading = false.obs;
  final RxList<Map<String, dynamic>> insideVisitors = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> pendingVisitors = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> visitorHistory = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> buildingResidents = <Map<String, dynamic>>[].obs;
  final RxString errorMessage = ''.obs;
  final RxString selectedEntryCode = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchInsideVisitors();
    fetchPendingVisitors();
    fetchVisitorHistory();
  }

  /// Verify entry code and fetch visitor details
  Future<Map<String, dynamic>?> verifyEntryCode(String entryCode) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      selectedEntryCode.value = entryCode;
      
      final result = await _service.getVisitorByEntryCode(entryCode);
      isLoading.value = false;
      return result;
    } catch (e) {
      isLoading.value = false;
      errorMessage.value = e.toString().replaceAll('Exception: ', '');
      return null;
    }
  }

  /// Confirm visitor entry to building
  Future<bool> confirmVisitorEntry(int visitorId) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      
      final result = await _service.confirmVisitorEntry(visitorId);
      
      if (result) {
        // Refresh lists
        await fetchInsideVisitors();
        await fetchPendingVisitors();
        await fetchVisitorHistory();
      }
      
      isLoading.value = false;
      return result;
    } catch (e) {
      isLoading.value = false;
      errorMessage.value = e.toString().replaceAll('Exception: ', '');
      return false;
    }
  }

  /// Mark visitor as exited from building
  Future<bool> markVisitorExit(int visitorId) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      
      final result = await _service.markVisitorExit(visitorId);
      
      if (result) {
        // Refresh lists
        await fetchInsideVisitors();
        await fetchVisitorHistory();
      }
      
      isLoading.value = false;
      return result;
    } catch (e) {
      isLoading.value = false;
      errorMessage.value = e.toString().replaceAll('Exception: ', '');
      return false;
    }
  }

  Future<bool> markPermanentEntry({
    required String subjectType,
    required int subjectId,
    required String entryCode,
  }) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final result = await _service.markPermanentEntry(
        subjectType: subjectType,
        subjectId: subjectId,
        entryCode: entryCode,
      );

      // Defer state cleanup to avoid rebuild-during-disposal issues
      Future.delayed(const Duration(milliseconds: 100), () {
        if (isLoading.value) {
          isLoading.value = false;
        }
      });
      
      return result;
    } catch (e) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (isLoading.value) {
          isLoading.value = false;
        }
      });
      errorMessage.value = e.toString().replaceAll('Exception: ', '');
      return false;
    }
  }

  Future<bool> markPermanentExit({
    required String subjectType,
    required int subjectId,
    required String entryCode,
  }) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final result = await _service.markPermanentExit(
        subjectType: subjectType,
        subjectId: subjectId,
        entryCode: entryCode,
      );

      // Defer state cleanup to avoid rebuild-during-disposal issues
      Future.delayed(const Duration(milliseconds: 100), () {
        if (isLoading.value) {
          isLoading.value = false;
        }
      });
      
      return result;
    } catch (e) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (isLoading.value) {
          isLoading.value = false;
        }
      });
      errorMessage.value = e.toString().replaceAll('Exception: ', '');
      return false;
    }
  }

  /// Fetch all currently inside visitors
  Future<void> fetchInsideVisitors() async {
    try {
      isLoading.value = true;
      final visitors = await _service.getInsideVisitors();
      insideVisitors.assignAll(visitors);
      isLoading.value = false;
    } catch (e) {
      debugPrint('Error fetching inside visitors: $e');
      isLoading.value = false;
    }
  }

  /// Fetch all pending/waiting visitors
  Future<void> fetchPendingVisitors() async {
    try {
      isLoading.value = true;
      final visitors = await _service.getPendingVisitors();
      pendingVisitors.assignAll(visitors);
      isLoading.value = false;
    } catch (e) {
      debugPrint('Error fetching pending visitors: $e');
      isLoading.value = false;
    }
  }

  /// Fetch visitor history with logs
  Future<void> fetchVisitorHistory({int limit = 50}) async {
    try {
      isLoading.value = true;
      final history = await _service.getVisitorHistory(limit: limit);
      visitorHistory.assignAll(history);
      isLoading.value = false;
    } catch (e) {
      debugPrint('Error fetching visitor history: $e');
      isLoading.value = false;
    }
  }

  /// Reject visitor entry
  Future<bool> rejectVisitorEntry(int visitorId, String reason) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      
      final result = await _service.rejectVisitorEntry(visitorId, reason);
      
      if (result) {
        await fetchPendingVisitors();
        await fetchVisitorHistory();
      }
      
      isLoading.value = false;
      return result;
    } catch (e) {
      isLoading.value = false;
      errorMessage.value = e.toString().replaceAll('Exception: ', '');
      return false;
    }
  }

  /// Refresh all data
  Future<void> refreshAll() async {
    await Future.wait([
      fetchInsideVisitors(),
      fetchPendingVisitors(),
      fetchVisitorHistory(),
    ]);
  }

  Future<void> fetchBuildingResidents() async {
    try {
      errorMessage.value = '';
      final residents = await _service.getBuildingResidents();
      buildingResidents.assignAll(residents);
    } catch (e) {
      debugPrint('Error fetching building residents: $e');
      errorMessage.value = e.toString().replaceAll('Exception: ', '');
    }
  }

  Future<Map<String, dynamic>?> createWalkInVisitor({
    required int residentId,
    required String type,
    required String name,
    String? phone,
    String? vehicleNo,
    String? companyName,
    String? purpose,
  }) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final result = await _service.createWalkInVisitor({
        'resident_id': residentId,
        'type': type,
        'name': name,
        'phone': phone,
        'vehicle_no': vehicleNo,
        'company_name': companyName,
        'purpose': purpose,
      });

      await refreshAll();
      isLoading.value = false;
      return result;
    } catch (e) {
      isLoading.value = false;
      errorMessage.value = e.toString().replaceAll('Exception: ', '');
      return null;
    }
  }
}
