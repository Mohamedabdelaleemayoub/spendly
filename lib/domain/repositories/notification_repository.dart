import '../entities/admin_notification.dart';

abstract class NotificationRepository {
  Future<List<AdminNotification>> getNotifications();
  Future<void> markAsRead(String id);
  Future<void> markAllAsRead();
  Future<int> getUnreadCount();
}
