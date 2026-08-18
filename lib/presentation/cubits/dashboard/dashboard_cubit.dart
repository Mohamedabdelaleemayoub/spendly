import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/errors/app_failure.dart';
import '../../../domain/entities/expense.dart';
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

  ExpenseSummaryPeriod _currentPeriod = ExpenseSummaryPeriod.month;

  @override
  void emit(DashboardState state) {
    if (!isClosed) {
      super.emit(state);
    }
  }

  void changePeriod(ExpenseSummaryPeriod period) {
    _currentPeriod = period;
    final currentState = state;
    if (currentState is DashboardLoaded) {
      final (categorySpending, employeeSpending) = _calculateBreakdown(
        expenses: currentState.allMonthExpenses,
        period: period,
        isAdmin: currentState.isAdmin,
      );

      emit(currentState.copyWith(
        period: period,
        categorySpending: categorySpending,
        employeeSpending: employeeSpending,
      ));
    }
  }

  DateTime _getStartOfWeek(DateTime date) {
    // Saudi / Arab week starts Saturday (weekday 6 in ISO)
    // Days since Saturday: (date.weekday + 1) % 7
    final daysSinceSaturday = (date.weekday + 1) % 7;
    return DateTime(date.year, date.month, date.day).subtract(Duration(days: daysSinceSaturday));
  }

  (List<CategorySpending>, List<EmployeeSpending>) _calculateBreakdown({
    required List<Expense> expenses,
    required ExpenseSummaryPeriod period,
    required bool isAdmin,
  }) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final weekStart = _getStartOfWeek(now);

    final filtered = expenses.where((exp) {
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
          empMap[empId]!.amount += exp.amount;
          empMap[empId]!.count += 1;
        } else {
          empMap[empId] = _EmployeeAggregate(
            userId: empId,
            name: empName,
            email: empEmail,
            amount: exp.amount,
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
        color: aggr.color,
        icon: aggr.icon,
        percentage: percentage,
      );
    }).toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));

    final employeeSpending = empMap.values.map((aggr) {
      final percentage = totalAmount > 0 ? (aggr.amount / totalAmount) * 100 : 0.0;
      return EmployeeSpending(
        userId: aggr.userId,
        name: aggr.name,
        email: aggr.email,
        amount: aggr.amount,
        count: aggr.count,
        percentage: percentage,
      );
    }).toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));

    return (categorySpending, employeeSpending);
  }

  Future<void> loadDashboard() async {
    emit(const DashboardLoading());
    try {
      final user = authRepository.currentUser;
      if (user == null) {
        emit(const DashboardError('المستخدم غير مسجل'));
        return;
      }

      final profile = await profileRepository.getProfile(user.id);
      final bool isAdmin = profile?.isAdmin ?? false;

      final now = DateTime.now();
      final monthExpenses = await expenseRepository.getExpensesForMonth(now);

      double totalThisMonth = 0.0;
      double totalThisWeek = 0.0;
      double totalToday = 0.0;

      int countThisMonth = 0;
      int countThisWeek = 0;
      int countToday = 0;

      final todayStart = DateTime(now.year, now.month, now.day);
      final weekStart = _getStartOfWeek(now);

      final Map<String, _EmployeeAggregate> empCountMap = {};

      for (final exp in monthExpenses) {
        final expDate = DateTime(exp.expenseDate.year, exp.expenseDate.month, exp.expenseDate.day);

        // Monthly
        totalThisMonth += exp.amount;
        countThisMonth++;

        // Today
        if (expDate.isAtSameMomentAs(todayStart)) {
          totalToday += exp.amount;
          countToday++;
        }

        // Week
        if (!expDate.isBefore(weekStart) && !expDate.isAfter(todayStart)) {
          totalThisWeek += exp.amount;
          countThisWeek++;
        }

        if (isAdmin) {
          empCountMap[exp.userId] = _EmployeeAggregate(
            userId: exp.userId,
            name: exp.profile?.name ?? 'موظف',
            email: exp.profile?.email,
            amount: 0,
            count: 0,
          );
        }
      }

      int employeeCount = empCountMap.length;
      if (isAdmin) {
        try {
          final allProfiles = await profileRepository.getEmployees();
          employeeCount = allProfiles.length;
        } catch (_) {}
      }

      final (categorySpending, employeeSpending) = _calculateBreakdown(
        expenses: monthExpenses,
        period: _currentPeriod,
        isAdmin: isAdmin,
      );

      // Get recent 5 expenses
      final recentExpenses = (List<Expense>.from(monthExpenses)
            ..sort((a, b) => b.expenseDate.compareTo(a.expenseDate)))
          .take(5)
          .toList();

      emit(DashboardLoaded(
        isAdmin: isAdmin,
        period: _currentPeriod,
        totalToday: totalToday,
        totalThisWeek: totalThisWeek,
        totalThisMonth: totalThisMonth,
        countToday: countToday,
        countThisWeek: countThisWeek,
        countThisMonth: countThisMonth,
        employeeCount: employeeCount,
        recentExpenses: recentExpenses,
        categorySpending: categorySpending,
        employeeSpending: employeeSpending,
        allMonthExpenses: monthExpenses,
      ));
    } on Failure catch (e) {
      emit(DashboardError(e.message));
    } catch (e) {
      emit(DashboardError('فشل تحميل لوحة المعلومات: $e'));
    }
  }
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
    required this.amount,
    required this.count,
  });

  final String userId;
  final String name;
  final String? email;
  double amount;
  int count;
}
