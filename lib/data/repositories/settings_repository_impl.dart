import '../../domain/repositories/settings_repository.dart';
import '../datasources/settings_remote_datasource.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  SettingsRepositoryImpl({required this.remoteDataSource});

  final SettingsRemoteDataSource remoteDataSource;

  @override
  Future<bool> getRequireAdminApproval() {
    return remoteDataSource.getRequireAdminApproval();
  }

  @override
  Future<void> setRequireAdminApproval(bool enabled) {
    return remoteDataSource.setRequireAdminApproval(enabled);
  }
}
