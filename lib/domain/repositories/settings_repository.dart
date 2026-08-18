import '../entities/travel_bonus_settings.dart';

abstract class SettingsRepository {
  Future<bool> getRequireAdminApproval();
  Future<void> setRequireAdminApproval(bool enabled);
  Future<TravelBonusSettings> getTravelBonusSettings();
  Future<void> setTravelBonusSettings(TravelBonusSettings settings);
}
