import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/errors/app_failure.dart';
import '../../../domain/repositories/notification_repository.dart';
import 'admin_notification_state.dart';

class AdminNotificationCubit extends Cubit<AdminNotificationState> {
  AdminNotificationCubit({required this.notificationRepository})
      : super(const AdminNotificationInitial());

  final NotificationRepository notificationRepository;

  @override
  void emit(AdminNotificationState state) {
    if (!isClosed) {
      super.emit(state);
    }
  }

  Future<void> loadNotifications() async {
    emit(const AdminNotificationLoading());
    try {
      final list = await notificationRepository.getNotifications();
      final count = list.where((n) => !n.isRead).length;
      emit(AdminNotificationLoaded(notifications: list, unreadCount: count));
    } on Failure catch (e) {
      emit(AdminNotificationError(e.message));
    } catch (e) {
      emit(AdminNotificationError('فشل تحميل الإشعارات: $e'));
    }
  }

  Future<void> markAsRead(String id) async {
    try {
      await notificationRepository.markAsRead(id);
      await loadNotifications();
    } catch (_) {}
  }

  Future<void> markAllAsRead() async {
    try {
      await notificationRepository.markAllAsRead();
      await loadNotifications();
    } catch (_) {}
  }
}
