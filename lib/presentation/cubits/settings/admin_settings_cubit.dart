import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/errors/app_failure.dart';
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
      emit(AdminSettingsLoaded(requireAdminApproval: requireApproval));
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
      emit(AdminSettingsLoaded(requireAdminApproval: enabled, isUpdating: false));
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
}
