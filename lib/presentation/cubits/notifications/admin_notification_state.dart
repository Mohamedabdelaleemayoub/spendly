import 'package:equatable/equatable.dart';
import '../../../domain/entities/admin_notification.dart';

sealed class AdminNotificationState extends Equatable {
  const AdminNotificationState();

  @override
  List<Object?> get props => [];
}

class AdminNotificationInitial extends AdminNotificationState {
  const AdminNotificationInitial();
}

class AdminNotificationLoading extends AdminNotificationState {
  const AdminNotificationLoading();
}

class AdminNotificationLoaded extends AdminNotificationState {
  const AdminNotificationLoaded({
    required this.notifications,
    required this.unreadCount,
  });

  final List<AdminNotification> notifications;
  final int unreadCount;

  @override
  List<Object?> get props => [notifications, unreadCount];
}

class AdminNotificationError extends AdminNotificationState {
  const AdminNotificationError(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}
