import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/errors/app_failure.dart';
import '../../../domain/repositories/balance_repository.dart';
import 'admin_balance_state.dart';

class AdminBalanceCubit extends Cubit<AdminBalanceState> {
  AdminBalanceCubit({
    required this.balanceRepository,
  }) : super(const AdminBalanceInitial());

  final BalanceRepository balanceRepository;

  @override
  void emit(AdminBalanceState state) {
    if (!isClosed) {
      super.emit(state);
    }
  }

  Future<void> loadAllBalances() async {
    emit(const AdminBalanceLoading());
    try {
      final balances = await balanceRepository.getAllEmployeeBalances();
      emit(AdminBalanceLoaded(employeeBalances: balances));
    } on Failure catch (e) {
      emit(AdminBalanceError(e.message));
    } catch (e) {
      emit(AdminBalanceError('تعذر تحميل أرصدة الموظفين: $e'));
    }
  }

  Future<void> loadEmployeeFinancialDetails(String userId) async {
    try {
      final summary = await balanceRepository.getEmployeeBalanceSummary(userId);
      final history = await balanceRepository.getFinancialHistory(userId);

      final currentState = state;
      if (currentState is AdminBalanceLoaded) {
        emit(currentState.copyWith(
          selectedEmployeeSummary: summary,
          selectedEmployeeHistory: history,
        ));
      } else {
        emit(AdminBalanceLoaded(
          employeeBalances: const [],
          selectedEmployeeSummary: summary,
          selectedEmployeeHistory: history,
        ));
      }
    } on Failure catch (e) {
      emit(AdminBalanceError(e.message));
    } catch (e) {
      emit(AdminBalanceError('تعذر تحميل تفاصيل رصيد الموظف: $e'));
    }
  }

  Future<void> addBalance({
    required String userId,
    required double amount,
    DateTime? transactionDate,
    String? note,
  }) async {
    final currentState = state;
    if (currentState is AdminBalanceLoaded) {
      emit(currentState.copyWith(isAddingBalance: true));
    }

    try {
      final tx = await balanceRepository.addBalance(
        userId: userId,
        amount: amount,
        transactionDate: transactionDate,
        note: note,
      );

      final updatedSummary = await balanceRepository.getEmployeeBalanceSummary(userId);
      final updatedHistory = await balanceRepository.getFinancialHistory(userId);
      final allBalances = await balanceRepository.getAllEmployeeBalances();

      emit(AdminBalanceAddedSuccess(
        transaction: tx,
        updatedSummary: updatedSummary,
      ));

      emit(AdminBalanceLoaded(
        employeeBalances: allBalances,
        selectedEmployeeSummary: updatedSummary,
        selectedEmployeeHistory: updatedHistory,
        isAddingBalance: false,
      ));
    } on Failure catch (e) {
      emit(AdminBalanceError(e.message));
    } catch (e) {
      emit(AdminBalanceError('تعذر إضافة الرصيد: $e'));
    }
  }
}
