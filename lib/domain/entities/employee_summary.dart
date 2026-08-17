import 'package:equatable/equatable.dart';
import 'profile.dart';

class EmployeeSummary extends Equatable {
  const EmployeeSummary({
    required this.profile,
    this.totalExpenses = 0.0,
    this.expensesCount = 0,
    this.lastExpenseDate,
  });

  final Profile profile;
  final double totalExpenses;
  final int expensesCount;
  final DateTime? lastExpenseDate;

  @override
  List<Object?> get props => [profile, totalExpenses, expensesCount, lastExpenseDate];
}
