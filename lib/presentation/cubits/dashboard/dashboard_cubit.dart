import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/services/supabase_service.dart';
import '../../../domain/entities/expense.dart';
import '../../../domain/entities/expense_currency.dart';
import '../../../domain/entities/profile.dart';
import '../../../domain/entities/trip_location_type.dart';
import '../../../domain/repositories/auth_repository.dart';
import '../../../domain/repositories/category_repository.dart';
import '../../../domain/repositories/expense_repository.dart';
import '../../../domain/repositories/profile_repository.dart';
import 'dashboard_state.dart';

class DashboardCubit extends Cubit<DashboardState> {
  DashboardCubit({
    required this.expenseRepository,
    required this.categoryRepository,
    required this.profileRepository,
    required this.authRepository,
  }) : super(const DashboardInitial());

  final ExpenseRepository expenseRepository;
  final CategoryRepository categoryRepository;
  final ProfileRepository profileRepository;
  final AuthRepository authRepository;

  RealtimeChannel? _realtimeChannel;

  ExpenseSummaryPeriod _currentPeriod = ExpenseSummaryPeriod.month;
  ExpenseCurrency _currentCurrency = ExpenseCurrency.egp;

  @override
  void emit(DashboardState state) {
    if (!isClosed) {
      super.emit(state);
    }
  }

