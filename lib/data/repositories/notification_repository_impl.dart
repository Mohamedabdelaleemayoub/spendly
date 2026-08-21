import 'package:flutter/foundation.dart';
import '../../domain/entities/admin_notification.dart';
import '../../domain/repositories/notification_repository.dart';
import '../datasources/local_database.dart';
import '../datasources/notification_remote_datasource.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  NotificationRepositoryImpl({
    required this.remoteDataSource,
    this.localDatabase,
  });

  final NotificationRemoteDataSource remoteDataSource;
  final LocalDatabase? localDatabase;

  @override
  Future<List<AdminNotification>> getNotifications() async {
    try {
      final remote = await remoteDataSource.getNotifications();
      if (localDatabase != null && localDatabase!.isInitialized) {
        await localDatabase!.saveNotifications(remote);
      }
      return remote;
    } catch (e) {
      debugPrint('⚠️ [NotificationRepositoryImpl] Remote getNotifications failed ($e), reading local DB.');
      if (localDatabase != null && localDatabase!.isInitialized) {
        return await localDatabase!.getNotifications();
      }
      return [];
    }
  }

  @override
  Future<void> markAsRead(String id) async {
    if (localDatabase != null && localDatabase!.isInitialized) {
      await localDatabase!.markNotificationAsRead(id);
    }
    try {
      await remoteDataSource.markAsRead(id);
    } catch (_) {}
  }

  @override
  Future<void> markAllAsRead() async {
    if (localDatabase != null && localDatabase!.isInitialized) {
      await localDatabase!.markAllNotificationsAsRead();
    }
    try {
      await remoteDataSource.markAllAsRead();
    } catch (_) {}
  }

  @override
  Future<int> getUnreadCount() async {
    try {
      return await remoteDataSource.getUnreadCount();
    } catch (_) {
      if (localDatabase != null && localDatabase!.isInitialized) {
        final notifs = await localDatabase!.getNotifications();
        return notifs.where((n) => !n.isRead).length;
      }
      return 0;
    }
  }
}
