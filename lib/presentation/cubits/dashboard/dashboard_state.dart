import 'package:equatable/equatable.dart';
import '../../../domain/entities/expense.dart';
import '../../../domain/entities/expense_currency.dart';

enum ExpenseSummaryPeriod {
  today,
  week,
  month,
}

class CategorySpending extends Equatable {
  const CategorySpending({
    required this.name,
    required this.amount,
    this.currency = ExpenseCurrency.egp,
    required this.color,
    required this.icon,
    required this.percentage,
  });

  final String name;
  final double amount;
  final ExpenseCurrency currency;
  final String color;
  final String icon;
  final double percentage;

  @override
  List<Object?> get props => [name, amount, currency, color, icon, percentage];
}

class EmployeeSpending extends Equatable {
  const EmployeeSpending({
    required this.userId,
    required this.name,
    this.email,
    double? amount,
    double? amountEgp,
    double? amountUsd,
    required this.count,
    required this.percentage,
  })  : amountEgp = amountEgp ?? amount ?? 0.0,
        amountUsd = amountUsd ?? 0.0;

  final String userId;
  final String name;
  final String? email;
  final double amountEgp;
  final double amountUsd;
  final int count;
  final double percentage;

  // Backward-compatibility getter
  double get amount => amountEgp;

  @override
  List<Object?> get props => [userId, name, email, amountEgp, amountUsd, count, percentage];
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
    this.selectedCurrency = ExpenseCurrency.egp,
    required this.totalTodayEgp,
    required this.totalTodayUsd,
    required this.totalThisWeekEgp,
    required this.totalThisWeekUsd,
    required this.totalThisMonthEgp,
    required this.totalThisMonthUsd,
    required this.countToday,
    required this.countThisWeek,
    required this.countThisMonth,
    required this.employeeCount,
    required this.recentExpenses,
    required this.categorySpending,
    this.employeeSpending = const [],
    this.allMonthExpenses = const [],
    this.outsideCairoTripsCount = 0,
    this.insideCairoTripsCount = 0,
    this.topTravelerName,
    this.topTravelerOutsideTrips = 0,
    this.totalSalariesEgp = 0.0,
    this.totalSalaryAdvancesEgp = 0.0,
    this.totalRemainingSalariesEgp = 0.0,
    this.weeklyReceivedEgp = 0.0,
    this.weeklySpentEgp = 0.0,
    this.weeklyReceivedUsd = 0.0,
    this.weeklySpentUsd = 0.0,
  });

  final bool isAdmin;
  final ExpenseSummaryPeriod period;
  final ExpenseCurrency selectedCurrency;
  final double totalTodayEgp;
  final double totalTodayUsd;
  final double totalThisWeekEgp;
  final double totalThisWeekUsd;
  final double totalThisMonthEgp;
  final double totalThisMonthUsd;
  final int countToday;
  final int countThisWeek;
  final int countThisMonth;
  final int employeeCount;
  final List<Expense> recentExpenses;
  final List<CategorySpending> categorySpending;
  final List<EmployeeSpending> employeeSpending;
  final List<Expense> allMonthExpenses;

  // Travel Activity fields
  final int outsideCairoTripsCount;
  final int insideCairoTripsCount;
  final String? topTravelerName;
  final int topTravelerOutsideTrips;

  // Salary & Advances Overview fields (Admin only)
  final double totalSalariesEgp;
  final double totalSalaryAdvancesEgp;
  final double totalRemainingSalariesEgp;

  // Weekly Work Budget Overview fields (This Week)
  final double weeklyReceivedEgp;
  final double weeklySpentEgp;
  final double weeklyReceivedUsd;
  final double weeklySpentUsd;

  double get weeklyRemainingEgp => weeklyReceivedEgp - weeklySpentEgp;
  double get weeklyRemainingUsd => weeklyReceivedUsd - weeklySpentUsd;

  // Backward compatibility getters (mapping to EGP by default)
  double get totalToday => totalTodayEgp;
  double get totalThisWeek => totalThisWeekEgp;
  double get totalThisMonth => totalThisMonthEgp;

  double get activePeriodTotalEgp {
    switch (period) {
      case ExpenseSummaryPeriod.today:
        return totalTodayEgp;
      case ExpenseSummaryPeriod.week:
        return totalThisWeekEgp;
      case ExpenseSummaryPeriod.month:
        return totalThisMonthEgp;
    }
  }

  double get activePeriodTotalUsd {
    switch (period) {
      case ExpenseSummaryPeriod.today:
        return totalTodayUsd;
      case ExpenseSummaryPeriod.week:
        return totalThisWeekUsd;
      case ExpenseSummaryPeriod.month:
        return totalThisMonthUsd;
    }
  }

  double get activePeriodTotal => activePeriodTotalEgp;

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
    ExpenseCurrency? selectedCurrency,
    double? totalTodayEgp,
    double? totalTodayUsd,
    double? totalThisWeekEgp,
    double? totalThisWeekUsd,
    double? totalThisMonthEgp,
    double? totalThisMonthUsd,
    int? countToday,
    int? countThisWeek,
    int? countThisMonth,
    int? employeeCount,
    List<Expense>? recentExpenses,
    List<CategorySpending>? categorySpending,
    List<EmployeeSpending>? employeeSpending,
    List<Expense>? allMonthExpenses,
    int? outsideCairoTripsCount,
    int? insideCairoTripsCount,
    String? topTravelerName,
    int? topTravelerOutsideTrips,
    double? totalSalariesEgp,
    double? totalSalaryAdvancesEgp,
    double? totalRemainingSalariesEgp,
    double? weeklyReceivedEgp,
    double? weeklySpentEgp,
    double? weeklyReceivedUsd,
    double? weeklySpentUsd,
  }) {
    return DashboardLoaded(
      isAdmin: isAdmin ?? this.isAdmin,
      period: period ?? this.period,
      selectedCurrency: selectedCurrency ?? this.selectedCurrency,
      totalTodayEgp: totalTodayEgp ?? this.totalTodayEgp,
      totalTodayUsd: totalTodayUsd ?? this.totalTodayUsd,
      totalThisWeekEgp: totalThisWeekEgp ?? this.totalThisWeekEgp,
      totalThisWeekUsd: totalThisWeekUsd ?? this.totalThisWeekUsd,
      totalThisMonthEgp: totalThisMonthEgp ?? this.totalThisMonthEgp,
      totalThisMonthUsd: totalThisMonthUsd ?? this.totalThisMonthUsd,
      countToday: countToday ?? this.countToday,
      countThisWeek: countThisWeek ?? this.countThisWeek,
      countThisMonth: countThisMonth ?? this.countThisMonth,
      employeeCount: employeeCount ?? this.employeeCount,
      recentExpenses: recentExpenses ?? this.recentExpenses,
      categorySpending: categorySpending ?? this.categorySpending,
      employeeSpending: employeeSpending ?? this.employeeSpending,
      allMonthExpenses: allMonthExpenses ?? this.allMonthExpenses,
      outsideCairoTripsCount: outsideCairoTripsCount ?? this.outsideCairoTripsCount,
      insideCairoTripsCount: insideCairoTripsCount ?? this.insideCairoTripsCount,
      topTravelerName: topTravelerName ?? this.topTravelerName,
      topTravelerOutsideTrips: topTravelerOutsideTrips ?? this.topTravelerOutsideTrips,
      totalSalariesEgp: totalSalariesEgp ?? this.totalSalariesEgp,
      totalSalaryAdvancesEgp: totalSalaryAdvancesEgp ?? this.totalSalaryAdvancesEgp,
      totalRemainingSalariesEgp: totalRemainingSalariesEgp ?? this.totalRemainingSalariesEgp,
      weeklyReceivedEgp: weeklyReceivedEgp ?? this.weeklyReceivedEgp,
      weeklySpentEgp: weeklySpentEgp ?? this.weeklySpentEgp,
      weeklyReceivedUsd: weeklyReceivedUsd ?? this.weeklyReceivedUsd,
      weeklySpentUsd: weeklySpentUsd ?? this.weeklySpentUsd,
    );
  }

  @override
  List<Object?> get props => [
        isAdmin,
        period,
        selectedCurrency,
        totalTodayEgp,
        totalTodayUsd,
        totalThisWeekEgp,
        totalThisWeekUsd,
        totalThisMonthEgp,
        totalThisMonthUsd,
        countToday,
        countThisWeek,
        countThisMonth,
        employeeCount,
        recentExpenses,
        categorySpending,
        employeeSpending,
        allMonthExpenses,
        outsideCairoTripsCount,
        insideCairoTripsCount,
        topTravelerName,
        topTravelerOutsideTrips,
        totalSalariesEgp,
        totalSalaryAdvancesEgp,
        totalRemainingSalariesEgp,
        weeklyReceivedEgp,
        weeklySpentEgp,
        weeklyReceivedUsd,
        weeklySpentUsd,
      ];
}

class DashboardError extends DashboardState {
  const DashboardError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
