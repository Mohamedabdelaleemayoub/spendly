abstract class SettingsRepository {
  Future<bool> getRequireAdminApproval();
  Future<void> setRequireAdminApproval(bool enabled);
}
