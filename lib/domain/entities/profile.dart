import 'package:equatable/equatable.dart';
import 'user_role.dart';

class Profile extends Equatable {
  const Profile({
    required this.id,
    required this.name,
    this.email,
    this.role = 'employee',
    this.status = 'active',
    this.avatarUrl,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String name;
  final String? email;
  final String role;
  final String status;
  final String? avatarUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  UserRole get userRole => UserRole.fromString(role);
  bool get isAdmin => userRole.isAdmin;
  bool get isEmployee => userRole.isEmployee;

  bool get isActive => status == 'active';
  bool get isInactive => status == 'inactive';

  Profile copyWith({
    String? id,
    String? name,
    String? email,
    String? role,
    String? status,
    String? avatarUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Profile(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      status: status ?? this.status,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [id, name, email, role, status, avatarUrl, createdAt, updatedAt];
}
