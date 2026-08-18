import 'package:equatable/equatable.dart';
import '../../../domain/entities/balance_transaction.dart';
import '../../../domain/entities/employee_balance_summary.dart';
import '../../../domain/entities/financial_history_item.dart';

sealed class AdminBalanceState extends Equatable {
  const AdminBalanceState();

  @override
  List<Object?> get props => [];
}

class AdminBalanceInitial extends AdminBalanceState {
  const AdminBalanceInitial();
}

class AdminBalanceLoading extends AdminBalanceState {
  const AdminBalanceLoading();
}

class AdminBalanceLoaded extends AdminBalanceState {
  const AdminBalanceLoaded({
    required this.employeeBalances,
    this.selectedEmployeeSummary,
    this.selectedEmployeeHistory = const [],
    this.isAddingBalance = false,
  });

  final List<EmployeeBalanceSummary> employeeBalances;
  final EmployeeBalanceSummary? selectedEmployeeSummary;
  final List<FinancialHistoryItem> selectedEmployeeHistory;
  final bool isAddingBalance;

  AdminBalanceLoaded copyWith({
    List<EmployeeBalanceSummary>? employeeBalances,
    EmployeeBalanceSummary? selectedEmployeeSummary,
    List<FinancialHistoryItem>? selectedEmployeeHistory,
    bool? isAddingBalance,
  }) {
    return AdminBalanceLoaded(
      employeeBalances: employeeBalances ?? this.employeeBalances,
      selectedEmployeeSummary: selectedEmployeeSummary ?? this.selectedEmployeeSummary,
      selectedEmployeeHistory: selectedEmployeeHistory ?? this.selectedEmployeeHistory,
      isAddingBalance: isAddingBalance ?? this.isAddingBalance,
    );
  }

  @override
  List<Object?> get props => [
        employeeBalances,
        selectedEmployeeSummary,
        selectedEmployeeHistory,
        isAddingBalance,
      ];
}

class AdminBalanceAddedSuccess extends AdminBalanceState {
  const AdminBalanceAddedSuccess({
    required this.transaction,
    required this.updatedSummary,
  });

  final BalanceTransaction transaction;
  final EmployeeBalanceSummary updatedSummary;

  @override
  List<Object?> get props => [transaction, updatedSummary];
}

class AdminBalanceError extends AdminBalanceState {
  const AdminBalanceError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
