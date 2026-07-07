import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/bill_service.dart';

class BillController extends GetxController {
  final BillService _billService = BillService();

  final _bills = <dynamic>[].obs;
  final _isLoading = false.obs;
  final _isGettingGateways = false.obs;
  final _gateways = <dynamic>[].obs;

  List<dynamic> get bills => _bills;
  List<dynamic> get activeBills => _bills.where((b) {
    final status = b['status']?.toString().toLowerCase();
    return status == 'unpaid' || status == 'pending_for_approval';
  }).toList();

  List<dynamic> get historyBills => _bills.where((b) {
    final status = b['status']?.toString().toLowerCase();
    return status == 'paid' || status == 'rejected';
  }).toList();

  bool get isLoading => _isLoading.value;
  bool get isGettingGateways => _isGettingGateways.value;
  List<dynamic> get gateways => _gateways;

  Future<void> fetchBills() async {
    _isLoading.value = true;
    try {
      final data = await _billService.getBills();
      _bills.assignAll(data);
    } catch (e) {
      debugPrint('Error fetching bills: $e');
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> fetchGateways(int buildingId) async {
    _isGettingGateways.value = true;
    try {
      final data = await _billService.getPaymentGateways(buildingId);
      _gateways.assignAll(data);
    } catch (e) {
      debugPrint('Error fetching gateways: $e');
    } finally {
      _isGettingGateways.value = false;
    }
  }

  Future<bool> payBillManual({
    required int billId,
    required double amount,
    int? gatewayId,
    String? trxId,
    required String method,
    String? notes,
  }) async {
    _isLoading.value = true;
    try {
      final success = await _billService.payBillManual(
        billId: billId,
        amount: amount,
        gatewayId: gatewayId,
        trxId: trxId,
        method: method,
        notes: notes,
      );
      if (success) {
        await fetchBills();
      }
      return success;
    } catch (e) {
      debugPrint('Error paying bill: $e');
      return false;
    } finally {
      _isLoading.value = false;
    }
  }
}
