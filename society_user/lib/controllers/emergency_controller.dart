import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/emergency_service.dart';
import 'auth_controller.dart';

class EmergencyController extends GetxController {
  final EmergencyService _emergencyService = EmergencyService();

  bool _isLoading = false;
  List<dynamic> _supportContacts = [];

  bool get isLoading => _isLoading;
  List<dynamic> get supportContacts => _supportContacts;

  Future<void> fetchSupportContacts() async {
    final authController = Get.find<AuthController>();
    final buildingId = authController.user?.buildingId;
    if (buildingId == null) return;

    _isLoading = true;
    update();
    try {
      _supportContacts = await _emergencyService.getSupportContacts(buildingId);
    } catch (e) {
      debugPrint('Error fetching support contacts: $e');
    } finally {
      _isLoading = false;
      update();
    }
  }

  Future<bool> triggerSos(String type, String message) async {
    _isLoading = true;
    update();
    try {
      final success = await _emergencyService.triggerSos(type, message);
      return success;
    } catch (e) {
      debugPrint('Error triggering SOS: $e');
      return false;
    } finally {
      _isLoading = false;
      update();
    }
  }
}
