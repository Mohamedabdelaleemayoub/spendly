import '../entities/audit_log.dart';

abstract class AuditRepository {
  Future<List<AuditLog>> getAuditLogs({
    String? entityType,
    String? userId,
    String? action,
    int? limit,
    int? offset,
  });

  Future<void> logAction({
    required String action,
    required String entityType,
    String? entityId,
    Map<String, dynamic>? oldValue,
    Map<String, dynamic>? newValue,
  });
}
