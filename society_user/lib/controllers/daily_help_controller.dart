import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/daily_help_service.dart';

class DailyHelpController extends GetxController {
  final DailyHelpService _dailyHelpService = DailyHelpService();

  List<dynamic> _dailyHelpStaff = [];
  bool _isLoading = false;

  List<dynamic> get dailyHelpStaff => _dailyHelpStaff;
  bool get isLoading => _isLoading;

  Future<void> fetchDailyHelpStaff() async {
    _isLoading = true;
    update();

    try {
      _dailyHelpStaff = await _dailyHelpService.getDailyHelp();
    } catch (e) {
      debugPrint('Error fetching daily help: $e');
    } finally {
      _isLoading = false;
      update();
    }
  }

  Future<dynamic> addDailyHelpStaff(Map<String, dynamic> data) async {
    _isLoading = true;
    update();

    try {
      final res = await _dailyHelpService.addDailyHelp(data);
      await fetchDailyHelpStaff();
      return res;
    } catch (e) {
      debugPrint('Error adding daily help: $e');
      return null;
    } finally {
      _isLoading = false;
      update();
    }
  }

  Future<bool> toggleGatepass(int dailyHelpId, bool enabled) async {
    _isLoading = true;
    update();

    try {
      await _dailyHelpService.updateDailyHelp(dailyHelpId, {
        'gatepass_enabled': enabled,
      });
      await fetchDailyHelpStaff();
      return true;
    } catch (e) {
      debugPrint('Error toggling daily help gatepass: $e');
      return false;
    } finally {
      _isLoading = false;
      update();
    }
  }
}
