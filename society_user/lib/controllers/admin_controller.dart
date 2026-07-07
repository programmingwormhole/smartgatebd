import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'auth_controller.dart';
import '../services/admin_service.dart';

class AdminController extends GetxController {
  final AdminService _adminService = AdminService();

  // Expose adminService for direct access
  AdminService get adminService => _adminService;

  final _isLoading = false.obs;
  final _stats = <String, dynamic>{}.obs;
  final _pendingPayments = <dynamic>[].obs;
  final _activeBuildingId = RxnInt();

  bool get isLoading => _isLoading.value;
  Map<String, dynamic> get stats => _stats;
  List<dynamic> get pendingPayments => _pendingPayments;
  int? get activeBuildingId => _activeBuildingId.value;

  void setActiveBuildingId(int? buildingId) {
    _activeBuildingId.value = buildingId;
  }

  int? _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  Future<int?> _resolveBuildingId({int? preferredBuildingId}) async {
    if (preferredBuildingId != null) {
      _activeBuildingId.value = preferredBuildingId;
      return preferredBuildingId;
    }

    if (_activeBuildingId.value != null) {
      return _activeBuildingId.value;
    }

    final user = Get.find<AuthController>().user;
    final authBuildingId = user?.buildingId;
    if (authBuildingId != null) {
      _activeBuildingId.value = authBuildingId;
      return authBuildingId;
    }

    if (user?.role.toLowerCase() == 'superadmin') {
      try {
        final buildings = await _adminService.getAllBuildings();
        if (buildings.isNotEmpty) {
          final firstBuildingId = _toInt(buildings.first['id']);
          if (firstBuildingId != null) {
            _activeBuildingId.value = firstBuildingId;
            return firstBuildingId;
          }
        }
      } catch (e) {
        debugPrint('Error resolving building context: $e');
      }
    }

    return null;
  }

