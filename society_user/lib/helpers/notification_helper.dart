// Helper class to trigger notifications from anywhere in the app
// Usage: NotificationHelper.createNotification(userId, title, message, 'success', 'visitor', visitorId);

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/notification_model.dart';
import '../controllers/notification_controller.dart';

class NotificationHelper {
  /// Call this from your controllers/services when an event occurs that requires user notification
  /// This will:
  /// 1. Create a notification in the database (via API in NotificationController)
  /// 2. Update the NotificationController to reflect the new notification
  /// 3. Show a snackbar to the user
  ///
  /// Example usage:
  /// NotificationHelper.notifyUser(
  ///   title: 'New Visitor',
  ///   message: 'John Doe is waiting at the gate',
  ///   type: 'info',
  ///   refType: 'visitor',
  ///   refId: visitorId,
  /// );
  static void notifyUser({
    required String title,
    required String message,
    String type = 'info', // info, warning, success, alert
    String? refType,
    int? refId,
  }) {
    try {
      // Try to update NotificationController if it exists
      if (Get.isRegistered<NotificationController>()) {
        final controller = Get.find<NotificationController>();
        
        // Refresh notifications to get the latest
        controller.fetchNotifications(refresh: true);
        controller.fetchUnreadCount();
      }

      // Show snackbar to user
      Get.snackbar(
        title,
        message,
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 5),
        backgroundColor: _getColorByType(type),
        colorText: Colors.white,
      );
    } catch (e) {
      print('Error notifying user: $e');
    }
  }

  static Color _getColorByType(String type) {
    switch (type) {
      case 'success':
        return Colors.green;
      case 'warning':
        return Colors.orange;
      case 'alert':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }
}

// Export this in your main.dart or wherever you initialize controllers
// GetX will handle calling NotificationController().onInit() automatically
// when you use GetBuilder<NotificationController>(init: NotificationController())
