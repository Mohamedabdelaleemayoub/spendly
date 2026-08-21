import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/errors/app_failure.dart';
import '../../core/services/uuid_generator.dart';
import '../../domain/entities/audit_log.dart';
import '../../domain/repositories/audit_repository.dart';
import '../datasources/audit_remote_datasource.dart';
import '../datasources/local_database.dart';
import '../models/audit_log_model.dart';

class AuditRepositoryImpl implements AuditRepository {
  AuditRepositoryImpl({
    required this.remoteDataSource,
    required this.localDatabase,
    required this.supabaseClient,
  });

  final AuditRemoteDataSource remoteDataSource;
  final LocalDatabase localDatabase;
  final SupabaseClient supabaseClient;

  @override
  Future<List<AuditLog>> getAuditLogs({
    String? entityType,
    String? userId,
    String? action,
    int? limit,
    int? offset,
  }) async {
    // 1. Always attempt to read cached local logs first
    final localLogs = await localDatabase.getAuditLogs(
      entityType: entityType,
      userId: userId,
      action: action,
      limit: limit,
      offset: offset,
    );

    // 2. If online and admin, pull remote logs
    try {
      final currentUserId = supabaseClient.auth.currentUser?.id;
      if (currentUserId != null) {
        final profile = await localDatabase.getProfile(currentUserId);
        if (profile?.role == 'admin') {
          final remoteLogs = await remoteDataSource.getAuditLogs(
            entityType: entityType,
            userId: userId,
            limit: limit,
            offset: offset,
          );
          await localDatabase.saveAuditLogs(remoteLogs);
          return remoteLogs;
        }
      }
    } catch (e) {
      debugPrint('ℹ️ [AuditRepositoryImpl] Using local cached audit logs: $e');
    }

    return localLogs;
  }

  @override
  Future<void> logAction({
    required String action,
    required String entityType,
    String? entityId,
    Map<String, dynamic>? oldValue,
    Map<String, dynamic>? newValue,
  }) async {
    try {
      final currentUserId = supabaseClient.auth.currentUser?.id;
      final currentProfile = currentUserId != null ? await localDatabase.getProfile(currentUserId) : null;
      final logId = UuidGenerator.generate();
      final now = DateTime.now();

      final model = AuditLogModel(
        id: logId,
        userId: currentUserId,
        userName: currentProfile?.name,
        action: action,
        entityType: entityType,
        entityId: entityId,
        oldValue: oldValue,
        newValue: newValue,
        createdAt: now,
      );

      // Save locally
      await localDatabase.saveAuditLog(model);

      // Enqueue sync operation
      await localDatabase.enqueueSyncOperation(
        operationId: UuidGenerator.generate(),
        entityType: 'audit_log',
        entityId: logId,
        operation: 'INSERT',
        payload: model.toJson(includeId: true),
      );
    } catch (e) {
      debugPrint('⚠️ [AuditRepositoryImpl] Failed to log action: $e');
      throw DatabaseFailure('فشل تسجيل السجل: $e');
    }
  }
}
