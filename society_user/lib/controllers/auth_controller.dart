import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';

class AuthController extends GetxController {
  final AuthService _authService = AuthService();

  UserModel? _user;
  bool _isLoading = false;
  bool _isOtpEnabledGlobal = false;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  bool get isOtpEnabled => _isOtpEnabledGlobal;

  bool get isAuthenticated => _user != null;

  Future<void> fetchConfig() async {
    _isOtpEnabledGlobal = await _authService.checkOtpConfig();
    update();
  }

  Future<void> checkAuthStatus() async {
    final token = await _authService.getToken();
    if (token != null && token.isNotEmpty) {
      await fetchProfile();
      if (_user != null) {
        // Assume authenticated if profile fetch returns a user
        await NotificationService().initialize();
      } else {
        // If the token is invalid, log out
        logout();
      }
    }
  }

  Future<bool> login(String phone, String password) async {
    _isLoading = true;
    update();

    try {
      final res = await _authService.login(phone, password);

      debugPrint(res.toString());

      // If OTP is disabled, the API returns the token and user directly
      if (!_isOtpEnabledGlobal && res.containsKey('access_token')) {
        await _authService.saveToken(res['access_token']);
        _user = UserModel.fromJson(res['user']);

        // Register FCM token
        await NotificationService().initialize();
      }

      _isLoading = false;
      update();
      return true;
    } catch (e) {
      _isLoading = false;
      update();
      rethrow;
    }
  }

  Future<bool> verifyOtp(String phone, String otpCode) async {
    _isLoading = true;
    update();

    try {
      final res = await _authService.verifyOtp(phone, otpCode);
      if (res.containsKey('access_token')) {
        await _authService.saveToken(res['access_token']);
        _user = UserModel.fromJson(res['user']);

        // Register FCM token
        await NotificationService().initialize();

        _isLoading = false;
        update();
        return true;
      }
      return false;
    } catch (e) {
      _isLoading = false;
      update();
      rethrow;
    }
  }

  void logout() {
    _authService.saveToken(''); // clear token
    _user = null;
    update();
  }

  Future<void> fetchProfile() async {
    try {
      final res = await _authService.getProfile();
      if (res.containsKey('user')) {
        _user = UserModel.fromJson(res['user']);
        update();
      }
    } catch (e) {
      debugPrint('Error fetching profile: $e');
    }
  }

  Future<bool> updateProfile(Map<String, dynamic> data) async {
    _isLoading = true;
    update();
    try {
      final res = await _authService.updateProfile(data);
      if (res.containsKey('user')) {
        _user = UserModel.fromJson(res['user']);
        _isLoading = false;
        update();
        return true;
      }
      return false;
    } catch (e) {
      _isLoading = false;
      update();
      return false;
    }
  }

  Future<Map<String, dynamic>> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    _isLoading = true;
    update();
    try {
      await _authService.changePassword(currentPassword, newPassword);
      _isLoading = false;
      update();
      return {'success': true, 'message': 'Password changed successfully'};
    } catch (e) {
      _isLoading = false;
      update();
      return {'success': false, 'message': e.toString().replaceFirst('Exception: ', '')};
    }
  }

  Future<bool> uploadProfilePicture(File imageFile) async {
    _isLoading = true;
    update();
    try {
      final res = await _authService.uploadProfilePicture(imageFile);
      if (res.containsKey('user')) {
        _user = UserModel.fromJson(res['user']);
        _isLoading = false;
        update();
        return true;
      }
      _isLoading = false;
      update();
      return false;
    } catch (e) {
      _isLoading = false;
      update();
      debugPrint('Error uploading profile picture: $e');
      rethrow;
    }
  }

  Future<bool> deleteProfilePicture() async {
    _isLoading = true;
    update();
    try {
      final res = await _authService.deleteProfilePicture();
      if (res.containsKey('user')) {
        _user = UserModel.fromJson(res['user']);
        _isLoading = false;
        update();
        return true;
      }
      _isLoading = false;
      update();
      return false;
    } catch (e) {
      _isLoading = false;
      update();
      debugPrint('Error deleting profile picture: $e');
      rethrow;
    }
  }
}
