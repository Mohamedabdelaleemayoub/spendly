import '../../domain/entities/admin_notification.dart';
import 'profile_model.dart';

class AdminNotificationModel extends AdminNotification {
  const AdminNotificationModel({
    required super.id,
    required super.type,
    required super.title,
    required super.message,
    super.userId,
    super.userProfile,
    super.isRead = false,
    required super.createdAt,
  });

  factory AdminNotificationModel.fromJson(Map<String, dynamic> json) {
    ProfileModel? profile;
    if (json['profiles'] != null && json['profiles'] is Map<String, dynamic>) {
      profile = ProfileModel.fromJson(json['profiles'] as Map<String, dynamic>);
    }

    return AdminNotificationModel(
      id: json['id'] as String,
      type: json['type'] as String? ?? 'registration_request',
      title: json['title'] as String? ?? '',
      message: json['message'] as String? ?? '',
      userId: json['user_id'] as String?,
      userProfile: profile,
      isRead: json['is_read'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? (DateTime.tryParse(json['created_at'] as String)?.toLocal() ?? DateTime.now())
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'title': title,
      'message': message,
      if (userId != null) 'user_id': userId,
      'is_read': isRead,
    };
  }

  factory AdminNotificationModel.fromEntity(AdminNotification notification) {
    return AdminNotificationModel(
      id: notification.id,
      type: notification.type,
      title: notification.title,
      message: notification.message,
      userId: notification.userId,
      userProfile: notification.userProfile,
      isRead: notification.isRead,
      createdAt: notification.createdAt,
    );
  }
}
