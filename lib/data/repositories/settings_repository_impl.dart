import 'package:flutter/foundation.dart';
import '../../core/services/uuid_generator.dart';
import '../../domain/entities/travel_bonus_settings.dart';
import '../../domain/repositories/settings_repository.dart';
import '../datasources/local_database.dart';
import '../datasources/settings_remote_datasource.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  SettingsRepositoryImpl({
    required this.remoteDataSource,
    this.localDatabase,
  });

  final SettingsRemoteDataSource remoteDataSource;
  final LocalDatabase? localDatabase;

  static const String _approvalKey = 'require_admin_approval';
  static const String _travelBonusKey = 'travel_bonus_settings';

  @override
  Future<bool> getRequireAdminApproval() async {
    try {
      final remote = await remoteDataSource.getRequireAdminApproval();
      if (localDatabase != null && localDatabase!.isInitialized) {
        await localDatabase!.saveSetting(_approvalKey, {'enabled': remote});
      }
      return remote;
    } catch (e) {
      debugPrint('⚠️ [SettingsRepositoryImpl] Remote getRequireAdminApproval failed ($e), reading local DB.');
      if (localDatabase != null && localDatabase!.isInitialized) {
        final val = await localDatabase!.getSetting(_approvalKey);
        if (val is Map && val['enabled'] != null) {
          return val['enabled'] == true;
        }
      }
      return false;
    }
  }

  @override
  Future<void> setRequireAdminApproval(bool enabled) async {
    if (localDatabase != null && localDatabase!.isInitialized) {
      await localDatabase!.saveSetting(_approvalKey, {'enabled': enabled});
    }

    try {
      await remoteDataSource.setRequireAdminApproval(enabled);
    } catch (e) {
      debugPrint('⚠️ [SettingsRepositoryImpl] Remote setRequireAdminApproval failed ($e), queued locally.');
      if (localDatabase != null && localDatabase!.isInitialized) {
        await localDatabase!.enqueueSyncOperation(
          operationId: UuidGenerator.generate(),
          entityType: 'settings',
          entityId: _approvalKey,
          operation: 'UPDATE',
          payload: {
            'key': _approvalKey,
            'value': {'enabled': enabled},
          },
        );
      }
    }
  }

  @override
  Future<TravelBonusSettings> getTravelBonusSettings() async {
    try {
      final remote = await remoteDataSource.getTravelBonusSettings();
      if (localDatabase != null && localDatabase!.isInitialized) {
        await localDatabase!.saveSetting(_travelBonusKey, remote.toJson());
      }
      return remote;
    } catch (e) {
      debugPrint('⚠️ [SettingsRepositoryImpl] Remote getTravelBonusSettings failed ($e), reading local DB.');
      if (localDatabase != null && localDatabase!.isInitialized) {
        final val = await localDatabase!.getSetting(_travelBonusKey);
        if (val is Map<String, dynamic>) {
          return TravelBonusSettings.fromJson(val);
        } else if (val is Map) {
          return TravelBonusSettings.fromJson(Map<String, dynamic>.from(val));
        }
      }
      return const TravelBonusSettings();
    }
  }

  @override
  Future<void> setTravelBonusSettings(TravelBonusSettings settings) async {
    if (localDatabase != null && localDatabase!.isInitialized) {
      await localDatabase!.saveSetting(_travelBonusKey, settings.toJson());
    }

    try {
      await remoteDataSource.setTravelBonusSettings(settings);
    } catch (e) {
      debugPrint('⚠️ [SettingsRepositoryImpl] Remote setTravelBonusSettings failed ($e), queued locally.');
      if (localDatabase != null && localDatabase!.isInitialized) {
        await localDatabase!.enqueueSyncOperation(
          operationId: UuidGenerator.generate(),
          entityType: 'settings',
          entityId: _travelBonusKey,
          operation: 'UPDATE',
          payload: {
            'key': _travelBonusKey,
            'value': settings.toJson(),
          },
        );
      }
    }
  }
}
