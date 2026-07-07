import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/pet_service.dart';

class PetController extends GetxController {
  final PetService _petService = PetService();

  List<dynamic> _pets = [];
  bool _isLoading = false;

  List<dynamic> get pets => _pets;
  bool get isLoading => _isLoading;

  Future<void> fetchPets() async {
    _isLoading = true;
    update();

    try {
      _pets = await _petService.getPets();
    } catch (e) {
      debugPrint('Error fetching pets: $e');
    } finally {
      _isLoading = false;
      update();
    }
  }

  Future<dynamic> addPet(Map<String, dynamic> data) async {
    _isLoading = true;
    update();

    try {
      final res = await _petService.addPet(data);
      await fetchPets();
      return res;
    } catch (e) {
      debugPrint('Error adding pet: $e');
      return null;
    } finally {
      _isLoading = false;
      update();
    }
  }
}
