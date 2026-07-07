import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/family_service.dart';

class FamilyController extends GetxController {
  final FamilyService _familyService = FamilyService();

  List<dynamic> _familyMembers = [];
  bool _isLoading = false;

  List<dynamic> get familyMembers => _familyMembers;
  bool get isLoading => _isLoading;

  Future<void> fetchFamilyMembers() async {
    _isLoading = true;
    update();

    try {
      _familyMembers = await _familyService.getFamilyMembers();
    } catch (e) {
      debugPrint('Error fetching family: $e');
    } finally {
      _isLoading = false;
      update();
    }
  }

  Future<dynamic> addFamilyMember(Map<String, dynamic> data) async {
    _isLoading = true;
    update();

    try {
      final res = await _familyService.addFamilyMember(data);
      await fetchFamilyMembers();
      return res;
    } catch (e) {
      debugPrint('Error adding family: $e');
      return null;
    } finally {
      _isLoading = false;
      update();
    }
  }

  Future<bool> toggleGatepass(int familyId, bool enabled) async {
    _isLoading = true;
    update();

    try {
      await _familyService.updateFamilyMember(familyId, {
        'gatepass_enabled': enabled,
      });
      await fetchFamilyMembers();
      return true;
    } catch (e) {
      debugPrint('Error toggling family gatepass: $e');
      return false;
    } finally {
      _isLoading = false;
      update();
    }
  }
}
