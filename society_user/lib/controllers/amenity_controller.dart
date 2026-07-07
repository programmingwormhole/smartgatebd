import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/amenity_service.dart';
import 'auth_controller.dart';

class AmenityController extends GetxController {
  final AmenityService _amenityService = AmenityService();

  final RxList<dynamic> amenities = <dynamic>[].obs;
  final RxList<dynamic> bookings = <dynamic>[].obs;
  final RxList<dynamic> slots = <dynamic>[].obs;
  final RxBool isLoading = false.obs;

  Future<void> fetchSlots(int amenityId, String date) async {
    isLoading.value = true;
    update();
    try {
      slots.value = await _amenityService.getSlots(amenityId, date);
    } catch (e) {
      debugPrint('Error fetching slots: $e');
    } finally {
      isLoading.value = false;
      update();
    }
  }

  Future<void> fetchAmenities() async {
    final buildingId = Get.find<AuthController>().user?.buildingId;
    if (buildingId == null) return;

    isLoading.value = true;
    update();
    try {
      amenities.value = await _amenityService.getAmenities(buildingId);
    } catch (e) {
      debugPrint('Error fetching amenities: $e');
    } finally {
      isLoading.value = false;
      update();
    }
  }

  Future<void> fetchBookings() async {
    isLoading.value = true;
    update();
    try {
      bookings.value = await _amenityService.getAmenityBookings();
    } catch (e) {
      debugPrint('Error fetching bookings: $e');
    } finally {
      isLoading.value = false;
      update();
    }
  }

  Future<bool> bookAmenity(int amenityId, Map<String, dynamic> data) async {
    isLoading.value = true;
    update();
    try {
      await _amenityService.bookAmenity(amenityId, data);
      await fetchBookings();
      return true;
    } catch (e) {
      debugPrint('Error booking amenity: $e');
      return false;
    } finally {
      isLoading.value = false;
      update();
    }
  }

  Future<bool> createAmenity(Map<String, dynamic> data) async {
    final buildingId = Get.find<AuthController>().user?.buildingId;
    if (buildingId == null) return false;

    isLoading.value = true;
    update();
    try {
      await _amenityService.createAmenity(buildingId, data);
      await fetchAmenities();
      return true;
    } catch (e) {
      debugPrint('Error creating amenity: $e');
      return false;
    } finally {
      isLoading.value = false;
      update();
    }
  }

  Future<bool> updateAmenity(int amenityId, Map<String, dynamic> data) async {
    isLoading.value = true;
    update();
    try {
      await _amenityService.updateAmenity(amenityId, data);
      await fetchAmenities();
      return true;
    } catch (e) {
      debugPrint('Error updating amenity: $e');
      return false;
    } finally {
      isLoading.value = false;
      update();
    }
  }

  Future<bool> deleteAmenity(int amenityId) async {
    isLoading.value = true;
    update();
    try {
      await _amenityService.deleteAmenity(amenityId);
      await fetchAmenities();
      return true;
    } catch (e) {
      debugPrint('Error deleting amenity: $e');
      return false;
    } finally {
      isLoading.value = false;
      update();
    }
  }
}