  Future<void> fetchDashboardStats() async {
    _isLoading.value = true;
    try {
      final data = await _adminService.getDashboardStats();
      _stats.assignAll(data);
    } catch (e) {
      debugPrint('Error fetching admin stats: $e');
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> fetchPendingPayments() async {
    _isLoading.value = true;
    try {
      final data = await _adminService.getPendingPayments();
      _pendingPayments.assignAll(data);
    } catch (e) {
      debugPrint('Error fetching pending payments: $e');
    } finally {
      _isLoading.value = false;
    }
  }

  Future<bool> approvePayment(int paymentId) async {
    _isLoading.value = true;
    try {
      final success = await _adminService.approvePayment(paymentId);
      if (success) {
        await fetchPendingPayments();
        await fetchDashboardStats();
      }
      return success;
    } catch (e) {
      debugPrint('Error approving payment: $e');
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  Future<bool> markBillAsPaid(int billId, {String? note}) async {
    _isLoading.value = true;
    try {
      final success = await _adminService.markBillAsPaid(billId, note: note);
      if (success) {
        await fetchPendingPayments();
        await fetchDashboardStats();
      }
      return success;
    } catch (e) {
      debugPrint('Error marking bill as paid: $e');
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  Future<bool> rejectPayment(int paymentId, String reason) async {
    _isLoading.value = true;
    try {
      final success = await _adminService.rejectPayment(
        paymentId,
        'Rejected from Admin App',
      ); // passing string reason
      if (success) {
        await fetchPendingPayments();
        await fetchDashboardStats();
      }
      return success;
    } catch (e) {
      debugPrint('Error rejecting payment: $e');
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  // --- Building & Resident Management ---

  final _members = <dynamic>[].obs;
  List<dynamic> get members => _members;

  Future<void> fetchBuildingMembers({int? buildingId}) async {
    _isLoading.value = true;
    try {
      final resolvedBuildingId = await _resolveBuildingId(
        preferredBuildingId: buildingId,
      );
      final data = await _adminService.getBuildingMembers(
        buildingId: resolvedBuildingId,
      );
      _isLoading.value = false;
      _members.assignAll(data);
    } catch (e) {
      _isLoading.value = false;
      debugPrint('Error fetching members: $e');
    } finally {
      _isLoading.value = false;
    }
  }

  Future<bool> addResident(int buildingId, Map<String, dynamic> data) async {
    debugPrint('Adding resident with data: $data');
    _isLoading.value = true;
    try {
      setActiveBuildingId(buildingId);
      final success = await _adminService.addResident(buildingId, data);
      if (success) {
        await fetchBuildingMembers(); // Refresh list after adding
      }
      return success;
    } catch (e) {
      debugPrint('Error adding resident: $e');
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  Future<bool> updateResident(int residentId, Map<String, dynamic> data) async {
    _isLoading.value = true;
    try {
      final success = await _adminService.updateResident(residentId, data);
      if (success) {
        await fetchBuildingMembers();
      }
      return success;
    } catch (e) {
      debugPrint('Error updating resident: $e');
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  Future<bool> deleteResident(int residentId) async {
    _isLoading.value = true;
    try {
      final success = await _adminService.deleteResident(residentId);
      if (success) {
        await fetchBuildingMembers();
      }
      return success;
    } catch (e) {
      debugPrint('Error deleting resident: $e');
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  // --- Bill Management ---

  Future<bool> generateBulkBills(Map<String, dynamic> data) async {
    _isLoading.value = true;
    try {
      final success = await _adminService.generateBulkBills(data);
      if (success) {
        // Refresh related stats if needed
      }
      return success;
    } catch (e) {
      debugPrint('Error generating bulk bills: $e');
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  // --- Request Management (Amenities, Services) ---

  final _amenityRequests = <dynamic>[].obs;
  final _serviceRequests = <dynamic>[].obs;
  final _complaintRequests = <dynamic>[].obs;

  List<dynamic> get amenityRequests => _amenityRequests;
  List<dynamic> get serviceRequests => _serviceRequests;
  List<dynamic> get complaintRequests => _complaintRequests;

  Future<void> fetchAmenityRequests() async {
    _isLoading.value = true;
    try {
      final data = await _adminService.getAmenityRequests();
      _amenityRequests.assignAll(data);
    } catch (e) {
      debugPrint('Error fetching amenity requests: $e');
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> fetchServiceRequests() async {
    _isLoading.value = true;
    try {
      final data = await _adminService.getServiceRequests();
      _serviceRequests.assignAll(data);
    } catch (e) {
      debugPrint('Error fetching service requests: $e');
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> fetchComplaintRequests({int? buildingId}) async {
    _isLoading.value = true;
    try {
      final resolvedBuildingId = await _resolveBuildingId(
        preferredBuildingId: buildingId,
      );
      final data = await _adminService.getComplaintRequests(
        buildingId: resolvedBuildingId,
      );
      _complaintRequests.assignAll(data);
    } catch (e) {
      debugPrint('Error fetching complaint requests: $e');
    } finally {
      _isLoading.value = false;
    }
  }

  Future<bool> updateAmenityStatus(
    int bookingId,
    String status, {
    String? rejectionReason,
    String? adminComment,
  }) async {
    _isLoading.value = true;
    try {
      final success = await _adminService.updateAmenityRequestStatus(
        bookingId,
        status,
        rejectionReason: rejectionReason,
        adminComment: adminComment,
      );
      if (success) {
        await fetchAmenityRequests();
      }
      return success;
    } catch (e) {
      debugPrint('Error updating amenity status: $e');
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  Future<bool> updateServiceStatus(
    int bookingId,
    String status, {
    String? rejectionReason,
    String? adminComment,
  }) async {
    _isLoading.value = true;
    try {
      final success = await _adminService.updateServiceRequestStatus(
        bookingId,
        status,
        rejectionReason: rejectionReason,
        adminComment: adminComment,
      );
      if (success) {
        await fetchServiceRequests();
      }
      return success;
    } catch (e) {
      debugPrint('Error updating service status: $e');
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  Future<bool> updateComplaintStatus(int complaintId, String status) async {
    _isLoading.value = true;
    try {
      final success = await _adminService.updateComplaintStatus(
        complaintId,
        status,
      );
      if (success) {
        await fetchComplaintRequests(buildingId: _activeBuildingId.value);
      }
      return success;
    } catch (e) {
      debugPrint('Error updating complaint status: $e');
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  Future<bool> toggleCommitteeStatus(int residentId, String newRole) async {
    _isLoading.value = true;
    try {
      final success = await _adminService.updateResidentRole(
        residentId,
        newRole,
      );
      if (success) {
        await fetchBuildingMembers();
      }
      return success;
    } catch (e) {
      debugPrint('Error toggling committee status: $e');
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  final _guards = <dynamic>[].obs;
  List<dynamic> get guards => _guards;

  Future<void> fetchGuards() async {
    final buildingId = await _resolveBuildingId();
    if (buildingId == null) return;

    _isLoading.value = true;
    try {
      final data = await _adminService.getGuards(buildingId);
      _guards.assignAll(data);
    } catch (e) {
      debugPrint('Error fetching guards: $e');
    } finally {
      _isLoading.value = false;
    }
  }

  Future<bool> createGuard(Map<String, dynamic> data) async {
    final buildingId = await _resolveBuildingId();
    if (buildingId == null) return false;

    _isLoading.value = true;
    try {
      final success = await _adminService.createGuard(buildingId, data);
      if (success) {
        await fetchGuards();
      }
      return success;
    } catch (e) {
      debugPrint('Error creating guard: $e');
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  Future<bool> updateGuard(int guardId, Map<String, dynamic> data) async {
    _isLoading.value = true;
    try {
      final success = await _adminService.updateGuard(guardId, data);
      if (success) {
        await fetchGuards();
      }
      return success;
    } catch (e) {
      debugPrint('Error updating guard: $e');
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  Future<bool> deleteGuard(int guardId) async {
    _isLoading.value = true;
    try {
      final success = await _adminService.deleteGuard(guardId);
      if (success) {
        await fetchGuards();
      }
      return success;
    } catch (e) {
      debugPrint('Error deleting guard: $e');
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  Future<bool> toggleGuardStatus(int guardId, bool status) async {
    _isLoading.value = true;
    try {
      final success = await _adminService.updateGuardStatus(
        guardId,
        status ? 'on_duty' : 'off_duty',
      );
      if (success) {
        await fetchGuards();
      }
      return success;
    } catch (e) {
      debugPrint('Error toggling guard status: $e');
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  Future<bool> updateGuardStatus(int guardId, String statusValue) async {
    _isLoading.value = true;
    try {
      final success = await _adminService.updateGuardStatus(
        guardId,
        statusValue,
      );
      if (success) {
        await fetchGuards();
      }
      return success;
    } catch (e) {
      debugPrint('Error updating guard status: $e');
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  final _buildingStructure = <String, dynamic>{}.obs;
  Map<String, dynamic> get buildingStructure => _buildingStructure;

  Future<void> fetchBuildingStructure({int? buildingId}) async {
    final resolvedBuildingId = await _resolveBuildingId(
      preferredBuildingId: buildingId,
    );
    if (resolvedBuildingId == null) {
      Get.snackbar(
        'Building Not Assigned',
        'Please select or assign a building first.',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    _isLoading.value = true;
    try {
      final data = await _adminService.getBuildingStructure(resolvedBuildingId);
      _buildingStructure.assignAll(data);
    } catch (e) {
      debugPrint('Error fetching building structure: $e');
    } finally {
      _isLoading.value = false;
    }
  }

  // Block CRUD
  Future<bool> createBlock(String name, {int? buildingId}) async {
    final resolvedBuildingId = await _resolveBuildingId(
      preferredBuildingId: buildingId,
    );
    if (resolvedBuildingId == null) {
      Get.snackbar(
        'Building Not Assigned',
        'Cannot create block because no building is assigned to this account.',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return false;
    }
    final success = await _adminService.createBlock(resolvedBuildingId, name);
    if (success) await fetchBuildingStructure(buildingId: resolvedBuildingId);
    return success;
  }

  Future<bool> updateBlock(int id, String name) async {
    final success = await _adminService.updateBlock(id, name);
    if (success) await fetchBuildingStructure();
    return success;
  }

  Future<bool> deleteBlock(int id) async {
    final success = await _adminService.deleteBlock(id);
    if (success) await fetchBuildingStructure();
    return success;
  }

  // Floor CRUD
  Future<bool> createFloor(int blockId, String floorNumber) async {
    final success = await _adminService.createFloor(blockId, floorNumber);
    if (success) await fetchBuildingStructure();
    return success;
  }

  Future<bool> updateFloor(int id, String floorNumber) async {
    final success = await _adminService.updateFloor(id, floorNumber);
    if (success) await fetchBuildingStructure();
    return success;
  }

  Future<bool> deleteFloor(int id) async {
    final success = await _adminService.deleteFloor(id);
    if (success) await fetchBuildingStructure();
    return success;
  }

  // Flat CRUD
  Future<bool> createFlat(int floorId, String flatNumber) async {
    final success = await _adminService.createFlat(floorId, flatNumber);
    if (success) await fetchBuildingStructure();
    return success;
  }

  Future<bool> updateFlat(int id, String flatNumber) async {
    final success = await _adminService.updateFlat(id, flatNumber);
    if (success) await fetchBuildingStructure();
    return success;
  }

  Future<bool> deleteFlat(int id) async {
    final success = await _adminService.deleteFlat(id);
    if (success) await fetchBuildingStructure();
    return success;
  }
}
