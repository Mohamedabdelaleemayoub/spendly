import 'package:equatable/equatable.dart';
import '../../../domain/entities/audit_log.dart';

sealed class AuditState extends Equatable {
  const AuditState();

  @override
  List<Object?> get props => [];
}

class AuditInitial extends AuditState {
  const AuditInitial();
}

class AuditLoading extends AuditState {
  const AuditLoading();
}

class AuditLoaded extends AuditState {
  const AuditLoaded({
    required this.logs,
    this.selectedEntityType,
    this.searchQuery,
  });

  final List<AuditLog> logs;
  final String? selectedEntityType;
  final String? searchQuery;

  List<AuditLog> get filteredLogs {
    return logs.where((log) {
      if (selectedEntityType != null && selectedEntityType!.isNotEmpty) {
        if (log.entityType != selectedEntityType) return false;
      }
      if (searchQuery != null && searchQuery!.trim().isNotEmpty) {
        final q = searchQuery!.toLowerCase().trim();
        final matchAction = log.action.toLowerCase().contains(q);
        final matchName = log.userName?.toLowerCase().contains(q) ?? false;
        final matchEntity = log.entityType.toLowerCase().contains(q);
        if (!matchAction && !matchName && !matchEntity) return false;
      }
      return true;
    }).toList();
  }

  AuditLoaded copyWith({
    List<AuditLog>? logs,
    String? selectedEntityType,
    String? searchQuery,
  }) {
    return AuditLoaded(
      logs: logs ?? this.logs,
      selectedEntityType: selectedEntityType ?? this.selectedEntityType,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  @override
  List<Object?> get props => [logs, selectedEntityType, searchQuery];
}

class AuditError extends AuditState {
  const AuditError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
