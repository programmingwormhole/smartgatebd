import 'package:get/get.dart';
import '../models/notification_model.dart';
import '../services/notification_api_service.dart';
import '../core/constants/app_config.dart';

class NotificationController extends GetxController {
  static final NotificationController _instance =
      NotificationController._internal();

  final NotificationApiService _apiService = NotificationApiService();

  List<NotificationModel> _notifications = [];
  int _unreadCount = 0;
  RxBool isLoading = RxBool(false);
  int _currentPage = 1;
  bool _hasMorePages = true;
  bool _isPeriodicRefreshEnabled = false;
  bool _isPeriodicLoopRunning = false;

  List<NotificationModel> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoadingGetter => isLoading.value;
  bool get hasMorePages => _hasMorePages;

  factory NotificationController() {
    return _instance;
  }

  NotificationController._internal();

  @override
  void onInit() {
    super.onInit();
    if (AppConfig.showDBNotification) {
      fetchNotifications();
      fetchUnreadCount();
    }
  }

  @override
  void onClose() {
    stopPeriodicRefresh();
    super.onClose();
  }

  void setMainPageActive(bool isActive) {
    if (!AppConfig.showDBNotification) return;

    _isPeriodicRefreshEnabled = isActive;

    if (isActive) {
      fetchUnreadCount();
      startPeriodicRefresh();
    }
  }

  void startPeriodicRefresh() {
    if (!AppConfig.showDBNotification || _isPeriodicLoopRunning) return;

    _isPeriodicLoopRunning = true;

    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 10));

      if (!isClosed && _isPeriodicRefreshEnabled) {
        await fetchUnreadCount();
      }

      final shouldContinue = !isClosed && _isPeriodicRefreshEnabled;
      if (!shouldContinue) {
        _isPeriodicLoopRunning = false;
      }
      return shouldContinue;
    });
  }

  void stopPeriodicRefresh() {
    _isPeriodicRefreshEnabled = false;
  }

  Future<void> fetchNotifications({int page = 1, bool refresh = false}) async {
    // Skip if database notifications are disabled
    if (!AppConfig.showDBNotification) return;

    if (refresh) {
      _currentPage = 1;
      _notifications.clear();
    }

    isLoading.value = true;
    update();

    try {
      final result = await _apiService.getNotifications(page: page);
      final notificationsList = (result['notifications'] as List)
          .map((n) => NotificationModel.fromJson(n))
          .toList();

      if (page == 1) {
        _notifications = notificationsList;
      } else {
        _notifications.addAll(notificationsList);
      }

      _currentPage = page;
      _hasMorePages =
          notificationsList.isNotEmpty && notificationsList.length >= 20;
    } catch (e) {
      print('Error fetching notifications: $e');
    } finally {
      isLoading.value = false;
      update();
    }
  }

  Future<void> fetchUnreadCount() async {
    // Skip if database notifications are disabled
    if (!AppConfig.showDBNotification) return;

    try {
      final newCount = await _apiService.getUnreadCount();
      if (_unreadCount != newCount) {
        _unreadCount = newCount;
        update();
      }
    } catch (e) {
      print('Error fetching unread count: $e');
    }
  }

  // Refresh both notifications and unread count
  Future<void> refreshNotifications() async {
    if (!AppConfig.showDBNotification) return;

    await fetchNotifications(refresh: true);
    await fetchUnreadCount();
  }

  Future<void> loadMoreNotifications() async {
    if (!AppConfig.showDBNotification || !_hasMorePages || isLoading.value)
      return;
    await fetchNotifications(page: _currentPage + 1);
  }

  Future<void> markAsRead(int notificationId) async {
    // Skip if database notifications are disabled
    if (!AppConfig.showDBNotification) return;

    try {
      await _apiService.markAsRead(notificationId);

      // Update local list
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        _notifications[index] = NotificationModel(
          id: _notifications[index].id,
          userId: _notifications[index].userId,
          title: _notifications[index].title,
          message: _notifications[index].message,
          type: _notifications[index].type,
          refType: _notifications[index].refType,
          refId: _notifications[index].refId,
          isRead: true,
          readAt: DateTime.now().toIso8601String(),
          createdAt: _notifications[index].createdAt,
          updatedAt: DateTime.now().toIso8601String(),
        );
      }

      await fetchUnreadCount();
      update();
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  Future<void> markAllAsRead() async {
    // Skip if database notifications are disabled
    if (!AppConfig.showDBNotification) return;

    try {
      await _apiService.markAllAsRead();

      // Update local list
      for (int i = 0; i < _notifications.length; i++) {
        _notifications[i] = NotificationModel(
          id: _notifications[i].id,
          userId: _notifications[i].userId,
          title: _notifications[i].title,
          message: _notifications[i].message,
          type: _notifications[i].type,
          refType: _notifications[i].refType,
          refId: _notifications[i].refId,
          isRead: true,
          readAt: DateTime.now().toIso8601String(),
          createdAt: _notifications[i].createdAt,
          updatedAt: DateTime.now().toIso8601String(),
        );
      }

      _unreadCount = 0;
      update();
    } catch (e) {
      print('Error marking all as read: $e');
    }
  }

  Future<void> deleteNotification(int notificationId) async {
    // Skip if database notifications are disabled
    if (!AppConfig.showDBNotification) return;

    try {
      await _apiService.deleteNotification(notificationId);

      // Update local list
      _notifications.removeWhere((n) => n.id == notificationId);

      await fetchUnreadCount();
      update();
    } catch (e) {
      print('Error deleting notification: $e');
    }
  }
}
