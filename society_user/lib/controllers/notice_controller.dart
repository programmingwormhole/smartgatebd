import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/notice_service.dart';
import 'auth_controller.dart';

class NoticeController extends GetxController {
  final NoticeService _noticeService = NoticeService();
  bool _isLoading = false;
  List<dynamic> _notices = [];
  int? _activeBuildingId;

  bool get isLoading => _isLoading;
  List<dynamic> get notices => _notices;
  int? get activeBuildingId => _activeBuildingId;

  void setActiveBuildingId(int? buildingId) {
    _activeBuildingId = buildingId;
    update();
  }

  Future<void> fetchNotices({int? buildingId}) async {
    final authController = Get.find<AuthController>();
    final resolvedBuildingId =
        buildingId ?? _activeBuildingId ?? authController.user?.buildingId;
    if (resolvedBuildingId == null) return;

    _activeBuildingId = resolvedBuildingId;

    _isLoading = true;
    update();
    try {
      _notices = await _noticeService.getNotices(resolvedBuildingId);
    } catch (e) {
      debugPrint('Error fetching notices: $e');
    } finally {
      _isLoading = false;
      update();
    }
  }
}
