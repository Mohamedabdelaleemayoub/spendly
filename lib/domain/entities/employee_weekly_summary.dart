import 'package:equatable/equatable.dart';
import 'profile.dart';
import 'weekly_work_budget_summary.dart';

class EmployeeWeeklySummary extends Equatable {
  const EmployeeWeeklySummary({
    required this.profile,
    required this.weeklyBudget,
  });

  final Profile profile;
  final WeeklyWorkBudgetSummary weeklyBudget;

  @override
  List<Object?> get props => [profile, weeklyBudget];
}
