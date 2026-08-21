import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/audit_log_model.dart';

abstract class AuditRemoteDataSource {
  Future<List<AuditLogModel>> getAuditLogs({
    String? entityType,
    String? userId,
    int? limit,
    int? offset,
  });
  Future<void> insertAuditLog(AuditLogModel log);
}

class AuditRemoteDataSourceImpl implements AuditRemoteDataSource {
  const AuditRemoteDataSourceImpl({required this.client});

  final SupabaseClient client;

  @override
  Future<List<AuditLogModel>> getAuditLogs({
    String? entityType,
    String? userId,
    int? limit,
    int? offset,
  }) async {
    var query = client
        .from('audit_logs')
        .select('*, profiles:profiles(full_name, email)');

    if (entityType != null && entityType.isNotEmpty) {
      query = query.eq('entity_type', entityType);
    }
    if (userId != null && userId.isNotEmpty) {
      query = query.eq('user_id', userId);
    }

    final response = await query
        .order('created_at', ascending: false)
        .range(offset ?? 0, (offset ?? 0) + (limit ?? 50) - 1);

    return (response as List<dynamic>)
        .map((j) => AuditLogModel.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> insertAuditLog(AuditLogModel log) async {
    await client.from('audit_logs').insert(log.toJson(includeId: true));
  }
}
