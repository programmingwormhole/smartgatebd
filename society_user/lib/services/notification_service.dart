import 'dart:convert';
import 'dart:developer';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../services/api_service.dart';
import '../core/constants/api_constants.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  final ApiService _apiService = ApiService();
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // Define channels
  static const AndroidNotificationChannel _emergencyChannel =
      AndroidNotificationChannel(
        'emergency_alerts',
        'Emergency Alerts',
        description:
            'This channel is used for important emergency notifications.',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        showBadge: true,
      );

  static const AndroidNotificationChannel _generalChannel =
      AndroidNotificationChannel(
        'general_notifications',
        'General Notifications',
        description: 'General updates and notifications.',
        importance: Importance.defaultImportance,
        playSound: true,
      );

  Future<void> initialize() async {
    try {
      if (Firebase.apps.isEmpty) {
        log('Firebase has not been initialized. Skipping NotificationService.');
        return;
      }

      // Initialize Local Notifications
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const DarwinInitializationSettings iosSettings =
          DarwinInitializationSettings(
            requestAlertPermission: true,
            requestBadgePermission: true,
            requestSoundPermission: true,
          );

      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse details) {
          log('Notification clicked: ${details.payload}');
        },
      );

      // Create channels on Android
      await _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(_emergencyChannel);
      await _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(_generalChannel);

      final fcm = FirebaseMessaging.instance;

      // Request permission for FCM
      NotificationSettings fcmSettings = await fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (fcmSettings.authorizationStatus == AuthorizationStatus.authorized) {
        log('User granted FCM permission');
      }

      // Get the token
      String? token = await fcm.getToken();
      if (token != null) {
        log('FCM Token: $token');
        await syncToken(token);
      }

      fcm.onTokenRefresh.listen((newToken) async {
        await syncToken(newToken);
      });

      FirebaseMessaging.onBackgroundMessage(
        _firebaseMessagingBackgroundHandler,
      );

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        log('Got a message whilst in the foreground!');
        log('Message data: ${message.data}');

        if (message.notification != null) {
          _showLocalNotification(message);
        }
      });
    } catch (e) {
      log('Failed to initialize NotificationService: $e');
    }
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    final data = message.data;
    if (notification == null) return;

    final isEmergency = data['type'] == 'emergency';
    final channel = isEmergency ? _emergencyChannel : _generalChannel;

    await _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channel.id,
          channel.name,
          channelDescription: channel.description,
          importance: channel.importance,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          playSound: true,
          // sound: isEmergency ? const RawResourceAndroidNotificationSound('emergency_alarm') : null,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: jsonEncode(data),
    );
  }

  Future<void> syncToken(String token) async {
    try {
      final authToken = await _apiService.getToken();
      if (authToken == null || authToken.isEmpty) {
        log('User not logged in, skipping FCM token sync.');
        return;
      }

      final response = await _apiService.post(ApiConstants.fcmTokens, {
        'device_token': token,
        'device_type': 'android',
      });

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded != null && decoded['user'] != null) {
          final user = decoded['user'];
          final buildingId = int.tryParse('${user['building_id'] ?? ''}');
          final role = user['role']?.toString().toLowerCase();
          final residentRole = user['resident']?['role']
              ?.toString()
              .toLowerCase();

          if (buildingId != null) {
            String roleTopic;
            if (role == 'admin' || residentRole == 'admin') {
              roleTopic = 'building_${buildingId}_admins';
            } else if (role == 'guard' || residentRole == 'guard') {
              roleTopic = 'building_${buildingId}_guards';
            } else {
              roleTopic = 'building_${buildingId}_residents';
            }

            final nextTopics = <String>['building_$buildingId', roleTopic];
            await _reconcileTopicSubscriptions(nextTopics);
            log(
              'Notification topic mapping resolved: userRole=$role residentRole=$residentRole buildingId=$buildingId roleTopic=$roleTopic',
            );
          } else {
            log('Skipping topic subscription: invalid building_id in token sync response.');
          }
        }
      }
    } catch (e) {
      log('Error syncing FCM token: $e');
    }
  }

  Future<void> _subscribeToTopic(String topic) async {
    try {
      await FirebaseMessaging.instance.subscribeToTopic(topic);
      log('Subscribed to topic: $topic');
    } catch (e) {
      log('Error subscribing to topic $topic: $e');
    }
  }

  Future<void> _unsubscribeFromTopic(String topic) async {
    try {
      await FirebaseMessaging.instance.unsubscribeFromTopic(topic);
      log('Unsubscribed from topic: $topic');
    } catch (e) {
      log('Error unsubscribing from topic $topic: $e');
    }
  }

  Future<List<String>> _getLastSyncedTopics() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList('fcm_synced_topics') ?? <String>[];
  }

  Future<void> _setLastSyncedTopics(List<String> topics) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('fcm_synced_topics', topics);
  }

  Future<void> _reconcileTopicSubscriptions(List<String> nextTopics) async {
    final previousTopics = await _getLastSyncedTopics();

    for (final topic in previousTopics) {
      if (!nextTopics.contains(topic)) {
        await _unsubscribeFromTopic(topic);
      }
    }

    for (final topic in nextTopics) {
      if (!previousTopics.contains(topic)) {
        await _subscribeToTopic(topic);
      }
    }

    await _setLastSyncedTopics(nextTopics);
  }

  Future<void> subscribeToBuildingTopic(int buildingId) async {
    await _subscribeToTopic('building_$buildingId');
  }

  Future<void> unsubscribeFromBuildingTopic(int buildingId) async {
    try {
      final topic = 'building_$buildingId';
      await FirebaseMessaging.instance.unsubscribeFromTopic(topic);
      log('Unsubscribed from topic: $topic');
    } catch (e) {
      log('Error unsubscribing from topic: $e');
    }
  }
}

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  log("Handling a background message: ${message.messageId}");
}
