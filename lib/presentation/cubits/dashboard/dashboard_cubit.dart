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

  @override
  void emit(DashboardState state) {
    if (!isClosed) {
      super.emit(state);
    }
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
      // Supabase RLS will return all expenses for admin, or only the employee's own expenses for employee
      final monthExpenses = await expenseRepository.getExpensesForMonth(now);

      double totalThisMonth = 0.0;
      double totalToday = 0.0;

      final todayStr =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      final Map<String, _CatAggregate> catMap = {};
      final Map<String, _EmployeeAggregate> empMap = {};

      for (final exp in monthExpenses) {
        totalThisMonth += exp.amount;

        final expDateStr =
            '${exp.expenseDate.year}-${exp.expenseDate.month.toString().padLeft(2, '0')}-${exp.expenseDate.day.toString().padLeft(2, '0')}';
        if (expDateStr == todayStr) {
          totalToday += exp.amount;
        }

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

      int employeeCount = empMap.length;
      if (isAdmin) {
        try {
          final allProfiles = await profileRepository.getEmployees();
          employeeCount = allProfiles.length;
        } catch (_) {}
      }

      final List<CategorySpending> categorySpending = catMap.values.map((aggr) {
        final percentage = totalThisMonth > 0 ? (aggr.amount / totalThisMonth) * 100 : 0.0;
        return CategorySpending(
          name: aggr.name,
          amount: aggr.amount,
          color: aggr.color,
          icon: aggr.icon,
          percentage: percentage,
        );
      }).toList()
        ..sort((a, b) => b.amount.compareTo(a.amount));

      final List<EmployeeSpending> employeeSpending = empMap.values.map((aggr) {
        final percentage = totalThisMonth > 0 ? (aggr.amount / totalThisMonth) * 100 : 0.0;
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

      // Get recent 5 expenses
      final recentExpenses = (List<Expense>.from(monthExpenses)
            ..sort((a, b) => b.expenseDate.compareTo(a.expenseDate)))
          .take(5)
          .toList();

      emit(DashboardLoaded(
        isAdmin: isAdmin,
        totalThisMonth: totalThisMonth,
        totalToday: totalToday,
        countThisMonth: monthExpenses.length,
        employeeCount: employeeCount,
        recentExpenses: recentExpenses,
        categorySpending: categorySpending,
        employeeSpending: employeeSpending,
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
