import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/errors/app_failure.dart';
import '../../../domain/repositories/auth_repository.dart';
import '../../../domain/repositories/balance_repository.dart';
import 'employee_balance_state.dart';

class EmployeeBalanceCubit extends Cubit<EmployeeBalanceState> {
  EmployeeBalanceCubit({
    required this.balanceRepository,
    required this.authRepository,
  }) : super(const EmployeeBalanceInitial());

  final BalanceRepository balanceRepository;
  final AuthRepository authRepository;

  @override
  void emit(EmployeeBalanceState state) {
    if (!isClosed) {
      super.emit(state);
    }
  }

  Future<void> loadBalance({String? userId}) async {
    emit(const EmployeeBalanceLoading());
    try {
      final targetUserId = userId ?? authRepository.currentUser?.id;
      if (targetUserId == null) {
        emit(const EmployeeBalanceError('المستخدم غير مسجل'));
        return;
      }

      final summary = await balanceRepository.getEmployeeBalanceSummary(targetUserId);
      final history = await balanceRepository.getFinancialHistory(targetUserId);

      emit(EmployeeBalanceLoaded(
        summary: summary,
        historyItems: history,
      ));
    } on Failure catch (e) {
      emit(EmployeeBalanceError(e.message));
    } catch (e) {
      emit(EmployeeBalanceError('تعذر تحميل الرصيد: $e'));
    }
  }
}
