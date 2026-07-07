import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/complaint_service.dart';

class ComplaintController extends GetxController {
  final ComplaintService _complaintService = ComplaintService();

  List<dynamic> _activeComplaints = [];
  List<dynamic> _resolvedComplaints = [];
  bool _isActiveLoading = false;
  bool _isResolvedLoading = false;

  List<dynamic> get activeComplaints => _activeComplaints;
  List<dynamic> get resolvedComplaints => _resolvedComplaints;
  bool get isActiveLoading => _isActiveLoading;
  bool get isResolvedLoading => _isResolvedLoading;

  Future<void> fetchActiveComplaints() async {
    _isActiveLoading = true;
    update();

    try {
      _activeComplaints = await _complaintService.getComplaints(
        status: 'active',
      );
    } catch (e) {
      debugPrint('Error fetching active complaints: $e');
    } finally {
      _isActiveLoading = false;
      update();
    }
  }

  Future<void> fetchResolvedComplaints() async {
    _isResolvedLoading = true;
    update();

    try {
      _resolvedComplaints = await _complaintService.getComplaints(
        status: 'resolved',
      );
    } catch (e) {
      debugPrint('Error fetching resolved complaints: $e');
    } finally {
      _isResolvedLoading = false;
      update();
    }
  }

  Future<void> fetchComplaints() async {
    await fetchActiveComplaints();
  }

  Future<bool> addComplaint(Map<String, dynamic> data) async {
    _isActiveLoading = true;
    update();

    try {
      await _complaintService.raiseComplaint(data);
      await fetchActiveComplaints();
      return true;
    } catch (e) {
      debugPrint('Error adding complaint: $e');
      return false;
    } finally {
      _isActiveLoading = false;
      update();
    }
  }
}
