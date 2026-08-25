import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/errors/app_failure.dart';
import '../../../domain/entities/expense.dart';
import '../../../domain/entities/expense_currency.dart';
import '../../../domain/repositories/auth_repository.dart';
import '../../../domain/repositories/expense_repository.dart';
import '../../../domain/repositories/profile_repository.dart';
import '../dashboard/dashboard_state.dart';
import 'report_state.dart';

class ReportCubit extends Cubit<ReportState> {
  ReportCubit({
    required this.expenseRepository,
    required this.profileRepository,
    required this.authRepository,
  }) : super(const ReportInitial());

  final ExpenseRepository expenseRepository;
  final ProfileRepository profileRepository;
  final AuthRepository authRepository;

  DateTime _currentMonth = DateTime(DateTime.now().year, DateTime.now().month);
  ExpenseCurrency _currentCurrency = ExpenseCurrency.egp;
  List<Expense> _cachedMonthExpenses = [];
  bool _isAdmin = false;

  @override
  void emit(ReportState state) {
    if (!isClosed) {
      super.emit(state);
    }
  }

  void changeCurrency(ExpenseCurrency currency) {
    _currentCurrency = currency;
    final currentState = state;
    if (currentState is ReportLoaded) {
      _recalculateAndEmit(currentState.selectedMonth);
    }
  }

  Future<void> loadReport([DateTime? month]) async {
    if (month != null) {
      _currentMonth = DateTime(month.year, month.month);
    }

    emit(const ReportLoading());
    try {
      final user = authRepository.currentUser;
      if (user != null) {
        final profile = await profileRepository.getProfile(user.id);
        _isAdmin = profile?.isAdmin ?? false;
      }

      _cachedMonthExpenses = await expenseRepository.getExpensesForMonth(_currentMonth);
      _recalculateAndEmit(_currentMonth);
    } catch (e) {
      try {
        _cachedMonthExpenses = await expenseRepository.getExpenses(pageSize: 300);
        _recalculateAndEmit(_currentMonth);
        return;
      } catch (_) {}
      emit(ReportError(e is Failure ? e.message : 'فشل تحميل التقارير: $e'));
    }
  }

  void _recalculateAndEmit(DateTime month) {
    double totalEgp = 0.0;
    double totalUsd = 0.0;

    for (final exp in _cachedMonthExpenses) {
      if (exp.currency == ExpenseCurrency.usd) {
        totalUsd += exp.amount;
      } else {
        totalEgp += exp.amount;
      }
    }

    final filteredExpenses = _cachedMonthExpenses
        .where((e) => e.currency == _currentCurrency)
        .toList();

    double total = _currentCurrency == ExpenseCurrency.usd ? totalUsd : totalEgp;
    final Map<String, _CatAggr> catMap = {};
    final Map<String, _EmpAggr> empMap = {};
    final Map<String, double> payMap = {
      for (final k in AppConstants.paymentMethods) k: 0.0,
    };

    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final Map<int, double> dayMap = {
      for (int i = 1; i <= daysInMonth; i++) i: 0.0,
    };

    for (final exp in filteredExpenses) {
      // Category aggregation
      final catName = exp.category?.name ?? 'بدون فئة';
      final catColor = exp.category?.color ?? '#636E72';
      final catIcon = exp.category?.icon ?? 'more_horiz';

      if (catMap.containsKey(catName)) {
        catMap[catName]!.amount += exp.amount;
      } else {
        catMap[catName] = _CatAggr(
          name: catName,
          amount: exp.amount,
          color: catColor,
          icon: catIcon,
        );
      }

      // Employee aggregation (for admin)
      if (_isAdmin) {
        final empId = exp.userId;
        final empName = exp.profile?.name ?? 'موظف';
        final empEmail = exp.profile?.email;

        if (empMap.containsKey(empId)) {
          empMap[empId]!.amount += exp.amount;
          empMap[empId]!.count += 1;
        } else {
          empMap[empId] = _EmpAggr(
            userId: empId,
            name: empName,
            email: empEmail,
            amount: exp.amount,
            count: 1,
          );
        }
      }

      // Payment method aggregation
      if (payMap.containsKey(exp.paymentMethod)) {
        payMap[exp.paymentMethod] = payMap[exp.paymentMethod]! + exp.amount;
      } else {
        payMap[exp.paymentMethod] = exp.amount;
      }

      // Daily aggregation
      final day = exp.expenseDate.day;
      if (dayMap.containsKey(day)) {
        dayMap[day] = dayMap[day]! + exp.amount;
      }
    }

    final categorySpending = catMap.values.map((aggr) {
      final percentage = total > 0 ? (aggr.amount / total) * 100 : 0.0;
      return CategorySpending(
        name: aggr.name,
        amount: aggr.amount,
        currency: _currentCurrency,
        color: aggr.color,
        icon: catIconFromKey(aggr.icon),
        percentage: percentage,
      );
    }).toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));

    final employeeSpending = empMap.values.map((aggr) {
      final percentage = total > 0 ? (aggr.amount / total) * 100 : 0.0;
      return EmployeeSpending(
        userId: aggr.userId,
        name: aggr.name,
        email: aggr.email,
        amountEgp: _currentCurrency == ExpenseCurrency.egp ? aggr.amount : 0.0,
        amountUsd: _currentCurrency == ExpenseCurrency.usd ? aggr.amount : 0.0,
        count: aggr.count,
        percentage: percentage,
      );
    }).toList()
      ..sort((a, b) {
        final amtA = _currentCurrency == ExpenseCurrency.usd ? a.amountUsd : a.amountEgp;
        final amtB = _currentCurrency == ExpenseCurrency.usd ? b.amountUsd : b.amountEgp;
        return amtB.compareTo(amtA);
      });

    final paymentMethodSpending = payMap.entries.map((entry) {
      final label = AppConstants.paymentMethodLabels[entry.key] ?? entry.key;
      final percentage = total > 0 ? (entry.value / total) * 100 : 0.0;
      return PaymentMethodSpending(
        methodKey: entry.key,
        label: label,
        amount: entry.value,
        percentage: percentage,
      );
    }).toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));

    final dailySpending = dayMap.entries
        .map((e) => DailySpending(day: e.key, amount: e.value))
        .toList()
      ..sort((a, b) => a.day.compareTo(b.day));

    emit(ReportLoaded(
      selectedMonth: month,
      selectedCurrency: _currentCurrency,
      totalAmount: total,
      totalAmountEgp: totalEgp,
      totalAmountUsd: totalUsd,
      totalCount: _cachedMonthExpenses.length,
      categorySpending: categorySpending,
      employeeSpending: employeeSpending,
      paymentMethodSpending: paymentMethodSpending,
      dailySpending: dailySpending,
      isAdmin: _isAdmin,
    ));
  }

  void previousMonth() {
    final prev = DateTime(_currentMonth.year, _currentMonth.month - 1);
    loadReport(prev);
  }

  void nextMonth() {
    final next = DateTime(_currentMonth.year, _currentMonth.month + 1);
    loadReport(next);
  }

  String catIconFromKey(String icon) => icon;
}

class _CatAggr {
  _CatAggr({
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

class _EmpAggr {
  _EmpAggr({
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