  void subscribeToRealtime() {
    _realtimeChannel?.unsubscribe();
    try {
      _realtimeChannel = SupabaseService.client
          .channel('public:profiles_and_expenses:dashboard')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'profiles',
            callback: (payload) {
              loadDashboard();
            },
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'expenses',
            callback: (payload) {
              loadDashboard();
            },
          )
          .subscribe();
    } catch (_) {}
  }

  @override
  Future<void> close() {
    _realtimeChannel?.unsubscribe();
    return super.close();
  }

  void changePeriod(ExpenseSummaryPeriod period) {
    _currentPeriod = period;
    final currentState = state;
    if (currentState is DashboardLoaded) {
      final (categorySpending, employeeSpending) = _calculateBreakdown(
        expenses: currentState.allMonthExpenses,
        period: period,
        currency: _currentCurrency,
        isAdmin: currentState.isAdmin,
      );

      final travelActivity = _calculateTravelActivity(
        expenses: currentState.allMonthExpenses,
        period: period,
      );

      emit(currentState.copyWith(
        period: period,
        categorySpending: categorySpending,
        employeeSpending: employeeSpending,
        outsideCairoTripsCount: travelActivity.outsideCairoCount,
        insideCairoTripsCount: travelActivity.insideCairoCount,
        topTravelerName: travelActivity.topTravelerName,
        topTravelerOutsideTrips: travelActivity.topTravelerCount,
      ));
    }
  }

  void changeCurrency(ExpenseCurrency currency) {
    _currentCurrency = currency;
    final currentState = state;
    if (currentState is DashboardLoaded) {
      final (categorySpending, employeeSpending) = _calculateBreakdown(
        expenses: currentState.allMonthExpenses,
        period: _currentPeriod,
        currency: currency,
        isAdmin: currentState.isAdmin,
      );

      emit(currentState.copyWith(
        selectedCurrency: currency,
        categorySpending: categorySpending,
        employeeSpending: employeeSpending,
      ));
    }
  }

  DateTime _getStartOfWeek(DateTime date) {
    final daysSinceSaturday = (date.weekday + 1) % 7;
    return DateTime(date.year, date.month, date.day).subtract(Duration(days: daysSinceSaturday));
  }

  _TravelSummary _calculateTravelActivity({
    required List<Expense> expenses,
    required ExpenseSummaryPeriod period,
  }) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final weekStart = _getStartOfWeek(now);

    final periodExpenses = expenses.where((exp) {
      final expDate = DateTime(exp.expenseDate.year, exp.expenseDate.month, exp.expenseDate.day);
      switch (period) {
        case ExpenseSummaryPeriod.today:
          return expDate.isAtSameMomentAs(todayStart);
        case ExpenseSummaryPeriod.week:
          return !expDate.isBefore(weekStart) && !expDate.isAfter(todayStart);
        case ExpenseSummaryPeriod.month:
          return exp.expenseDate.year == now.year && exp.expenseDate.month == now.month;
      }
    }).toList();

    int inside = 0;
    int outside = 0;
    final Map<String, _TravelerCount> travelerMap = {};

    for (final exp in periodExpenses) {
      if (exp.tripLocationType == TripLocationType.outsideCairo) {
        outside++;
        final name = exp.profile?.name ?? 'موظف';
        final traveler = travelerMap.putIfAbsent(exp.userId, () => _TravelerCount(name: name, count: 0));
        traveler.count++;
      } else {
        inside++;
      }
    }

    String? topName;
    int topCount = 0;
    for (final t in travelerMap.values) {
      if (t.count > topCount) {
        topCount = t.count;
        topName = t.name;
      }
    }

    return _TravelSummary(
      insideCairoCount: inside,
      outsideCairoCount: outside,
      topTravelerName: topName,
      topTravelerCount: topCount,
    );
  }

  (List<CategorySpending>, List<EmployeeSpending>) _calculateBreakdown({
    required List<Expense> expenses,
    required ExpenseSummaryPeriod period,
    required ExpenseCurrency currency,
    required bool isAdmin,
  }) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final weekStart = _getStartOfWeek(now);

    final filtered = expenses.where((exp) {
      final expDate = DateTime(exp.expenseDate.year, exp.expenseDate.month, exp.expenseDate.day);
      final bool dateMatches;
      switch (period) {
        case ExpenseSummaryPeriod.today:
          dateMatches = expDate.isAtSameMomentAs(todayStart);
          break;
        case ExpenseSummaryPeriod.week:
          dateMatches = !expDate.isBefore(weekStart) && !expDate.isAfter(todayStart);
          break;
        case ExpenseSummaryPeriod.month:
          dateMatches = exp.expenseDate.year == now.year && exp.expenseDate.month == now.month;
          break;
      }
      return dateMatches && exp.currency == currency;
    }).toList();

    double totalAmount = 0.0;
    final Map<String, _CatAggregate> catMap = {};
    final Map<String, _EmployeeAggregate> empMap = {};

    for (final exp in filtered) {
      totalAmount += exp.amount;

      // Category aggregation
      final catName = exp.category?.name ?? 'بدون فئة';
      final catColor = exp.category?.color ?? '#636E72';
      final catIcon = exp.category?.icon ?? 'more_horiz';

      if (catMap.containsKey(catName)) {
        catMap[catName]!.amount += exp.amount;
      } else {
        catMap[catName] = _CatAggregate(
          name: catName,
          amount: exp.amount,
          color: catColor,
          icon: catIcon,
        );
      }

      // Employee aggregation (for admin)
      if (isAdmin) {
        final empId = exp.userId;
        final empName = exp.profile?.name ?? 'موظف';
        final empEmail = exp.profile?.email;

        if (empMap.containsKey(empId)) {
          if (exp.currency == ExpenseCurrency.usd) {
            empMap[empId]!.amountUsd += exp.amount;
          } else {
            empMap[empId]!.amountEgp += exp.amount;
          }
          empMap[empId]!.count += 1;
        } else {
          empMap[empId] = _EmployeeAggregate(
            userId: empId,
            name: empName,
            email: empEmail,
            amountEgp: exp.currency == ExpenseCurrency.egp ? exp.amount : 0.0,
            amountUsd: exp.currency == ExpenseCurrency.usd ? exp.amount : 0.0,
            count: 1,
          );
        }
      }
    }

    final categorySpending = catMap.values.map((aggr) {
      final percentage = totalAmount > 0 ? (aggr.amount / totalAmount) * 100 : 0.0;
      return CategorySpending(
        name: aggr.name,
        amount: aggr.amount,
        currency: currency,
        color: aggr.color,
        icon: aggr.icon,
        percentage: percentage,
      );
    }).toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));

    List<EmployeeSpending> employeeSpending = [];
    if (isAdmin) {
      employeeSpending = empMap.values.map((aggr) {
        final relevantAmount = currency == ExpenseCurrency.usd ? aggr.amountUsd : aggr.amountEgp;
        final percentage = totalAmount > 0 ? (relevantAmount / totalAmount) * 100 : 0.0;
        return EmployeeSpending(
          userId: aggr.userId,
          name: aggr.name,
          email: aggr.email,
          amountEgp: aggr.amountEgp,
          amountUsd: aggr.amountUsd,
          count: aggr.count,
          percentage: percentage,
        );
      }).toList()
        ..sort((a, b) {
          final amtA = currency == ExpenseCurrency.usd ? a.amountUsd : a.amountEgp;
          final amtB = currency == ExpenseCurrency.usd ? b.amountUsd : b.amountEgp;
          return amtB.compareTo(amtA);
        });
    }

    return (categorySpending, employeeSpending);
  }

  Future<void> loadDashboard() async {
    emit(const DashboardLoading());
    try {
      final user = authRepository.currentUser;
      Profile? profile;
      if (user != null) {
        profile = await profileRepository.getProfile(user.id);
      }
      final isAdmin = profile?.isAdmin ?? false;

      final now = DateTime.now();
      final monthExpenses = await expenseRepository.getExpensesForMonth(now);

      double totalThisMonthEgp = 0.0;
      double totalThisWeekEgp = 0.0;
      double totalTodayEgp = 0.0;

      double totalThisMonthUsd = 0.0;
      double totalThisWeekUsd = 0.0;
      double totalTodayUsd = 0.0;

      int countThisMonth = 0;
      int countThisWeek = 0;
      int countToday = 0;

      final todayStart = DateTime(now.year, now.month, now.day);
      final weekStart = _getStartOfWeek(now);

      final Map<String, bool> empCountMap = {};

      for (final exp in monthExpenses) {
        final expDate = DateTime(exp.expenseDate.year, exp.expenseDate.month, exp.expenseDate.day);
        final isEgp = exp.currency == ExpenseCurrency.egp;

        // Monthly
        if (isEgp) {
          totalThisMonthEgp += exp.amount;
        } else {
          totalThisMonthUsd += exp.amount;
        }
        countThisMonth++;

        // Today
        if (expDate.isAtSameMomentAs(todayStart)) {
          if (isEgp) {
            totalTodayEgp += exp.amount;
          } else {
            totalTodayUsd += exp.amount;
          }
          countToday++;
        }

        // Week
        if (!expDate.isBefore(weekStart) && !expDate.isAfter(todayStart)) {
          if (isEgp) {
            totalThisWeekEgp += exp.amount;
          } else {
            totalThisWeekUsd += exp.amount;
          }
          countThisWeek++;
        }

        if (isAdmin) {
          empCountMap[exp.userId] = true;
        }
      }

      double totalSalariesEgp = 0.0;
      double totalSalaryAdvancesEgp = 0.0;
      double totalRemainingSalariesEgp = 0.0;

      double weeklyReceivedEgp = 0.0;
      double weeklySpentEgp = 0.0;
      double weeklyReceivedUsd = 0.0;
      double weeklySpentUsd = 0.0;

      int employeeCount = empCountMap.length;
      if (isAdmin) {
        try {
          final empsWithStats = await profileRepository.getEmployeesWithStats();
          employeeCount = empsWithStats.length;
          for (final e in empsWithStats) {
            if (e.profile.isActive) {
              totalSalariesEgp += e.profile.salaryAmount;
              totalSalaryAdvancesEgp += e.totalAdvances;
              totalRemainingSalariesEgp += e.remainingSalary;

              weeklyReceivedEgp += e.weeklyReceivedEgp;
              weeklySpentEgp += e.weeklySpentEgp;
              weeklyReceivedUsd += e.weeklyReceivedUsd;
              weeklySpentUsd += e.weeklySpentUsd;
            }
          }
        } catch (_) {}
      }

      final (categorySpending, employeeSpending) = _calculateBreakdown(
        expenses: monthExpenses,
        period: _currentPeriod,
        currency: _currentCurrency,
        isAdmin: isAdmin,
      );

      final travelActivity = _calculateTravelActivity(
        expenses: monthExpenses,
        period: _currentPeriod,
      );

      // Get recent 5 expenses
      final recentExpenses = (List<Expense>.from(monthExpenses)
            ..sort((a, b) => b.expenseDate.compareTo(a.expenseDate)))
          .take(5)
          .toList();

      emit(DashboardLoaded(
        isAdmin: isAdmin,
        period: _currentPeriod,
        selectedCurrency: _currentCurrency,
        totalTodayEgp: totalTodayEgp,
        totalTodayUsd: totalTodayUsd,
        totalThisWeekEgp: totalThisWeekEgp,
        totalThisWeekUsd: totalThisWeekUsd,
        totalThisMonthEgp: totalThisMonthEgp,
        totalThisMonthUsd: totalThisMonthUsd,
        countToday: countToday,
        countThisWeek: countThisWeek,
        countThisMonth: countThisMonth,
        employeeCount: employeeCount,
        recentExpenses: recentExpenses,
        categorySpending: categorySpending,
        employeeSpending: employeeSpending,
        allMonthExpenses: monthExpenses,
        outsideCairoTripsCount: travelActivity.outsideCairoCount,
        insideCairoTripsCount: travelActivity.insideCairoCount,
        topTravelerName: travelActivity.topTravelerName,
        topTravelerOutsideTrips: travelActivity.topTravelerCount,
        totalSalariesEgp: totalSalariesEgp,
        totalSalaryAdvancesEgp: totalSalaryAdvancesEgp,
        totalRemainingSalariesEgp: totalRemainingSalariesEgp,
        weeklyReceivedEgp: weeklyReceivedEgp,
        weeklySpentEgp: weeklySpentEgp,
        weeklyReceivedUsd: weeklyReceivedUsd,
        weeklySpentUsd: weeklySpentUsd,
      ));
    } catch (e) {
      try {
        final localExpenses = await expenseRepository.getExpenses(pageSize: 300);
        final (categorySpending, employeeSpending) = _calculateBreakdown(
          expenses: localExpenses,
          period: _currentPeriod,
          currency: _currentCurrency,
          isAdmin: false,
        );
        final travelActivity = _calculateTravelActivity(
          expenses: localExpenses,
          period: _currentPeriod,
        );
        emit(DashboardLoaded(
          isAdmin: false,
          period: _currentPeriod,
          selectedCurrency: _currentCurrency,
          totalTodayEgp: 0.0,
          totalTodayUsd: 0.0,
          totalThisWeekEgp: 0.0,
          totalThisWeekUsd: 0.0,
          totalThisMonthEgp: 0.0,
          totalThisMonthUsd: 0.0,
          countToday: 0,
          countThisWeek: 0,
          countThisMonth: 0,
          employeeCount: 0,
          recentExpenses: localExpenses.take(5).toList(),
          categorySpending: categorySpending,
          employeeSpending: employeeSpending,
          allMonthExpenses: localExpenses,
          outsideCairoTripsCount: travelActivity.outsideCairoCount,
          insideCairoTripsCount: travelActivity.insideCairoCount,
          topTravelerName: travelActivity.topTravelerName,
          topTravelerOutsideTrips: travelActivity.topTravelerCount,
          totalSalariesEgp: 0.0,
          totalSalaryAdvancesEgp: 0.0,
          totalRemainingSalariesEgp: 0.0,
          weeklyReceivedEgp: 0.0,
          weeklySpentEgp: 0.0,
          weeklyReceivedUsd: 0.0,
          weeklySpentUsd: 0.0,
        ));
        return;
      } catch (_) {}
      emit(DashboardError(e is Failure ? e.message : 'فشل تحميل لوحة المعلومات: $e'));
    }
  }
}

class _TravelSummary {
  _TravelSummary({
    required this.insideCairoCount,
    required this.outsideCairoCount,
    this.topTravelerName,
    required this.topTravelerCount,
  });

  final int insideCairoCount;
  final int outsideCairoCount;
  final String? topTravelerName;
  final int topTravelerCount;
}

class _TravelerCount {
  _TravelerCount({required this.name, required this.count});
  final String name;
  int count;
}

class _CatAggregate {
  _CatAggregate({
    required this.name,
    required this.amount,
    required this.color,
    required this.icon,
  });

  final String name;
  double amount;
  final String color;
  final String icon;
}

class _EmployeeAggregate {
  _EmployeeAggregate({
    required this.userId,
    required this.name,
    required this.email,
    required this.amountEgp,
    required this.amountUsd,
    required this.count,
  });

  final String userId;
  final String name;
  final String? email;
  double amountEgp;
  double amountUsd;
  int count;
}
