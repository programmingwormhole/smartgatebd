import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../services/visitor_service.dart';

class VisitorController extends GetxController {
  final VisitorService _visitorService = VisitorService();

  final RxList<dynamic> visitors = <dynamic>[].obs;
  final RxBool isLoading = false.obs;

  Future<void> fetchVisitors() async {
    isLoading.value = true;
    update();
    try {
      visitors.value = await _visitorService.getVisitorHistory();
    } catch (e) {
      debugPrint('Error fetching visitors: $e');
    } finally {
      isLoading.value = false;
      update();
    }
  }

  Future<dynamic> addPreApprovedVisitor(Map<String, dynamic> data) async {
    isLoading.value = true;
    update();
    try {
      final res = await _visitorService.preApproveVisitor(data);
      await fetchVisitors();
      return res;
    } catch (e) {
      debugPrint('Error adding visitor: $e');
      return null;
    } finally {
      isLoading.value = false;
      update();
    }
  }

  Future<bool> approveVisitor(int visitorId) async {
    isLoading.value = true;
    update();
    try {
      await _visitorService.approveVisitor(visitorId);
      await fetchVisitors();
      Get.snackbar('Success', 'Visitor approved successfully');
      return true;
    } catch (e) {
      debugPrint('Error approving visitor: $e');
      Get.snackbar('Error', 'Failed to approve visitor');
      return false;
    } finally {
      isLoading.value = false;
      update();
    }
  }

  Future<bool> rejectVisitor(int visitorId, String reason) async {
    isLoading.value = true;
    update();
    try {
      await _visitorService.rejectVisitor(visitorId, reason: reason);
      await fetchVisitors();
      Get.snackbar('Success', 'Visitor rejected successfully');
      return true;
    } catch (e) {
      debugPrint('Error rejecting visitor: $e');
      Get.snackbar('Error', 'Failed to reject visitor');
      return false;
    } finally {
      isLoading.value = false;
      update();
    }
  }

  Future<void> deleteVisitor(dynamic id) async {
    isLoading.value = true;
    update();
    try {
      await _visitorService.deleteVisitor(id);
      await fetchVisitors();
      Get.snackbar('Success', 'Visitor deleted successfully');
    } catch (e) {
      debugPrint('Error deleting visitor: $e');
      Get.snackbar('Error', 'Failed to delete visitor');
    } finally {
      isLoading.value = false;
      update();
    }
  }
}
