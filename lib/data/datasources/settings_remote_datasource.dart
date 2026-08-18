import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/errors/exception_mapper.dart';
import '../../domain/entities/travel_bonus_settings.dart';

abstract class SettingsRemoteDataSource {
  Future<bool> getRequireAdminApproval();
  Future<void> setRequireAdminApproval(bool enabled);
  Future<TravelBonusSettings> getTravelBonusSettings();
  Future<void> setTravelBonusSettings(TravelBonusSettings settings);
}

class SettingsRemoteDataSourceImpl implements SettingsRemoteDataSource {
  SettingsRemoteDataSourceImpl({required this.client});

  final SupabaseClient client;
  static const String _settingsTable = 'app_settings';
  static const String _approvalKey = 'require_admin_approval';
  static const String _travelBonusKey = 'travel_bonus_settings';

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

  @override
  Future<TravelBonusSettings> getTravelBonusSettings() async {
    try {
      final response = await client
          .from(_settingsTable)
          .select('value')
          .eq('key', _travelBonusKey)
          .maybeSingle();

      if (response == null) return const TravelBonusSettings();
      final val = response['value'];
      if (val is Map<String, dynamic>) {
        return TravelBonusSettings.fromJson(val);
      } else if (val is Map) {
        return TravelBonusSettings.fromJson(Map<String, dynamic>.from(val));
      }
      return const TravelBonusSettings();
    } catch (e) {
      throw mapExceptionToFailure(e);
    }
  }

  @override
  Future<void> setTravelBonusSettings(TravelBonusSettings settings) async {
    try {
      final user = client.auth.currentUser;
      await client.from(_settingsTable).upsert({
        'key': _travelBonusKey,
        'value': settings.toJson(),
        'updated_at': DateTime.now().toUtc().toIso8601String(),
        if (user != null) 'updated_by': user.id,
      });
    } catch (e) {
      throw mapExceptionToFailure(e);
    }
  }
}
