import 'package:equatable/equatable.dart';
import '../../../domain/entities/travel_bonus_settings.dart';

sealed class AdminSettingsState extends Equatable {
  const AdminSettingsState();

  @override
  List<Object?> get props => [];
}

class AdminSettingsInitial extends AdminSettingsState {
  const AdminSettingsInitial();
}

class AdminSettingsLoading extends AdminSettingsState {
  const AdminSettingsLoading();
}

class AdminSettingsLoaded extends AdminSettingsState {
  const AdminSettingsLoaded({
    required this.requireAdminApproval,
    this.travelBonusSettings = const TravelBonusSettings(),
    this.isUpdating = false,
  });

  final bool requireAdminApproval;
  final TravelBonusSettings travelBonusSettings;
  final bool isUpdating;

  AdminSettingsLoaded copyWith({
    bool? requireAdminApproval,
    TravelBonusSettings? travelBonusSettings,
    bool? isUpdating,
  }) {
    return AdminSettingsLoaded(
      requireAdminApproval: requireAdminApproval ?? this.requireAdminApproval,
      travelBonusSettings: travelBonusSettings ?? this.travelBonusSettings,
      isUpdating: isUpdating ?? this.isUpdating,
    );
  }

  @override
  List<Object?> get props => [requireAdminApproval, travelBonusSettings, isUpdating];
}

class AdminSettingsError extends AdminSettingsState {
  const AdminSettingsError(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}
