import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/service_service.dart';
import 'auth_controller.dart';

class ServiceController extends GetxController {
  final ServiceService _serviceService = ServiceService();

  final RxList<dynamic> services = <dynamic>[].obs;
  final RxList<dynamic> bookings = <dynamic>[].obs;
  final RxBool isLoading = false.obs;

  Future<void> fetchServices() async {
    final buildingId = Get.find<AuthController>().user?.buildingId;
    if (buildingId == null) return;

    isLoading.value = true;
    update();
    try {
      services.value = await _serviceService.getServices(buildingId);
    } catch (e) {
      debugPrint('Error fetching services: $e');
    } finally {
      isLoading.value = false;
      update();
    }
  }

  Future<void> fetchBookings() async {
    isLoading.value = true;
    update();
    try {
      bookings.value = await _serviceService.getServiceBookings();
    } catch (e) {
      debugPrint('Error fetching service bookings: $e');
    } finally {
      isLoading.value = false;
      update();
    }
  }

  Future<bool> bookService(Map<String, dynamic> data) async {
    isLoading.value = true;
    update();
    try {
      await _serviceService.bookService(data);
      await fetchBookings();
      return true;
    } catch (e) {
      debugPrint('Error booking service: $e');
      return false;
    } finally {
      isLoading.value = false;
      update();
    }
  }

  Future<bool> createService(Map<String, dynamic> data) async {
    isLoading.value = true;
    update();
    try {
      await _serviceService.createService(data);
      await fetchServices();
      return true;
    } catch (e) {
      debugPrint('Error creating service: $e');
      return false;
    } finally {
      isLoading.value = false;
      update();
    }
  }

  Future<bool> updateService(dynamic serviceId, Map<String, dynamic> data) async {
    isLoading.value = true;
    update();
    try {
      await _serviceService.updateService(serviceId, data);
      await fetchServices();
      return true;
    } catch (e) {
      debugPrint('Error updating service: $e');
      return false;
    } finally {
      isLoading.value = false;
      update();
    }
  }

  Future<bool> deleteService(dynamic serviceId) async {
    isLoading.value = true;
    update();
    try {
      await _serviceService.deleteService(serviceId);
      await fetchServices();
      return true;
    } catch (e) {
      debugPrint('Error deleting service: $e');
      return false;
    } finally {
      isLoading.value = false;
      update();
    }
  }
}
