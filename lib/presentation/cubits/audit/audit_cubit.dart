import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/repositories/audit_repository.dart';
import 'audit_state.dart';

class AuditCubit extends Cubit<AuditState> {
  AuditCubit({required this.auditRepository}) : super(const AuditInitial());

  final AuditRepository auditRepository;

  @override
  void emit(AuditState state) {
    if (!isClosed) {
      super.emit(state);
    }
  }

  Future<void> loadAuditLogs({String? entityType}) async {
    emit(const AuditLoading());
    try {
      final logs = await auditRepository.getAuditLogs(entityType: entityType);
      emit(AuditLoaded(logs: logs, selectedEntityType: entityType));
    } catch (e) {
      emit(AuditError('فشل تحميل سجل العمليات: $e'));
    }
  }

  void filterByEntityType(String? entityType) {
    final currentState = state;
    if (currentState is AuditLoaded) {
      emit(currentState.copyWith(selectedEntityType: entityType));
    } else {
      loadAuditLogs(entityType: entityType);
    }
  }

  void search(String query) {
    final currentState = state;
    if (currentState is AuditLoaded) {
      emit(currentState.copyWith(searchQuery: query));
    }
  }
}
