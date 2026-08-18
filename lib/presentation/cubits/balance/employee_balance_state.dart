import 'package:equatable/equatable.dart';
import '../../../domain/entities/employee_balance_summary.dart';
import '../../../domain/entities/financial_history_item.dart';

sealed class EmployeeBalanceState extends Equatable {
  const EmployeeBalanceState();

  @override
  List<Object?> get props => [];
}

class EmployeeBalanceInitial extends EmployeeBalanceState {
  const EmployeeBalanceInitial();
}

class EmployeeBalanceLoading extends EmployeeBalanceState {
  const EmployeeBalanceLoading();
}

class EmployeeBalanceLoaded extends EmployeeBalanceState {
  const EmployeeBalanceLoaded({
    required this.summary,
    required this.historyItems,
  });

  final EmployeeBalanceSummary summary;
  final List<FinancialHistoryItem> historyItems;

  @override
  List<Object?> get props => [summary, historyItems];
}

class EmployeeBalanceError extends EmployeeBalanceState {
  const EmployeeBalanceError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
