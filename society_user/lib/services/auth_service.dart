import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
import '../core/constants/api_constants.dart';

class AuthService {
  final ApiService _apiService = ApiService();

  // Check if OTP is enabled on backend
  Future<bool> checkOtpConfig() async {
    final response = await _apiService.get(ApiConstants.loginConfig);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['otp_enabled'] ?? false;
    }
    return false;
  }

  // Login
  Future<Map<String, dynamic>> login(String phone, String password) async {
    final response = await _apiService.post(ApiConstants.login, {
      'login': phone,
      'password': password,
    });

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Invalid Credentials');
    }
  }

  // Verify OTP
  Future<Map<String, dynamic>> verifyOtp(String phone, String code) async {
    final response = await _apiService.post(ApiConstants.verifyOtp, {
      'phone': phone,
      'otp_code': code,
    });

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Invalid OTP Code');
    }
  }

  // Save Token
  Future<void> saveToken(String token) async {
    await _apiService.saveToken(token);
  }

  // Get Token
  Future<String?> getToken() async {
    return await _apiService.getToken();
  }

  // Get Profile
  Future<Map<String, dynamic>> getProfile() async {
    final response = await _apiService.get('/profile');
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load profile');
    }
  }

  // Update Profile
  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data) async {
    final sanitizedData = <String, dynamic>{};
    data.forEach((key, value) {
      if (value is String) {
        final trimmed = value.trim();
        if ((key == 'email' || key == 'phone') && trimmed.isEmpty) {
          sanitizedData[key] = null;
        } else {
          sanitizedData[key] = trimmed;
        }
      } else {
        sanitizedData[key] = value;
      }
    });

    final response = await _apiService.post('/profile/update', sanitizedData);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to update profile');
    }
  }

  // Change Password
  Future<Map<String, dynamic>> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    final response = await _apiService.post('/profile/change-password', {
      'current_password': currentPassword,
      'new_password': newPassword,
      'new_password_confirmation': newPassword,
    });

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final errorData = jsonDecode(response.body);
      final errorMessage = errorData['message'] ?? 'Failed to change password';
      throw Exception(errorMessage);
    }
  }

  // Get Push Notification Preference
  Future<bool> getPushNotificationPreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('push_notifications_enabled') ?? true;
    } catch (e) {
      return true;
    }
  }

  // Set Push Notification Preference
  Future<void> setPushNotificationPreference(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('push_notifications_enabled', enabled);
    } catch (e) {
      rethrow;
    }
  }

  // Upload Profile Picture
  Future<Map<String, dynamic>> uploadProfilePicture(File imageFile) async {
    final response = await _apiService.postMultipart(
      '/profile/upload-picture',
      {},
      {'profile_picture': imageFile.path},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final errorData = jsonDecode(response.body);
      final errorMessage = errorData['message'] ?? 'Failed to upload profile picture';
      throw Exception(errorMessage);
    }
  }

  // Delete Profile Picture
  Future<Map<String, dynamic>> deleteProfilePicture() async {
    final response = await _apiService.delete('/profile/picture');

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final errorData = jsonDecode(response.body);
      final errorMessage = errorData['message'] ?? 'Failed to delete profile picture';
      throw Exception(errorMessage);
    }
  }
}
