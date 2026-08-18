import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/errors/exception_mapper.dart';
import '../models/admin_notification_model.dart';

abstract class NotificationRemoteDataSource {
  Future<List<AdminNotificationModel>> getNotifications();
  Future<void> markAsRead(String id);
  Future<void> markAllAsRead();
  Future<int> getUnreadCount();
}

class NotificationRemoteDataSourceImpl implements NotificationRemoteDataSource {
  NotificationRemoteDataSourceImpl({required this.client});

  final SupabaseClient client;
  static const String _notificationsTable = 'admin_notifications';

  static const String _selectColumns = '''
    *,
    profiles:profiles!admin_notifications_user_id_fkey(
      id,
      full_name,
      email,
      role,
      status,
      avatar_url
    )
  ''';

  @override
  Future<List<AdminNotificationModel>> getNotifications() async {
    try {
      final response = await client
          .from(_notificationsTable)
          .select(_selectColumns)
          .order('created_at', ascending: false)
          .limit(50);

      return (response as List<dynamic>)
          .map((json) => AdminNotificationModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw mapExceptionToFailure(e);
    }
  }

  @override
  Future<void> markAsRead(String id) async {
    try {
      await client
          .from(_notificationsTable)
          .update({'is_read': true})
          .eq('id', id);
    } catch (e) {
      throw mapExceptionToFailure(e);
    }
  }

  @override
  Future<void> markAllAsRead() async {
    try {
      await client
          .from(_notificationsTable)
          .update({'is_read': true})
          .eq('is_read', false);
    } catch (e) {
      throw mapExceptionToFailure(e);
    }
  }

  @override
  Future<int> getUnreadCount() async {
    try {
      final response = await client
          .from(_notificationsTable)
          .select('id')
          .eq('is_read', false);

      return (response as List<dynamic>).length;
    } catch (e) {
      return 0;
    }
  }
}
