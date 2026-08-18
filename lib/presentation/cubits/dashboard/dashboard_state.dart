import 'package:equatable/equatable.dart';
import '../../../domain/entities/expense.dart';

enum ExpenseSummaryPeriod {
  today,
  week,
  month,
}

class CategorySpending extends Equatable {
  const CategorySpending({
    required this.name,
    required this.amount,
    required this.color,
    required this.icon,
    required this.percentage,
  });

  final String name;
  final double amount;
  final String color;
  final String icon;
  final double percentage;

  @override
  List<Object?> get props => [name, amount, color, icon, percentage];
}

class EmployeeSpending extends Equatable {
  const EmployeeSpending({
    required this.userId,
    required this.name,
    required this.email,
    required this.amount,
    required this.count,
    required this.percentage,
  });

  final String userId;
  final String name;
  final String? email;
  final double amount;
  final int count;
  final double percentage;

  @override
  List<Object?> get props => [userId, name, email, amount, count, percentage];
}

sealed class DashboardState extends Equatable {
  const DashboardState();

  @override
  List<Object?> get props => [];
}

class DashboardInitial extends DashboardState {
  const DashboardInitial();
}

class DashboardLoading extends DashboardState {
  const DashboardLoading();
}

class DashboardLoaded extends DashboardState {
  const DashboardLoaded({
    required this.isAdmin,
    this.period = ExpenseSummaryPeriod.month,
    required this.totalToday,
    required this.totalThisWeek,
    required this.totalThisMonth,
    required this.countToday,
    required this.countThisWeek,
    required this.countThisMonth,
    required this.employeeCount,
    required this.recentExpenses,
    required this.categorySpending,
    this.employeeSpending = const [],
    this.allMonthExpenses = const [],
  });

  final bool isAdmin;
  final ExpenseSummaryPeriod period;
  final double totalToday;
  final double totalThisWeek;
  final double totalThisMonth;
  final int countToday;
  final int countThisWeek;
  final int countThisMonth;
  final int employeeCount;
  final List<Expense> recentExpenses;
  final List<CategorySpending> categorySpending;
  final List<EmployeeSpending> employeeSpending;
  final List<Expense> allMonthExpenses;

  double get activePeriodTotal {
    switch (period) {
      case ExpenseSummaryPeriod.today:
        return totalToday;
      case ExpenseSummaryPeriod.week:
        return totalThisWeek;
      case ExpenseSummaryPeriod.month:
        return totalThisMonth;
    }
  }

  int get activePeriodCount {
    switch (period) {
      case ExpenseSummaryPeriod.today:
        return countToday;
      case ExpenseSummaryPeriod.week:
        return countThisWeek;
      case ExpenseSummaryPeriod.month:
        return countThisMonth;
    }
  }

  DashboardLoaded copyWith({
    bool? isAdmin,
    ExpenseSummaryPeriod? period,
    double? totalToday,
    double? totalThisWeek,
    double? totalThisMonth,
    int? countToday,
    int? countThisWeek,
    int? countThisMonth,
    int? employeeCount,
    List<Expense>? recentExpenses,
    List<CategorySpending>? categorySpending,
    List<EmployeeSpending>? employeeSpending,
    List<Expense>? allMonthExpenses,
  }) {
    return DashboardLoaded(
      isAdmin: isAdmin ?? this.isAdmin,
      period: period ?? this.period,
      totalToday: totalToday ?? this.totalToday,
      totalThisWeek: totalThisWeek ?? this.totalThisWeek,
      totalThisMonth: totalThisMonth ?? this.totalThisMonth,
      countToday: countToday ?? this.countToday,
      countThisWeek: countThisWeek ?? this.countThisWeek,
      countThisMonth: countThisMonth ?? this.countThisMonth,
      employeeCount: employeeCount ?? this.employeeCount,
      recentExpenses: recentExpenses ?? this.recentExpenses,
      categorySpending: categorySpending ?? this.categorySpending,
      employeeSpending: employeeSpending ?? this.employeeSpending,
      allMonthExpenses: allMonthExpenses ?? this.allMonthExpenses,
    );
  }

  @override
  List<Object?> get props => [
        isAdmin,
        period,
        totalToday,
        totalThisWeek,
        totalThisMonth,
        countToday,
        countThisWeek,
        countThisMonth,
        employeeCount,
        recentExpenses,
        categorySpending,
        employeeSpending,
        allMonthExpenses,
      ];
}

class DashboardError extends DashboardState {
  const DashboardError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
