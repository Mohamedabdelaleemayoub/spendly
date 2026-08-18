import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/errors/exception_mapper.dart';

abstract class SettingsRemoteDataSource {
  Future<bool> getRequireAdminApproval();
  Future<void> setRequireAdminApproval(bool enabled);
}

class SettingsRemoteDataSourceImpl implements SettingsRemoteDataSource {
  SettingsRemoteDataSourceImpl({required this.client});

  final SupabaseClient client;
  static const String _settingsTable = 'app_settings';
  static const String _approvalKey = 'require_admin_approval';

  @override
  Future<bool> getRequireAdminApproval() async {
    try {
      final response = await client
          .from(_settingsTable)
          .select('value')
          .eq('key', _approvalKey)
          .maybeSingle();

      if (response == null) return false;
      final val = response['value'];
      if (val is Map && val['enabled'] != null) {
        return val['enabled'] == true;
      }
      return false;
    } catch (e) {
      throw mapExceptionToFailure(e);
    }
  }

  @override
  Future<void> setRequireAdminApproval(bool enabled) async {
    try {
      final user = client.auth.currentUser;
      await client.from(_settingsTable).upsert({
        'key': _approvalKey,
        'value': {'enabled': enabled},
        'updated_at': DateTime.now().toUtc().toIso8601String(),
        if (user != null) 'updated_by': user.id,
      });
    } catch (e) {
      throw mapExceptionToFailure(e);
    }
  }
}
