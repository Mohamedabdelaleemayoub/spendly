import 'package:equatable/equatable.dart';

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
    this.isUpdating = false,
  });

  final bool requireAdminApproval;
  final bool isUpdating;

  AdminSettingsLoaded copyWith({
    bool? requireAdminApproval,
    bool? isUpdating,
  }) {
    return AdminSettingsLoaded(
      requireAdminApproval: requireAdminApproval ?? this.requireAdminApproval,
      isUpdating: isUpdating ?? this.isUpdating,
    );
  }

  @override
  List<Object?> get props => [requireAdminApproval, isUpdating];
}

class AdminSettingsError extends AdminSettingsState {
  const AdminSettingsError(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}
