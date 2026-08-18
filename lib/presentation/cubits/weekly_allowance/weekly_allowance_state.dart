import 'package:equatable/equatable.dart';
import '../../../core/utils/date_time_utils.dart';
import '../../../domain/entities/expense_currency.dart';
import '../../../domain/entities/weekly_allowance_transaction.dart';
import '../../../domain/entities/weekly_work_budget_summary.dart';

enum WeeklyPeriodSelection {
  thisWeek,
  previousWeek,
  nextWeek,
  custom,
}

abstract class WeeklyAllowanceState extends Equatable {
  const WeeklyAllowanceState();

  @override
  List<Object?> get props => [];
}

class WeeklyAllowanceInitial extends WeeklyAllowanceState {
  const WeeklyAllowanceInitial();
}

class WeeklyAllowanceLoading extends WeeklyAllowanceState {
  const WeeklyAllowanceLoading();
}

class WeeklyAllowanceLoaded extends WeeklyAllowanceState {
  const WeeklyAllowanceLoaded({
    required this.userId,
    required this.weekRange,
    this.periodSelection = WeeklyPeriodSelection.thisWeek,
    this.selectedCurrency = ExpenseCurrency.egp,
    required this.summary,
    required this.transactions,
    this.isActionLoading = false,
  });

  final String userId;
  final WeeklyDateRange weekRange;
  final WeeklyPeriodSelection periodSelection;
  final ExpenseCurrency selectedCurrency;
  final WeeklyWorkBudgetSummary summary;
  final List<WeeklyAllowanceTransaction> transactions;
  final bool isActionLoading;

  double get activeReceived => selectedCurrency == ExpenseCurrency.egp
      ? summary.receivedEgp
      : summary.receivedUsd;

  double get activeSpent => selectedCurrency == ExpenseCurrency.egp
      ? summary.spentEgp
      : summary.spentUsd;

  double get activeRemaining => selectedCurrency == ExpenseCurrency.egp
      ? summary.remainingEgp
      : summary.remainingUsd;

  WeeklyAllowanceLoaded copyWith({
    String? userId,
    WeeklyDateRange? weekRange,
    WeeklyPeriodSelection? periodSelection,
    ExpenseCurrency? selectedCurrency,
    WeeklyWorkBudgetSummary? summary,
    List<WeeklyAllowanceTransaction>? transactions,
    bool? isActionLoading,
  }) {
    return WeeklyAllowanceLoaded(
      userId: userId ?? this.userId,
      weekRange: weekRange ?? this.weekRange,
      periodSelection: periodSelection ?? this.periodSelection,
      selectedCurrency: selectedCurrency ?? this.selectedCurrency,
      summary: summary ?? this.summary,
      transactions: transactions ?? this.transactions,
      isActionLoading: isActionLoading ?? this.isActionLoading,
    );
  }

  @override
  List<Object?> get props => [
        userId,
        weekRange,
        periodSelection,
        selectedCurrency,
        summary,
        transactions,
        isActionLoading,
      ];
}

class WeeklyAllowanceError extends WeeklyAllowanceState {
  const WeeklyAllowanceError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
