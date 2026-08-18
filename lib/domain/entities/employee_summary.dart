import 'package:equatable/equatable.dart';
import 'profile.dart';

class EmployeeSummary extends Equatable {
  const EmployeeSummary({
    required this.profile,
    this.totalExpenses = 0.0,
    this.expensesCount = 0,
    this.lastExpenseDate,
    this.totalAdvances = 0.0,
    this.weeklyReceivedEgp = 0.0,
    this.weeklySpentEgp = 0.0,
    this.weeklyReceivedUsd = 0.0,
    this.weeklySpentUsd = 0.0,
  });

  final Profile profile;
  final double totalExpenses;
  final int expensesCount;
  final DateTime? lastExpenseDate;
  final double totalAdvances;

  // Weekly Work Budget Fields (This Week)
  final double weeklyReceivedEgp;
  final double weeklySpentEgp;
  final double weeklyReceivedUsd;
  final double weeklySpentUsd;

  double get weeklyRemainingEgp => weeklyReceivedEgp - weeklySpentEgp;
  double get weeklyRemainingUsd => weeklyReceivedUsd - weeklySpentUsd;

  double get remainingSalary => (profile.salaryAmount - totalAdvances).clamp(0.0, double.infinity);

  @override
  List<Object?> get props => [
        profile,
        totalExpenses,
        expensesCount,
        lastExpenseDate,
        totalAdvances,
        weeklyReceivedEgp,
        weeklySpentEgp,
        weeklyReceivedUsd,
        weeklySpentUsd,
      ];
}
