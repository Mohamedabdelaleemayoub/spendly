import 'package:equatable/equatable.dart';
import '../../../domain/entities/expense_currency.dart';
import '../../../domain/entities/salary_advance.dart';

abstract class SalaryAdvancesState extends Equatable {
  const SalaryAdvancesState();

  @override
  List<Object?> get props => [];
}

class SalaryAdvancesInitial extends SalaryAdvancesState {
  const SalaryAdvancesInitial();
}

class SalaryAdvancesLoading extends SalaryAdvancesState {
  const SalaryAdvancesLoading();
}

class SalaryAdvancesLoaded extends SalaryAdvancesState {
  const SalaryAdvancesLoaded({
    required this.userId,
    required this.salaryAmount,
    required this.salaryCurrency,
    required this.advances,
    this.isActionLoading = false,
  });

  final String userId;
  final double salaryAmount;
  final ExpenseCurrency salaryCurrency;
  final List<SalaryAdvance> advances;
  final bool isActionLoading;

  double get totalAdvances => advances.fold<double>(
        0.0,
        (sum, item) => sum + item.amount,
      );

  double get remainingSalary => (salaryAmount - totalAdvances).clamp(0.0, double.infinity);

  SalaryAdvancesLoaded copyWith({
    String? userId,
    double? salaryAmount,
    ExpenseCurrency? salaryCurrency,
    List<SalaryAdvance>? advances,
    bool? isActionLoading,
  }) {
    return SalaryAdvancesLoaded(
      userId: userId ?? this.userId,
      salaryAmount: salaryAmount ?? this.salaryAmount,
      salaryCurrency: salaryCurrency ?? this.salaryCurrency,
      advances: advances ?? this.advances,
      isActionLoading: isActionLoading ?? this.isActionLoading,
    );
  }

  @override
  List<Object?> get props => [
        userId,
        salaryAmount,
        salaryCurrency,
        advances,
        isActionLoading,
      ];
}

class SalaryAdvancesActionSuccess extends SalaryAdvancesState {
  const SalaryAdvancesActionSuccess(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

class SalaryAdvancesError extends SalaryAdvancesState {
  const SalaryAdvancesError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
