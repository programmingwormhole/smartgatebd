import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/vehicle_service.dart';

class VehicleController extends GetxController {
  final VehicleService _vehicleService = VehicleService();

  List<dynamic> _vehicles = [];
  bool _isLoading = false;

  List<dynamic> get vehicles => _vehicles;
  bool get isLoading => _isLoading;

  Future<void> fetchVehicles() async {
    _isLoading = true;
    update();

    try {
      _vehicles = await _vehicleService.getVehicles();
    } catch (e) {
      debugPrint('Error fetching vehicles: $e');
    } finally {
      _isLoading = false;
      update();
    }
  }

  Future<bool> addVehicle(Map<String, dynamic> data) async {
    _isLoading = true;
    update();

    try {
      await _vehicleService.addVehicle(data);
      await fetchVehicles();
      return true;
    } catch (e) {
      debugPrint('Error adding vehicle: $e');
      return false;
    } finally {
      _isLoading = false;
      update();
    }
  }
}
