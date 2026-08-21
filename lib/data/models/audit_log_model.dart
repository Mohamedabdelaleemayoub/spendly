import 'dart:convert';
import '../../domain/entities/audit_log.dart';

/// Data model for [AuditLog] supporting JSON and SQLite conversions.
class AuditLogModel extends AuditLog {
  const AuditLogModel({
    required super.id,
    super.userId,
    super.userName,
    required super.action,
    required super.entityType,
    super.entityId,
    super.oldValue,
    super.newValue,
    required super.createdAt,
  });

  factory AuditLogModel.fromEntity(AuditLog entity) {
    return AuditLogModel(
      id: entity.id,
      userId: entity.userId,
      userName: entity.userName,
      action: entity.action,
      entityType: entity.entityType,
      entityId: entity.entityId,
      oldValue: entity.oldValue,
      newValue: entity.newValue,
      createdAt: entity.createdAt,
    );
  }

  factory AuditLogModel.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic>? parseJsonMap(dynamic val) {
      if (val == null) return null;
      if (val is Map<String, dynamic>) return val;
      if (val is Map) return Map<String, dynamic>.from(val);
      if (val is String && val.trim().isNotEmpty) {
        try {
          final decoded = jsonDecode(val);
          if (decoded is Map<String, dynamic>) return decoded;
          if (decoded is Map) return Map<String, dynamic>.from(decoded);
        } catch (_) {}
      }
      return null;
    }

    String? name;
    if (json['profiles'] != null && json['profiles'] is Map) {
      name = json['profiles']['full_name'] as String?;
    } else if (json['user_name'] != null) {
      name = json['user_name'] as String?;
    }

    return AuditLogModel(
      id: json['id'] as String,
      userId: json['user_id'] as String?,
      userName: name,
      action: json['action'] as String? ?? 'unknown',
      entityType: json['entity_type'] as String? ?? 'general',
      entityId: json['entity_id'] as String?,
      oldValue: parseJsonMap(json['old_value']),
      newValue: parseJsonMap(json['new_value']),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson({bool includeId = true}) {
    return {
      if (includeId) 'id': id,
      if (userId != null) 'user_id': userId,
      'action': action,
      'entity_type': entityType,
      if (entityId != null) 'entity_id': entityId,
      if (oldValue != null) 'old_value': oldValue,
      if (newValue != null) 'new_value': newValue,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toLocalDbRow() {
    return {
      'id': id,
      'user_id': userId,
      'user_name': userName,
      'action': action,
      'entity_type': entityType,
      'entity_id': entityId,
      'old_value': oldValue != null ? jsonEncode(oldValue) : null,
      'new_value': newValue != null ? jsonEncode(newValue) : null,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
