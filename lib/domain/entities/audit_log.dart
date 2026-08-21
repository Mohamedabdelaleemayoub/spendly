import 'package:equatable/equatable.dart';

/// Represents an immutable audit trail entry for critical business mutations.
class AuditLog extends Equatable {
  const AuditLog({
    required this.id,
    this.userId,
    this.userName,
    required this.action,
    required this.entityType,
    this.entityId,
    this.oldValue,
    this.newValue,
    required this.createdAt,
  });

  final String id;
  final String? userId;
  final String? userName;
  final String action;
  final String entityType;
  final String? entityId;
  final Map<String, dynamic>? oldValue;
  final Map<String, dynamic>? newValue;
  final DateTime createdAt;

  @override
  List<Object?> get props => [
        id,
        userId,
        userName,
        action,
        entityType,
        entityId,
        oldValue,
        newValue,
        createdAt,
      ];
}
