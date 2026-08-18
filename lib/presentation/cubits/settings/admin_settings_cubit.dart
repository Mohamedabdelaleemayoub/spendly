import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/errors/app_failure.dart';
import '../../../domain/entities/expense_currency.dart';
import '../../../domain/entities/travel_bonus_settings.dart';
import '../../../domain/repositories/settings_repository.dart';
import 'admin_settings_state.dart';

class AdminSettingsCubit extends Cubit<AdminSettingsState> {
  AdminSettingsCubit({required this.settingsRepository})
      : super(const AdminSettingsInitial());

  final SettingsRepository settingsRepository;

  @override
  void emit(AdminSettingsState state) {
    if (!isClosed) {
      super.emit(state);
    }
  }

  Future<void> loadSettings() async {
    emit(const AdminSettingsLoading());
    try {
      final requireApproval = await settingsRepository.getRequireAdminApproval();
      final bonusSettings = await settingsRepository.getTravelBonusSettings();
      emit(AdminSettingsLoaded(
        requireAdminApproval: requireApproval,
        travelBonusSettings: bonusSettings,
      ));
    } on Failure catch (e) {
      emit(AdminSettingsError(e.message));
    } catch (e) {
      emit(AdminSettingsError('فشل تحميل الإعدادات: $e'));
    }
  }

  Future<void> toggleRequireAdminApproval(bool enabled) async {
    final currentState = state;
    if (currentState is AdminSettingsLoaded) {
      emit(currentState.copyWith(isUpdating: true));
    }

    try {
      await settingsRepository.setRequireAdminApproval(enabled);
      final currentBonus = (currentState is AdminSettingsLoaded)
          ? currentState.travelBonusSettings
          : const TravelBonusSettings();

      emit(AdminSettingsLoaded(
        requireAdminApproval: enabled,
        travelBonusSettings: currentBonus,
        isUpdating: false,
      ));
    } on Failure catch (e) {
      emit(AdminSettingsError(e.message));
      if (currentState is AdminSettingsLoaded) {
        emit(currentState.copyWith(isUpdating: false));
      }
    } catch (e) {
      emit(AdminSettingsError('فشل حفظ إعداد الموافقة: $e'));
      if (currentState is AdminSettingsLoaded) {
        emit(currentState.copyWith(isUpdating: false));
      }
    }
  }

  Future<void> updateTravelBonusSettings({
    required bool enabled,
    required double bonusPerTrip,
    required ExpenseCurrency currency,
  }) async {
    final currentState = state;
    if (currentState is AdminSettingsLoaded) {
      emit(currentState.copyWith(isUpdating: true));
    }

    final newSettings = TravelBonusSettings(
      enabled: enabled,
      bonusPerTrip: bonusPerTrip,
      currency: currency,
    );

    try {
      await settingsRepository.setTravelBonusSettings(newSettings);
      final currentApproval = (currentState is AdminSettingsLoaded)
          ? currentState.requireAdminApproval
          : false;

      emit(AdminSettingsLoaded(
        requireAdminApproval: currentApproval,
        travelBonusSettings: newSettings,
        isUpdating: false,
      ));
    } on Failure catch (e) {
      emit(AdminSettingsError(e.message));
      if (currentState is AdminSettingsLoaded) {
        emit(currentState.copyWith(isUpdating: false));
      }
    } catch (e) {
      emit(AdminSettingsError('فشل حفظ إعدادات بدل السفر: $e'));
      if (currentState is AdminSettingsLoaded) {
        emit(currentState.copyWith(isUpdating: false));
      }
    }
  }
}
