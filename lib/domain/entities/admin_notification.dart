import 'package:equatable/equatable.dart';
import 'profile.dart';

class AdminNotification extends Equatable {
  const AdminNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    this.userId,
    this.userProfile,
    this.isRead = false,
    required this.createdAt,
  });

  final String id;
  final String type;
  final String title;
  final String message;
  final String? userId;
  final Profile? userProfile;
  final bool isRead;
  final DateTime createdAt;

  AdminNotification copyWith({
    String? id,
    String? type,
    String? title,
    String? message,
    String? userId,
    Profile? userProfile,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return AdminNotification(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      userId: userId ?? this.userId,
      userProfile: userProfile ?? this.userProfile,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [id, type, title, message, userId, userProfile, isRead, createdAt];
}
